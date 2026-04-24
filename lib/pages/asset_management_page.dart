import 'package:flutter/material.dart';
import 'package:front_inventarios/utils/asset_utils.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';
import 'package:front_inventarios/pages/assets/pc_assets_page.dart';
import 'package:front_inventarios/pages/assets/communication_assets_page.dart';
import 'package:front_inventarios/pages/assets/generic_assets_page.dart';
import 'package:front_inventarios/pages/assets/software_assets_page.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:front_inventarios/utils/asset_filter.dart';
import 'package:front_inventarios/widgets/maintenance_form_dialog.dart';
import 'package:front_inventarios/widgets/material_list_paginator.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';
import 'package:uuid/uuid.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/pages/asset_detail_page.dart';

class AssetManagementPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const AssetManagementPage({super.key, this.scaffoldKey});

  @override
  State<AssetManagementPage> createState() => _AssetManagementPageState();
}

class _AssetManagementPageState extends State<AssetManagementPage> {
  List<Map<String, dynamic>> _allAssets = [];
  List<Map<String, dynamic>> _filteredAssets = [];
  bool _isLoading = true;
  bool _isTableView = false;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  int _listRowsPerPage = 10;
  int _listCurrentPage = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _drawerScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final GlobalKey<FormFieldState> _categoryDropdownKey =
      GlobalKey<FormFieldState>();

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

