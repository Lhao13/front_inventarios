import 'package:flutter/material.dart';
import 'package:front_inventarios/utils/asset_utils.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:front_inventarios/utils/asset_filter.dart';
import 'package:front_inventarios/widgets/maintenance_form_dialog.dart';
import 'package:front_inventarios/widgets/material_list_paginator.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';
import 'package:uuid/uuid.dart';

/// Clase base para las páginas de gestión de activos.
/// Evita la duplicación masiva de código al compartir la vista, paginación, filtros globales y ruteo de formularios.
abstract class BaseAssetPageState<T extends StatefulWidget> extends State<T> {
  // --- Estado Global Compartido ---
  List<Map<String, dynamic>> _allAssets = [];
  List<Map<String, dynamic>> _filteredAssets = [];
  bool _isLoading = true;
  bool _isTableView = true;

  int _listRowsPerPage = 10;
  int _listCurrentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _drawerScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  // --- Listas Maestras ---
  List<Map<String, dynamic>> _tiposActivo = [];
  List<Map<String, dynamic>> _condiciones = [];
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _ciudades = [];
  List<Map<String, dynamic>> _custodios = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _marcas = [];

  // --- Filtros Globales Actuales ---
  final Set<int> _selectedTiposActivo = {};
  final Set<int> _selectedCondiciones = {};
  final Set<int> _selectedSedes = {};
  final Set<int> _selectedAreas = {};
  final Set<int> _selectedCiudades = {};
  final Set<int> _selectedCustodios = {};
  final Set<int> _selectedProveedores = {};
  final Set<int> _selectedMarcas = {};

  final Set<String> _selectedNombres = {};
  final Set<String> _selectedCodigos = {};
  final Set<String> _selectedSeries = {};

  DateTimeRange? _rangoAdquisicion;
  DateTimeRange? _rangoEntrega;

  // --- Getters que deben implementar las subclases ---

  /// Retorna el título de la página (ej. "Equipos PC")
  String get pageTitle;

  /// Retorna la categoría por la cual filtrar ('PC', 'SOFTWARE', etc). Si es null, muestra todo.
  String? get categoryName;

  /// Definición de columnas para la vista de tabla.
  List<AssetColumnDef> get columns;

  /// Permitir a la página global definir un header (para los action chips)
  Widget? buildHeader() => null;

  /// Retorna filtros extras o personalizados para el drawer (ej. RAM, CPU).
  List<Widget> buildCustomDrawerFilters() => [];

  /// Permite extender el conteo de filtros para el contador general
  int getCustomFilterCount() => 0;

  /// Limpia los objetos de filtros personalizados
  void clearCustomFilters() {}

  /// Aplica el match de lógica de negocio para los filtros personalizados
  bool customMatch(Map<String, dynamic> asset, {String? ignoreField}) => true;

