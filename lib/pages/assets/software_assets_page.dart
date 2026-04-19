import 'package:flutter/material.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/pages/assets/base_asset_page_state.dart';

class SoftwareAssetsPage extends StatefulWidget {
  const SoftwareAssetsPage({super.key});

  @override
  State<SoftwareAssetsPage> createState() => _SoftwareAssetsPageState();
}

class _SoftwareAssetsPageState extends BaseAssetPageState<SoftwareAssetsPage> {
  // Column definitions for SOFTWARE category
  static final List<AssetColumnDef> _softwareColumns = [
    AssetColumnDef(
      label: 'Nombre',
      getValue: (a) => a['nombre']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Código',
      getValue: (a) => a['codigo']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Tipo Activo',
      getValue: (a) => a['tipo_activo']?['tipo']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Condición',
      getValue: (a) => a['condicion_activo']?['condicion']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Custodio',
      getValue: (a) => a['custodio']?['nombre_completo']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Área',
      getValue: (a) => a['area_activo']?['area']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Proveedor',
      getValue: (a) => a['proveedor']?['nombre']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Proveedor Sw.',
      getValue: (a) {
        final list = a['info_software'];
        if (list is List && list.isNotEmpty) return list[0]['proveedor']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Fecha Inicio',
      getValue: (a) {
        final list = a['info_software'];
        if (list is List && list.isNotEmpty) return list[0]['fecha_inicio']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Fecha Fin',
      getValue: (a) {
        final list = a['info_software'];
        if (list is List && list.isNotEmpty) return list[0]['fecha_fin']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Observaciones',
      getValue: (a) {
        final list = a['info_software'];
        if (list is List && list.isNotEmpty) return list[0]['observaciones']?.toString() ?? 'N/A';
        return 'N/A';
      },
      visibleByDefault: true,
    ),
  ];

  @override
  String get pageTitle => 'Licencias y Software';

  @override
  String? get categoryName => 'SOFTWARE';

  @override
  List<AssetColumnDef> get columns => _softwareColumns;

  // Software currently doesn't have extra custom drawer filters defined,
  // so the base defaults (empty custom filters) will automatically be used.
}
