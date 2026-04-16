import 'package:flutter_test/flutter_test.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';

void main() {
  group('SyncQueueService', () {
    final service = SyncQueueService.instance;

    setUp(() {
      service.pausePolling();
    });

    tearDown(() {
      service.stopListening();
    });

    test('pausePolling deactivates polling timer', () {
      service.resumePolling();
      expect(service.isPollingActive, isTrue);

      service.pausePolling();
      expect(service.isPollingActive, isFalse);
    });

    test('resumePolling activates polling timer', () {
      service.pausePolling();
      expect(service.isPollingActive, isFalse);

      service.resumePolling();
      expect(service.isPollingActive, isTrue);
    });

    test('stopListening disables polling and cancels connectivity subscription', () {
      service.resumePolling();
      expect(service.isPollingActive, isTrue);

      service.stopListening();
      expect(service.isPollingActive, isFalse);
    });
  });
}
