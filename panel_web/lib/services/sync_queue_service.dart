// SyncQueueService - STUB para panel web.
// En el panel web la sincronización offline no es necesaria.
// Este archivo existe solo para compatibilidad de compilación.
import 'package:flutter/foundation.dart';

class SyncQueueService {
  static final SyncQueueService instance = SyncQueueService._internal();
  SyncQueueService._internal();

  bool get isOnline => true;
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier(true);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier(false);
  final ChangeNotifier onCacheUpdated = ChangeNotifier();

  Future<void> syncPendingOperations() async {}
  Future<void> forceSyncAndRefresh() async {}
}
