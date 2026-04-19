import 'package:flutter/material.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/pages/assets/base_asset_page_state.dart';

class GenericAssetsPage extends StatefulWidget {
  const GenericAssetsPage({super.key});

  @override
  State<GenericAssetsPage> createState() => _GenericAssetsPageState();
}

class _GenericAssetsPageState extends BaseAssetPageState<GenericAssetsPage> {
  // Column definitions for GENERICO category
  static final List<AssetColumnDef> _genericColumns = [
    AssetColumnDef(label: 'S/N', getValue: (a) => a['numero_serie']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Nombre', getValue: (a) => a['nombre']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Código', getValue: (a) => a['codigo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Tipo Activo', getValue: (a) => a['tipo_activo']?['tipo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Condición', getValue: (a) => a['condicion_activo']?['condicion']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Custodio', getValue: (a) => a['custodio']?['nombre_completo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Ciudad', getValue: (a) => a['ciudad_activo']?['ciudad']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Sede', getValue: (a) => a['sede_activo']?['sede']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Área', getValue: (a) => a['area_activo']?['area']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Proveedor', getValue: (a) => a['proveedor']?['nombre']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Fe. Adquisición', getValue: (a) => a['fecha_adquisicion']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'IP', getValue: (a) => a['ip']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Fe. Entrega', getValue: (a) => a['fecha_entrega']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Coordenada', getValue: (a) => a['coordenada']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(
      label: 'Marca',
      getValue: (a) {
        final list = a['info_equipo_generico'];
        if (list is List && list.isNotEmpty) return list[0]['marca']?['marca_proveedor']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Modelo',
      getValue: (a) {
        final list = a['info_equipo_generico'];
        if (list is List && list.isNotEmpty) return list[0]['modelo']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Cód. Cargador',
      getValue: (a) {
        final list = a['info_equipo_generico'];
        if (list is List && list.isNotEmpty) return list[0]['cargador_codigo']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Num. Conexiones',
      getValue: (a) {
        final list = a['info_equipo_generico'];
        if (list is List && list.isNotEmpty) return list[0]['num_conexiones']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Observaciones',
      getValue: (a) {
        final list = a['info_equipo_generico'];
        if (list is List && list.isNotEmpty) return list[0]['observaciones']?.toString() ?? 'N/A';
        return 'N/A';
      },
      visibleByDefault: true,
    ),
  ];

  // Filtros adicionales personalizados
  final List<String> _selectedModelos = [];

  @override
  String get pageTitle => 'Equipos Genéricos';

  @override
  String? get categoryName => 'GENERICO';

  @override
  List<AssetColumnDef> get columns => _genericColumns;

  @override
  int getCustomFilterCount() {
    return _selectedModelos.isNotEmpty ? 1 : 0;
  }

  @override
  void clearCustomFilters() {
    _selectedModelos.clear();
  }

  @override
  bool customMatch(Map<String, dynamic> asset, {String? ignoreField}) {
    final info = getAssetInfo(asset, 'info_equipo_generico');
    final matchesModelo = ignoreField == 'modelo' || _selectedModelos.isEmpty || _selectedModelos.contains((info?['modelo'] ?? '').toString());
    return matchesModelo;
  }

  @override
  List<Widget> buildCustomDrawerFilters() {
    return [
      const Divider(),
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Filtros Específicos (Genéricos)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      ),
      buildStringDrawerFilterButton(
        'Modelo', 
        _selectedModelos, 
        getUniquePredictiveList('modelo', subKey: 'info_equipo_generico').map((e) => e['valor'].toString()).toList()
      ),
    ];
  }
}
