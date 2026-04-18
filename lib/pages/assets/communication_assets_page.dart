import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';
import 'package:front_inventarios/widgets/multi_select_dialog.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/widgets/maintenance_form_dialog.dart';
import 'package:front_inventarios/widgets/material_list_paginator.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:uuid/uuid.dart';

class CommsAssetsPage extends StatefulWidget {
  const CommsAssetsPage({super.key});

  @override
  State<CommsAssetsPage> createState() => _CommsAssetsPageState();
}

class _CommsAssetsPageState extends State<CommsAssetsPage> {
  List<Map<String, dynamic>> _allAssets = [];
  List<Map<String, dynamic>> _filteredAssets = [];
  bool _isLoading = true;
  bool _isTableView = true;

  int _listRowsPerPage = 10;
  int _listCurrentPage = 0;

  // Column definitions for COMUNICACION category
  static final List<AssetColumnDef> _commsColumns = [
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
      getValue: (a) => a['tipo_activo']?['tipo']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Condición',
      getValue: (a) => a['condicion_activo']?['condicion']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Custodio',
      getValue: (a) => a['custodio']?['nombre_completo']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Ciudad',
      getValue: (a) => a['ciudad_activo']?['ciudad']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Sede',
      getValue: (a) => a['sede_activo']?['sede']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Área',
      getValue: (a) => a['area_activo']?['area']?.toString() ?? 'N/A',
    ),
    AssetColumnDef(
      label: 'Proveedor',
      getValue: (a) => a['proveedor']?['nombre']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Fe. Adquisición',
      getValue: (a) => a['fecha_adquisicion']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'IP',
      getValue: (a) => a['ip']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Fe. Entrega',
      getValue: (a) => a['fecha_entrega']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Coordenada',
      getValue: (a) => a['coordenada']?.toString() ?? 'N/A',
      visibleByDefault: false,
    ),
    AssetColumnDef(
      label: 'Marca',
      getValue: (a) {
        final i = _info(a, 'info_equipo_comunicacion');
        return i?['marca']?['marca_proveedor']?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Modelo',
      getValue: (a) {
        final i = _info(a, 'info_equipo_comunicacion');
        return i?['modelo']?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Num. Puertos',
      getValue: (a) {
        final i = _info(a, 'info_equipo_comunicacion');
        return i?['num_puertos']?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Tipo Extensión',
      getValue: (a) {
        final i = _info(a, 'info_equipo_comunicacion');
        return i?['tipo_extension']?.toString() ?? 'N/A';
      },
    ),
    AssetColumnDef(
      label: 'Observaciones',
      getValue: (a) {
        final i = _info(a, 'info_equipo_comunicacion');
        return i?['observaciones']?.toString() ?? 'N/A';
      },
      visibleByDefault: true,
    ),
  ];

  static Map<String, dynamic>? _info(Map<String, dynamic> asset, String key) {
    final list = asset[key];
    if (list is List && list.isNotEmpty) {
      return list[0] as Map<String, dynamic>?;
    }
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
  final List<int> _selectedTiposActivo = [];
  final List<int> _selectedCondiciones = [];
  final List<int> _selectedSedes = [];
  final List<int> _selectedAreas = [];
  final List<int> _selectedCiudades = [];
  final List<int> _selectedCustodios = [];
  final List<int> _selectedProveedores = [];
  final List<int> _selectedMarcas = [];

  final List<String> _selectedNombres = [];
  final List<String> _selectedCodigos = [];
  final List<String> _selectedSeries = [];
  final List<String> _selectedModelos = [];
  final List<String> _selectedPuertos = [];

  DateTimeRange? _rangoAdquisicion;
  DateTimeRange? _rangoEntrega;

  @override
  void initState() {
    super.initState();
    _loadBrands();
    _loadAssets();
    SyncQueueService.instance.onCacheUpdated.addListener(_onCacheUpdated);
  }

  void _onCacheUpdated() {
    if (mounted) _loadAssets(showLoading: false);
  }

  @override
  void dispose() {
    // Remove listeners and clear resources to avoid memory leaks
    SyncQueueService.instance.onCacheUpdated.removeListener(_onCacheUpdated);
    _selectedNombres.clear();
    _selectedCodigos.clear();
    _selectedSeries.clear();
    _selectedModelos.clear();
    _selectedPuertos.clear();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    try {
      final res = await LocalDbService.instance.getCollection('marca');
      if (mounted) {
        setState(() => _marcas = res);
      }
    } catch (_) {}
  }

  Future<void> _loadAssets({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
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
          _tiposActivo = futures[0]
              .where((t) => t['categoria'] == 'COMUNICACION')
              .toList();
          _condiciones = futures[1];
          _sedes = futures[2];
          _areas = futures[3];
          _ciudades = futures[4];
          _custodios = futures[5];
          _proveedores = futures[6];
          _marcas = futures[7];

          _allAssets = localActivos
              .where((a) => a['categoria_activo'] == 'COMUNICACION')
              .toList();
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Error loading Communication assets: $e',
          isError: true,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  bool _assetMatches(Map<String, dynamic> asset, {String? ignoreField}) {
    final info =
        asset['info_equipo_comunicacion'] != null &&
            (asset['info_equipo_comunicacion'] as List).isNotEmpty
        ? (asset['info_equipo_comunicacion'] as List)[0]
        : null;

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
    bool matchesModelo =
        ignoreField == 'modelo' ||
        _selectedModelos.isEmpty ||
        _selectedModelos.contains((info?['modelo'] ?? '').toString());
    bool matchesPuertos =
        ignoreField == 'num_puertos' ||
        _selectedPuertos.isEmpty ||
        _selectedPuertos.contains((info?['num_puertos'] ?? '').toString());

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
        _selectedMarcas.contains(info?['id_marca']);

    bool matchesAdquisicion = true;
    if (ignoreField != 'fecha_adquisicion' &&
        _rangoAdquisicion != null &&
        asset['fecha_adquisicion'] != null) {
      try {
        final dt = DateTime.parse(asset['fecha_adquisicion'].toString());
        if (dt.isBefore(_rangoAdquisicion!.start) ||
            dt.isAfter(_rangoAdquisicion!.end)) {
          matchesAdquisicion = false;
        }
      } catch (_) {}
    }

    bool matchesEntrega = true;
    if (ignoreField != 'fecha_entrega' &&
        _rangoEntrega != null &&
        asset['fecha_entrega'] != null) {
      try {
        final dt = DateTime.parse(asset['fecha_entrega'].toString());
        if (dt.isBefore(_rangoEntrega!.start) ||
            dt.isAfter(_rangoEntrega!.end)) {
          matchesEntrega = false;
        }
      } catch (_) {}
    }

    return matchesNombre &&
        matchesCodigo &&
        matchesSerie &&
        matchesModelo &&
        matchesPuertos &&
        matchesTipo &&
        matchesCondicion &&
        matchesSede &&
        matchesArea &&
        matchesCiudad &&
        matchesCustodio &&
        matchesProveedor &&
        matchesMarca &&
        matchesAdquisicion &&
        matchesEntrega;
  }

  void _applyFilters() {
    if (mounted) {
      setState(() {
        _filteredAssets = _allAssets.where((a) => _assetMatches(a)).toList();
      });
    }
  }

  void _clearFilters() {
    if (mounted) {
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
        _selectedModelos.clear();
        _selectedPuertos.clear();
        _rangoAdquisicion = null;
        _rangoEntrega = null;
      });
      _applyFilters();
    }
  }

  Future<void> _deleteAsset(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Equipo Comunicación'),
        content: const Text('¿Deseas eliminar este equipo permanentemente?'),
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

  Future<void> _showAssetDialog({Map<String, dynamic>? existingAsset}) async {
    final isUpdate = existingAsset != null;
    if (isUpdate) {
      context.showSnackBar(
        'Precaución: Refresque todos los campos en este formulario para el Activo ${existingAsset['nombre']} antes de guardar.',
      );
    }

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
                        isUpdate
                            ? 'Actualizar Equipo'
                            : 'Agregar Especial - Comunicación',
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
                    initialCategory: 'COMUNICACION',
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
                              'p_num_puertos': numPuertos,
                              'p_tipo_extension': tipoExtension,
                              'p_observaciones': observaciones,
                            };

                            if (isUpdate) {
                              params['p_id_activo'] = existingAsset['id'];
                              await LocalDbService.instance.enqueueOperation(
                                'actualizar_activo_equipo_comunicacion',
                                params,
                              );
                              if (!mounted) return;
                              context.showSnackBar(
                                'Activo Comunicación actualizado localmente.',
                              );
                            } else {
                              params['p_id_activo'] = const Uuid().v4();
                              await LocalDbService.instance.enqueueOperation(
                                'crear_activo_equipo_comunicacion',
                                params,
                              );
                              if (!mounted) return;
                              context.showSnackBar(
                                'Activo Comunicación creado localmente.',
                              );
                            }

                            if (SyncQueueService.instance.isOnline) {
                              SyncQueueService.instance.syncPendingOperations();
                            }

                            Navigator.pop(dialogContext);
                            _loadAssets();
                          } catch (error) {
                            if (!mounted) return;
                            context.showSnackBar(
                              'Error en la base de datos: $error',
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
          });
          _applyFilters();
        }
      },
    );
  }

  List<Map<String, dynamic>> _getUniquePredictiveList(
    String key, {
    String? subKey,
  }) {
    if (_allAssets.isEmpty) return [];
    final possibleAssets = _allAssets.where(
      (a) => _assetMatches(a, ignoreField: key),
    );
    final items = possibleAssets
        .map((a) {
          if (subKey != null) {
            final info = _info(a, subKey);
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
        final info = _info(a, 'info_equipo_comunicacion');
        if (info != null && info['id_marca'] != null) {
          validKeys.add(info['id_marca']);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Equipos Comunicación',
          textScaler: TextScaler.linear(1),
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
              tooltip: 'Filtros',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          top: false,
          bottom: true,
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
                      'Filtros Comms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    _buildDrawerFilterButton<String>(
                      'Modelos',
                      _selectedModelos,
                      _getUniquePredictiveList(
                        'modelo',
                        subKey: 'info_equipo_comunicacion',
                      ),
                      'valor',
                    ),
                    _buildDrawerFilterButton<String>(
                      'Num Puertos',
                      _selectedPuertos,
                      _getUniquePredictiveList(
                        'num_puertos',
                        subKey: 'info_equipo_comunicacion',
                      ),
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
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
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
                    onPressed: () => _showAssetDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isTableView
                    ? _buildTableSection()
                    : _buildListSection(),
              ),
            ],
          ),
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
          child: Text('No hay activos para mostrar. Modifique los filtros.'),
        );
      }
    }

    return AssetDataTable(
      assets: _filteredAssets,
      columns: _commsColumns,
      isLoading: _isLoading,
      onEdit: (asset) => _showAssetDialog(existingAsset: asset),
      onDelete: _deleteAsset,
      customActionsBuilder: (asset) => [
        Tooltip(
          message: 'Programar Mantenimiento',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showDialog(
              context: context,
              builder: (_) => MaintenanceFormDialog(initialAssetId: asset['id']),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.build_circle, color: Colors.blueGrey, size: 22),
            ),
          ),
        ),
      ],
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
          child: Text('No hay activos para mostrar. Modifique los filtros.'),
        );
      }
    }

    final totalItems = _filteredAssets.length;
    final totalPages = (totalItems / _listRowsPerPage).ceil();

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
              final info =
                  asset['info_equipo_comunicacion'] != null &&
                      (asset['info_equipo_comunicacion'] as List).isNotEmpty
                  ? (asset['info_equipo_comunicacion'] as List)[0]
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(
                    Icons.router,
                    size: 40,
                    color: Colors.teal,
                  ),
                  title: Text(
                    'S/N: ${asset['numero_serie'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Nombre: ${asset['nombre'] ?? 'S/N'} | Área: ${asset['area_activo']?['area'] ?? 'N/A'}\n'
                    'Puertos: ${info?['num_puertos'] ?? 'N/A'} | Extensión: ${info?['tipo_extension'] ?? 'N/A'}',
                  ),
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