  // --- Helpers de info compartidos ---
  Map<String, dynamic>? getAssetInfo(Map<String, dynamic> asset, String key) {
    final list = asset[key];
    if (list is List && list.isNotEmpty) {
      return list[0] as Map<String, dynamic>?;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadFiltersFromCache();
    _loadAssets();
    SyncQueueService.instance.onCacheUpdated.addListener(_onCacheUpdated);
  }

  void _loadFiltersFromCache() {
    final cacheKey = pageTitle;
    if (FilterMemoryCache.globalCache.containsKey(cacheKey)) {
      final cached = FilterMemoryCache.globalCache[cacheKey]!;
      _selectedTiposActivo.addAll(cached.selectedTiposActivo);
      _selectedCondiciones.addAll(cached.selectedCondiciones);
      _selectedSedes.addAll(cached.selectedSedes);
      _selectedAreas.addAll(cached.selectedAreas);
      _selectedCiudades.addAll(cached.selectedCiudades);
      _selectedCustodios.addAll(cached.selectedCustodios);
      _selectedProveedores.addAll(cached.selectedProveedores);
      _selectedMarcas.addAll(cached.selectedMarcas);
      _selectedNombres.addAll(cached.selectedNombres);
      _selectedCodigos.addAll(cached.selectedCodigos);
      _selectedSeries.addAll(cached.selectedSeries);
      _rangoAdquisicion = cached.rangoAdquisicion;
      _rangoEntrega = cached.rangoEntrega;
    }
  }

  void _saveFiltersToCache() {
    FilterMemoryCache.globalCache[pageTitle] = _createFilterCriteria();
  }

  @override
  void dispose() {
    SyncQueueService.instance.onCacheUpdated.removeListener(_onCacheUpdated);
    _selectedNombres.clear();
    _selectedCodigos.clear();
    _selectedSeries.clear();
    _drawerScrollController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _onCacheUpdated() {
    if (mounted) _loadAssets(showLoading: false);
  }

  /// Expuesta publicamente para que las sub-clases puedan forzar actualizaciones si es requerido
  void reloadBaseAssets() {
    _loadAssets();
  }

  Future<void> _loadAssets({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
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
          if (categoryName != null) {
            _tiposActivo = futures[0]
                .where((t) => t['categoria'] == categoryName)
                .toList();
            _allAssets = localActivos
                .where((a) => a['categoria_activo'] == categoryName)
                .toList();
          } else {
            _tiposActivo = futures[0];
            _allAssets = localActivos;
          }
          _condiciones = futures[1];
          _sedes = futures[2];
          _areas = futures[3];
          _ciudades = futures[4];
          _custodios = futures[5];
          _proveedores = futures[6];
          _marcas = futures[7];

          _isLoading = false;
        });
        applyFilters();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  AssetFilterCriteria _createFilterCriteria() {
    return AssetFilterCriteria(
      selectedTiposActivo: Set.from(_selectedTiposActivo),
      selectedCondiciones: Set.from(_selectedCondiciones),
      selectedSedes: Set.from(_selectedSedes),
      selectedAreas: Set.from(_selectedAreas),
      selectedCiudades: Set.from(_selectedCiudades),
      selectedCustodios: Set.from(_selectedCustodios),
      selectedProveedores: Set.from(_selectedProveedores),
      selectedMarcas: Set.from(_selectedMarcas),
      selectedNombres: Set.from(_selectedNombres),
      selectedCodigos: Set.from(_selectedCodigos),
      selectedSeries: Set.from(_selectedSeries),
      rangoAdquisicion: _rangoAdquisicion,
      rangoEntrega: _rangoEntrega,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
    );
  }

  void applyFilters() {
    _saveFiltersToCache();
    if (!mounted) return;
    setState(() {
      _filteredAssets = _createFilterCriteria()
          .apply(_allAssets)
          .where((a) => customMatch(a))
          .toList();
    });
  }

  void _clearGlobalFilters() {
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
      _listCurrentPage = 0;
    });
    FilterMemoryCache.globalCache.remove(pageTitle);
    clearCustomFilters();
    applyFilters();
  }

