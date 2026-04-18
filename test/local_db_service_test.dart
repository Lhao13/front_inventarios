import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:front_inventarios/services/local_db_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('LocalDbService', () {
    const testDbFileName = 'test_inventarios_offline.db';

    setUp(() async {
      LocalDbService.setDatabaseFileNameForTesting(testDbFileName);
      await LocalDbService.resetDatabaseForTesting();
    });

    tearDown(() async {
      await LocalDbService.resetDatabaseForTesting();
    });

    test('saveCollection and getCollection should persist items', () async {
      final items = [
        {'id': '1', 'nombre': 'Activo A'},
        {'id': '2', 'nombre': 'Activo B'},
      ];

      await LocalDbService.instance.saveCollection('activo', items, 'id');
      final result = await LocalDbService.instance.getCollection('activo');

      expect(result, hasLength(2));
      expect(result.first['nombre'], 'Activo A');
      expect(result.last['nombre'], 'Activo B');
    });

    test(
      'enqueueOperation stores a pending operation and optimistic cache entry',
      () async {
        final params = {
          'p_id_activo': 'activo-123',
          'p_numero_serie': 'SN0001',
          'p_nombre': 'Laptop Test',
          'p_codigo': 'LT-001',
          'p_id_tipo_activo': 1,
          'p_id_condicion_activo': 2,
          'p_id_custodio': 3,
          'p_id_sede_activo': 4,
          'p_id_area_activo': 5,
          'p_id_provedor': 6,
          'p_fecha_adquisicion': '2024-01-01',
          'p_fecha_entrega': '2024-01-10',
          'p_ip': '192.168.0.1',
          'p_coordenada': '0,0',
          'p_procesador': 'Intel',
          'p_ram': '16GB',
          'p_almacenamiento': '512GB',
          'p_modelo': 'Model X',
          'p_id_marca': 11,
          'p_cargador_codigo': 'CHG-01',
          'p_num_puertos': 4,
          'p_observaciones': 'Test',
        };

        await LocalDbService.instance.enqueueOperation(
          'crear_activo_pc',
          params,
        );
        final pending = await LocalDbService.instance.getPendingOperations();
        final cache = await LocalDbService.instance.getCollection('activo');

        expect(pending, isNotEmpty);
        expect(pending.first['rpc_name'], 'crear_activo_pc');
        expect(cache, hasLength(1));
        expect(cache.first['id'], 'activo-123');
        expect(cache.first['nombre'], 'Laptop Test');
      },
    );

    test(
      'updateOperationStatus and removeOperation manage queue entries',
      () async {
        await LocalDbService.instance.enqueueOperation(
          'table:mantenimiento:insert',
          {'id': 'mtt-1', 'nombre': 'Mantenimiento test'},
        );

        final pendingBefore = await LocalDbService.instance
            .getPendingOperations();
        expect(pendingBefore, hasLength(1));

        final opId = pendingBefore.first['id'] as String;
        await LocalDbService.instance.updateOperationStatus(
          opId,
          'failed',
          errorMsg: 'Error de prueba',
        );

        final pendingAfterUpdate = await LocalDbService.instance
            .getPendingOperations();
        expect(pendingAfterUpdate, hasLength(1));
        expect(pendingAfterUpdate.first['status'], 'failed');
        expect(
          pendingAfterUpdate.first['error_msg'],
          contains('Error de prueba'),
        );

        await LocalDbService.instance.removeOperation(opId);
        final pendingAfterRemove = await LocalDbService.instance
            .getPendingOperations();
        expect(pendingAfterRemove, isEmpty);
      },
    );

    test('clearAll removes cached collections and queue entries', () async {
      await LocalDbService.instance.saveCollection('activo', [
        {'id': '1', 'nombre': 'Activo A'},
      ], 'id');
      await LocalDbService.instance.enqueueOperation(
        'table:mantenimiento:insert',
        {'id': 'mtt-2', 'nombre': 'Mantenimiento test'},
      );

      await LocalDbService.instance.clearAll();
      final cache = await LocalDbService.instance.getCollection('activo');
      final pending = await LocalDbService.instance.getPendingOperations();

      expect(cache, isEmpty);
      expect(pending, isEmpty);
    });
  });
}
