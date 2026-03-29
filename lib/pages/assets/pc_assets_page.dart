import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:uuid/uuid.dart';

class PcAssetsPage extends StatefulWidget {
  const PcAssetsPage({super.key});

  @override
  State<PcAssetsPage> createState() => _PcAssetsPageState();
}

class _PcAssetsPageState extends State<PcAssetsPage> {
  List<Map<String, dynamic>> _allAssets = [];
  List<Map<String, dynamic>> _filteredAssets = [];
  bool _isLoading = true;
  bool _isTableView = true;

  // Column definitions for PC category
  static final List<AssetColumnDef> _pcColumns = [
    AssetColumnDef(label: 'S/N',              getValue: (a) => a['numero_serie']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Nombre',           getValue: (a) => a['nombre']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Código',           getValue: (a) => a['codigo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Tipo Activo',      getValue: (a) => a['tipo_activo']?['tipo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Condición',        getValue: (a) => a['condicion_activo']?['condicion']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Custodio',         getValue: (a) => a['custodio']?['nombre_completo']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Ciudad',           getValue: (a) => a['ciudad_activo']?['ciudad']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Sede',             getValue: (a) => a['sede_activo']?['sede']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Área',              getValue: (a) => a['area_activo']?['area']?.toString() ?? 'N/A'),
    AssetColumnDef(label: 'Proveedor',        getValue: (a) => a['proveedor']?['nombre']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Fe. Adquisición', getValue: (a) => a['fecha_adquisicion']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Fe. Entrega',      getValue: (a) => a['fecha_entrega']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'IP',               getValue: (a) => a['ip']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Coordenada',       getValue: (a) => a['coordenada']?.toString() ?? 'N/A', visibleByDefault: false),
    AssetColumnDef(label: 'Marca',            getValue: (a) { final info = _info(a, 'info_pc'); return info?['marca']?['marca_proveedor']?.toString() ?? 'N/A'; }),
    AssetColumnDef(label: 'Modelo',           getValue: (a) { final info = _info(a, 'info_pc'); return info?['modelo']?.toString() ?? 'N/A'; }),
    AssetColumnDef(label: 'Procesador',       getValue: (a) { final info = _info(a, 'info_pc'); return info?['procesador']?.toString() ?? 'N/A'; }),
    AssetColumnDef(label: 'RAM',              getValue: (a) { final info = _info(a, 'info_pc'); return info?['ram']?.toString() ?? 'N/A'; }),
    AssetColumnDef(label: 'Almacenamiento',   getValue: (a) { final info = _info(a, 'info_pc'); return info?['almacenamiento']?.toString() ?? 'N/A'; }),
    AssetColumnDef(label: 'Cód. Cargador',   getValue: (a) { final info = _info(a, 'info_pc'); return info?['cargador_codigo']?.toString() ?? 'N/A'; }, visibleByDefault: false),
    AssetColumnDef(label: 'Num. Puertos',     getValue: (a) { final info = _info(a, 'info_pc'); return info?['num_puertos']?.toString() ?? 'N/A'; }, visibleByDefault: false),
    AssetColumnDef(label: 'Observaciones',    getValue: (a) { final info = _info(a, 'info_pc'); return info?['observaciones']?.toString() ?? 'N/A'; }, visibleByDefault: true),
  ];

  /// Helper to safely get the first element of a sub-list relation.
  static Map<String, dynamic>? _info(Map<String, dynamic> asset, String key) {
    final list = asset[key];
    if (list is List && list.isNotEmpty) return list[0] as Map<String, dynamic>?;
    return null;
  }

  // Master Data
  List<Map<String, dynamic>> _tiposActivo = [];
  List<Map<String, dynamic>> _condiciones = [];
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _ciudades = [];
  List<Map<String, dynamic>> _custodios = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _marcas = [];

  // Filter Models
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
  final TextEditingController _modelosController = TextEditingController();
  final TextEditingController _procesadoresController = TextEditingController();

  List<String> _selectedRams = [];
  List<String> _selectedStorages = [];

  static const List<String> _ramOptions = ['4GB', '8GB', '12GB', '16GB', '32GB', '64GB', '128GB', '256GB'];
  static const List<String> _storageOptions = ['128GB', '256GB', '512GB', '1TB', '2TB', '4TB', '10TB'];

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
      // LECTURA OFFLINE FIRST DIRECTA (Ultra Rápida)
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
          _tiposActivo = futures[0].where((t) => t['categoria'] == 'PC').toList();
          _condiciones = futures[1];
          _sedes = futures[2];
          _areas = futures[3];
          _ciudades = futures[4];
          _custodios = futures[5];
          _proveedores = futures[6];
          _marcas = futures[7];

          _allAssets = localActivos.where((a) => a['categoria_activo'] == 'PC').toList();
          _filteredAssets = _allAssets;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading PC assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final nombres = _nombresController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final codigos = _codigosController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final series = _seriesController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final modelos = _modelosController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final cpus = _procesadoresController.text.trim().toLowerCase().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final result = _allAssets.where((asset) {
      final info = asset['info_pc'] != null && (asset['info_pc'] as List).isNotEmpty ? (asset['info_pc'] as List)[0] : null;

      bool matchesNombre = nombres.isEmpty || nombres.any((n) => (asset['nombre'] ?? '').toString().toLowerCase().contains(n));
      bool matchesCodigo = codigos.isEmpty || codigos.any((c) => (asset['codigo'] ?? '').toString().toLowerCase().contains(c));
      bool matchesSerie = series.isEmpty || series.any((s) => (asset['numero_serie'] ?? '').toString().toLowerCase().contains(s));
      bool matchesModelo = modelos.isEmpty || modelos.any((m) => (info?['modelo'] ?? '').toString().toLowerCase().contains(m));
      bool matchesCpu = cpus.isEmpty || cpus.any((c) => (info?['procesador'] ?? '').toString().toLowerCase().contains(c));
      bool matchesRam = _selectedRams.isEmpty || _selectedRams.contains(info?['ram']?.toString());
      bool matchesStorage = _selectedStorages.isEmpty || _selectedStorages.contains(info?['almacenamiento']?.toString());

      bool matchesTipo = _selectedTiposActivo.isEmpty || _selectedTiposActivo.contains(asset['id_tipo_activo']);
      bool matchesCondicion = _selectedCondiciones.isEmpty || _selectedCondiciones.contains(asset['id_condicion_activo']);
      bool matchesSede = _selectedSedes.isEmpty || _selectedSedes.contains(asset['id_sede_activo']);
      bool matchesArea = _selectedAreas.isEmpty || _selectedAreas.contains(asset['id_area_activo']);
      bool matchesCiudad = _selectedCiudades.isEmpty || _selectedCiudades.contains(asset['id_ciudad_activo']);
      bool matchesCustodio = _selectedCustodios.isEmpty || _selectedCustodios.contains(asset['id_custodio']);
      bool matchesProveedor = _selectedProveedores.isEmpty || _selectedProveedores.contains(asset['id_provedor']);
      bool matchesMarca = _selectedMarcas.isEmpty || _selectedMarcas.contains(info?['id_marca']);

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

      return matchesNombre && matchesCodigo && matchesSerie && matchesModelo &&
             matchesCpu && matchesRam && matchesStorage &&
             matchesTipo && matchesCondicion && matchesSede &&
             matchesArea && matchesCiudad && matchesCustodio &&
             matchesProveedor && matchesMarca &&
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
      _modelosController.clear();
      _procesadoresController.clear();
      _selectedRams.clear();
      _selectedStorages.clear();
      _rangoAdquisicion = null;
      _rangoEntrega = null;
    });
    _applyFilters();
  }

  Future<void> _deleteAsset(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar PC'),
        content: const Text('¿Deseas eliminar este PC permanentemente?'),
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

      if (mounted) context.showSnackBar('Activo eliminado de manera local (Cola activada).');
      _loadAssets();
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Future<void> _showAssetDialog({Map<String, dynamic>? existingAsset}) async {
    final isUpdate = existingAsset != null;
    if (isUpdate) context.showSnackBar('Precaución: Refresque todos los campos en este formulario para el Activo ${existingAsset['nombre']} antes de guardar.');

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
                    Expanded(child: Text(isUpdate ? 'Actualizar PC' : 'Agregar Especial - PC', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogContext))
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DynamicAssetForm(
                    initialCategory: 'PC',
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
                          'p_numero_serie': numeroSerie,
                          'p_nombre': nombre,
                          'p_codigo': codigo,
                          'p_id_tipo_activo': tipoActivoId,
                          'p_id_condicion_activo': condicionActivoId,
                          'p_id_custodio': custodioId,
                          'p_id_ciudad_activo': ciudadActivoId,
                          'p_id_sede_activo': sedeActivoId,
                          'p_id_area_activo': areaActivoId,
                          'p_id_provedor': proveedorId,
                          'p_fecha_adquisicion': fechaAdquisicion,
                          'p_ip': ip,
                          'p_fecha_entrega': fechaEntrega,
                          'p_coordenada': coordenada,
                          'p_id_marca': marcaId,
                          'p_modelo': modelo,
                          'p_procesador': procesador,
                          'p_ram': ram,
                          'p_almacenamiento': almacenamiento,
                          'p_cargador_codigo': cargadorCodigo,
                          'p_num_puertos': numPuertos,
                          'p_observaciones': observaciones,
                        };

                        if (isUpdate) {
                          params['p_id_activo'] = existingAsset['id'];
                          await LocalDbService.instance.enqueueOperation('actualizar_activo_pc', params);
                          if (!mounted) return;
                          context.showSnackBar('Activo PC actualizado localmente.');
                        } else {
                          params['p_id_activo'] = const Uuid().v4();
                          await LocalDbService.instance.enqueueOperation('crear_activo_pc', params);
                          if (!mounted) return;
                          context.showSnackBar('Activo PC creado localmente.');
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

  Widget _buildStringDrawerFilterButton(String label, List<String> selectedItems, List<String> allItems) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(selectedItems.isEmpty ? 'Todos' : '${selectedItems.length} seleccionados'),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () async {
        final List<Map<String, dynamic>> itemsList = allItems.map((e) => {'id': e}).toList();
        final List<String>? result = await showDialog<List<String>>(
          context: context,
          builder: (_) => MultiSelectDialog<String>(
            title: label,
            items: itemsList,
            initialSelectedIds: selectedItems,
            displayKey: 'id',
            valueKey: 'id',
          ),
        );
        if (result != null) {
          setState(() {
            if (label == 'RAM') {
              _selectedRams = result.map((e) => e.toString()).toList();
            } else if (label == 'Almacenamiento') {
              _selectedStorages = result.map((e) => e.toString()).toList();
            }
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
        title: const Text('Equipos PC'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
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
                  const Text('Filtros PC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  _buildDrawerTextField('Números de Serie', _seriesController),
                  _buildDrawerTextField('Modelos', _modelosController),
                  _buildDrawerTextField('Procesadores', _procesadoresController),
                  
                  const Divider(),
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('Capacidad', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  _buildStringDrawerFilterButton('RAM', _selectedRams, _ramOptions),
                  _buildStringDrawerFilterButton('Almacenamiento', _selectedStorages, _storageOptions),
                  
                  const Divider(),
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('Listas Maestras', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  _buildDrawerFilterButton('Tipo Activo', _selectedTiposActivo, _tiposActivo, 'tipo'),
                  _buildDrawerFilterButton('Condición', _selectedCondiciones, _condiciones, 'condicion'),
                  _buildDrawerFilterButton('Custodio', _selectedCustodios, _custodios, 'nombre_completo'),
                  _buildDrawerFilterButton('Sede', _selectedSedes, _sedes, 'sede'),
                  _buildDrawerFilterButton('Área', _selectedAreas, _areas, 'area'),
                  _buildDrawerFilterButton('Ciudad', _selectedCiudades, _ciudades, 'ciudad'),
                  _buildDrawerFilterButton('Proveedor', _selectedProveedores, _proveedores, 'nombre'),
                  _buildDrawerFilterButton('Marca', _selectedMarcas, _marcas, 'marca_proveedor'),

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
                  label: const Text('Agregar PC'),
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
      columns: _pcColumns,
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
        final info = asset['info_pc'] != null && (asset['info_pc'] as List).isNotEmpty ? (asset['info_pc'] as List)[0] : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.computer, size: 40, color: Colors.blue),
            title: Text(asset['nombre']?.toString() ?? 'PC Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'S/N: ${asset['numero_serie'] ?? 'N/A'} | Tipo: ${asset['tipo_activo']?['tipo'] ?? 'N/A'} | Área: ${asset['area_activo']?['area'] ?? 'N/A'}\n'
              'CPU: ${info?['procesador'] ?? 'N/A'} | RAM: ${info?['ram'] ?? 'N/A'} | Disco: ${info?['almacenamiento'] ?? 'N/A'}',
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
