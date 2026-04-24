import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:front_inventarios/services/local_db_service.dart';



/// Servicio encargado de vigilar la conectividad a internet 
/// y ejecutar de forma automática la Sincronización (Lecturas y Escrituras).
class SyncQueueService {
  static final SyncQueueService instance = SyncQueueService._init();
  SyncQueueService._init();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _internalIsSyncing = false;
  bool _internalIsRefreshing = false;
  Timer? _pollingTimer; // Timer para autorecarga iterativa
  RealtimeChannel? _realtimeChannel;
  DateTime? _ignoreRealtimeUntil;

  // Notifiers for UI
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasSyncErrorsNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime> onCacheUpdated = ValueNotifier<DateTime>(DateTime.now()); // Para notificar a las pantallas

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
        debugPrint('📡 Señal Perdida: Modo Offline Activo');
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

    // Arrancar el Polling Automático (Cada 30 segundos si hay internet)
    _startPolling();
    
    // Configurar Realtime si hay sesión
    _setupRealtime();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (isOnline && Supabase.instance.client.auth.currentSession != null) {
        await forceSyncAndRefresh();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void pausePolling() {
    _stopPolling();
    stopRealtime();
    debugPrint('⏳ Polling y Realtime pausados.');
  }

  bool get isPollingActive => _pollingTimer?.isActive ?? false;

  void resumePolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;
    _startPolling();
    if (isOnline) {
      _setupRealtime();
    }
    debugPrint('▶️ SyncQueue polling reanudado (Online: $isOnline).');
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
    _stopPolling();
    stopRealtime();
  }

  /// Evento lanzado cuando vuelve el internet
  Future<void> _handleInternetRecovered() async {
    if (Supabase.instance.client.auth.currentSession == null) {
      debugPrint('📡 Internet Recuperado pero no hay sesión activa. Posponiendo Sincronización.');
      return;
    }

    debugPrint('📡 Internet Recuperado. Iniciando Sincronización Automática...');
    
    // 1. Envía todo lo que se hizo offline (las escrituras ganan primero)
    await syncPendingOperations();

    // 2. Descarga lo más reciente (para tener el cache de lectura fresco)
    await refreshCache();
    
    // 3. Reconectar Realtime
    _setupRealtime();
    
    debugPrint('📡 Sincronización Completada.');
  }

