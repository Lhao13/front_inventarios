import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:uuid/uuid.dart';

class SoftwareAssetsPage extends StatefulWidget {
  const SoftwareAssetsPage({super.key});

  @override
  State<SoftwareAssetsPage> createState() => _SoftwareAssetsPageState();
}

class _SoftwareAssetsPageState extends State<SoftwareAssetsPage> {
  List<Map<String, dynamic>> _allAssets = [];
  List<Map<String, dynamic>> _filteredAssets = [];
  bool _isLoading = true;
  bool _isTableView = true;

  // Column definitions for SOFTWARE category
  static final List<AssetColumnDef> _softwareColumns = [
    AssetColumnDef(label: 'Nombre',          getValue: (a) => a['nombre']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Código',          getValue: (a) => a['codigo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Tipo Activo',     getValue: (a) => a['tipo_activo']?['tipo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Condición',       getValue: (a) => a['condicion_activo']?['condicion']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Custodio',        getValue: (a) => a['custodio']?['nombre_completo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Área',             getValue: (a) => a['area_activo']?['area']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Proveedor',       getValue: (a) => a['proveedor']?['nombre']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Proveedor Sw.',   getValue: (a) { final i = _info(a, 'info_software'); return i?['proveedor']?.toString() ?? 'N/A'; }),
    AssetColumnDef(label: 'Fecha Inicio',    getValue: (a) { final i = _info(a, 'info_software'); return i?['fecha_inicio']?.toString() ?? 'N/A'; }),
    AssetColumnDef(label: 'Fecha Fin',       getValue: (a) { final i = _info(a, 'info_software'); return i?['fecha_fin']?.toString() ?? 'N/A'; }),
    AssetColumnDef(label: 'Observaciones',   getValue: (a) { final i = _info(a, 'info_software'); return i?['observaciones']?.toString() ?? 'N/A'; }, visibleByDefault: true),
  ];

  static Map<String, dynamic>? _info(Map<String, dynamic> asset, String key) {
    final list = asset[key];
    if (list is List && list.isNotEmpty) return list[0] as Map<String, dynamic>?;
    return null;
  }

  // Master Data
  List<Map<String, dynamic>> _tiposActivo = [];
  List<Map<String, dynamic>> _condiciones = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _custodios = [];
  List<Map<String, dynamic>> _proveedores = [];

  // Filter Models
  List<int> _selectedTiposActivo = [];
  List<int> _selectedCondiciones = [];
  List<int> _selectedAreas = [];
  List<int> _selectedCustodios = [];
  List<int> _selectedProveedores = [];

  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _codigosController = TextEditingController();

  DateTimeRange? _rangoAdquisicion;
  DateTimeRange? _rangoEntrega;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    SyncQueueService.instance.onCacheUpdated.addListener(_onCacheUpdated);
  }

  void _onCacheUpdated() {
    if (mounted) _loadAssets(showLoading: false);
  }

