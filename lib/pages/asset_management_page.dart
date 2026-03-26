import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';
import 'package:front_inventarios/pages/assets/pc_assets_page.dart';
import 'package:front_inventarios/pages/assets/software_assets_page.dart';
import 'package:front_inventarios/pages/assets/communication_assets_page.dart';
import 'package:front_inventarios/pages/assets/generic_assets_page.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';

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

  // Master Data Reference Logic
  List<Map<String, dynamic>> _tiposActivo = [];
  List<Map<String, dynamic>> _condiciones = [];
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _ciudades = [];
  List<Map<String, dynamic>> _custodios = [];
  List<Map<String, dynamic>> _proveedores = [];

  // Filter Models
  List<int> _selectedTiposActivo = [];
  List<int> _selectedCondiciones = [];
  List<int> _selectedSedes = [];
  List<int> _selectedAreas = [];
  List<int> _selectedCiudades = [];
  List<int> _selectedCustodios = [];
  List<int> _selectedProveedores = [];

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

  @override
  void dispose() {
    _nombresController.dispose();
    _codigosController.dispose();
    _seriesController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        supabase.from('tipo_activo').select('id, tipo, categoria').order('tipo'),
        supabase.from('condicion_activo').select('id, condicion').order('condicion'),
        supabase.from('sede_activo').select('id, sede').order('sede'),
        supabase.from('area_activo').select('id, area').order('area'),
        supabase.from('ciudad_activo').select('id, ciudad').order('ciudad'),
        supabase.from('custodio').select('id, nombre_completo').order('nombre_completo'),
        supabase.from('proveedor').select('id, nombre').order('nombre'),
        supabase.from('activo').select('''
          *,
          tipo_activo(tipo),
          condicion_activo(condicion),
          ciudad_activo(ciudad),
          sede_activo(sede),
          area_activo(area),
          proveedor(nombre),
          custodio(nombre_completo)
        ''').order('id')
      ]);

      if (!mounted) return;
      setState(() {
        _tiposActivo = List<Map<String, dynamic>>.from(futures[0] as List);
        _condiciones = List<Map<String, dynamic>>.from(futures[1] as List);
        _sedes = List<Map<String, dynamic>>.from(futures[2] as List);
        _areas = List<Map<String, dynamic>>.from(futures[3] as List);
        _ciudades = List<Map<String, dynamic>>.from(futures[4] as List);
        _custodios = List<Map<String, dynamic>>.from(futures[5] as List);
        _proveedores = List<Map<String, dynamic>>.from(futures[6] as List);

        _allAssets = List<Map<String, dynamic>>.from(futures[7] as List);
        _filteredAssets = _allAssets;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final nombres = _nombresController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final codigos = _codigosController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final series = _seriesController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final result = _allAssets.where((asset) {
      // Texts Multi Matching
      bool matchesNombre = nombres.isEmpty || nombres.any((n) => (asset['nombre'] ?? '').toString().toLowerCase().contains(n));
      bool matchesCodigo = codigos.isEmpty || codigos.any((c) => (asset['codigo'] ?? '').toString().toLowerCase().contains(c));
      bool matchesSerie = series.isEmpty || series.any((s) => (asset['numero_serie'] ?? '').toString().toLowerCase().contains(s));

      // Multi Select Matching
      bool matchesTipo = _selectedTiposActivo.isEmpty || _selectedTiposActivo.contains(asset['id_tipo_activo']);
      bool matchesCondicion = _selectedCondiciones.isEmpty || _selectedCondiciones.contains(asset['id_condicion_activo']);
      bool matchesSede = _selectedSedes.isEmpty || _selectedSedes.contains(asset['id_sede_activo']);
      bool matchesArea = _selectedAreas.isEmpty || _selectedAreas.contains(asset['id_area_activo']);
      bool matchesCiudad = _selectedCiudades.isEmpty || _selectedCiudades.contains(asset['id_ciudad_activo']);
      bool matchesCustodio = _selectedCustodios.isEmpty || _selectedCustodios.contains(asset['id_custodio']);
      bool matchesProveedor = _selectedProveedores.isEmpty || _selectedProveedores.contains(asset['id_provedor']);

      // Date Ranges Matching
      bool matchesAdquisicion = true;
      if (_rangoAdquisicion != null && asset['fecha_adquisicion'] != null) {
        try {
          final dt = DateTime.parse(asset['fecha_adquisicion'].toString());
          if (dt.isBefore(_rangoAdquisicion!.start) || dt.isAfter(_rangoAdquisicion!.end)) {
            matchesAdquisicion = false;
          }
        } catch (_) {}
      }

      bool matchesEntrega = true;
      if (_rangoEntrega != null && asset['fecha_entrega'] != null) {
        try {
          final dt = DateTime.parse(asset['fecha_entrega'].toString());
          if (dt.isBefore(_rangoEntrega!.start) || dt.isAfter(_rangoEntrega!.end)) {
            matchesEntrega = false;
          }
        } catch (_) {}
      }

      return matchesNombre && matchesCodigo && matchesSerie &&
             matchesTipo && matchesCondicion && matchesSede &&
             matchesArea && matchesCiudad && matchesCustodio &&
             matchesProveedor && matchesAdquisicion && matchesEntrega;
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
      _nombresController.clear();
      _codigosController.clear();
      _seriesController.clear();
      _rangoAdquisicion = null;
      _rangoEntrega = null;
    });
    _applyFilters();
  }

  Future<void> _deleteAsset(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Activo'),
        content: const Text('¿Deseas eliminar este activo permanentemente?'),
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
      await supabase.rpc('eliminar_activo', params: {'p_id_activo': id});
      if (mounted) context.showSnackBar('Activo eliminado correctamente.');
      _loadAssets();
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Future<void> _showMultiSelect(String title, List<Map<String, dynamic>> items, List<int> selectedIds, String displayKey, ValueChanged<List<int>> onConfirm) async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (_) => MultiSelectDialog(
        title: title,
        items: items,
        initialSelectedIds: selectedIds,
        displayKey: displayKey,
      ),
    );
    if (result != null) {
      onConfirm(result);
      _applyFilters();
    }
  }

  Widget _buildDrawerFilterButton(String label, List<int> selectedIds, List<Map<String, dynamic>> items, String displayKey) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(selectedIds.isEmpty ? 'Todos' : '${selectedIds.length} seleccionados'),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () {
        _showMultiSelect(label, items, selectedIds, displayKey, (newSelection) {
          setState(() {
            selectedIds.clear();
            selectedIds.addAll(newSelection);
          });
        });
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
        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { onChanged(null); _applyFilters(); })
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Activos Completa'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtros',
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            }
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
                  const Text('Filtros Avanzados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: _clearFilters, child: const Text('Limpiar Todos'))
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('Campos de Texto (Separados por coma)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  _buildDrawerTextField('Nombres', _nombresController),
                  _buildDrawerTextField('Códigos', _codigosController),
                  _buildDrawerTextField('Números de Serie', _seriesController),
                  
                  const Divider(),
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('Listas Maestras', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  _buildDrawerFilterButton('Tipo Activo', _selectedTiposActivo, _tiposActivo, 'tipo'),
                  _buildDrawerFilterButton('Condición', _selectedCondiciones, _condiciones, 'condicion'),
                  _buildDrawerFilterButton('Custodio', _selectedCustodios, _custodios, 'nombre_completo'),
                  _buildDrawerFilterButton('Sede', _selectedSedes, _sedes, 'sede'),
                  _buildDrawerFilterButton('Área', _selectedAreas, _areas, 'area'),
                  _buildDrawerFilterButton('Ciudad', _selectedCiudades, _ciudades, 'ciudad'),
                  _buildDrawerFilterButton('Proveedor', _selectedProveedores, _proveedores, 'nombre'),

                  const Divider(),
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('Rango de Fechas', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
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
            /// ActionChips Categorical Navigation (Scrollable horizontally)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.computer, size: 16),
                    label: const Text('Equipos PC'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PcAssetsPage())),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.developer_board, size: 16),
                    label: const Text('Software'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SoftwareAssetsPage())),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.router, size: 16),
                    label: const Text('Comunicación'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommsAssetsPage())),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.devices_other, size: 16),
                    label: const Text('Genéricos'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenericAssetsPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /// Header y Toggle
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
                  const Text('   <- Visores Detallados ', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
            ),
            const SizedBox(height: 10),

            /// Data Layout
            Expanded(child: _isTableView ? _buildTableSection() : _buildListSection()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Scaffold.of(context).openEndDrawer();
        },
        tooltip: 'Abrir Filtros',
        child: const Icon(Icons.filter_list),
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
              DataColumn(label: Text('Nombre Activo')),
              DataColumn(label: Text('Categoría')),
              DataColumn(label: Text('Tipo Activo')),
              DataColumn(label: Text('Condición')),
              DataColumn(label: Text('Sede')),
              DataColumn(label: Text('Área')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: _filteredAssets.map((asset) {
              return DataRow(
                cells: [
                  DataCell(Text(asset['numero_serie']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['nombre']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['categoria_activo']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['tipo_activo']?['tipo']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['condicion_activo']?['condicion']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['sede_activo']?['sede']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['area_activo']?['area']?.toString() ?? 'N/A')),
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

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.devices, color: Colors.blue.shade800),
            ),
            title: Text(asset['nombre']?.toString() ?? 'Activo Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Cat: ${asset['categoria_activo'] ?? 'N/A'} | Tipo: ${asset['tipo_activo']?['tipo'] ?? 'N/A'}\n'
              'Sede: ${asset['sede_activo']?['sede'] ?? 'N/A'} | Área: ${asset['area_activo']?['area'] ?? 'N/A'}\n'
              'S/N: ${asset['numero_serie'] ?? 'N/A'} | Código: ${asset['codigo'] ?? 'N/A'}',
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
