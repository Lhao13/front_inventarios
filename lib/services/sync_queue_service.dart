import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:front_inventarios/main.dart'; // import supabase
import 'package:front_inventarios/services/local_db_service.dart';

/// Servicio encargado de vigilar la conectividad a internet 
/// y ejecutar de forma automática la Sincronización (Lecturas y Escrituras).
class SyncQueueService {
  static final SyncQueueService instance = SyncQueueService._init();
  SyncQueueService._init();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _internalIsSyncing = false;

  // Notifiers for UI
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  
  bool get isOnline => isOnlineNotifier.value;
  bool get isSyncing => isSyncingNotifier.value;

  /// Inicia el Demonio para escuchar cambios en la Red
  void startListening() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        
        isOnlineNotifier.value = true;
        _handleInternetRecovered();
      } else {
        isOnlineNotifier.value = false;
        print('📡 Señal Perdida: Modo Offline Activo');
      }
    });

    // Revisión manual al arrancar
    Connectivity().checkConnectivity().then((results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        isOnlineNotifier.value = true;
        _handleInternetRecovered();
      } else {
        isOnlineNotifier.value = false;
      }
    });
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  /// Evento lanzado cuando vuelve el internet
  Future<void> _handleInternetRecovered() async {
    print('📡 Internet Recuperado. Iniciando Sincronización Automática...');
    
    // 1. Envía todo lo que se hizo offline (las escrituras ganan primero)
    await syncPendingOperations();

    // 2. Descarga lo más reciente (para tener el cache de lectura fresco)
    await refreshCache();
    
    print('📡 Sincronización Completada.');
  }

  // ==========================================================
  // 1. SINCRONIZACIÓN HACIA ARRIBA (UPLOAD OFFLINE QUEUE)
  // ==========================================================
  
  Future<void> syncPendingOperations() async {
    if (_internalIsSyncing) return;
    _internalIsSyncing = true;
    isSyncingNotifier.value = true;

    bool anythingSynced = false;
    bool hasPermanentError = false;

    try {
      final pendingOps = await LocalDbService.instance.getPendingOperations();
      
      if (pendingOps.isEmpty) {
        _internalIsSyncing = false;
        isSyncingNotifier.value = false;
        return;
      }

      print('🔄 Sincronizando ${pendingOps.length} operaciones pendientes...');

      for (var op in pendingOps) {
        final id = op['id'] as String;
        final rpcName = op['rpc_name'] as String;
        final paramsString = op['params_json'] as String;
        
        final params = jsonDecode(paramsString) as Map<String, dynamic>;

        try {
          if (rpcName.startsWith('table:')) {
            final parts = rpcName.split(':');
            final table = parts[1];
            final action = parts[2];

            if (action == 'insert') {
              await supabase.from(table).insert(params);
            } else if (action == 'update') {
              await supabase.from(table).update(params).eq('id', params['id']);
            } else if (action == 'delete') {
              await supabase.from(table).delete().eq('id', params['id']);
            }
          } else {
            // Ejecutamos el RPC guardado enviándolo a Supabase
            await supabase.rpc(rpcName, params: params);
          }
          
          // Si fue un éxito o un 200, eliminamos de la cola local
          await LocalDbService.instance.removeOperation(id);
          anythingSynced = true;
          print('✅ Operación $id ($rpcName) enviada con éxito.');
          
        } catch (e) {
          // Si hay error en Supabase (ej: Unique Constraint, Error 500)
          print('❌ Error enviando Operación $id ($rpcName): $e');
          
          final errorString = e.toString();
          // Errores permanentes: PGRST202 (función no encontrada), 23505 (llave duplicada), 23503 (llave foránea)
          if (errorString.contains('code: PGRST202') || 
              errorString.contains('code: 23505') || 
              errorString.contains('code: 23503')) {
            print('⚠️ Marcando operación $id ($rpcName) como FALLIDA (error permanente) para no reintentar infinitamente.');
            await LocalDbService.instance.updateOperationStatus(id, 'failed');
            hasPermanentError = true;
          }
        }
      }

      if (anythingSynced || hasPermanentError) {
        print('🔄 Operaciones sincronizadas o procesadas, actualizando cache local desde supabase para corregir UI...');
        await refreshCache();
      }
    } catch (e) {
      print('❌ Falla Crítica en SyncQueue: $e');
    } finally {
      _internalIsSyncing = false;
      isSyncingNotifier.value = false;
    }
  }

  // ==========================================================
  // 2. SINCRONIZACIÓN HACIA ABAJO (DOWNLOAD CACHE)
  // ==========================================================

  /// Descarga absolutamente todas las tablas necesarias y las clona en SQLite
  Future<void> refreshCache() async {
    try {
      // Usaremos try/catch separados por si una falla, que no mate la recarga de las demás
      
      // -- 1. Tabla de Activos Principal (Full Query)
      try {
        final activosResponse = await supabase.from('activo').select('''
          *,
          info_pc(*, marca(marca_proveedor)),
          info_equipo_comunicacion(*, marca(marca_proveedor)),
          info_equipo_generico(*, marca(marca_proveedor)),
          info_software(*),
          tipo_activo(tipo),
          condicion_activo(condicion),
          ciudad_activo(ciudad),
          sede_activo(sede),
          area_activo(area),
          proveedor(nombre),
          custodio(nombre_completo)
        ''');
        // Salvamos en la colección 'activo' (cuyo ID primario es 'id' tipo UUID)
        await LocalDbService.instance.saveCollection('activo', List<Map<String, dynamic>>.from(activosResponse), 'id');
      } catch (e) { print('Error cacheando Activos: $e'); }

      // -- 2. Tabla Mantenimientos
      try {
        final mttoResponse = await supabase
            .from('mantenimiento')
            .select('*, activo(numero_serie, tipo_activo(tipo))');
        await LocalDbService.instance.saveCollection('mantenimiento', List<Map<String, dynamic>>.from(mttoResponse), 'id');
      } catch (e) { print('Error cacheando Mantenimientos: $e'); }

      // -- 3. Tablas Maestras
      await _cacheSimpleTable('tipo_activo');
      await _cacheSimpleTable('condicion_activo');
      await _cacheSimpleTable('custodio');
      await _cacheSimpleTable('ciudad_activo');
      await _cacheSimpleTable('sede_activo');
      await _cacheSimpleTable('area_activo');
      await _cacheSimpleTable('proveedor');
      await _cacheSimpleTable('marca');

    } catch (e) {
      print('❌ Error general recargando caché: $e');
    }
  }

  Future<void> _cacheSimpleTable(String tableName) async {
    try {
      final resp = await supabase.from(tableName).select();
      await LocalDbService.instance.saveCollection(tableName, List<Map<String, dynamic>>.from(resp), 'id');
    } catch (e) {
      print('Error en caching de tabla maestra $tableName: $e');
    }
  }
}
