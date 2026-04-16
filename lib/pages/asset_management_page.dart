import 'package:flutter/material.dart';
import 'package:front_inventarios/widgets/global_asset_data_source.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';
import 'package:front_inventarios/pages/assets/pc_assets_page.dart';
import 'package:front_inventarios/pages/assets/communication_assets_page.dart';
import 'package:front_inventarios/pages/assets/generic_assets_page.dart';
import 'package:front_inventarios/pages/assets/software_assets_page.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:front_inventarios/widgets/maintenance_form_dialog.dart';

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

  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _listRowsPerPage = 10;
  int _listCurrentPage = 0;

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

  final List<String> _selectedNombres = [];
  final List<String> _selectedCodigos = [];
  final List<String> _selectedSeries = [];

  DateTimeRange? _rangoAdquisicion;
  DateTimeRange? _rangoEntrega;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    SyncQueueService.instance.onCacheUpdated.addListener(_onCacheUpdated);
  }

  @override
  void dispose() {
    SyncQueueService.instance.onCacheUpdated.removeListener(_onCacheUpdated);
    _selectedNombres.clear();
    _selectedCodigos.clear();
    _selectedSeries.clear();
    super.dispose();
  }

  void _onCacheUpdated() {
    if (mounted) _loadAssets(showLoading: false);
  }

  Future<void> _loadAssets({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final localActivos = await LocalDbService.instance.getCollection(
        'activo',
      );

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
          _filteredAssets = _allAssets.where((a) => _assetMatches(a)).toList();
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

  bool _assetMatches(Map<String, dynamic> asset, {String? ignoreField}) {
    // Find dynamic sub-marca ID
    int? assetMarcaId;
    if (asset['info_pc'] != null && (asset['info_pc'] as List).isNotEmpty) {
      assetMarcaId = (asset['info_pc'] as List)[0]['id_marca'];
    } else if (asset['info_equipo_comunicacion'] != null &&
        (asset['info_equipo_comunicacion'] as List).isNotEmpty) {
      assetMarcaId = (asset['info_equipo_comunicacion'] as List)[0]['id_marca'];
    } else if (asset['info_equipo_generico'] != null &&
        (asset['info_equipo_generico'] as List).isNotEmpty) {
      assetMarcaId = (asset['info_equipo_generico'] as List)[0]['id_marca'];
    }

    bool matchesTipo =
        ignoreField == 'id_tipo_activo' ||
        _selectedTiposActivo.isEmpty ||
        _selectedTiposActivo.contains(asset['id_tipo_activo']);
    bool matchesCondicion =
        ignoreField == 'id_condicion_activo' ||
        _selectedCondiciones.isEmpty ||
        _selectedCondiciones.contains(asset['id_condicion_activo']);
    bool matchesSede =
        ignoreField == 'id_sede_activo' ||
        _selectedSedes.isEmpty ||
        _selectedSedes.contains(asset['id_sede_activo']);
    bool matchesArea =
        ignoreField == 'id_area_activo' ||
        _selectedAreas.isEmpty ||
        _selectedAreas.contains(asset['id_area_activo']);
    bool matchesCiudad =
        ignoreField == 'id_ciudad_activo' ||
        _selectedCiudades.isEmpty ||
        _selectedCiudades.contains(asset['id_ciudad_activo']);
    bool matchesCustodio =
        ignoreField == 'id_custodio' ||
        _selectedCustodios.isEmpty ||
        _selectedCustodios.contains(asset['id_custodio']);
    bool matchesProveedor =
        ignoreField == 'id_provedor' ||
        _selectedProveedores.isEmpty ||
        _selectedProveedores.contains(asset['id_provedor']);
    bool matchesMarca =
        ignoreField == 'id_marca' ||
        _selectedMarcas.isEmpty ||
        _selectedMarcas.contains(assetMarcaId);

    bool matchesNombre =
        ignoreField == 'nombre' ||
        _selectedNombres.isEmpty ||
        _selectedNombres.contains((asset['nombre'] ?? '').toString());
    bool matchesCodigo =
        ignoreField == 'codigo' ||
        _selectedCodigos.isEmpty ||
        _selectedCodigos.contains((asset['codigo'] ?? '').toString());
    bool matchesSerie =
        ignoreField == 'numero_serie' ||
        _selectedSeries.isEmpty ||
        _selectedSeries.contains((asset['numero_serie'] ?? '').toString());

    bool matchesAdquisicion = true;
    if (ignoreField != 'fecha_adquisicion' &&
        _rangoAdquisicion != null &&
        asset['fecha_adquisicion'] != null) {
      try {
        final dt = DateTime.parse(asset['fecha_adquisicion'].toString());
        if (dt.isBefore(_rangoAdquisicion!.start) ||
            dt.isAfter(_rangoAdquisicion!.end))
          matchesAdquisicion = false;
      } catch (_) {}
    }

    bool matchesEntrega = true;
    if (ignoreField != 'fecha_entrega' &&
        _rangoEntrega != null &&
        asset['fecha_entrega'] != null) {
      try {
        final dt = DateTime.parse(asset['fecha_entrega'].toString());
        if (dt.isBefore(_rangoEntrega!.start) || dt.isAfter(_rangoEntrega!.end))
          matchesEntrega = false;
      } catch (_) {}
    }

    return matchesTipo &&
        matchesCondicion &&
        matchesSede &&
        matchesArea &&
        matchesCiudad &&
        matchesCustodio &&
        matchesProveedor &&
        matchesMarca &&
        matchesNombre &&
        matchesCodigo &&
        matchesSerie &&
        matchesAdquisicion &&
        matchesEntrega;
  }

  void _applyFilters() {
    setState(() {
      _filteredAssets = _allAssets.where((a) => _assetMatches(a)).toList();
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
      _selectedNombres.clear();
      _selectedCodigos.clear();
      _selectedSeries.clear();
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
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
      await LocalDbService.instance.enqueueOperation('eliminar_activo', {
        'p_id_activo': id,
      });
      if (SyncQueueService.instance.isOnline)
        SyncQueueService.instance.syncPendingOperations();
      if (mounted)
        context.showSnackBar('Activo eliminado localmente (Cola activada).');
      _loadAssets();
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Widget _buildDrawerFilterButton<T>(
    String label,
    List<T> selectedIds,
    List<Map<String, dynamic>> items,
    String displayKey,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        selectedIds.isEmpty ? 'Todos' : '${selectedIds.length} seleccionados',
      ),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () async {
        final result = await showDialog<List<T>>(
          context: context,
          builder: (_) => MultiSelectDialog<T>(
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
            _listCurrentPage = 0; // Reset page on filter
          });
          _applyFilters();
        }
      },
    );
  }

  List<Map<String, dynamic>> _getUniquePredictiveList(String key) {
    if (_allAssets.isEmpty) return [];
    final possibleAssets = _allAssets.where(
      (a) => _assetMatches(a, ignoreField: key),
    );
    final items = possibleAssets
        .map((a) => a[key]?.toString())
        .where((val) => val != null && val.trim().isNotEmpty)
        .toSet()
        .toList();
    items.sort();
    return items.map((val) => {'id': val, 'valor': val}).toList();
  }

  List<Map<String, dynamic>> _getFilteredMasterList(
    List<Map<String, dynamic>> masterList,
    String ignoreField,
  ) {
    if (_allAssets.isEmpty || masterList.isEmpty) return [];
    final validKeys = <int>{};
    for (var a in _allAssets.where(
      (asset) => _assetMatches(asset, ignoreField: ignoreField),
    )) {
      if (ignoreField == 'id_marca') {
        int? assetMarcaId;
        if (a['info_pc'] != null && (a['info_pc'] as List).isNotEmpty) {
          assetMarcaId = (a['info_pc'] as List)[0]['id_marca'];
        } else if (a['info_equipo_comunicacion'] != null &&
            (a['info_equipo_comunicacion'] as List).isNotEmpty) {
          assetMarcaId = (a['info_equipo_comunicacion'] as List)[0]['id_marca'];
        } else if (a['info_equipo_generico'] != null &&
            (a['info_equipo_generico'] as List).isNotEmpty) {
          assetMarcaId = (a['info_equipo_generico'] as List)[0]['id_marca'];
        }
        if (assetMarcaId != null) validKeys.add(assetMarcaId);
      } else {
        final val = a[ignoreField];
        if (val is int) validKeys.add(val);
      }
    }
    return masterList.where((m) => validKeys.contains(m['id'])).toList();
  }

  Widget _buildDrawerDateFilter(
    String label,
    DateTimeRange? currentRange,
    ValueChanged<DateTimeRange?> onChanged,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        currentRange == null
            ? 'Cualquier fecha'
            : '${currentRange.start.toLocal().toString().split(' ')[0]} - ${currentRange.end.toLocal().toString().split(' ')[0]}',
      ),
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
      case 'PC':
        return Icons.computer;
      case 'SOFTWARE':
        return Icons.developer_board;
      case 'COMUNICACION':
        return Icons.router;
      case 'GENERICO':
        return Icons.devices_other;
      default:
        return Icons.inventory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Activos (Global)',
          textScaler: TextScaler.linear(0.9),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sincronizar Datos',
            onPressed: () async {
              await SyncQueueService.instance.forceSyncAndRefresh();
              await _loadAssets();
            },
          ),
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
              padding: const EdgeInsets.only(
                top: 48,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros Globales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpiar Todos'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Identificadores Predictivos',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDrawerFilterButton<String>(
                    'Nombres',
                    _selectedNombres,
                    _getUniquePredictiveList('nombre'),
                    'valor',
                  ),
                  _buildDrawerFilterButton<String>(
                    'Códigos',
                    _selectedCodigos,
                    _getUniquePredictiveList('codigo'),
                    'valor',
                  ),
                  _buildDrawerFilterButton<String>(
                    'Números de Serie',
                    _selectedSeries,
                    _getUniquePredictiveList('numero_serie'),
                    'valor',
                  ),

                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Listas Maestras',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDrawerFilterButton(
                    'Tipo Activo',
                    _selectedTiposActivo,
                    _getFilteredMasterList(_tiposActivo, 'id_tipo_activo'),
                    'tipo',
                  ),
                  _buildDrawerFilterButton(
                    'Condición',
                    _selectedCondiciones,
                    _getFilteredMasterList(_condiciones, 'id_condicion_activo'),
                    'condicion',
                  ),
                  _buildDrawerFilterButton(
                    'Custodio',
                    _selectedCustodios,
                    _getFilteredMasterList(_custodios, 'id_custodio'),
                    'nombre_completo',
                  ),
                  _buildDrawerFilterButton(
                    'Sede',
                    _selectedSedes,
                    _getFilteredMasterList(_sedes, 'id_sede_activo'),
                    'sede',
                  ),
                  _buildDrawerFilterButton(
                    'Área',
                    _selectedAreas,
                    _getFilteredMasterList(_areas, 'id_area_activo'),
                    'area',
                  ),
                  _buildDrawerFilterButton(
                    'Ciudad',
                    _selectedCiudades,
                    _getFilteredMasterList(_ciudades, 'id_ciudad_activo'),
                    'ciudad',
                  ),
                  _buildDrawerFilterButton(
                    'Proveedor',
                    _selectedProveedores,
                    _getFilteredMasterList(_proveedores, 'id_provedor'),
                    'nombre',
                  ),
                  _buildDrawerFilterButton(
                    'Marca',
                    _selectedMarcas,
                    _getFilteredMasterList(_marcas, 'id_marca'),
                    'marca_proveedor',
                  ),

                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Rango de Fechas',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDrawerDateFilter(
                    'Fecha de Adquisición',
                    _rangoAdquisicion,
                    (r) => setState(() => _rangoAdquisicion = r),
                  ),
                  _buildDrawerDateFilter(
                    'Fecha de Entrega',
                    _rangoEntrega,
                    (r) => setState(() => _rangoEntrega = r),
                  ),
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
                  const Text(
                    'Módulos: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('PC'),
                    avatar: const Icon(Icons.computer, size: 16),
                    onPressed: () async {
                      _clearFilters();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PcAssetsPage()),
                      );
                      _loadAssets();
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Comunicaciones'),
                    avatar: const Icon(Icons.router, size: 16),
                    onPressed: () async {
                      _clearFilters();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommsAssetsPage(),
                        ),
                      );
                      _loadAssets();
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Genéricos'),
                    avatar: const Icon(Icons.devices_other, size: 16),
                    onPressed: () async {
                      _clearFilters();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GenericAssetsPage(),
                        ),
                      );
                      _loadAssets();
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Software'),
                    avatar: const Icon(Icons.developer_board, size: 16),
                    onPressed: () async {
                      _clearFilters();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SoftwareAssetsPage(),
                        ),
                      );
                      _loadAssets();
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.view_list),
                      label: Text('Lista'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.table_chart),
                      label: Text('Tabla'),
                    ),
                  ],
                  selected: {_isTableView},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isTableView = newSelection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isTableView ? _buildTableSection() : _buildListSection(),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 60.0,
        ), // Elevar el botón para no tapar los controles de página
        child: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Abrir Filtros',
            icon: const Icon(Icons.filter_list),
            label: const Text('Filtros'),
          ),
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredAssets.isEmpty) {
      if (_allAssets.isEmpty) {
        return ValueListenableBuilder<bool>(
          valueListenable: SyncQueueService.instance.isSyncingNotifier,
          builder: (context, isSyncing, child) {
            if (isSyncing) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Sincronizando inventario por primera vez...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Text(
                'No hay activos para mostrar. Modifique los filtros.',
              ),
            );
          },
        );
      } else {
        return const Center(
          child: Text('No hay activos para mostrar. Busque en otra categoría.'),
        );
      }
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Theme(
          data: Theme.of(context).copyWith(
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: Colors.transparent,
            ),
          ),
          child: PaginatedDataTable(
            header: null,
            columnSpacing: 24,
            rowsPerPage: _rowsPerPage,
            availableRowsPerPage: const [10, 20, 30, 40, 50, 100],
            onRowsPerPageChanged: (value) {
              setState(() {
                _rowsPerPage = value ?? PaginatedDataTable.defaultRowsPerPage;
              });
            },
            showFirstLastButtons: true,
            columns: const [
              DataColumn(
                label: Text(
                  'S/N',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Nombre',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Código',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tipo Activo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Condición',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Custodio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Ciudad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Sede',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Área',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Proveedor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Fe. Adquisición',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'IP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Fe. Entrega',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Coordenada',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Acciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            source: GlobalAssetDataSource(
              assets: _filteredAssets,
              context: context,
              onDelete: _deleteAsset,
              onScheduleMaintenance: (a) => showDialog(
                context: context,
                builder: (_) => MaintenanceFormDialog(initialAssetId: a['id']),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListSection() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredAssets.isEmpty) {
      if (_allAssets.isEmpty) {
        return ValueListenableBuilder<bool>(
          valueListenable: SyncQueueService.instance.isSyncingNotifier,
          builder: (context, isSyncing, child) {
            if (isSyncing) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Sincronizando inventario por primera vez...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Text(
                'No hay activos para mostrar. Modifique los filtros.',
              ),
            );
          },
        );
      } else {
        return const Center(
          child: Text('No hay activos para mostrar. Busque en otra categoría.'),
        );
      }
    }

    final totalItems = _filteredAssets.length;
    final totalPages = (totalItems / _listRowsPerPage).ceil();

    // Ensure current page is valid after filters drop
    if (_listCurrentPage >= totalPages && totalPages > 0) {
      _listCurrentPage = totalPages - 1;
    }

    final startIndex = _listCurrentPage * _listRowsPerPage;
    final endIndex = (startIndex + _listRowsPerPage) > totalItems
        ? totalItems
        : (startIndex + _listRowsPerPage);

    final pageAssets = _filteredAssets.sublist(startIndex, endIndex);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: pageAssets.length,
            itemBuilder: (context, index) {
              final asset = pageAssets[index];
              final icon = _getIconForCategory(asset['categoria_activo']);

              final isSoftware = asset['categoria_activo'] == 'SOFTWARE';
              final displayTitle = isSoftware
                  ? (asset['nombre'] ?? 'Software ${asset['id']}')
                  : 'S/N: ${asset['numero_serie'] ?? 'N/A'}';

              final displaySubtitle = isSoftware
                  ? 'Categoría: ${asset['categoria_activo'] ?? 'Desconocida'}\n'
                        'Tipo: ${asset['tipo_activo']?['tipo'] ?? 'N/A'} | Área: ${asset['area_activo']?['area'] ?? 'N/A'}'
                  : 'Nombre: ${asset['nombre'] ?? 'Sin Nombre'} | Tipo: ${asset['tipo_activo']?['tipo'] ?? 'N/A'}\n'
                        'Categoría: ${asset['categoria_activo'] ?? 'Desconocida'} | Área: ${asset['area_activo']?['area'] ?? 'N/A'}';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: Icon(icon, size: 40, color: Colors.blueGrey),
                  title: Text(
                    displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(displaySubtitle),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.build_circle,
                          color: Colors.blueGrey,
                        ),
                        tooltip: 'Programar Mantenimiento',
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => MaintenanceFormDialog(
                            initialAssetId: asset['id'],
                          ),
                        ),
                      ),
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
          ),
        ),
        // Paginator bar for cards matching material theme
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Filas: '),
                DropdownButton<int>(
                  value: _listRowsPerPage,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 20, child: Text('20')),
                    DropdownMenuItem(value: 30, child: Text('30')),
                    DropdownMenuItem(value: 40, child: Text('40')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                    DropdownMenuItem(value: 100, child: Text('100')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _listRowsPerPage = val;
                        _listCurrentPage = 0; // Reset page
                      });
                    }
                  },
                ),
                const SizedBox(width: 12),
                Text('${startIndex + 1}-${endIndex} de $totalItems'),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _listCurrentPage > 0
                      ? () => setState(() => _listCurrentPage--)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _listCurrentPage < totalPages - 1
                      ? () => setState(() => _listCurrentPage++)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
