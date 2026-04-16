import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_inventarios/utils/asset_filter.dart';

void main() {
  group('AssetFilterCriteria', () {
    final assetA = {
      'id_tipo_activo': 1,
      'id_condicion_activo': 2,
      'id_sede_activo': 3,
      'id_area_activo': 4,
      'id_ciudad_activo': 5,
      'id_custodio': 6,
      'id_provedor': 7,
      'nombre': 'Computadora',
      'codigo': 'PC-001',
      'numero_serie': 'SN1234',
      'fecha_adquisicion': '2024-01-15',
      'fecha_entrega': '2024-07-15',
      'info_pc': [
        {'id_marca': 11},
      ],
    };

    test('matches when all filters are empty', () {
      final criteria = const AssetFilterCriteria();
      expect(criteria.matches(assetA), isTrue);
    });

    test('filters by tipo activo and marca', () {
      final criteria = AssetFilterCriteria(
        selectedTiposActivo: {1},
        selectedMarcas: {11},
      );

      expect(criteria.matches(assetA), isTrue);
    });

    test('does not match when codigo differs', () {
      final criteria = AssetFilterCriteria(
        selectedCodigos: {'PC-999'},
      );

      expect(criteria.matches(assetA), isFalse);
    });

    test('applies date range restrictions correctly', () {
      final criteria = AssetFilterCriteria(
        rangoAdquisicion: DateTimeRange(
          start: DateTime(2024, 01, 01),
          end: DateTime(2024, 01, 31),
        ),
        rangoEntrega: DateTimeRange(
          start: DateTime(2024, 07, 01),
          end: DateTime(2024, 07, 31),
        ),
      );

      expect(criteria.matches(assetA), isTrue);
    });

    test('does not match when fecha_adquisicion is outside range', () {
      final criteria = AssetFilterCriteria(
        rangoAdquisicion: DateTimeRange(
          start: DateTime(2024, 02, 01),
          end: DateTime(2024, 02, 28),
        ),
      );

      expect(criteria.matches(assetA), isFalse);
    });

    test('apply returns only matching assets', () {
      final criteria = AssetFilterCriteria(selectedNombres: {'Computadora'});
      final result = criteria.apply([assetA, {...assetA, 'nombre': 'Impresora'}]);

      expect(result.length, 1);
      expect(result.first['nombre'], 'Computadora');
    });
  });
}
