import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/widgets/maintenance_form_dialog.dart';
import 'package:front_inventarios/utils/date_utils.dart';
import 'package:front_inventarios/utils/asset_filter.dart';

/// Página de Mantenimientos.
///
/// Esta página permite al usuario gestionar los mantenimientos de los activos.
class MaintenancePage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const MaintenancePage({super.key, this.scaffoldKey});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _maintenances = [];
  List<Map<String, dynamic>> _assets = [];

  // Variables for view and filters
  bool _isTableView = true;
  List<Map<String, dynamic>> _filteredMaintenances = [];
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // Filter models
  final List<String> _selectedTipos = [];
  final List<String> _selectedEstados = [];
  final List<String> _selectedActivosStr = [];
  DateTimeRange? _rangoProgramada;
  DateTimeRange? _rangoRealizada;

  final ScrollController _listScrollController = ScrollController();

  late final List<AssetColumnDef> _columns = [
    AssetColumnDef(label: 'Activo', getValue: (m) => _getAssetDisplayInfo(m)),
    AssetColumnDef(
      label: 'Tipo',
      getValue: (m) => m['tipo']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Estado',
      getValue: (m) => m['estado']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Fecha Programada',
      getValue: (m) => m['fecha_programada']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Fecha Realizada',
      getValue: (m) => m['fecha_realizada']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Observaciones',
      getValue: (m) => m['observacion']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final cachedSort = FilterMemoryCache.tableSortCache['Maintenance'];
    if (cachedSort != null) {
      _sortColumnIndex = cachedSort.columnIndex;
      _sortAscending = cachedSort.ascending;
    }
    _loadMaintenances();
    _loadAssets();
    SyncQueueService.instance.onCacheUpdated.addListener(_onCacheUpdated);
  }

  void _onCacheUpdated() {
    if (mounted) {
      _loadMaintenances(showLoading: false);
      _loadAssets(showLoading: false);
    }
  }

  @override
  void dispose() {
    SyncQueueService.instance.onCacheUpdated.removeListener(_onCacheUpdated);
    _listScrollController.dispose();
    super.dispose();
  }

  String _getAssetDisplayInfo(Map<String, dynamic> m) {
    if (m['activo'] != null) {
      if (m['activo']['categoria_activo'] == 'SOFTWARE') {
        return m['activo']['nombre']?.toString() ?? 'Software Sin Nombre';
      }
      if (m['activo']['numero_serie'] != null) {
        return m['activo']['numero_serie'];
      }
    }
    // Búsqueda en los arreglos cargados offline
    final asset = _assets.firstWhere(
      (a) => a['id'] == m['id_activo'],
      orElse: () => <String, dynamic>{}, // Provide empty Map<String, dynamic>
    );
    if (asset.isNotEmpty) {
      if (asset['categoria_activo'] == 'SOFTWARE') {
        return asset['nombre']?.toString() ?? 'Software Sin Nombre';
      }
      if (asset['numero_serie'] != null) {
        return asset['numero_serie'];
      }
    }
    return 'ID: ${m['id_activo']}';
  }

  Future<void> _loadMaintenances({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final response = await LocalDbService.instance.getCollection(
        'mantenimiento',
      );
      // Sort response latest programada first locally
      response.sort((a, b) {
        final aDate = a['fecha_programada']?.toString() ?? '';
        final bDate = b['fecha_programada']?.toString() ?? '';
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;
      setState(() {
        _maintenances = response;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar mantenimientos: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssets({bool showLoading = true}) async {
    try {
      final localActivos = await LocalDbService.instance.getCollection(
        'activo',
      );
      final filtered = localActivos
        ..sort((a, b) {
          final sA = a['numero_serie']?.toString() ?? '';
          final sB = b['numero_serie']?.toString() ?? '';
          return sA.compareTo(sB);
        });

      if (mounted) {
        setState(() {
          _assets = filtered;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) debugPrint('Error loading assets: $e');
    }
  }

  bool _maintenanceMatches(Map<String, dynamic> m, {String? ignoreField}) {
    final activoStr = _getAssetDisplayInfo(m);

    bool matchesTipo =
        ignoreField == 'tipo' ||
        _selectedTipos.isEmpty ||
        _selectedTipos.contains((m['tipo'] ?? '').toString());
    bool matchesEstado =
        ignoreField == 'estado' ||
        _selectedEstados.isEmpty ||
        _selectedEstados.contains((m['estado'] ?? '').toString());
    bool matchesActivo =
        ignoreField == 'activo' ||
        _selectedActivosStr.isEmpty ||
        _selectedActivosStr.contains(activoStr);

    bool matchesProgramada = true;
    if (ignoreField != 'fecha_programada' &&
        _rangoProgramada != null &&
        m['fecha_programada'] != null) {
      try {
        final dt = DateTime.parse(m['fecha_programada'].toString());
        if (dt.isBefore(_rangoProgramada!.start) ||
            dt.isAfter(_rangoProgramada!.end)) {
          matchesProgramada = false;
        }
      } catch (_) {}
    }

    bool matchesRealizada = true;
    if (ignoreField != 'fecha_realizada' &&
        _rangoRealizada != null &&
        m['fecha_realizada'] != null) {
      try {
        final dt = DateTime.parse(m['fecha_realizada'].toString());
        if (dt.isBefore(_rangoRealizada!.start) ||
            dt.isAfter(_rangoRealizada!.end)) {
          matchesRealizada = false;
        }
      } catch (_) {}
    }

    return matchesTipo &&
        matchesEstado &&
        matchesActivo &&
        matchesProgramada &&
        matchesRealizada;
  }

  void _applyFilters() {
    setState(() {
      _filteredMaintenances = _maintenances
          .where((m) => _maintenanceMatches(m))
          .toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedTipos.clear();
      _selectedEstados.clear();
      _selectedActivosStr.clear();
      _rangoProgramada = null;
      _rangoRealizada = null;
    });
    _applyFilters();
  }

  int _getFilterCount() {
    int count = 0;
    if (_selectedTipos.isNotEmpty) count++;
    if (_selectedEstados.isNotEmpty) count++;
    if (_selectedActivosStr.isNotEmpty) count++;
    if (_rangoProgramada != null) count++;
    if (_rangoRealizada != null) count++;
    return count;
  }

  List<Map<String, dynamic>> _getUniquePredictiveList(String key) {
    if (_maintenances.isEmpty) return [];
    final possibleMains = _maintenances.where(
      (m) => _maintenanceMatches(m, ignoreField: key),
    );

    final items = possibleMains
        .map((m) {
          if (key == 'activo') return _getAssetDisplayInfo(m);
          return m[key]?.toString();
        })
        .where((val) => val != null && val.trim().isNotEmpty)
        .toSet()
        .toList();
    items.sort();
    return items.map((val) => {'id': val, 'valor': val}).toList();
  }

  Widget _buildDrawerFilterButton<T>(
    String label,
    List<T> selectedIds,
    List<Map<String, dynamic>> items,
    String displayKey,
  ) {
    final bool isActive = selectedIds.isNotEmpty;
    return ListTile(
      tileColor: isActive ? Colors.blue.shade200 : null,
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
          });
          _applyFilters();
        }
      },
    );
  }

  Widget _buildDrawerDateFilter(
    String label,
    DateTimeRange? currentRange,
    ValueChanged<DateTimeRange?> onChanged,
  ) {
    final bool isActive = currentRange != null;
    return ListTile(
      tileColor: isActive ? Colors.blue.shade50 : null,
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

  Future<void> _completeMaintenance(String id) async {
    try {
      await LocalDbService.instance
          .enqueueOperation('table:mantenimiento:update', {
            'id': id,
            'estado': 'Completado',
            'fecha_realizada': AppDateUtils.formatYYYYMMDD(DateTime.now()),
          });
      if (SyncQueueService.instance.isOnline) {
        SyncQueueService.instance.syncPendingOperations();
      }

      if (!mounted) return;
      context.showSnackBar(
        'Mantenimiento marcado como completado (Cola Local).',
      );
      _loadMaintenances();
    } catch (e) {
      if (mounted) context.showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _deleteMaintenance(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Mantenimiento'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este registro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LocalDbService.instance.enqueueOperation(
        'table:mantenimiento:delete',
        {'id': id},
      );
      if (SyncQueueService.instance.isOnline) {
        SyncQueueService.instance.syncPendingOperations();
      }

      if (!mounted) return;
      context.showSnackBar('Mantenimiento eliminado de forma local.');
      _loadMaintenances();
    } catch (e) {
      if (mounted) context.showSnackBar('Error: $e', isError: true);
    }
  }

  void _showAddMaintenanceDialog({Map<String, dynamic>? initialData}) {
    showDialog(
      context: context,
      builder: (_) => MaintenanceFormDialog(
        initialData: initialData,
        onSaved: () {
          _loadMaintenances();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.6,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Filtros: ${_getFilterCount()}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Limpiar'),
                          onPressed: _clearFilters,
                        ),
                      ],
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
                        'Buscar por ID de Activo',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildDrawerFilterButton<String>(
                      'Por Serial / Nombre',
                      _selectedActivosStr,
                      _getUniquePredictiveList('activo'),
                      'valor',
                    ),

                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Filtros de Estado',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildDrawerFilterButton(
                      'Tipo',
                      _selectedTipos,
                      _getUniquePredictiveList('tipo'),
                      'valor',
                    ),
                    _buildDrawerFilterButton(
                      'Estado',
                      _selectedEstados,
                      _getUniquePredictiveList('estado'),
                      'valor',
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
                      'Fecha Programada',
                      _rangoProgramada,
                      (r) => setState(() => _rangoProgramada = r),
                    ),
                    _buildDrawerDateFilter(
                      'Fecha Realizada',
                      _rangoRealizada,
                      (r) => setState(() => _rangoRealizada = r),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mantenimientos',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Sincronizar de la Nube',
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await SyncQueueService.instance.forceSyncAndRefresh();
                    await _loadMaintenances();
                    await _loadAssets();
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (RoleService.currentRole != UserRole.ayudante)
                  ElevatedButton.icon(
                    onPressed: _showAddMaintenanceDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Programar'),
                  ),

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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _filteredMaintenances.isEmpty
                  ? (_maintenances.isEmpty
                        ? ValueListenableBuilder<bool>(
                            valueListenable:
                                SyncQueueService.instance.isSyncingNotifier,
                            builder: (context, isSyncing, child) {
                              if (isSyncing) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text(
                                        'Sincronizando mantenimientos por primera vez...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const Center(
                                child: Text(
                                  'No hay mantenimientos. Modifique los filtros.',
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Text(
                              'No hay mantenimientos. Modifique los filtros.',
                            ),
                          ))
                  : _isTableView
                  ? _buildTableSection()
                  : _buildListSection(),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Abrir Filtros',
            backgroundColor: _getFilterCount() > 0 ? Colors.orange : null,
            icon: const Icon(Icons.filter_list),
            label: Text('Filtros (${_getFilterCount()})'),
          ),
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    return AssetDataTable(
      assets: _filteredMaintenances,
      columns: _columns,
      onEdit: RoleService.currentRole != UserRole.ayudante
          ? (m) async => _showAddMaintenanceDialog(initialData: m)
          : null,
      onDelete: RoleService.currentRole != UserRole.ayudante
          ? (id) => _deleteMaintenance(id)
          : null,
      customActionsBuilder: (m) => [
        if (m['estado'] != 'Completado' &&
            RoleService.currentRole != UserRole.ayudante)
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            tooltip: 'Marcar como Completado',
            onPressed: () => _completeMaintenance(m['id'] as String),
          ),
      ],
    );
  }

  Widget _buildListSection() {
    return Scrollbar(
      controller: _listScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      child: ListView.builder(
        controller: _listScrollController,
        itemCount: _filteredMaintenances.length,
        itemBuilder: (context, index) {
          final m = _filteredMaintenances[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: m['estado'] == 'Pendiente'
                    ? Colors.orange
                    : m['estado'] == 'Completado'
                    ? Colors.green
                    : Colors.blue,
                child: Icon(
                  m['estado'] == 'Completado' ? Icons.check : Icons.build,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text('${_getAssetDisplayInfo(m)} - ${m['tipo']}'),
              subtitle: Text(
                'Programado: ${m['fecha_programada']} | Estado: ${m['estado']}'
                '${m['fecha_realizada'] != null ? '\nRealizado: ${m['fecha_realizada']}' : ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (RoleService.currentRole != UserRole.ayudante)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      tooltip: 'Editar',
                      onPressed: () =>
                          _showAddMaintenanceDialog(initialData: m),
                    ),
                  if (m['estado'] != 'Completado' &&
                      RoleService.currentRole != UserRole.ayudante)
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      tooltip: 'Marcar como Completado',
                      onPressed: () => _completeMaintenance(m['id'] as String),
                    ),
                  if (RoleService.currentRole != UserRole.ayudante)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Eliminar',
                      onPressed: () => _deleteMaintenance(m['id'] as String),
                    ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
