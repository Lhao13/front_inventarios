import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';

/// Página de Gestión de Activos.
///
/// Esta vista tiene dos bloques principales:
/// 1) Menú móvil superior con la opción "Agregar un activo".
/// 2) Tabla de activos con filtros por campos.
class AssetManagementPage extends StatefulWidget {
  const AssetManagementPage({super.key});

  @override
  State<AssetManagementPage> createState() => _AssetManagementPageState();
}

class _AssetManagementPageState extends State<AssetManagementPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<_AssetRow> _allAssets = [];
  List<_AssetRow> _filteredAssets = [];

  final TextEditingController _idFilterController = TextEditingController();
  final TextEditingController _serieFilterController = TextEditingController();
  final TextEditingController _nombreFilterController =
      TextEditingController();
  final TextEditingController _codigoFilterController =
      TextEditingController();
  final TextEditingController _ipFilterController = TextEditingController();

  String _selectedCategoryFilter = 'TODAS';

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    _idFilterController.dispose();
    _serieFilterController.dispose();
    _nombreFilterController.dispose();
    _codigoFilterController.dispose();
    _ipFilterController.dispose();
    super.dispose();
  }

  /// Carga activos desde Supabase.
  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await supabase
          .from('activo')
          .select(
            'id, numero_serie, nombre, codigo, ip, categoria_activo, fecha_adquisicion, fecha_entrega',
          )
          .order('id');

      final parsed = (response as List)
          .map((row) => _AssetRow.fromMap(row as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _allAssets = parsed;
        _filteredAssets = parsed;
      });
      _applyFilters();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar los activos: $error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Aplica filtros sobre la lista en memoria.
  void _applyFilters() {
    final idText = _idFilterController.text.trim().toLowerCase();
    final serieText = _serieFilterController.text.trim().toLowerCase();
    final nombreText = _nombreFilterController.text.trim().toLowerCase();
    final codigoText = _codigoFilterController.text.trim().toLowerCase();
    final ipText = _ipFilterController.text.trim().toLowerCase();

    final result = _allAssets.where((asset) {
      final matchesId = idText.isEmpty || asset.id.toString().contains(idText);
      final matchesSerie =
          serieText.isEmpty || asset.numeroSerie.toLowerCase().contains(serieText);
      final matchesNombre =
          nombreText.isEmpty || asset.nombre.toLowerCase().contains(nombreText);
      final matchesCodigo =
          codigoText.isEmpty || asset.codigo.toLowerCase().contains(codigoText);
      final matchesIp = ipText.isEmpty || asset.ip.toLowerCase().contains(ipText);
      final matchesCategory = _selectedCategoryFilter == 'TODAS' ||
          asset.categoria == _selectedCategoryFilter;

      return matchesId &&
          matchesSerie &&
          matchesNombre &&
          matchesCodigo &&
          matchesIp &&
          matchesCategory;
    }).toList();

    setState(() {
      _filteredAssets = result;
    });
  }

  Future<void> _createAssetWithDetail({
    required String numeroSerie,
    required String categoria,
    required int tipoActivoId,
    required int condicionActivoId,
    required int custodioId,
    required int ciudadActivoId,
    required int sedeActivoId,
    required int areaActivoId,
    required int proveedorId,
    required String fechaAdquisicion,
    required String fechaEntrega,
    required String coordenada,
    String? nombre,
    int? codigo,
    String? ip,
    int? marcaId,
    String? modelo,
    String? observaciones,
    // PC Specific
    String? procesador,
    String? ram,
    String? almacenamiento,
    String? cargadorCodigo,
    int? numPuertos,
    // Communication Specific
    String? tipoExtension,
    // Generic Specific
    int? numConexiones,
    String? varImpresoraColor,
    String? varMonitorTipoConexion,
    // Software Specific
    String? proveedorSoftware,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    Map<String, dynamic> baseParams = {
      'p_id_tipo_activo': tipoActivoId,
      'p_id_condicion_activo': condicionActivoId,
      'p_id_custodio': custodioId,
      'p_id_area_activo': areaActivoId,
      'p_id_provedor': proveedorId,
      'p_nombre': nombre,
      'p_codigo': codigo,
      'p_observaciones': observaciones,
    };

    String rpcName;

    switch (categoria) {
      case 'PC':
        rpcName = 'crear_activo_pc';
        baseParams.addAll({
          'p_numero_serie': numeroSerie,
          'p_id_ciudad_activo': ciudadActivoId,
          'p_id_sede_activo': sedeActivoId,
          'p_fecha_adquisicion': fechaAdquisicion,
          'p_fecha_entrega': fechaEntrega,
          'p_coordenada': coordenada,
          'p_ip': ip,
          'p_id_marca': marcaId,
          'p_modelo': modelo,
          'p_procesador': procesador,
          'p_ram': ram,
          'p_almacenamiento': almacenamiento,
          'p_cargador_codigo': cargadorCodigo,
          'p_num_puertos': numPuertos,
        });
        break;
      case 'COMUNICACION':
        rpcName = 'crear_activo_equipo_comunicacion';
        baseParams.addAll({
          'p_numero_serie': numeroSerie,
          'p_id_ciudad_activo': ciudadActivoId,
          'p_id_sede_activo': sedeActivoId,
          'p_fecha_adquisicion': fechaAdquisicion,
          'p_fecha_entrega': fechaEntrega,
          'p_coordenada': coordenada,
          'p_ip': ip,
          'p_id_marca': marcaId,
          'p_modelo': modelo,
          'p_num_puertos': numPuertos,
          'p_tipo_extension': tipoExtension,
        });
        break;
      case 'GENERICO':
        rpcName = 'crear_activo_equipo_generico';
        baseParams.addAll({
          'p_numero_serie': numeroSerie,
          'p_id_ciudad_activo': ciudadActivoId,
          'p_id_sede_activo': sedeActivoId,
          'p_fecha_adquisicion': fechaAdquisicion,
          'p_fecha_entrega': fechaEntrega,
          'p_coordenada': coordenada,
          'p_id_marca': marcaId,
          'p_modelo': modelo,
          'p_cargador_codigo': cargadorCodigo,
          'p_num_conexiones': numConexiones,
          'p_var_impresora_color': varImpresoraColor,
          'p_var_monitor_tipo_conexion': varMonitorTipoConexion,
        });
        break;
      case 'SOFTWARE':
        rpcName = 'crear_activo_software';
        baseParams.addAll({
          'p_proveedor': proveedorSoftware,
          'p_fecha_inicio': fechaInicio,
          'p_fecha_fin': fechaFin,
        });
        break;
      default:
        throw Exception('Categoría no reconocida');
    }

    // Limpiar nulos para evitar problemas en RPC si los parámetros no se definen
    baseParams.removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));

    await supabase.rpc(rpcName, params: baseParams);
  }

  /// Función para eliminar un activo.
  Future<void> _deleteAsset(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar activo'),
        content: const Text('¿Estás seguro de que deseas eliminar este activo de manera permanente?'),
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
      await supabase.rpc('eliminar_activo', params: {'p_id_activo': id});
      if (mounted) context.showSnackBar('Activo eliminado correctamente.');
      _loadAssets();
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar el activo: $e', isError: true);
    }
  }

  /// Muestra formulario para agregar activo.
  Future<void> _showAddAssetDialog() async {
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
                    const Text('Agregar un activo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DynamicAssetForm(
                    onSave: ({
                      required String numeroSerie,
                      required String categoria,
                      required int tipoActivoId,
                      required int condicionActivoId,
                      required int custodioId,
                      required int ciudadActivoId,
                      required int sedeActivoId,
                      required int areaActivoId,
                      required int proveedorId,
                      required String fechaAdquisicion,
                      required String fechaEntrega,
                      required String coordenada,
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
                        await _createAssetWithDetail(
                          numeroSerie: numeroSerie,
                          categoria: categoria,
                          tipoActivoId: tipoActivoId,
                          condicionActivoId: condicionActivoId,
                          custodioId: custodioId,
                          ciudadActivoId: ciudadActivoId,
                          sedeActivoId: sedeActivoId,
                          areaActivoId: areaActivoId,
                          proveedorId: proveedorId,
                          fechaAdquisicion: fechaAdquisicion,
                          fechaEntrega: fechaEntrega,
                          coordenada: coordenada,
                          nombre: nombre,
                          codigo: codigo,
                          ip: ip,
                          marcaId: marcaId,
                          modelo: modelo,
                          observaciones: observaciones,
                          procesador: procesador,
                          ram: ram,
                          almacenamiento: almacenamiento,
                          cargadorCodigo: cargadorCodigo,
                          numPuertos: numPuertos,
                          tipoExtension: tipoExtension,
                          numConexiones: numConexiones,
                          varImpresoraColor: varImpresoraColor,
                          varMonitorTipoConexion: varMonitorTipoConexion,
                          proveedorSoftware: proveedorSoftware,
                          fechaInicio: fechaInicio,
                          fechaFin: fechaFin,
                        );

                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        context.showSnackBar('Activo creado correctamente.');
                        _loadAssets();
                      } catch (error) {
                        if (!mounted) return;
                        context.showSnackBar('Error al crear el activo: $error', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Menú superior móvil con acción de alta.
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gestión de Activos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones de activos',
                onSelected: (value) {
                  if (value == 'add_asset') {
                    _showAddAssetDialog();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'add_asset',
                    child: Row(
                      children: [
                        Icon(Icons.add_box_outlined),
                        SizedBox(width: 8),
                        Text('Agregar un activo'),
                      ],
                    ),
                  ),
                ],
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.menu),
                  label: const Text('Menú móvil'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// Barra de filtros por campos.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _idFilterController,
                      decoration: const InputDecoration(
                        labelText: 'ID',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: TextField(
                      controller: _serieFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Número de serie',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: TextField(
                      controller: _nombreFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _codigoFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Código',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _ipFilterController,
                      decoration: const InputDecoration(
                        labelText: 'IP',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategoryFilter,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'TODAS', child: Text('TODAS')),
                        DropdownMenuItem(value: 'PC', child: Text('PC')),
                        DropdownMenuItem(
                          value: 'SOFTWARE',
                          child: Text('SOFTWARE'),
                        ),
                        DropdownMenuItem(
                          value: 'COMUNICACION',
                          child: Text('COMUNICACIÓN'),
                        ),
                        DropdownMenuItem(
                          value: 'GENERICO',
                          child: Text('GENÉRICO'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedCategoryFilter = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _idFilterController.clear();
                      _serieFilterController.clear();
                      _nombreFilterController.clear();
                      _codigoFilterController.clear();
                      _ipFilterController.clear();
                      setState(() {
                        _selectedCategoryFilter = 'TODAS';
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpiar filtros'),
                  ),
                  IconButton(
                    tooltip: 'Recargar',
                    onPressed: _loadAssets,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          /// Tabla de activos.
          Expanded(
            child: _buildTableSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadAssets,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_filteredAssets.isEmpty) {
      return const Center(
        child: Text('No hay activos para mostrar con los filtros actuales.'),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Número de serie')),
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Categoría')),
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('IP')),
              DataColumn(label: Text('Fecha adquisición')),
              DataColumn(label: Text('Fecha entrega')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: _filteredAssets.map((asset) {
              return DataRow(
                cells: [
                  DataCell(Text(asset.id.toString())),
                  DataCell(Text(asset.numeroSerie)),
                  DataCell(Text(asset.nombre)),
                  DataCell(Text(asset.categoria)),
                  DataCell(Text(asset.codigo)),
                  DataCell(Text(asset.ip)),
                  DataCell(Text(asset.fechaAdquisicion)),
                  DataCell(Text(asset.fechaEntrega)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (RoleService.currentRole != UserRole.ayudante)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAsset(asset.id),
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
}

/// Modelo de fila para tabla de activos.
class _AssetRow {
  final int id;
  final String numeroSerie;
  final String nombre;
  final String categoria;
  final String codigo;
  final String ip;
  final String fechaAdquisicion;
  final String fechaEntrega;

  const _AssetRow({
    required this.id,
    required this.numeroSerie,
    required this.nombre,
    required this.categoria,
    required this.codigo,
    required this.ip,
    required this.fechaAdquisicion,
    required this.fechaEntrega,
  });

  factory _AssetRow.fromMap(Map<String, dynamic> map) {
    return _AssetRow(
      id: (map['id'] as num?)?.toInt() ?? 0,
      numeroSerie: (map['numero_serie'] ?? '').toString(),
      nombre: (map['nombre'] ?? '').toString(),
      categoria: (map['categoria_activo'] ?? '').toString(),
      codigo: (map['codigo'] ?? '').toString(),
      ip: (map['ip'] ?? '').toString(),
      fechaAdquisicion: (map['fecha_adquisicion'] ?? '').toString(),
      fechaEntrega: (map['fecha_entrega'] ?? '').toString(),
    );
  }
}