  @override
  void dispose() {
    SyncQueueService.instance.onCacheUpdated.removeListener(_onCacheUpdated);
    _nombresController.dispose();
    _codigosController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final localActivos = await LocalDbService.instance.getCollection('activo');
      
      final futures = await Future.wait([
        LocalDbService.instance.getCollection('tipo_activo'),
        LocalDbService.instance.getCollection('condicion_activo'),
        LocalDbService.instance.getCollection('area_activo'),
        LocalDbService.instance.getCollection('custodio'),
        LocalDbService.instance.getCollection('proveedor'),
      ]);
      
      if (mounted) {
        setState(() {
          _tiposActivo = futures[0].where((t) => t['categoria'] == 'SOFTWARE').toList();
          _condiciones = futures[1];
          _areas = futures[2];
          _custodios = futures[3];
          _proveedores = futures[4];

          _allAssets = localActivos.where((a) => a['categoria_activo'] == 'SOFTWARE').toList();
          _filteredAssets = _allAssets;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading Software assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final nombres = _nombresController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final codigos = _codigosController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final result = _allAssets.where((asset) {
      bool matchesNombre = nombres.isEmpty || nombres.any((n) => (asset['nombre'] ?? '').toString().toLowerCase().contains(n));
      bool matchesCodigo = codigos.isEmpty || codigos.any((c) => (asset['codigo'] ?? '').toString().toLowerCase().contains(c));

      bool matchesTipo = _selectedTiposActivo.isEmpty || _selectedTiposActivo.contains(asset['id_tipo_activo']);
      bool matchesCondicion = _selectedCondiciones.isEmpty || _selectedCondiciones.contains(asset['id_condicion_activo']);
      bool matchesArea = _selectedAreas.isEmpty || _selectedAreas.contains(asset['id_area_activo']);
      bool matchesCustodio = _selectedCustodios.isEmpty || _selectedCustodios.contains(asset['id_custodio']);
      bool matchesProveedor = _selectedProveedores.isEmpty || _selectedProveedores.contains(asset['id_provedor']);

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

      return matchesNombre && matchesCodigo &&
             matchesTipo && matchesCondicion && matchesArea && 
             matchesCustodio && matchesProveedor &&
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
      _selectedAreas.clear();
      _selectedCustodios.clear();
      _selectedProveedores.clear();
      _nombresController.clear();
      _codigosController.clear();
      _rangoAdquisicion = null;
      _rangoEntrega = null;
    });
    _applyFilters();
  }

  Future<void> _deleteAsset(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Software'),
        content: const Text('¿Deseas eliminar este software permanentemente?'),
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
      if (mounted) context.showSnackBar('Software eliminado localmente (Cola activada).');
      _loadAssets();
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Future<void> _showAssetDialog({Map<String, dynamic>? existingAsset}) async {
    final isUpdate = existingAsset != null;
    if (isUpdate) context.showSnackBar('Precaución: Refresque todos los campos en este formulario antes de guardar.');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(isUpdate ? 'Actualizar Software' : 'Agregar Especial - Software', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogContext))
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DynamicAssetForm(
                    initialCategory: 'SOFTWARE',
                    initialData: existingAsset,
                    onSave: ({
                      String? numeroSerie,
                      required String categoria,
                      required int tipoActivoId,
                      int? condicionActivoId,
                      int? custodioId,
                      int? ciudadActivoId,
                      int? sedeActivoId,
                      int? areaActivoId,
                      int? proveedorId,
                      String? fechaAdquisicion,
                      String? fechaEntrega,
                      String? coordenada,
                      String? nombre,
                      int? codigo,
                      String? ip,
                      int? marcaId,
                      String? modelo,
                      String? observaciones,
                      String? procesador,
                      String? ram,
                      String? almacenamiento,
                      String? cargadorCodigo,
                      int? numPuertos,
                      String? tipoExtension,
                      int? numConexiones,
                      String? varImpresoraColor,
                      String? varMonitorTipoConexion,
                      String? proveedorSoftware,
                      String? fechaInicio,
                      String? fechaFin,
                    }) async {
                      try {
                        Map<String, dynamic> params = {
                          'p_nombre': nombre,
                          'p_codigo': codigo,
                          'p_id_tipo_activo': tipoActivoId,
                          'p_id_condicion_activo': condicionActivoId,
                          'p_id_custodio': custodioId,
                          'p_id_area_activo': areaActivoId,
                          'p_id_provedor': proveedorId,
                          'p_proveedor': proveedorSoftware,
                          'p_fecha_inicio': fechaInicio,
                          'p_fecha_fin': fechaFin,
                          'p_observaciones': observaciones,
                        };

                        if (isUpdate) {
                          params['p_id_activo'] = existingAsset['id'];
                          await LocalDbService.instance.enqueueOperation('actualizar_activo_software', params);
                          if (!mounted) return;
                          context.showSnackBar('Activo actualizado localmente.');
                        } else {
                          params['p_id_activo'] = const Uuid().v4();
                          await LocalDbService.instance.enqueueOperation('crear_activo_software', params);
                          if (!mounted) return;
                          context.showSnackBar('Activo creado localmente.');
                        }
                        
                        if (SyncQueueService.instance.isOnline) {
                          SyncQueueService.instance.syncPendingOperations();
                        }
                        
                        Navigator.pop(dialogContext);
                        _loadAssets();
                      } catch (error) {
                        if (!mounted) return;
                        context.showSnackBar('Error en la base de datos: $error', isError: true);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerFilterButton(String label, List<int> selectedIds, List<Map<String, dynamic>> items, String displayKey) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(selectedIds.isEmpty ? 'Todos' : '${selectedIds.length} seleccionados'),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () async {
        final result = await showDialog<List<int>>(
          context: context,
          builder: (_) => MultiSelectDialog<int>(title: label, items: items, initialSelectedIds: selectedIds, displayKey: displayKey),
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
        decoration: InputDecoration(labelText: label, hintText: 'Ej: val1, val2', border: const OutlineInputBorder(), isDense: true),
        onChanged: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildDrawerDateFilter(String label, DateTimeRange? currentRange, ValueChanged<DateTimeRange?> onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(currentRange == null ? 'Cualquier fecha' : '${currentRange.start.toLocal().toString().split(' ')[0]} - ${currentRange.end.toLocal().toString().split(' ')[0]}'),
      trailing: currentRange != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () { onChanged(null); _applyFilters(); }) : const Icon(Icons.calendar_today),
      onTap: () async {
        final range = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDateRange: currentRange);
        if (range != null) { onChanged(range); _applyFilters(); }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licencias de Software'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            tooltip: 'Sincronizar Datos',
            onPressed: () async {
              await SyncQueueService.instance.forceSyncAndRefresh();
              await _loadAssets();
            }
          ),
          Builder(
            builder: (context) => IconButton(icon: const Icon(Icons.filter_list), tooltip: 'Filtros', onPressed: () => Scaffold.of(context).openEndDrawer()),
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
                  const Text('Filtros Software', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: _clearFilters, child: const Text('Limpiar Todos'))
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('Descripciones (Separados por coma)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  _buildDrawerTextField('Nombres', _nombresController),
                  _buildDrawerTextField('Códigos', _codigosController),
                  
                  const Divider(),
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('Listas Maestras', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  _buildDrawerFilterButton('Tipo Activo', _selectedTiposActivo, _tiposActivo, 'tipo'),
                  _buildDrawerFilterButton('Condición', _selectedCondiciones, _condiciones, 'condicion'),
                  _buildDrawerFilterButton('Custodio', _selectedCustodios, _custodios, 'nombre_completo'),
                  _buildDrawerFilterButton('Área', _selectedAreas, _areas, 'area'),
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
                ElevatedButton.icon(
                  onPressed: () => _showAssetDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Software'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
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
          label: const Text('Filtros'),
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    return AssetDataTable(
      assets: _filteredAssets,
      columns: _softwareColumns,
      isLoading: _isLoading,
      onEdit: (asset) => _showAssetDialog(existingAsset: asset),
      onDelete: _deleteAsset,
    );
  }

  Widget _buildListSection() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredAssets.isEmpty) return const Center(child: Text('No hay activos para mostrar. Modifique los filtros.'));

    return ListView.builder(
      itemCount: _filteredAssets.length,
      itemBuilder: (context, index) {
        final asset = _filteredAssets[index];
        final info = asset['info_software'] != null && (asset['info_software'] as List).isNotEmpty ? (asset['info_software'] as List)[0] : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.developer_board, size: 40, color: Colors.indigo),
            title: Text(asset['nombre']?.toString() ?? 'Software Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Tipo: ${asset['tipo_activo']?['tipo'] ?? 'N/A'} | Área: ${asset['area_activo']?['area'] ?? 'N/A'}\n'
              'Inicio: ${info?['fecha_inicio'] ?? 'N/A'} | Vence: ${info?['fecha_fin'] ?? 'N/A'}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAssetDialog(existingAsset: asset),
                  tooltip: 'Editar',
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
    );
  }
}
