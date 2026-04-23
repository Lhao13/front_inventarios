import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';

/// Servicio local para el manejo Offline-First de Caché y Cola de Operaciones.
/// Utiliza un esquema tipo "Document Store" (collection, id, json_data) para no 
/// depender de decenas de tablas relacionales en el móvil.
class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;
  static String _databaseFileName = 'inventarios_offline.db';

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseFileName);
    return _database!;
  }

  static const int _databaseVersion = 2;

  @visibleForTesting
  static void setDatabaseFileNameForTesting(String fileName) {
    _databaseFileName = fileName;
  }

  @visibleForTesting
  static Future<void> resetDatabaseForTesting() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseFileName);
    try {
      await deleteDatabase(path);
    } catch (_) {}
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrateDatabase(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _migrateDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion >= newVersion) return;

    await db.transaction((txn) async {
      var version = oldVersion;
      while (version < newVersion) {
        final nextVersion = version + 1;
        switch (nextVersion) {
          case 2:
            await _migrateToVersion2(txn);
            break;
          // case 3:
          //   await _migrateToVersion3(txn);
          //   break;
          default:
            throw Exception('Migración desconocida de la versión $version a $nextVersion');
        }
        version = nextVersion;
      }
    });
  }

  Future<void> _migrateToVersion2(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE sync_queue ADD COLUMN error_msg TEXT');
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla caché estilo Document Store para lectura de todas las tablas
    await db.execute('''
      CREATE TABLE cache_storage (
        collection TEXT NOT NULL,
        id TEXT NOT NULL,
        json_data TEXT NOT NULL,
        PRIMARY KEY (collection, id)
      )
    ''');

    // Tabla de cola de operaciones offline para envíos pendientes
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        rpc_name TEXT NOT NULL,
        params_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        error_msg TEXT
      )
    ''');
  }

  // ==========================================================
  // 1. MANEJO DE CACHÉ (LECTURAS)
  // ==========================================================

  /// Guarda una colección completa (útil para cuando llega la info de internet)
  Future<void> saveCollection(String collection, List<Map<String, dynamic>> items, String idKey) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
      // 1. LIMPIAR lo que tenemos localmente para esta colección 
      await txn.delete('cache_storage', where: 'collection = ?', whereArgs: [collection]);

      // 2. INSERTAR la data fresca
      if (items.isNotEmpty) {
        final batch = txn.batch();
        for (final item in items) {
          batch.insert('cache_storage', {
            'collection': collection,
            'id': item[idKey].toString(),
            'json_data': jsonEncode(item),
          });
        }
        await batch.commit(noResult: true);
      }

      // 3. RE-APLICAR cambios optimistas (Solo los PENDIENTES, no los fallidos/rechazados)
      final pending = await txn.query('sync_queue', where: 'status = ?', whereArgs: ['pending']);
      for (final row in pending) {
        final rpcName = row['rpc_name'] as String;
        final params = jsonDecode(row['params_json'] as String) as Map<String, dynamic>;
        await _applyOptimisticToTxn(txn, rpcName, params);
      }
    });
  }

  /// Inserta o actualiza un único registro en la caché local (Sincronización Quirúrgica)
  Future<void> upsertToCollection(String collection, Map<String, dynamic> item, String idValue) async {
    final db = await instance.database;
    await db.insert('cache_storage', {
      'collection': collection,
      'id': idValue,
      'json_data': jsonEncode(item),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Elimina un único registro de la caché local
  Future<void> removeFromCollection(String collection, String idValue) async {
    final db = await instance.database;
    await db.delete('cache_storage', 
      where: 'collection = ? AND id = ?', 
      whereArgs: [collection, idValue]
    );
  }

  /// Recupera una colección desde el caché local offline
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final db = await instance.database;
    final res = await db.query(
      'cache_storage',
      where: 'collection = ?',
      whereArgs: [collection],
    );

    return res.map((row) => jsonDecode(row['json_data'] as String) as Map<String, dynamic>).toList();
  }

  /// Limpia toda la base de datos local
  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('cache_storage');
    await db.delete('sync_queue');
  }

  // ==========================================================
  // 2. MANEJO DE COLA DE OPERACIONES (ESCRITURAS OFFLINE)
  // ==========================================================

  /// Añade una instrucción RPC a la cola para ser ejecutada cuando haya internet
  Future<void> enqueueOperation(String rpcName, Map<String, dynamic> params) async {
    final db = await instance.database;
    // Si la operación falla, se queda en pendiente ("pending")
    await db.insert('sync_queue', {
      'id': const Uuid().v4(), // UUID v4 garantiza unicidad sin condición de carrera
      'rpc_name': rpcName,
      'params_json': jsonEncode(params),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    });

    // --- LÓGICA OPTIMISTA (Actualización inmediata en Caché Local) ---
    // Inject fake row to reflect immediately in the UI.
    await db.transaction((txn) async {
      await _applyOptimisticToTxn(txn, rpcName, params);
    });

    // NOTIFICAR a la UI que hubo un cambio local (Optimismo)
    SyncQueueService.instance.onCacheUpdated.value = DateTime.now();
  }

  /// Parcha la caché local con datos "falsos" mientras la operación se sincroniza.
  Future<void> _applyOptimisticToTxn(DatabaseExecutor txn, String rpcName, Map<String, dynamic> params) async {
    try {
      if (rpcName.startsWith('crear_activo_')) {
        String cat = 'PC';
        if (rpcName.contains('_comunicacion')) cat = 'COMUNICACION';
        if (rpcName.contains('_software')) cat = 'SOFTWARE';
        if (rpcName.contains('_generico')) cat = 'GENERICO';

        Map<String, dynamic> fakeRow = {
          'id': params['p_id_activo'],
          'numero_serie': params['p_numero_serie'],
          'nombre': params['p_nombre'],
          'codigo': params['p_codigo'],
          'categoria_activo': cat,
          'id_tipo_activo': params['p_id_tipo_activo'],
          'id_condicion_activo': params['p_id_condicion_activo'],
          'id_custodio': params['p_id_custodio'],
          'id_sede_activo': params['p_id_sede_activo'],
          'id_area_activo': params['p_id_area_activo'],
          'id_provedor': params['p_id_provedor'],
          'fecha_adquisicion': params['p_fecha_adquisicion'],
          'fecha_entrega': params['p_fecha_entrega'],
          'ip': params['p_ip'],
          'coordenada': params['p_coordenada'],
        };
        
        // Joined fakes
        if (cat == 'PC') {
          fakeRow['info_pc'] = [{
            'procesador': params['p_procesador'],
            'ram': params['p_ram'],
            'almacenamiento': params['p_almacenamiento'],
            'modelo': params['p_modelo'],
            'id_marca': params['p_id_marca'],
            'cargador_codigo': params['p_cargador_codigo'],
            'num_puertos': params['p_num_puertos'],
            'observaciones': params['p_observaciones'],
          }];
        } else if (cat == 'SOFTWARE') {
          fakeRow['info_software'] = [{
            'proveedor_software': params['p_proveedor_software'],
            'fecha_inicio': params['p_fecha_inicio'],
            'fecha_fin': params['p_fecha_fin'],
            'observaciones': params['p_observaciones'],
          }];
        } else if (cat == 'COMUNICACION') {
          fakeRow['info_equipo_comunicacion'] = [{
            'num_puertos': params['p_num_puertos'],
            'num_conexiones': params['p_num_conexiones'],
            'tipo_extension': params['p_tipo_extension'],
            'id_marca': params['p_id_marca'],
            'modelo': params['p_modelo'],
            'observaciones': params['p_observaciones'],
          }];
        } else if (cat == 'GENERICO') {
            fakeRow['info_equipo_generico'] = [{
              'id_marca': params['p_id_marca'],
              'modelo': params['p_modelo'],
              'observaciones': params['p_observaciones'],
          }];
        }

        await txn.insert('cache_storage', {
          'collection': 'activo',
          'id': params['p_id_activo'],
          'json_data': jsonEncode(fakeRow),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

      } else if (rpcName.startsWith('table:')) {
        final parts = rpcName.split(':');
        if (parts.length >= 3) {
          final tableName = parts[1];
          final action = parts[2];
          
          if (action == 'insert' || action == 'update') {
            await txn.insert('cache_storage', {
              'collection': tableName,
              'id': params['id'].toString(), 
              'json_data': jsonEncode(params),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } else if (action == 'delete') {
            await txn.delete('cache_storage', 
              where: 'collection = ? AND id = ?', 
              whereArgs: [tableName, params['id'].toString()]
            );
          }
        }
      } else if (rpcName.startsWith('actualizar_activo_')) {
        final id = params['p_id_activo'];
        final existing = await txn.query('cache_storage', where: 'collection = ? AND id = ?', whereArgs: ['activo', id]);
        if (existing.isNotEmpty) {
          Map<String, dynamic> oldData = jsonDecode(existing.first['json_data'] as String);
          
          // --- 1. Actualización de Campos Básicos ---
          oldData['numero_serie'] = params['p_numero_serie'] ?? oldData['numero_serie'];
          oldData['nombre'] = params['p_nombre'] ?? oldData['nombre'];
          oldData['codigo'] = params['p_codigo'] ?? oldData['codigo'];
          oldData['ip'] = params['p_ip'] ?? oldData['ip'];
          oldData['coordenada'] = params['p_coordenada'] ?? oldData['coordenada'];
          oldData['fecha_adquisicion'] = params['p_fecha_adquisicion'] ?? oldData['fecha_adquisicion'];
          oldData['fecha_entrega'] = params['p_fecha_entrega'] ?? oldData['fecha_entrega'];
          
          // IDs de llaves foráneas
          oldData['id_tipo_activo'] = params['p_id_tipo_activo'] ?? oldData['id_tipo_activo'];
          oldData['id_area_activo'] = params['p_id_area_activo'] ?? oldData['id_area_activo'];
          oldData['id_sede_activo'] = params['p_id_sede_activo'] ?? oldData['id_sede_activo'];
          oldData['id_ciudad_activo'] = params['p_id_ciudad_activo'] ?? oldData['id_ciudad_activo'];
          oldData['id_condicion_activo'] = params['p_id_condicion_activo'] ?? oldData['id_condicion_activo'];
          oldData['id_custodio'] = params['p_id_custodio'] ?? oldData['id_custodio'];
          oldData['id_provedor'] = params['p_id_proveedor'] ?? oldData['id_provedor'];

          // --- 2. Actualización de Objetos Anidados (para la UI) ---
          Future<void> injectNested(String paramKey, String table, String fieldKey) async {
            final fId = params[paramKey];
            if (fId != null) {
              final nested = await txn.query('cache_storage', where: 'collection = ? AND id = ?', whereArgs: [table, fId.toString()]);
              if (nested.isNotEmpty) oldData[fieldKey] = jsonDecode(nested.first['json_data'] as String);
            }
          }

          await injectNested('p_id_tipo_activo', 'tipo_activo', 'tipo_activo');
          await injectNested('p_id_area_activo', 'area_activo', 'area_activo');
          await injectNested('p_id_sede_activo', 'sede_activo', 'sede_activo');
          await injectNested('p_id_ciudad_activo', 'ciudad_activo', 'ciudad_activo');
          await injectNested('p_id_condicion_activo', 'condicion_activo', 'condicion_activo');
          await injectNested('p_id_custodio', 'custodio', 'custodio');
          await injectNested('p_id_proveedor', 'proveedor', 'proveedor');

          // --- 3. Actualización de Tablas de Info (PC, Software, etc) ---
          if (rpcName.contains('_pc')) {
            List<dynamic> infoList = oldData['info_pc'] ?? [{}];
            Map<String, dynamic> info = Map<String, dynamic>.from(infoList[0]);
            info['procesador'] = params['p_procesador'] ?? info['procesador'];
            info['ram'] = params['p_ram'] ?? info['ram'];
            info['almacenamiento'] = params['p_almacenamiento'] ?? info['almacenamiento'];
            info['modelo'] = params['p_modelo'] ?? info['modelo'];
            info['id_marca'] = params['p_id_marca'] ?? info['id_marca'];
            info['cargador_codigo'] = params['p_cargador_codigo'] ?? info['cargador_codigo'];
            info['num_puertos'] = params['p_num_puertos'] ?? info['num_puertos'];
            info['observaciones'] = params['p_observaciones'] ?? info['observaciones'];
            
            if (params['p_id_marca'] != null) {
              final m = await txn.query('cache_storage', where: 'collection = ? AND id = ?', whereArgs: ['marca', params['p_id_marca'].toString()]);
              if (m.isNotEmpty) info['marca'] = jsonDecode(m.first['json_data'] as String);
            }
            oldData['info_pc'] = [info];

          } else if (rpcName.contains('_software')) {
            List<dynamic> infoList = oldData['info_software'] ?? [{}];
            Map<String, dynamic> info = Map<String, dynamic>.from(infoList[0]);
            info['proveedor_software'] = params['p_proveedor_software'] ?? info['proveedor_software'];
            info['fecha_inicio'] = params['p_fecha_inicio'] ?? info['fecha_inicio'];
            info['fecha_fin'] = params['p_fecha_fin'] ?? info['fecha_fin'];
            info['observaciones'] = params['p_observaciones'] ?? info['observaciones'];
            oldData['info_software'] = [info];

          } else if (rpcName.contains('_comunicacion')) {
            List<dynamic> infoList = oldData['info_equipo_comunicacion'] ?? [{}];
            Map<String, dynamic> info = Map<String, dynamic>.from(infoList[0]);
            info['num_puertos'] = params['p_num_puertos'] ?? info['num_puertos'];
            info['num_conexiones'] = params['p_num_conexiones'] ?? info['num_conexiones'];
            info['tipo_extension'] = params['p_tipo_extension'] ?? info['tipo_extension'];
            info['modelo'] = params['p_modelo'] ?? info['modelo'];
            info['id_marca'] = params['p_id_marca'] ?? info['id_marca'];
            info['observaciones'] = params['p_observaciones'] ?? info['observaciones'];
            
            if (params['p_id_marca'] != null) {
              final m = await txn.query('cache_storage', where: 'collection = ? AND id = ?', whereArgs: ['marca', params['p_id_marca'].toString()]);
              if (m.isNotEmpty) info['marca'] = jsonDecode(m.first['json_data'] as String);
            }
            oldData['info_equipo_comunicacion'] = [info];

          } else if (rpcName.contains('_generico')) {
            List<dynamic> infoList = oldData['info_equipo_generico'] ?? [{}];
            Map<String, dynamic> info = Map<String, dynamic>.from(infoList[0]);
            info['modelo'] = params['p_modelo'] ?? info['modelo'];
            info['id_marca'] = params['p_id_marca'] ?? info['id_marca'];
            info['observaciones'] = params['p_observaciones'] ?? info['observaciones'];
            
            if (params['p_id_marca'] != null) {
              final m = await txn.query('cache_storage', where: 'collection = ? AND id = ?', whereArgs: ['marca', params['p_id_marca'].toString()]);
              if (m.isNotEmpty) info['marca'] = jsonDecode(m.first['json_data'] as String);
            }
            oldData['info_equipo_generico'] = [info];
          }

          await txn.update('cache_storage', {
            'json_data': jsonEncode(oldData),
          }, where: 'collection = ? AND id = ?', whereArgs: ['activo', id]);
        }
      } else if (rpcName == 'eliminar_activo') {
        final id = params['p_id_activo'];
        await txn.delete('cache_storage', where: 'collection = ? AND id = ?', whereArgs: ['activo', id]);
      }
    } catch (e) {
      debugPrint('Aviso: Error inyectando cache optimista: $e');
    }
  }

  /// Obtiene las operaciones pendientes y fallidas
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await instance.database;
    return await db.query('sync_queue', where: 'status IN (?, ?)', whereArgs: ['pending', 'failed'], orderBy: 'created_at ASC');
  }

  /// Cambia el estado de una operación para que deje de reintentarse (y opcionalmente guarda el error)
  Future<void> updateOperationStatus(String id, String newStatus, {String? errorMsg}) async {
    final db = await instance.database;
    final Map<String, dynamic> data = {'status': newStatus};
    if (errorMsg != null) {
      data['error_msg'] = errorMsg;
    }
    await db.update('sync_queue', data, where: 'id = ?', whereArgs: [id]);
  }

  /// Elimina una operación de la cola tras haberse completado con éxito online
  Future<void> removeOperation(String id) async {
    final db = await instance.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }
}
