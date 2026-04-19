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
import 'package:front_inventarios/utils/asset_filter.dart';
import 'package:front_inventarios/widgets/maintenance_form_dialog.dart';
import 'package:front_inventarios/widgets/material_list_paginator.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';
import 'package:uuid/uuid.dart';

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
  bool _isTableView = true;

  int _tableRowsPerPage = 10;
  int _tableCurrentPage = 0;
  int _listRowsPerPage = 10;
  int _listCurrentPage = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _drawerScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

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
    _drawerScrollController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
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
      selectedTiposActivo: _selectedTiposActivo,
      selectedCondiciones: _selectedCondiciones,
      selectedSedes: _selectedSedes,
      selectedAreas: _selectedAreas,
      selectedCiudades: _selectedCiudades,
      selectedCustodios: _selectedCustodios,
      selectedProveedores: _selectedProveedores,
      selectedMarcas: _selectedMarcas,
      selectedNombres: _selectedNombres,
      selectedCodigos: _selectedCodigos,
      selectedSeries: _selectedSeries,
      rangoAdquisicion: _rangoAdquisicion,
      rangoEntrega: _rangoEntrega,
    );
  }

  void _applyFilters() {
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

  Future<void> _showAssetUpdateDialog(Map<String, dynamic> asset) async {
    final String category = (asset['categoria_activo'] ?? 'PC').toString();

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
                        'Actualizar Activo - $category',
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

                            if (category == 'PC') {
                              rpcName = 'actualizar_activo_pc';
                              params = {
                                'p_id_activo': asset['id'],
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
                              rpcName = 'actualizar_activo_software';
                              params = {
                                'p_id_activo': asset['id'],
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
                              rpcName = 'actualizar_activo_equipo_comunicacion';
                              params = {
                                'p_id_activo': asset['id'],
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
                              rpcName = 'actualizar_activo_equipo_generico';
                              params = {
                                'p_id_activo': asset['id'],
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

                              // 1. Check if the page is still mounted before showing SnackBar
                              if (!mounted) return;
                              context.showSnackBar(
                                'Activo actualizado localmente.',
                              );

                              // 2. Check if the dialog is still mounted before popping it
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              _loadAssets();
                            }
                          } catch (error) {
                            if (!mounted) return;
                            context.showSnackBar(
                              'Error al actualizar: $error',
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
          _showAssetCreateDialog(category);
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

  Future<void> _showAssetCreateDialog(String category) async {
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
                        'Agregar Activo - $category',
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
                    initialData: null,
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
                            final String newId = const Uuid().v4();

                            if (category == 'PC') {
                              rpcName = 'crear_activo_pc';
                              params = {
                                'p_id_activo': newId,
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
                              rpcName = 'crear_activo_software';
                              params = {
                                'p_id_activo': newId,
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
                              rpcName = 'crear_activo_equipo_comunicacion';
                              params = {
                                'p_id_activo': newId,
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
                              rpcName = 'crear_activo_equipo_generico';
                              params = {
                                'p_id_activo': newId,
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
                              context.showSnackBar('Activo creado localmente.');

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              _loadAssets();
                            }
                          } catch (error) {
                            if (!mounted) return;
                            context.showSnackBar(
                              'Error al crear: $error',
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

  Widget _buildDrawerFilterButton<T>(
    String label,
    Set<T> selectedIds,
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
      key: widget.scaffoldKey ?? _scaffoldKey,
      endDrawer: Drawer(
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
                          'Filtros activos: ${_getFilterCount()}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Limpiar Filtros'),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Categorías: ',
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
                ElevatedButton.icon(
                  onPressed: _showCategorySelectorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Activo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
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
        padding: const EdgeInsets.only(bottom: 60.0),
        child: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Abrir Filtros',
            icon: const Icon(Icons.filter_list),
            label: Text('Filtros (${_getFilterCount()})'),
          ),
        ),
      ),
    );
  }

  double _getColWidth(String label) {
    switch (label) {
      case 'Acciones':
        return 140;
      case 'Categoría':
        return 110;
      case 'S/N':
        return 130;
      case 'Nombre':
        return 160;
      case 'Código':
        return 110;
      case 'Tipo Activo':
        return 140;
      case 'Condición':
        return 140;
      case 'Custodio':
        return 160;
      case 'Ciudad':
        return 110;
      case 'Sede':
        return 140;
      case 'Área':
        return 140;
      case 'Proveedor':
        return 100;
      case 'Fe. Adquisición':
        return 120;
      case 'IP':
        return 120;
      case 'Fe. Entrega':
        return 120;
      case 'Coordenada':
        return 140;
      default:
        return 130;
    }
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
    // ── Pagination math ──────────────────────────────────────────────────
    final totalItems = _filteredAssets.length;
    final totalPages = (totalItems / _tableRowsPerPage).ceil().clamp(1, 999999);
    if (_tableCurrentPage >= totalPages) _tableCurrentPage = totalPages - 1;
    if (_tableCurrentPage < 0) _tableCurrentPage = 0;
    final startIndex = _tableCurrentPage * _tableRowsPerPage;
    final endIndex = (startIndex + _tableRowsPerPage).clamp(0, totalItems);
    final pageAssets = _filteredAssets.sublist(startIndex, endIndex);

    final datatableTheme = Theme.of(context).copyWith(
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
      ),
    );
    // ────────────────────────────────────────────────────────────────────

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FIXED HEADER ---
                  Theme(
                    data: datatableTheme,
                    child: DataTable(
                      columnSpacing: 8,
                      horizontalMargin: 8,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withAlpha(128),
                      ),
                      columns: [
                        _buildStickyHeaderCol('Acciones'),
                        _buildStickyHeaderCol('Categoría'),
                        _buildStickyHeaderCol('S/N'),
                        _buildStickyHeaderCol('Nombre'),
                        _buildStickyHeaderCol('Código'),
                        _buildStickyHeaderCol('Tipo Activo'),
                        _buildStickyHeaderCol('Condición'),
                        _buildStickyHeaderCol('Custodio'),
                        _buildStickyHeaderCol('Ciudad'),
                        _buildStickyHeaderCol('Sede'),
                        _buildStickyHeaderCol('Área'),
                        _buildStickyHeaderCol('Proveedor'),
                        _buildStickyHeaderCol('Fe. Adquisición'),
                        _buildStickyHeaderCol('IP'),
                        _buildStickyHeaderCol('Fe. Entrega'),
                        _buildStickyHeaderCol('Coordenada'),
                      ],
                      rows: const [],
                    ),
                  ),

                  // --- SCROLLABLE BODY ---
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      child: Theme(
                        data: datatableTheme,
                        child: DataTable(
                          headingRowHeight: 0,
                          columnSpacing: 8,
                          horizontalMargin: 8,
                          border: TableBorder(
                            verticalInside: BorderSide(
                              color: Colors.grey.withAlpha(80),
                              width: 1,
                            ),
                          ),
                          columns: [
                            _buildStickyHeaderCol('Acciones', empty: true),
                            _buildStickyHeaderCol('Categoría', empty: true),
                            _buildStickyHeaderCol('S/N', empty: true),
                            _buildStickyHeaderCol('Nombre', empty: true),
                            _buildStickyHeaderCol('Código', empty: true),
                            _buildStickyHeaderCol('Tipo Activo', empty: true),
                            _buildStickyHeaderCol('Condición', empty: true),
                            _buildStickyHeaderCol('Custodio', empty: true),
                            _buildStickyHeaderCol('Ciudad', empty: true),
                            _buildStickyHeaderCol('Sede', empty: true),
                            _buildStickyHeaderCol('Área', empty: true),
                            _buildStickyHeaderCol('Proveedor', empty: true),
                            _buildStickyHeaderCol(
                              'Fe. Adquisición',
                              empty: true,
                            ),
                            _buildStickyHeaderCol('IP', empty: true),
                            _buildStickyHeaderCol('Fe. Entrega', empty: true),
                            _buildStickyHeaderCol('Coordenada', empty: true),
                          ],
                          rows: pageAssets.map(_buildGlobalTableRow).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        MaterialListPaginator(
          rowsPerPage: _tableRowsPerPage,
          currentPage: _tableCurrentPage,
          totalItems: totalItems,
          rowsPerPageOptions: const [10, 20, 30, 40, 50, 100],
          onRowsPerPageChanged: (v) => setState(() {
            _tableRowsPerPage = v;
            _tableCurrentPage = 0;
          }),
          onFirst: () => setState(() => _tableCurrentPage = 0),
          onPrevious: () => setState(() => _tableCurrentPage--),
          onNext: () => setState(() => _tableCurrentPage++),
          onLast: () => setState(() => _tableCurrentPage = totalPages - 1),
        ),
      ],
    );
  }

  DataColumn _buildStickyHeaderCol(String label, {bool empty = false}) {
    return DataColumn(
      label: SizedBox(
        width: _getColWidth(label),
        child: empty
            ? null
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  DataRow _buildGlobalTableRow(Map<String, dynamic> asset) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: _getColWidth('Acciones'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de Mantenimiento
                Tooltip(
                  message: 'Programar Mantenimiento',
                  child: InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) =>
                          MaintenanceFormDialog(initialAssetId: asset['id']),
                    ),
                    borderRadius: BorderRadius.circular(20),
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
                const SizedBox(width: 4),
                // Icono de Editar (Update)
                Tooltip(
                  message: 'Actualizar Activo',
                  child: InkWell(
                    onTap: () => _showAssetUpdateDialog(asset),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.edit, color: Colors.blue, size: 22),
                    ),
                  ),
                ),
                if (RoleService.currentRole != UserRole.ayudante) ...[
                  const SizedBox(width: 4),
                  // Icono de Eliminar
                  Tooltip(
                    message: 'Eliminar',
                    child: InkWell(
                      onTap: () => _deleteAsset(asset['id']),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.delete, color: Colors.red, size: 22),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: _getColWidth('Categoría'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(
                  asset['categoria_activo']?.toString() ?? 'PC',
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                asset['categoria_activo']?.toString() ?? 'PC',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _getCategoryTextColor(
                    asset['categoria_activo']?.toString() ?? 'PC',
                  ),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),

        _buildTableCell('numero_serie', 'S/N', asset),
        _buildTableCell('nombre', 'Nombre', asset),
        _buildTableCell('codigo', 'Código', asset),
        _buildTableCell('tipo_activo', 'Tipo Activo', asset, subKey: 'tipo'),
        _buildTableCell(
          'condicion_activo',
          'Condición',
          asset,
          subKey: 'condicion',
        ),
        _buildTableCell(
          'custodio',
          'Custodio',
          asset,
          subKey: 'nombre_completo',
        ),
        _buildTableCell('ciudad_activo', 'Ciudad', asset, subKey: 'ciudad'),
        _buildTableCell('sede_activo', 'Sede', asset, subKey: 'sede'),
        _buildTableCell('area_activo', 'Área', asset, subKey: 'area'),
        _buildTableCell('proveedor', 'Proveedor', asset, subKey: 'nombre'),
        _buildTableCell('fecha_adquisicion', 'Fe. Adquisición', asset),
        _buildTableCell('ip', 'IP', asset),
        _buildTableCell('fecha_entrega', 'Fe. Entrega', asset),
        _buildTableCell('coordenada', 'Coordenada', asset),
      ],
    );
  }

  DataCell _buildTableCell(
    String key,
    String colLabel,
    Map<String, dynamic> asset, {
    String? subKey,
  }) {
    String value = '';
    if (subKey != null) {
      value = asset[key]?[subKey]?.toString() ?? 'N/A';
    } else {
      value = asset[key]?.toString() ?? 'N/A';
    }

    return DataCell(
      SizedBox(
        width: _getColWidth(colLabel),
        child: Text(value, overflow: TextOverflow.ellipsis),
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
          child: Scrollbar(
            controller: _listScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _listScrollController,
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
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
}