  int _getFilterCount() {
    int count = 0;
    if (_selectedTiposActivo.isNotEmpty) count++;
    if (_selectedCondiciones.isNotEmpty) count++;
    if (_selectedSedes.isNotEmpty) count++;
    if (_selectedAreas.isNotEmpty) count++;
    if (_selectedCiudades.isNotEmpty) count++;
    if (_selectedCustodios.isNotEmpty) count++;
    if (_selectedProveedores.isNotEmpty) count++;
    if (_selectedMarcas.isNotEmpty) count++;
    if (_selectedNombres.isNotEmpty) count++;
    if (_selectedCodigos.isNotEmpty) count++;
    if (_selectedSeries.isNotEmpty) count++;
    if (_rangoAdquisicion != null) count++;
    if (_rangoEntrega != null) count++;
    return count + getCustomFilterCount();
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
      if (SyncQueueService.instance.isOnline) {
        SyncQueueService.instance.syncPendingOperations();
      }
      if (mounted) {
        context.showSnackBar('Activo eliminado localmente (Cola activada).');
      }
      _loadAssets();
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Future<void> _showAssetUpdateDialog(
    Map<String, dynamic>? existingAsset,
  ) async {
    final String initialCat = existingAsset == null
        ? (categoryName ?? 'GENERICO')
        : (existingAsset['categoria_activo'] ?? 'GENERICO').toString();
    final bool isUpdate = existingAsset != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final dialogWidth = screenWidth > 800 ? 600.0 : screenWidth * 0.9;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isUpdate ? 'Actualizar Activo' : 'Nuevo Activo',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DynamicAssetForm(
                    initialCategory: initialCat,
                    initialData: existingAsset,
                    onSave:
                        ({
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
                          String? codigo,
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
                            String rpcName = '';
                            Map<String, dynamic> params = {};
                            final String newId = existingAsset == null
                                ? const Uuid().v4()
                                : existingAsset['id'].toString();

                            if (categoria == 'PC') {
                              rpcName = isUpdate
                                  ? 'actualizar_activo_pc'
                                  : 'crear_activo_pc';
                              params = {
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
                            } else if (categoria == 'SOFTWARE') {
                              rpcName = isUpdate
                                  ? 'actualizar_activo_software'
                                  : 'crear_activo_software';
                              params = {
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
                            } else if (categoria == 'COMUNICACION') {
                              rpcName = isUpdate
                                  ? 'actualizar_activo_equipo_comunicacion'
                                  : 'crear_activo_equipo_comunicacion';
                              params = {
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
                                'p_num_puertos': numPuertos,
                                'p_tipo_extension': tipoExtension,
                                'p_observaciones': observaciones,
                              };
                            } else if (categoria == 'GENERICO') {
                              rpcName = isUpdate
                                  ? 'actualizar_activo_equipo_generico'
                                  : 'crear_activo_equipo_generico';
                              params = {
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
                                'p_fecha_entrega': fechaEntrega,
                                'p_coordenada': coordenada,
                                'p_id_marca': marcaId,
                                'p_modelo': modelo,
                                'p_cargador_codigo': cargadorCodigo,
                                'p_num_conexiones': numConexiones,
                                'p_var_impresora_color': varImpresoraColor,
                                'p_var_monitor_tipo_conexion':
                                    varMonitorTipoConexion,
                                'p_observaciones': observaciones,
                              };
                            }

                            if (rpcName.isNotEmpty) {
                              params['p_id_activo'] = newId;
                              await LocalDbService.instance.enqueueOperation(
                                rpcName,
                                params,
                              );
                              if (SyncQueueService.instance.isOnline) {
                                SyncQueueService.instance
                                    .syncPendingOperations();
                              }
                              if (!mounted) return;
                              context.showSnackBar(
                                'Activo guardado localmente.',
                              );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              _loadAssets();
                            }
                          } catch (error) {
                            if (!mounted) return;
                            context.showSnackBar(
                              'Error al procesar: $error',
                              isError: true,
                            );
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

  // --- Helpers UI del Drawer ---

  /// Para Dropdowns de Filtro Múltiple de Strings Predictivos
  Widget buildStringDrawerFilterButton(
    String label,
    List<String> selectedItems,
    List<String> allItems,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        selectedItems.isEmpty
            ? 'Todos'
            : '${selectedItems.length} seleccionados',
      ),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () async {
        final result = await showDialog<List<String>>(
          context: context,
          builder: (_) => MultiSelectDialog<String>(
            title: label,
            items: allItems.map((val) => {'id': val, 'valor': val}).toList(),
            initialSelectedIds: selectedItems,
            displayKey: 'valor',
          ),
        );
        if (result != null) {
          setState(() {
            selectedItems.clear();
            selectedItems.addAll(result);
          });
          applyFilters();
        }
      },
    );
  }

  /// Construye un Filtro para Entidades Foraneas como Custodio o Marca
  Widget buildDrawerFilterButton<T>(
    String label,
    Set<T> selectedIds,
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
            initialSelectedIds: selectedIds.toList(),
            displayKey: displayKey,
          ),
        );
        if (result != null) {
          setState(() {
            selectedIds.clear();
            selectedIds.addAll(result);
            _listCurrentPage = 0;
          });
          applyFilters();
        }
      },
    );
  }

  List<Map<String, dynamic>> getUniquePredictiveList(
    String key, {
    String? subKey,
  }) {
    if (_allAssets.isEmpty) return [];
    final criteria = _createFilterCriteria();
    final possibleAssets = _allAssets.where(
      (a) =>
          criteria.matches(a, ignoreField: key) &&
          customMatch(a, ignoreField: key),
    );
    final items = possibleAssets
        .map((a) {
          if (subKey != null) {
            final info = getAssetInfo(a, subKey);
            return info?[key]?.toString();
          }
          return a[key]?.toString();
        })
        .where((val) => val != null && val.trim().isNotEmpty)
        .toSet()
        .toList();
    items.sort();
    return items.map((val) => {'id': val, 'valor': val}).toList();
  }

  List<Map<String, dynamic>> getFilteredMasterList(
    List<Map<String, dynamic>> masterList,
    String ignoreField,
  ) {
    if (_allAssets.isEmpty || masterList.isEmpty) return [];
    final criteria = _createFilterCriteria();
    final validKeys = <int>{};
    for (var a in _allAssets.where(
      (asset) =>
          criteria.matches(asset, ignoreField: ignoreField) &&
          customMatch(asset, ignoreField: ignoreField),
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
                applyFilters();
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
          applyFilters();
        }
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'PC':
        return Colors.blue.shade100;
      case 'SOFTWARE':
        return Colors.green.shade100;
      case 'COMUNICACION':
        return Colors.orange.shade100;
      case 'GENERICO':
        return Colors.blueGrey.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getCategoryTextColor(String category) {
    switch (category.toUpperCase()) {
      case 'PC':
        return Colors.blue.shade900;
      case 'SOFTWARE':
        return Colors.green.shade900;
      case 'COMUNICACION':
        return Colors.orange.shade900;
      case 'GENERICO':
        return Colors.blueGrey.shade900;
      default:
        return Colors.grey.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si la subclase no define appBar (y usamos Drawer al final), podemos integrarlo libremente.
    return Scaffold(
      key: _scaffoldKey,
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
                          'Activos: ${_getFilterCount()}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Limpiar'),
                          onPressed: _clearGlobalFilters,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _drawerScrollController,
                  thumbVisibility: true,
                  thickness: 8,
                  child: ListView(
                    controller: _drawerScrollController,
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
                      buildDrawerFilterButton<String>(
                        'Nombres',
                        _selectedNombres,
                        getUniquePredictiveList('nombre'),
                        'valor',
                      ),
                      buildDrawerFilterButton<String>(
                        'Códigos',
                        _selectedCodigos,
                        getUniquePredictiveList('codigo'),
                        'valor',
                      ),
                      buildDrawerFilterButton<String>(
                        'Números de Serie',
                        _selectedSeries,
                        getUniquePredictiveList('numero_serie'),
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
                      if (categoryName == null)
                        buildDrawerFilterButton(
                          'Tipo Activo',
                          _selectedTiposActivo,
                          getFilteredMasterList(_tiposActivo, 'id_tipo_activo'),
                          'tipo',
                        ),
                      buildDrawerFilterButton(
                        'Condición',
                        _selectedCondiciones,
                        getFilteredMasterList(
                          _condiciones,
                          'id_condicion_activo',
                        ),
                        'condicion',
                      ),
                      buildDrawerFilterButton(
                        'Custodio',
                        _selectedCustodios,
                        getFilteredMasterList(_custodios, 'id_custodio'),
                        'nombre_completo',
                      ),
                      buildDrawerFilterButton(
                        'Sede',
                        _selectedSedes,
                        getFilteredMasterList(_sedes, 'id_sede_activo'),
                        'sede',
                      ),
                      buildDrawerFilterButton(
                        'Área',
                        _selectedAreas,
                        getFilteredMasterList(_areas, 'id_area_activo'),
                        'area',
                      ),
                      buildDrawerFilterButton(
                        'Ciudad',
                        _selectedCiudades,
                        getFilteredMasterList(_ciudades, 'id_ciudad_activo'),
                        'ciudad',
                      ),
                      buildDrawerFilterButton(
                        'Proveedor',
                        _selectedProveedores,
                        getFilteredMasterList(_proveedores, 'id_provedor'),
                        'nombre',
                      ),
                      buildDrawerFilterButton(
                        'Marca',
                        _selectedMarcas,
                        getFilteredMasterList(_marcas, 'id_marca'),
                        'marca_proveedor',
                      ),

                      // Extra custom filters injected by subclass
                      ...buildCustomDrawerFilters(),

                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Rangos de Fechas',
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
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.shade600,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pageTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'Actualizar\nDatos',
                            style: TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            await SyncQueueService.instance
                                .forceSyncAndRefresh();
                            await _loadAssets();
                          },
                        ),
                        Builder(
                          builder: (context) => IconButton(
                            icon: Badge(
                              isLabelVisible: _getFilterCount() > 0,
                              label: Text(_getFilterCount().toString()),
                              child: const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                              ),
                            ),
                            tooltip: 'Filtros: ${_getFilterCount()} activos',
                            onPressed: () =>
                                Scaffold.of(context).openEndDrawer(),
                          ),
                        ),
                      ],
                    ),
                    if (buildHeader() != null) ...[
                      const SizedBox(height: 8),
                      buildHeader()!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add),
                          label: Text('Agregar', textAlign: TextAlign.center),
                          onPressed: () => _showAssetUpdateDialog(null),
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
                            setState(() => _isTableView = newSelection.first);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _allAssets.isEmpty
                          ? const Center(
                              child: Text('No hay activos en inventario.'),
                            )
                          : _filteredAssets.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron activos con los filtros actuales.',
                              ),
                            )
                          : _isTableView
                          ? _buildTableSection()
                          : _buildListSection(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ), // Closing Segmented UI
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Filtros',
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
      assets: _filteredAssets,
      columns: columns,
      initialSortColumnIndex: _sortColumnIndex,
      initialSortAscending: _sortAscending,
      onSortChanged: (idx, asc) {
        setState(() {
          _sortColumnIndex = idx;
          _sortAscending = asc;
        });
        _saveFiltersToCache();
      },
      onEdit: RoleService.currentRole != UserRole.ayudante
          ? (a) async {
              await _showAssetUpdateDialog(a);
            }
          : null,
      onDelete: RoleService.currentRole != UserRole.ayudante
          ? (id) async {
              await _deleteAsset(id);
            }
          : null,
      customActionsBuilder: (asset) {
        final category = asset['categoria_activo']?.toString().toUpperCase();
        if (category == 'SOFTWARE') return [];
        return [
          Tooltip(
            message: 'Programar Mantenimiento',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showDialog(
                context: context,
                builder: (_) => MaintenanceFormDialog(
                  initialAssetId: asset['id']?.toString(),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.build_circle,
                  color: Colors.blueGrey,
                  size: 22,
                ),
              ),
            ),
          ),
        ];
      },
    );
  }

  Widget _buildListSection() {
    final totalItems = _filteredAssets.length;
    final totalPages = totalItems == 0
        ? 1
        : (totalItems / _listRowsPerPage).ceil();

    final effectivePage = _listCurrentPage.clamp(
      0,
      totalPages > 0 ? totalPages - 1 : 0,
    );

    final startIndex = effectivePage * _listRowsPerPage;
    final endIndex = (startIndex + _listRowsPerPage) > totalItems
        ? totalItems
        : (startIndex + _listRowsPerPage);

    final pageAssets = _filteredAssets.sublist(startIndex, endIndex);

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _listScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _listScrollController,
              itemCount: pageAssets.length,
              itemBuilder: (context, index) {
                final a = pageAssets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: categoryName != null
                          ? Colors.blue.shade100
                          : _getCategoryColor(
                              a['categoria_activo']?.toString() ?? '',
                            ),
                      child: Icon(
                        AssetUtils.getIconForCategory(
                          a['categoria_activo']?.toString() ?? '',
                        ),
                        color: categoryName != null
                            ? Colors.blue.shade900
                            : _getCategoryTextColor(
                                a['categoria_activo']?.toString() ?? '',
                              ),
                      ),
                    ),
                    title: Text(
                      a['nombre']?.toString() ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'S/N: ${a['numero_serie'] ?? 'N/A'}\nCódigo: ${a['codigo'] ?? 'N/A'}\nEstado: ${a['condicion_activo']?['condicion'] ?? 'N/A'}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a['categoria_activo']?.toString().toUpperCase() !=
                            'SOFTWARE')
                          IconButton(
                            icon: const Icon(
                              Icons.build,
                              color: Colors.blueGrey,
                            ),
                            tooltip: 'Mantenimientos',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => MaintenanceFormDialog(
                                  initialAssetId: a['id']?.toString(),
                                ),
                              );
                            },
                          ),
                        if (RoleService.currentRole != UserRole.ayudante)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Editar',
                            onPressed: () => _showAssetUpdateDialog(a),
                          ),
                        if (RoleService.currentRole != UserRole.ayudante)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar',
                            onPressed: () => _deleteAsset(a['id'].toString()),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        MaterialListPaginator(
          rowsPerPage: _listRowsPerPage,
          currentPage: effectivePage,
          totalItems: totalItems,
          rowsPerPageOptions: const [10, 20, 30, 40, 50, 100],
          onRowsPerPageChanged: (v) => setState(() {
            _listRowsPerPage = v;
            _listCurrentPage = 0;
          }),
          onFirst: () => setState(() => _listCurrentPage = 0),
          onPrevious: () =>
              setState(() => _listCurrentPage = effectivePage - 1),
          onNext: () => setState(() => _listCurrentPage = effectivePage + 1),
          onLast: () => setState(() => _listCurrentPage = totalPages - 1),
        ),
      ],
    );
  }
}