  /// Forzado manual desde la UI para empujar cambios pendientes y traer caché fresca
  Future<void> forceSyncAndRefresh() async {
    if (!isOnlineNotifier.value) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    
    debugPrint('🔄 Sincronización Manual Solicitada...');
    // 1. Intentamos subir (esto ignorará si ya hay otra subida en curso)
    await syncPendingOperations();
    // 2. Obligamos a recargar la caché sí o sí
    await refreshCache();
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

      debugPrint('🔄 Sincronizando ${pendingOps.length} operaciones pendientes...');

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
              await Supabase.instance.client.from(table).insert(params);
            } else if (action == 'update') {
              await Supabase.instance.client.from(table).update(params).eq('id', params['id']);
            } else if (action == 'delete') {
              await Supabase.instance.client.from(table).delete().eq('id', params['id']);
            }
          } else {
            // Ejecutamos el RPC guardado enviándolo a Supabase
            await Supabase.instance.client.rpc(rpcName, params: params);
          }
          
          // Si fue un éxito o un 200, eliminamos de la cola local
          await LocalDbService.instance.removeOperation(id);
          anythingSynced = true;
          debugPrint('✅ Operación $id ($rpcName) enviada con éxito.');
          
        } on PostgrestException catch (e) {
          final errorString = e.message;
          final errorCode = e.code;
          
          // Errores permanentes: 23505 (Unique violation), P0001 (Raise exception), 23503 (FK), 42703 (Column not found)
          bool isPermanent = errorCode == '23505' || errorCode == 'P0001' || errorCode == '23503' || (errorCode != null && errorCode.startsWith('42'));

          if (isPermanent) {
            debugPrint('🚫 Operación $id RECHAZADA (Error Permanente $errorCode): $errorString');
            await LocalDbService.instance.updateOperationStatus(id, 'rejected', errorMsg: errorString);
            hasPermanentError = true;
          } else {
            debugPrint('⚠️ Error temporal en sync: $errorString. Se queda en cola.');
            await LocalDbService.instance.updateOperationStatus(id, 'failed', errorMsg: errorString);
          }
        } catch (e) {
          debugPrint('❌ Error genérico en sync: $e');
          await LocalDbService.instance.updateOperationStatus(id, 'failed', errorMsg: e.toString());
        }
      }

      if (hasPermanentError) {
         hasSyncErrorsNotifier.value = true;
      }

      if (anythingSynced || hasPermanentError) {
        debugPrint('🔄 Sincronización de cola finalizada. Iniciando periodo de silencio de Realtime (10s) para evitar ruidos...');
        
        // Bloqueamos Realtime por 10 segundos para que los ecos de nuestras propias 
        // operaciones no ensucien la base de datos mientras terminamos de estabilizar.
        _ignoreRealtimeUntil = DateTime.now().add(const Duration(seconds: 10));

        // Programamos un refresco de integridad para CUANDO PASE el ruido
        Future.delayed(const Duration(seconds: 10), () async {
          debugPrint('🧹 Fin del silencio. Ejecutando Refresco de Integridad Final...');
          await refreshCache();
          _ignoreRealtimeUntil = null;
        });
      }
    } catch (e) {
      debugPrint('❌ Falla Crítica en SyncQueue: $e');
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
    if (Supabase.instance.client.auth.currentSession == null) return;
    if (_internalIsRefreshing) return;
    
    _internalIsRefreshing = true;
    if (!isSyncingNotifier.value) {
      isSyncingNotifier.value = true;
    }

    try {
      // Usaremos try/catch separados por si una falla, que no mate la recarga de las demás
      
      // -- 1. Tabla de Activos Principal (Full Query Vía RPC)
      try {
        final activosResponse = await Supabase.instance.client.rpc('get_activos_completos');
        if (activosResponse != null) {
          await LocalDbService.instance.saveCollection(
            'activo', 
            List<Map<String, dynamic>>.from(activosResponse as List), 
            'id'
          );
        }
      } catch (e) { debugPrint('Error cacheando Activos: $e'); }

      // -- 2. Tabla Mantenimientos
      try {
        final mttoResponse = await Supabase.instance.client
            .from('mantenimiento')
            .select('*, activo(numero_serie, tipo_activo(tipo))');
        
        await LocalDbService.instance.saveCollection(
          'mantenimiento', 
          List<Map<String, dynamic>>.from(mttoResponse), 
          'id'
        );
      } catch (e) { debugPrint('Error cacheando Mantenimientos: $e'); }

      // -- 3. Tablas Maestras
      await _cacheSimpleTable('tipo_activo');
      await _cacheSimpleTable('condicion_activo');
      await _cacheSimpleTable('custodio');
      await _cacheSimpleTable('ciudad_activo');
      await _cacheSimpleTable('sede_activo');
      await _cacheSimpleTable('area_activo');
      await _cacheSimpleTable('proveedor');
      await _cacheSimpleTable('marca');

      // Notificar a toda la interfaz que los datos han cambiado
      onCacheUpdated.value = DateTime.now();
    } catch (e) {
      debugPrint('❌ Error general recargando caché: $e');
    } finally {
      _internalIsRefreshing = false;
      if (!_internalIsSyncing) {
        isSyncingNotifier.value = false;
      }
    }
  }

  Future<void> _cacheSimpleTable(String tableName) async {
    try {
      final resp = await Supabase.instance.client.from(tableName).select();
      await LocalDbService.instance.saveCollection(
        tableName, 
        List<Map<String, dynamic>>.from(resp), 
        'id'
      );
    } catch (e) {
      debugPrint('Error en caching de tabla maestra $tableName: $e');
    }
  }

  // ==========================================================
  // 3. REALTIME (PUSH NOTIFICATIONS FROM SUPABASE)
  // ==========================================================

  bool _isSettingUpRealtime = false;

  /// Configura la suscripción a cambios en tiempo real de Supabase
  void _setupRealtime() async {
    if (!isOnline || _isSettingUpRealtime) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    _isSettingUpRealtime = true;
    try {
      // 1. Limpieza total y drástica de canales previos
      debugPrint('📡 Limpiando todos los canales Realtime...');
      await Supabase.instance.client.removeAllChannels();
      _realtimeChannel = null;

      // Un pequeño respiro para el servidor de Supabase
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Crear canal con nombre ÚNICO para evitar colisiones 1001 o null
      final channelId = 'db-changes-${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('📡 Configurando nuevo canal Realtime: $channelId');
      _realtimeChannel = Supabase.instance.client.channel(channelId);
      
      // Escuchar cambios en activos
      _realtimeChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'activo',
        callback: (payload) async => await _handleRealtimePayload(payload, 'Activo'),
      );

      // Escuchar cambios en mantenimientos
      _realtimeChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'mantenimiento',
        callback: (payload) async => await _handleRealtimePayload(payload, 'Mantenimiento'),
      );

      _realtimeChannel!.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('✅ Suscrito con éxito al canal: $channelId');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          debugPrint('❌ Error en Suscripción Realtime ($channelId): $error');
        }
      });
    } catch (e) {
      debugPrint('⚠️ Fallo en el setup de Realtime: $e');
    } finally {
      _isSettingUpRealtime = false;
    }
  }

  /// Detiene y limpia la conexión Realtime
  Future<void> stopRealtime() async {
    if (_realtimeChannel != null) {
      try {
        debugPrint('📡 Cerrando canal Realtime previo...');
        await Supabase.instance.client.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      } catch (e) {
        debugPrint('⚠️ Error al cerrar canal Realtime: $e');
      }
    }
  }

  Future<void> _handleRealtimePayload(PostgresChangePayload payload, String source) async {
    // Si estamos en periodo de "silencio" (post-sincronización masiva), ignoramos el mensaje
    if (_ignoreRealtimeUntil != null && DateTime.now().isBefore(_ignoreRealtimeUntil!)) {
      debugPrint('🔇 Realtime: Ignorando mensaje por periodo de silencio (estabilizando sync)...');
      return;
    }

    final table = payload.table;
    final event = payload.eventType;

    if (event == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'];
      if (oldId != null) {
        debugPrint('🗑️ Realtime: Eliminando $source localmente ($oldId)');
        await LocalDbService.instance.removeFromCollection(table, oldId.toString());
        onCacheUpdated.value = DateTime.now();
      }
    } else {
      // Para Insert o Update, descargamos solo ese registro (Sincronización Quirúrgica)
      final newId = payload.newRecord['id'];
      if (newId != null) {
        await _refreshSingleRow(table, newId.toString(), source);
      }
    }
  }

  Future<void> _refreshSingleRow(String table, String id, String sourceName) async {
    try {
      Map<String, dynamic>? data;

      if (table == 'activo') {
        // Obtenemos el activo con todos sus joins necesarios para la UI
        data = await Supabase.instance.client
            .from('activo')
            .select('''
              *,
              tipo_activo(tipo),
              condicion_activo(condicion),
              custodio(nombre_completo),
              ciudad_activo(ciudad),
              sede_activo(sede),
              area_activo(area),
              proveedor(nombre),
              info_pc(*, marca(marca_proveedor)),
              info_software(*),
              info_equipo_comunicacion(*, marca(marca_proveedor)),
              info_equipo_generico(*, marca(marca_proveedor))
            ''')
            .eq('id', id)
            .maybeSingle();
      } else if (table == 'mantenimiento') {
        data = await Supabase.instance.client
            .from('mantenimiento')
            .select('*, activo(numero_serie, tipo_activo(tipo))')
            .eq('id', id)
            .maybeSingle();
      } else {
        // Tablas maestras
        data = await Supabase.instance.client
            .from(table)
            .select()
            .eq('id', id)
            .maybeSingle();
      }

      if (data != null) {
        debugPrint('✨ Realtime: Actualizando $sourceName localmente ($id)');
        await LocalDbService.instance.upsertToCollection(table, data, id);
        onCacheUpdated.value = DateTime.now();
      }
    } catch (e) {
      debugPrint('⚠️ Error en refresco quirúrgico ($table:$id): $e');
      // Si falla el quirúrgico por alguna razón, usamos el refresh completo como salvavidas
      refreshCache();
    }
  }
}

