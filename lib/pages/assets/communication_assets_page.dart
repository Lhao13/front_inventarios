import 'package:flutter/material.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/pages/assets/base_asset_page_state.dart';

class CommsAssetsPage extends StatefulWidget {
  const CommsAssetsPage({super.key});

  @override
  State<CommsAssetsPage> createState() => _CommsAssetsPageState();
}

class _CommsAssetsPageState extends BaseAssetPageState<CommsAssetsPage> {
  // Column definitions for COMUNICACION category
  static final List<AssetColumnDef> _commsColumns = [
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
        final list = a['info_equipo_comunicacion'];
        if (list is List && list.isNotEmpty) return list[0]['marca']?['marca_proveedor']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Modelo',
      getValue: (a) {
        final list = a['info_equipo_comunicacion'];
        if (list is List && list.isNotEmpty) return list[0]['modelo']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Num. Puertos',
      getValue: (a) {
        final list = a['info_equipo_comunicacion'];
        if (list is List && list.isNotEmpty) return list[0]['num_puertos']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Tipo Extensión',
      getValue: (a) {
        final list = a['info_equipo_comunicacion'];
        if (list is List && list.isNotEmpty) return list[0]['tipo_extension']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Observaciones',
      getValue: (a) {
        final list = a['info_equipo_comunicacion'];
        if (list is List && list.isNotEmpty) return list[0]['observaciones']?.toString() ?? 'N/A';
        return 'N/A';
      },
      visibleByDefault: true,
    ),
  ];

  // Filtros adicionales personalizados
  final List<String> _selectedModelos = [];
  final List<String> _selectedPuertos = [];

  @override
  String get pageTitle => 'Equipos de Comunicación';

  @override
  String? get categoryName => 'COMUNICACION';

  @override
  List<AssetColumnDef> get columns => _commsColumns;

  @override
  int getCustomFilterCount() {
    int count = 0;
    if (_selectedModelos.isNotEmpty) count++;
    if (_selectedPuertos.isNotEmpty) count++;
    return count;
  }

  @override
  void clearCustomFilters() {
    _selectedModelos.clear();
    _selectedPuertos.clear();
  }

  @override
  bool customMatch(Map<String, dynamic> asset, {String? ignoreField}) {
    final info = getAssetInfo(asset, 'info_equipo_comunicacion');
    final matchesModelo = ignoreField == 'modelo' || _selectedModelos.isEmpty || _selectedModelos.contains((info?['modelo'] ?? '').toString());
    final matchesPuertos = ignoreField == 'num_puertos' || _selectedPuertos.isEmpty || _selectedPuertos.contains((info?['num_puertos'] ?? '').toString());
    
    return matchesModelo && matchesPuertos;
  }

  @override
  List<Widget> buildCustomDrawerFilters() {
    return [
      const Divider(),
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Filtros Específicos (Comunicación)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      ),
      buildStringDrawerFilterButton(
        'Modelo', 
        _selectedModelos, 
        getUniquePredictiveList('modelo', subKey: 'info_equipo_comunicacion').map((e) => e['valor'].toString()).toList()
      ),
      buildStringDrawerFilterButton(
        'Num. Puertos', 
        _selectedPuertos, 
        getUniquePredictiveList('num_puertos', subKey: 'info_equipo_comunicacion').map((e) => e['valor'].toString()).toList()
      ),
    ];
  }
}
