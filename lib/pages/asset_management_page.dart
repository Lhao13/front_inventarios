import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';
import 'package:front_inventarios/pages/assets/pc_assets_page.dart';
import 'package:front_inventarios/pages/assets/communication_assets_page.dart';
import 'package:front_inventarios/pages/assets/generic_assets_page.dart';
import 'package:front_inventarios/pages/assets/software_assets_page.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';

class AssetManagementPage extends StatefulWidget {
  const AssetManagementPage({super.key});

  @override
  State<AssetManagementPage> createState() => _AssetManagementPageState();
}

class _AssetManagementPageState extends State<AssetManagementPage> {
  List<Map<String, dynamic>> _allAssets = [];
  List<Map<String, dynamic>> _filteredAssets = [];
  bool _isLoading = true;
  bool _isTableView = true;

  // Master Data Cache
  List<Map<String, dynamic>> _tiposActivo = [];
  List<Map<String, dynamic>> _condiciones = [];
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _ciudades = [];
  List<Map<String, dynamic>> _custodios = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _marcas = [];

  // Currently Selected Filters
  List<int> _selectedTiposActivo = [];
  List<int> _selectedCondiciones = [];
  List<int> _selectedSedes = [];
  List<int> _selectedAreas = [];
  List<int> _selectedCiudades = [];
  List<int> _selectedCustodios = [];
  List<int> _selectedProveedores = [];
  List<int> _selectedMarcas = [];

  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _codigosController = TextEditingController();
  final TextEditingController _seriesController = TextEditingController();

  DateTimeRange? _rangoAdquisicion;
  DateTimeRange? _rangoEntrega;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final localActivos = await LocalDbService.instance.getCollection('activo');
      
      final futures = await Future.wait([
        LocalDbService.instance.getCollection('tipo_activo'),
        LocalDbService.instance.getCollection('condicion_activo'),
        LocalDbService.instance.getCollection('sede_activo'),
        LocalDbService.instance.getCollection('area_activo'),
        LocalDbService.instance.getCollection('ciudad_activo'),
        LocalDbService.instance.getCollection('custodio'),
        LocalDbService.instance.getCollection('proveedor'),
        LocalDbService.instance.getCollection('marca'),
      ]);

