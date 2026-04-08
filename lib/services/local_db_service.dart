import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Servicio local para el manejo Offline-First de Caché y Cola de Operaciones.
/// Utiliza un esquema tipo "Document Store" (collection, id, json_data) para no 
/// depender de decenas de tablas relacionales en el móvil.
class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventarios_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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
        status TEXT NOT NULL
      )
    ''');
  }

  // ==========================================================
  // 1. MANEJO DE CACHÉ (LECTURAS)
  // ==========================================================

  /// Guarda una colección completa (útil para cuando llega la info de internet)
  Future<void> saveCollection(String collection, List<Map<String, dynamic>> items, String idKey) async {
    final db = await instance.database;
    final batch = db.batch();

    // Limpiamos los anteriores para tener siempre los datos frescos
    batch.delete('cache_storage', where: 'collection = ?', whereArgs: [collection]);

    for (final item in items) {
      batch.insert('cache_storage', {
        'collection': collection,
        'id': item[idKey].toString(),
        'json_data': jsonEncode(item),
      });
    }

    await batch.commit(noResult: true);
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
      'id': DateTime.now().millisecondsSinceEpoch.toString(), // ID simple temporal
      'rpc_name': rpcName,
      'params_json': jsonEncode(params),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    });

    // --- LÓGICA OPTIMISTA (Actualización inmediata en Caché Local) ---
    // Inject fake row to reflect immediately in the UI.
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

        await db.insert('cache_storage', {
          'collection': 'activo',
          'id': params['p_id_activo'],
          'json_data': jsonEncode(fakeRow),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

      } else if (rpcName.startsWith('table:')) {
        // Optimistic UI for generic tables (e.g. table:mantenimiento:insert)
        final parts = rpcName.split(':');
        if (parts.length >= 3) {
          final tableName = parts[1];
          final action = parts[2];
          
          if (action == 'insert' || action == 'update') {
            await db.insert('cache_storage', {
              'collection': tableName,
              'id': params['id'], // Asumiendo que params tiene 'id' siempre (como en maintenance_page)
              'json_data': jsonEncode(params),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } else if (action == 'delete') {
            await db.delete('cache_storage', 
              where: 'collection = ? AND id = ?', 
              whereArgs: [tableName, params['id']]
            );
          }
        }
      } else if (rpcName.startsWith('actualizar_activo_')) {
        // En una app más grande haríamos merge, aquí reemplazamos los top keys.
        final id = params['p_id_activo'];
        final existing = await db.query('cache_storage', where: 'collection = ? AND id = ?', whereArgs: ['activo', id]);
        if (existing.isNotEmpty) {
          Map<String, dynamic> oldData = jsonDecode(existing.first['json_data'] as String);
          oldData['numero_serie'] = params['p_numero_serie'] ?? oldData['numero_serie'];
          oldData['nombre'] = params['p_nombre'] ?? oldData['nombre'];
          oldData['codigo'] = params['p_codigo'] ?? oldData['codigo'];
          // Simple optimistic update for top fields only
          await db.update('cache_storage', {
            'json_data': jsonEncode(oldData),
          }, where: 'collection = ? AND id = ?', whereArgs: ['activo', id]);
        }
      } else if (rpcName == 'eliminar_activo') {
        final id = params['p_id_activo'];
        await db.delete('cache_storage', where: 'collection = ? AND id = ?', whereArgs: ['activo', id]);
      }
    } catch (e) {
      print('Aviso: Error inyectando cache optimista: $e');
    }
  }

  /// Obtiene las operaciones pendientes
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await instance.database;
    return await db.query('sync_queue', where: 'status = ?', whereArgs: ['pending'], orderBy: 'created_at ASC');
  }

  /// Cambia el estado de una operación para que deje de reintentarse
  Future<void> updateOperationStatus(String id, String newStatus) async {
    final db = await instance.database;
    await db.update('sync_queue', {'status': newStatus}, where: 'id = ?', whereArgs: [id]);
  }

  /// Elimina una operación de la cola tras haberse completado con éxito online
  Future<void> removeOperation(String id) async {
    final db = await instance.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }
}
