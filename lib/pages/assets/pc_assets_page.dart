import 'package:flutter/material.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/pages/assets/base_asset_page_state.dart';

class PcAssetsPage extends StatefulWidget {
  const PcAssetsPage({super.key});

  @override
  State<PcAssetsPage> createState() => _PcAssetsPageState();
}

class _PcAssetsPageState extends BaseAssetPageState<PcAssetsPage> {
  // Column definitions for PC category
  static final List<AssetColumnDef> _pcColumns = [
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
    AssetColumnDef(label: 'Fe. Entrega', getValue: (a) => a['fecha_entrega']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'IP', getValue: (a) => a['ip']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Coordenada', getValue: (a) => a['coordenada']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(
      label: 'Marca',
      getValue: (a) {
        final list = a['info_pc'];
        if (list is List && list.isNotEmpty) return list[0]['marca']?['marca_proveedor']?.toString() ?? 'N/A';
        return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Modelo',
      getValue: (a) {
         final list = a['info_pc'];
         if (list is List && list.isNotEmpty) return list[0]['modelo']?.toString() ?? 'N/A';
         return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Procesador',
      getValue: (a) {
         final list = a['info_pc'];
         if (list is List && list.isNotEmpty) return list[0]['procesador']?.toString() ?? 'N/A';
         return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'RAM',
      getValue: (a) {
         final list = a['info_pc'];
         if (list is List && list.isNotEmpty) return list[0]['ram']?.toString() ?? 'N/A';
         return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Almacenamiento',
      getValue: (a) {
         final list = a['info_pc'];
         if (list is List && list.isNotEmpty) return list[0]['almacenamiento']?.toString() ?? 'N/A';
         return 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Cód. Cargador',
      getValue: (a) {
         final list = a['info_pc'];
         if (list is List && list.isNotEmpty) return list[0]['cargador_codigo']?.toString() ?? 'N/A';
         return 'N/A';
      },
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Num. Puertos',
      getValue: (a) {
         final list = a['info_pc'];
         if (list is List && list.isNotEmpty) return list[0]['num_puertos']?.toString() ?? 'N/A';
         return 'N/A';
      },
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Observaciones',
      getValue: (a) {
         final list = a['info_pc'];
         if (list is List && list.isNotEmpty) return list[0]['observaciones']?.toString() ?? 'N/A';
         return 'N/A';
      },
      visibleByDefault: true,
    ),
  ];

  // Filtros adicionales
  final List<String> _selectedModelos = [];
  final List<String> _selectedCpu = [];
  final List<String> _selectedRams = [];
  final List<String> _selectedStorages = [];

  static const List<String> _ramOptions = ['4GB', '8GB', '12GB', '16GB', '32GB', '64GB', '128GB', '256GB'];
  static const List<String> _storageOptions = ['128GB', '256GB', '512GB', '1TB', '2TB', '4TB', '10TB'];

  @override
  String get pageTitle => 'Equipos PC';

  @override
  String? get categoryName => 'PC';

  @override
  List<AssetColumnDef> get columns => _pcColumns;

  @override
  int getCustomFilterCount() {
    int count = 0;
    if (_selectedModelos.isNotEmpty) count++;
    if (_selectedCpu.isNotEmpty) count++;
    if (_selectedRams.isNotEmpty) count++;
    if (_selectedStorages.isNotEmpty) count++;
    return count;
  }

  @override
  void clearCustomFilters() {
    _selectedModelos.clear();
    _selectedCpu.clear();
    _selectedRams.clear();
    _selectedStorages.clear();
  }

  @override
  bool customMatch(Map<String, dynamic> asset, {String? ignoreField}) {
    final info = getAssetInfo(asset, 'info_pc');

    bool matchesModelo = ignoreField == 'modelo' || _selectedModelos.isEmpty || _selectedModelos.contains((info?['modelo'] ?? '').toString());
    bool matchesCpu = ignoreField == 'procesador' || _selectedCpu.isEmpty || _selectedCpu.contains((info?['procesador'] ?? '').toString());
    bool matchesRam = ignoreField == 'ram' || _selectedRams.isEmpty || _selectedRams.contains(info?['ram']?.toString());
    bool matchesStorage = ignoreField == 'almacenamiento' || _selectedStorages.isEmpty || _selectedStorages.contains(info?['almacenamiento']?.toString());

    return matchesModelo && matchesCpu && matchesRam && matchesStorage;
  }

  @override
  List<Widget> buildCustomDrawerFilters() {
    return [
      const Divider(),
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Filtros Específicos (PC)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      ),
      buildStringDrawerFilterButton('Modelo', _selectedModelos, getUniquePredictiveList('modelo', subKey: 'info_pc').map((e) => e['valor'].toString()).toList()),
      buildStringDrawerFilterButton('Procesador', _selectedCpu, getUniquePredictiveList('procesador', subKey: 'info_pc').map((e) => e['valor'].toString()).toList()),
      buildStringDrawerFilterButton('RAM', _selectedRams, _ramOptions),
      buildStringDrawerFilterButton('Almacenamiento', _selectedStorages, _storageOptions),
    ];
  }
}