      if (mounted) {
        setState(() {
          _tiposActivo = futures[0];
          _condiciones = futures[1];
          _sedes = futures[2];
          _areas = futures[3];
          _ciudades = futures[4];
          _custodios = futures[5];
          _proveedores = futures[6];
          _marcas = futures[7];

          _allAssets = localActivos;
          _filteredAssets = _allAssets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    // Parser text separated by commas
    final nombres = _nombresController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final codigos = _codigosController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final series = _seriesController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final result = _allAssets.where((asset) {
      // Find dynamic sub-marca ID
      int? assetMarcaId;
      if (asset['info_pc'] != null && (asset['info_pc'] as List).isNotEmpty) {
        assetMarcaId = (asset['info_pc'] as List)[0]['id_marca'];
      } else if (asset['info_equipo_comunicacion'] != null && (asset['info_equipo_comunicacion'] as List).isNotEmpty) {
        assetMarcaId = (asset['info_equipo_comunicacion'] as List)[0]['id_marca'];
      } else if (asset['info_equipo_generico'] != null && (asset['info_equipo_generico'] as List).isNotEmpty) {
        assetMarcaId = (asset['info_equipo_generico'] as List)[0]['id_marca'];
      }

      // Check lists (OR logic inside list, AND logic between groups)
      bool matchesTipo = _selectedTiposActivo.isEmpty || _selectedTiposActivo.contains(asset['id_tipo_activo']);
      bool matchesCondicion = _selectedCondiciones.isEmpty || _selectedCondiciones.contains(asset['id_condicion_activo']);
      bool matchesSede = _selectedSedes.isEmpty || _selectedSedes.contains(asset['id_sede_activo']);
      bool matchesArea = _selectedAreas.isEmpty || _selectedAreas.contains(asset['id_area_activo']);
      bool matchesCiudad = _selectedCiudades.isEmpty || _selectedCiudades.contains(asset['id_ciudad_activo']);
      bool matchesCustodio = _selectedCustodios.isEmpty || _selectedCustodios.contains(asset['id_custodio']);
      bool matchesProveedor = _selectedProveedores.isEmpty || _selectedProveedores.contains(asset['id_provedor']);
      bool matchesMarca = _selectedMarcas.isEmpty || _selectedMarcas.contains(assetMarcaId);

      // Check multi texts (OR logic inside the separated strings)
      bool matchesNombre = nombres.isEmpty || nombres.any((n) => (asset['nombre'] ?? '').toString().toLowerCase().contains(n));
      bool matchesCodigo = codigos.isEmpty || codigos.any((c) => (asset['codigo'] ?? '').toString().toLowerCase().contains(c));
      bool matchesSerie = series.isEmpty || series.any((s) => (asset['numero_serie'] ?? '').toString().toLowerCase().contains(s));

      // Dates
      bool matchesAdquisicion = true;
      if (_rangoAdquisicion != null && asset['fecha_adquisicion'] != null) {
        try {
          final dt = DateTime.parse(asset['fecha_adquisicion'].toString());
          if (dt.isBefore(_rangoAdquisicion!.start) || dt.isAfter(_rangoAdquisicion!.end)) matchesAdquisicion = false;
        } catch (_) {}
      }

      bool matchesEntrega = true;
      if (_rangoEntrega != null && asset['fecha_entrega'] != null) {
        try {
          final dt = DateTime.parse(asset['fecha_entrega'].toString());
          if (dt.isBefore(_rangoEntrega!.start) || dt.isAfter(_rangoEntrega!.end)) matchesEntrega = false;
        } catch (_) {}
      }

      return matchesTipo && matchesCondicion && matchesSede && matchesArea && 
             matchesCiudad && matchesCustodio && matchesProveedor && matchesMarca &&
             matchesNombre && matchesCodigo && matchesSerie && 
             matchesAdquisicion && matchesEntrega;
    }).toList();

    setState(() {
      _filteredAssets = result;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedTiposActivo.clear();
      _selectedCondiciones.clear();
      _selectedSedes.clear();
      _selectedAreas.clear();
      _selectedCiudades.clear();
      _selectedCustodios.clear();
      _selectedProveedores.clear();
      _selectedMarcas.clear();
      _nombresController.clear();
      _codigosController.clear();
      _seriesController.clear();
      _rangoAdquisicion = null;
      _rangoEntrega = null;
    });
    _applyFilters();
  }

  Future<void> _deleteAsset(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Activo'),
        content: const Text('¿Deseas eliminar este activo permanente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await LocalDbService.instance.enqueueOperation('eliminar_activo', {'p_id_activo': id});
      if (SyncQueueService.instance.isOnline) SyncQueueService.instance.syncPendingOperations();
      if (mounted) context.showSnackBar('Activo eliminado localmente (Cola activada).');
      _loadAssets();
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Widget _buildDrawerFilterButton(String label, List<int> selectedIds, List<Map<String, dynamic>> items, String displayKey) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(selectedIds.isEmpty ? 'Todos' : '${selectedIds.length} seleccionados'),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () async {
        final result = await showDialog<List<int>>(
          context: context,
          builder: (_) => MultiSelectDialog(
            title: label,
            items: items,
            initialSelectedIds: selectedIds,
            displayKey: displayKey,
          ),
        );
        if (result != null) {
          setState(() {
            selectedIds.clear();
            selectedIds.addAll(result);
          });
          _applyFilters();
        }
      },
    );
  }

  Widget _buildDrawerTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Ej: val1, val2',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildDrawerDateFilter(String label, DateTimeRange? currentRange, ValueChanged<DateTimeRange?> onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(currentRange == null ? 'Cualquier fecha' : '${currentRange.start.toLocal().toString().split(' ')[0]} - ${currentRange.end.toLocal().toString().split(' ')[0]}'),
      trailing: currentRange != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                onChanged(null);
                _applyFilters();
              },
            )
          : const Icon(Icons.calendar_today),
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDateRange: currentRange,
        );
        if (range != null) {
          onChanged(range);
          _applyFilters();
        }
      },
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category) {
      case 'PC': return Icons.computer;
      case 'SOFTWARE': return Icons.developer_board;
      case 'COMUNICACION': return Icons.router;
      case 'GENERICO': return Icons.devices_other;
      default: return Icons.inventory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Activos (Global)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtros Globales',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 48, bottom: 16, left: 16, right: 16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Filtros Globales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   TextButton(
                     onPressed: _clearFilters,
                     child: const Text('Limpiar Todos')
                   )
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Descripciones (Separados por coma)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  _buildDrawerTextField('Nombres', _nombresController),
                  _buildDrawerTextField('Códigos', _codigosController),
                  _buildDrawerTextField('Números de Serie', _seriesController),
                  
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Listas Maestras', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  _buildDrawerFilterButton('Tipo Activo', _selectedTiposActivo, _tiposActivo, 'tipo'),
                  _buildDrawerFilterButton('Condición', _selectedCondiciones, _condiciones, 'condicion'),
                  _buildDrawerFilterButton('Custodio', _selectedCustodios, _custodios, 'nombre_completo'),
                  _buildDrawerFilterButton('Sede', _selectedSedes, _sedes, 'sede'),
                  _buildDrawerFilterButton('Área', _selectedAreas, _areas, 'area'),
                  _buildDrawerFilterButton('Ciudad', _selectedCiudades, _ciudades, 'ciudad'),
                  _buildDrawerFilterButton('Proveedor', _selectedProveedores, _proveedores, 'nombre'),
                  _buildDrawerFilterButton('Marca', _selectedMarcas, _marcas, 'marca_proveedor'),

                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Rango de Fechas', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  _buildDrawerDateFilter('Fecha de Adquisición', _rangoAdquisicion, (r) => setState(() => _rangoAdquisicion = r)),
                  _buildDrawerDateFilter('Fecha de Entrega', _rangoEntrega, (r) => setState(() => _rangoEntrega = r)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Módulos: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('PC'), avatar: const Icon(Icons.computer, size: 16), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PcAssetsPage()))),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Comunicaciones'), avatar: const Icon(Icons.router, size: 16), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommsAssetsPage()))),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Genéricos'), avatar: const Icon(Icons.devices_other, size: 16), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenericAssetsPage()))),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Software'), avatar: const Icon(Icons.developer_board, size: 16), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SoftwareAssetsPage()))),
                ],
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(value: false, icon: Icon(Icons.view_list), label: Text('Lista')),
                    ButtonSegment<bool>(value: true, icon: Icon(Icons.table_chart), label: Text('Tabla')),
                  ],
                  selected: {_isTableView},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() { _isTableView = newSelection.first; });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: _isTableView ? _buildTableSection() : _buildListSection()),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton.extended(
          onPressed: () => Scaffold.of(context).openEndDrawer(),
          tooltip: 'Abrir Filtros',
          icon: const Icon(Icons.filter_list),
          label: const Text('Filtros')
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredAssets.isEmpty) return const Center(child: Text('No hay activos para mostrar. Modifique los filtros.'));

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('S/N')),
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Tipo Activo')),
              DataColumn(label: Text('Condición')),
              DataColumn(label: Text('Custodio')),
              DataColumn(label: Text('Ciudad')),
              DataColumn(label: Text('Sede')),
              DataColumn(label: Text('Área')),
              DataColumn(label: Text('Proveedor')),
              DataColumn(label: Text('Fe. Adquisición')),
              DataColumn(label: Text('IP')),
              DataColumn(label: Text('Fe. Entrega')),
              DataColumn(label: Text('Coordenada')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: _filteredAssets.map((asset) {
              return DataRow(
                cells: [
                  DataCell(Text(asset['numero_serie']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['nombre']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['codigo']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['tipo_activo']?['tipo']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['condicion_activo']?['condicion']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['custodio']?['nombre_completo']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['ciudad_activo']?['ciudad']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['sede_activo']?['sede']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['area_activo']?['area']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['proveedor']?['nombre']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['fecha_adquisicion']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['ip']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['fecha_entrega']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['coordenada']?.toString() ?? 'N/A')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (RoleService.currentRole != UserRole.ayudante)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAsset(asset['id']),
                            tooltip: 'Eliminar',
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListSection() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredAssets.isEmpty) return const Center(child: Text('No hay activos para mostrar. Modifique los filtros.'));

    return ListView.builder(
      itemCount: _filteredAssets.length,
      itemBuilder: (context, index) {
        final asset = _filteredAssets[index];
        final icon = _getIconForCategory(asset['categoria_activo']);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: Icon(icon, size: 40, color: Colors.blueGrey),
            title: Text(asset['nombre'] ?? 'Activo ${asset['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Categoría: ${asset['categoria_activo'] ?? 'Desconocida'}\n'
              'S/N: ${asset['numero_serie'] ?? 'N/A'} | Tipo: ${asset['tipo_activo']?['tipo'] ?? 'N/A'}\n'
              'Área: ${asset['area_activo']?['area'] ?? 'N/A'}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (RoleService.currentRole != UserRole.ayudante)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAsset(asset['id']),
                    tooltip: 'Eliminar',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