  late final List<AssetColumnDef> _globalColumns = [
    AssetColumnDef(
      label: 'Categoría',
      getValue: (a) => a['categoria_activo']?.toString() ?? 'N/A',
      cellBuilder: (a) {
        final category = a['categoria_activo']?.toString();
        final color = AssetUtils.getColorForCategory(category);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            category ?? 'N/A',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        );
      },
    ),
    AssetColumnDef(
      label: 'S/N',
      getValue: (a) => a['numero_serie']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Nombre',
      getValue: (a) => a['nombre']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Código',
      getValue: (a) => a['codigo']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Tipo Activo',
      getValue: (a) {
        final val = a['tipo_activo'];
        if (val is Map) return val['tipo']?.toString() ?? 'N/A';
        if (val is List && val.isNotEmpty) {
          final first = val[0];
          if (first is Map) return first['tipo']?.toString() ?? 'N/A';
        }
        return val?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Condición',
      getValue: (a) {
        final val = a['condicion_activo'];
        if (val is Map) return val['condicion']?.toString() ?? 'N/A';
        if (val is List && val.isNotEmpty) {
          final first = val[0];
          if (first is Map) return first['condicion']?.toString() ?? 'N/A';
        }
        return val?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Custodio',
      getValue: (a) {
        final val = a['custodio'];
        if (val is Map) return val['nombre_completo']?.toString() ?? 'N/A';
        if (val is List && val.isNotEmpty) {
          final first = val[0];
          if (first is Map) {
            return first['nombre_completo']?.toString() ?? 'N/A';
          }
        }
        return val?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Ciudad',
      getValue: (a) {
        final val = a['ciudad_activo'];
        if (val is Map) return val['ciudad']?.toString() ?? 'N/A';
        if (val is List && val.isNotEmpty) {
          final first = val[0];
          if (first is Map) return first['ciudad']?.toString() ?? 'N/A';
        }
        return val?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Sede',
      getValue: (a) {
        final val = a['sede_activo'];
        if (val is Map) return val['sede']?.toString() ?? 'N/A';
        if (val is List && val.isNotEmpty) {
          final first = val[0];
          if (first is Map) return first['sede']?.toString() ?? 'N/A';
        }
        return val?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Área',
      getValue: (a) {
        final val = a['area_activo'];
        if (val is Map) return val['area']?.toString() ?? 'N/A';
        if (val is List && val.isNotEmpty) {
          final first = val[0];
          if (first is Map) return first['area']?.toString() ?? 'N/A';
        }
        return val?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Proveedor',
      getValue: (a) {
        final val = a['proveedor'];
        if (val is Map) return val['nombre']?.toString() ?? 'N/A';
        if (val is List && val.isNotEmpty) {
          final first = val[0];
          if (first is Map) return first['nombre']?.toString() ?? 'N/A';
        }
        return val?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Fe. Adquisición',
      getValue: (a) => a['fecha_adquisicion']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(label: 'IP', getValue: (a) => a['ip']?.toString() ?? 'N/A'),
    AssetColumnDef(
      label: 'Fe. Entrega',
      getValue: (a) => a['fecha_entrega']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Coordenada',
      getValue: (a) =>
          (a['coordenada'] ?? a['coordenadas'])?.toString() ?? 'N/A',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFiltersFromCache();
    _loadAssets();
    SyncQueueService.instance.onCacheUpdated.addListener(_onCacheUpdated);
  }

  void _loadFiltersFromCache() {
    const cacheKey = 'Global Assets';
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
    FilterMemoryCache.globalCache['Global Assets'] = _createFilterCriteria();
  }

  @override
  void dispose() {
    SyncQueueService.instance.onCacheUpdated.removeListener(_onCacheUpdated);
    _drawerScrollController.dispose();
    _listScrollController.dispose();
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
          _filteredAssets = _createFilterCriteria().apply(_allAssets);
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

  void _applyFilters() {
    _saveFiltersToCache();
    setState(() {
      _filteredAssets = _createFilterCriteria().apply(_allAssets);
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
    FilterMemoryCache.globalCache.remove('Global Assets');
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

  Future<void> _showAssetFormDialog(
    String category, {
    Map<String, dynamic>? asset,
  }) async {
    final bool isUpdate = asset != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    initialCategory: category,
                    initialData: asset,
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
                            final String assetId = isUpdate
                                ? asset['id']
                                : const Uuid().v4();

                            if (category == 'PC') {
                              rpcName = isUpdate
                                  ? 'actualizar_activo_pc'
                                  : 'crear_activo_pc';
                              params = {
                                'p_id_activo': assetId,
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
                            } else if (category == 'SOFTWARE') {
                              rpcName = isUpdate
                                  ? 'actualizar_activo_software'
                                  : 'crear_activo_software';
                              params = {
                                'p_id_activo': assetId,
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
                            } else if (category == 'COMUNICACION') {
                              rpcName = isUpdate
                                  ? 'actualizar_activo_equipo_comunicacion'
                                  : 'crear_activo_equipo_comunicacion';
                              params = {
                                'p_id_activo': assetId,
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
                            } else if (category == 'GENERICO') {
                              rpcName = isUpdate
                                  ? 'actualizar_activo_equipo_generico'
                                  : 'crear_activo_equipo_generico';
                              params = {
                                'p_id_activo': assetId,
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
                                isUpdate
                                    ? 'Activo actualizado localmente.'
                                    : 'Activo creado localmente.',
                              );

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              _loadAssets();
                            }
                          } catch (error) {
                            if (!mounted) return;
                            context.showSnackBar(
                              'Error al ${isUpdate ? 'actualizar' : 'crear'}: $error',
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

  Future<void> _showCategorySelectorDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Elegir Categoría de Activo'),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildCategoryOption(
                  context: dialogContext,
                  category: 'PC',
                  icon: Icons.computer,
                  description:
                      'Equipos de cómputo, laptops, servidores y estaciones de trabajo.',
                ),
                _buildCategoryOption(
                  context: dialogContext,
                  category: 'COMUNICACION',
                  title: 'Comunicaciones',
                  icon: Icons.router,
                  description:
                      'Equipos de red, telefonía IP, routers y dispositivos de conectividad.',
                ),
                _buildCategoryOption(
                  context: dialogContext,
                  category: 'GENERICO',
                  title: 'Genérico',
                  icon: Icons.devices_other,
                  description:
                      'Periféricos, monitores, impresoras y otros activos complementarios.',
                ),
                _buildCategoryOption(
                  context: dialogContext,
                  category: 'SOFTWARE',
                  icon: Icons.developer_board,
                  description:
                      'Licencias de programas, suscripciones y activos digitales intangibles.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryOption({
    required BuildContext context,
    required String category,
    String? title,
    required IconData icon,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showAssetFormDialog(category);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFilterButton<T>(
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
            _listCurrentPage = 0; // Reset page on filter
          });
          _applyFilters();
        }
      },
    );
  }

  List<Map<String, dynamic>> _getUniquePredictiveList(String key) {
    if (_allAssets.isEmpty) return [];
    final criteria = _createFilterCriteria();
    final possibleAssets = _allAssets.where(
      (a) => criteria.matches(a, ignoreField: key),
    );
    final items = possibleAssets
        .map((a) => a[key]?.toString())
        .where((val) => val != null && val.trim().isNotEmpty)
        .toSet()
        .toList();
    items.sort();
    return items.map((val) => {'id': val, 'valor': val}).toList();
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
    return count;
  }

  List<Map<String, dynamic>> _getFilteredMasterList(
    List<Map<String, dynamic>> masterList,
    String ignoreField,
  ) {
    if (_allAssets.isEmpty || masterList.isEmpty) return [];
    final criteria = _createFilterCriteria();
    final validKeys = <int>{};
    for (var a in _allAssets.where(
      (asset) => criteria.matches(asset, ignoreField: ignoreField),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey ?? _scaffoldKey,
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
                        Text(
                          'Filtros Globales',
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
                          onPressed: _clearFilters,
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
                  trackVisibility: true,
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
                        _getFilteredMasterList(
                          _condiciones,
                          'id_condicion_activo',
                        ),
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
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Categoria todo a la izquierda
                SizedBox(
                  width: 200, // Fixed width to keep it as a button-like size
                  child: _buildCategoryDropdown(),
                ),

                // Icono todo a la derecha
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(
                    'Actualizar\nDatos',
                    style: TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade700),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await SyncQueueService.instance.forceSyncAndRefresh();
                    await _loadAssets();
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showCategorySelectorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Activo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  style: SegmentedButton.styleFrom(
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: Colors.blue,
                  ),
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
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
              child: _isTableView ? _buildTableSection() : _buildListSection(),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
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
      assets: _filteredAssets,
      columns: _globalColumns,
      initialSortColumnIndex: _sortColumnIndex,
      initialSortAscending: _sortAscending,
      onSortChanged: (idx, asc) {
        setState(() {
          _sortColumnIndex = idx;
          _sortAscending = asc;
        });
        _saveFiltersToCache();
      },
      onRowTap: (asset) async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetDetailPage(asset: asset)),
        );
        if (result == true) {
          _loadAssets();
        }
      },
      onEdit: RoleService.currentRole != UserRole.ayudante
          ? (asset) async {
              final String category =
                  (asset['categoria_activo'] ?? 'PC').toString();
              _showAssetFormDialog(category, asset: asset);
            }
          : null,
      onDelete: (RoleService.currentRole != UserRole.ayudante &&
              RoleService.currentRole != UserRole.prestamo)
          ? (id) async => _deleteAsset(id)
          : null,
      customActionsBuilder: (asset) {
        final category = asset['categoria_activo']?.toString().toUpperCase();
        if (RoleService.currentRole == UserRole.ayudante ||
            RoleService.currentRole == UserRole.prestamo ||
            category == 'SOFTWARE') {
          return [];
        }
        return [
          Tooltip(
            message: 'Mantenimiento',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => MaintenanceFormDialog(
                    initialAssetId: asset['id'] as String,
                  ),
                );
              },
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
          child: Scrollbar(
            controller: _listScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              controller: _listScrollController,
              itemCount: pageAssets.length,
              itemBuilder: (context, index) {
                final asset = pageAssets[index];
                final icon = AssetUtils.getIconForCategory(
                  asset['categoria_activo'],
                );

                final isSoftware = asset['categoria_activo'] == 'SOFTWARE';
                final displayTitle = isSoftware
                    ? (asset['nombre'] ?? 'Software ${asset['id']}')
                    : 'S/N: ${asset['numero_serie'] ?? 'N/A'}';

                final displaySubtitle = isSoftware
                    ? 'Categoría: ${asset['categoria_activo'] ?? 'Desconocida'}\n'
                          'Tipo: ${asset['tipo_activo']?['tipo'] ?? 'N/A'} \n'
                          'Área: ${asset['area_activo']?['area'] ?? 'N/A'}'
                    : 'Nombre: ${asset['nombre'] ?? 'Sin Nombre'}\n'
                          'Tipo: ${asset['tipo_activo']?['tipo'] ?? 'N/A'}\n'
                          'Categoría: ${asset['categoria_activo'] ?? 'Desconocida'} \n'
                          'Área: ${asset['area_activo']?['area'] ?? 'N/A'}';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssetDetailPage(asset: asset),
                        ),
                      );
                      if (result == true) {
                        _loadAssets();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Leading: Icono en Círculo
                            CircleAvatar(
                              backgroundColor: AssetUtils.getColorForCategory(
                                asset['categoria_activo'],
                              ).withValues(alpha: 0.2),
                              radius: 25,
                              child: Icon(
                                icon,
                                size: 28,
                                color: AssetUtils.getColorForCategory(
                                  asset['categoria_activo'],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Centro: Información (Título y Subtítulo)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    displayTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displaySubtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Derecha: Acciones (Columna para evitar overflow)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Botón Editar
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    final String category =
                                        (asset['categoria_activo'] ?? 'PC')
                                            .toString();
                                    _showAssetFormDialog(
                                      category,
                                      asset: asset,
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(6.0),
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Botón Mantenimiento
                                if (asset['categoria_activo']
                                        ?.toString()
                                        .toUpperCase() !=
                                    'SOFTWARE' &&
                                    RoleService.currentRole != UserRole.ayudante &&
                                    RoleService.currentRole != UserRole.prestamo) ...[
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => MaintenanceFormDialog(
                                        initialAssetId: asset['id'],
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.build_circle,
                                        color: Colors.blueGrey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                                if (RoleService.currentRole != UserRole.ayudante && 
                                    RoleService.currentRole != UserRole.prestamo) ...[
                                  const SizedBox(height: 4),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _deleteAsset(asset['id']),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        MaterialListPaginator(
          rowsPerPage: _listRowsPerPage,
          currentPage: _listCurrentPage,
          totalItems: totalItems,
          rowsPerPageOptions: const [10, 20, 30, 40, 50, 100],
          onRowsPerPageChanged: (v) => setState(() {
            _listRowsPerPage = v;
            _listCurrentPage = 0;
          }),
          onFirst: () => setState(() => _listCurrentPage = 0),
          onPrevious: () => setState(() => _listCurrentPage--),
          onNext: () => setState(() => _listCurrentPage++),
          onLast: () => setState(() => _listCurrentPage = totalPages - 1),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        key: _categoryDropdownKey,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        dropdownColor: Colors.blueGrey.shade100,
        hint: const Text(
          'Elija una categoría',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.blue),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        items: const [
          DropdownMenuItem(
            value: 'PC',
            child: _CategoryItem(label: 'PC', icon: Icons.computer),
          ),
          DropdownMenuItem(
            value: 'Communications',
            child: _CategoryItem(label: 'Comunicaciones', icon: Icons.router),
          ),
          DropdownMenuItem(
            value: 'Generic',
            child: _CategoryItem(label: 'Genéricos', icon: Icons.devices_other),
          ),
          DropdownMenuItem(
            value: 'Software',
            child: _CategoryItem(
              label: 'Software',
              icon: Icons.developer_board,
            ),
          ),
        ],
        onChanged: (val) async {
          if (val == null) return;
          Widget page;
          switch (val) {
            case 'PC':
              page = const PcAssetsPage();
              break;
            case 'Communications':
              page = const CommsAssetsPage();
              break;
            case 'Generic':
              page = const GenericAssetsPage();
              break;
            case 'Software':
              page = const SoftwareAssetsPage();
              break;
            default:
              return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
          _categoryDropdownKey.currentState?.reset();
          _loadAssets();
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryItem({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
