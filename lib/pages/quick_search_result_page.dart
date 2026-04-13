import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';

class QuickSearchResultPage extends StatefulWidget {
  final String searchValue;
  final bool isNumericCode;

  const QuickSearchResultPage({
    super.key,
    required this.searchValue,
    required this.isNumericCode,
  });

  @override
  State<QuickSearchResultPage> createState() => _QuickSearchResultPageState();
}

class _QuickSearchResultPageState extends State<QuickSearchResultPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _assetData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAsset();
  }

  Future<void> _fetchAsset() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = supabase.from('activo').select('''
        *,
        info_pc(*, marca(marca_proveedor)),
        info_equipo_comunicacion(*, marca(marca_proveedor)),
        info_equipo_generico(*, marca(marca_proveedor)),
        info_software(*),
        tipo_activo(tipo),
        condicion_activo(condicion),
        ciudad_activo(ciudad),
        sede_activo(sede),
        area_activo(area),
        proveedor(nombre),
        custodio(nombre_completo)
      ''');

      final List<dynamic> response;
      if (widget.isNumericCode) {
        response = await query.eq('codigo', int.parse(widget.searchValue));
      } else {
        response = await query.eq('numero_serie', widget.searchValue);
      }

      if (response.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontró ningún activo con este valor: ${widget.searchValue}';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _assetData = response.first as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar el activo: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAsset(String id) async {
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
      if (!mounted) return;
      context.showSnackBar('Activo eliminado correctamente.');
      Navigator.pop(context); // Volver atrás después de eliminar
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Future<void> _showUpdateDialog() async {
    if (_assetData == null) return;
    final cat = _assetData!['categoria_activo'] as String;

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
                    Expanded(child: Text('Actualizar $cat', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogContext))
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DynamicAssetForm(
                    initialCategory: cat,
                    initialData: _assetData,
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
                          'p_id_activo': _assetData!['id'],
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
                          'p_observaciones': observaciones,
                        };

                        if (categoria == 'PC') {
                          params.addAll({
                            'p_procesador': procesador,
                            'p_ram': ram,
                            'p_almacenamiento': almacenamiento,
                            'p_cargador_codigo': cargadorCodigo,
                            'p_num_puertos': numPuertos,
                          });
                          await supabase.rpc('actualizar_activo_pc', params: params);
                        } else if (categoria == 'COMUNICACION') {
                          params.addAll({
                            'p_num_puertos': numPuertos,
                            'p_tipo_extension': tipoExtension,
                          });
                          await supabase.rpc('actualizar_equipo_comunicacion', params: params);
                        } else if (categoria == 'GENERICO') {
                          params.addAll({
                            'p_cargador_codigo': cargadorCodigo,
                            'p_num_conexiones': numConexiones,
                            'p_var_impresora_color': varImpresoraColor,
                            'p_var_monitor_tipo_conexion': varMonitorTipoConexion,
                          });
                          await supabase.rpc('actualizar_equipo_generico', params: params);
                        } else if (categoria == 'SOFTWARE') {
                          params.addAll({
                            'p_proveedor': proveedorSoftware,
                            'p_fecha_inicio': fechaInicio,
                            'p_fecha_fin': fechaFin,
                          });
                          await supabase.rpc('actualizar_activo_software', params: params);
                        }

                        if (!mounted) return;
                        context.showSnackBar('Activo actualizado correctamente.');
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _fetchAsset(); // Recargar datos
                      } catch (error) {
                        if (!mounted) return;
                        context.showSnackBar('Error al actualizar: $error', isError: true);
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

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'PC': return Icons.computer;
      case 'SOFTWARE': return Icons.developer_board;
      case 'COMUNICACION': return Icons.router;
      case 'GENERICO': return Icons.devices_other;
      default: return Icons.inventory;
    }
  }

  Map<String, dynamic>? _getSpecificInfo(Map<String, dynamic> asset, String category) {
    String key;
    if (category == 'PC') {
      key = 'info_pc';
    } else if (category == 'SOFTWARE') {
      key = 'info_software';
    } else if (category == 'COMUNICACION') {
      key = 'info_equipo_comunicacion';
    } else if (category == 'GENERICO') {
      key = 'info_equipo_generico';
    } else {
      return null;
    }

    final list = asset[key];
    if (list is List && list.isNotEmpty) return list[0] as Map<String, dynamic>?;
    return null;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de Búsqueda'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Volver'),
                        )
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = _assetData!;
    final cat = a['categoria_activo']?.toString() ?? 'Desconocida';
    final info = _getSpecificInfo(a, cat);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(_getCategoryIcon(cat), size: 64, color: Colors.blue.shade800),
          ),
          const SizedBox(height: 16),
          Text(a['nombre']?.toString() ?? 'Sin Nombre', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.blue.shade800, borderRadius: BorderRadius.circular(20)),
            child: Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datos Generales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const Divider(),
                  _buildDetailRow('Número de Serie:', a['numero_serie']?.toString() ?? 'N/A'),
                  _buildDetailRow('Código:', a['codigo']?.toString() ?? 'N/A'),
                  _buildDetailRow('Tipo Activo:', a['tipo_activo']?['tipo']?.toString() ?? 'N/A'),
                  _buildDetailRow('Condición:', a['condicion_activo']?['condicion']?.toString() ?? 'N/A'),
                  _buildDetailRow('Custodio:', a['custodio']?['nombre_completo']?.toString() ?? 'N/A'),
                  _buildDetailRow('Sede:', a['sede_activo']?['sede']?.toString() ?? 'N/A'),
                  _buildDetailRow('Área:', a['area_activo']?['area']?.toString() ?? 'N/A'),
                  _buildDetailRow('Fecha Adquisición:', a['fecha_adquisicion']?.toString() ?? 'N/A'),
                  _buildDetailRow('IP:', a['ip']?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (info != null)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos Específicos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const Divider(),
                    if (info['marca'] != null) _buildDetailRow('Marca:', info['marca']['marca_proveedor']?.toString() ?? 'N/A'),
                    if (info['modelo'] != null) _buildDetailRow('Modelo:', info['modelo']?.toString() ?? 'N/A'),
                    if (info['procesador'] != null) _buildDetailRow('Procesador:', info['procesador']?.toString() ?? 'N/A'),
                    if (info['ram'] != null) _buildDetailRow('RAM:', info['ram']?.toString() ?? 'N/A'),
                    if (info['almacenamiento'] != null) _buildDetailRow('Almacenamiento:', info['almacenamiento']?.toString() ?? 'N/A'),
                    if (info['cargador_codigo'] != null) _buildDetailRow('Código Cargador:', info['cargador_codigo']?.toString() ?? 'N/A'),
                    if (info['num_puertos'] != null) _buildDetailRow('Num. Puertos:', info['num_puertos']?.toString() ?? 'N/A'),
                    if (info['tipo_extension'] != null) _buildDetailRow('Tipo Extensión:', info['tipo_extension']?.toString() ?? 'N/A'),
                    if (info['num_conexiones'] != null) _buildDetailRow('Num. Conexiones:', info['num_conexiones']?.toString() ?? 'N/A'),
                    if (info['var_impresora_color'] != null) _buildDetailRow('Impresora Color:', info['var_impresora_color']?.toString() ?? 'N/A'),
                    if (info['var_monitor_tipo_conexion'] != null) _buildDetailRow('Tipo Conexión (Monitor):', info['var_monitor_tipo_conexion']?.toString() ?? 'N/A'),
                    if (info['proveedor'] != null) _buildDetailRow('Proveedor (Software):', info['proveedor']?.toString() ?? 'N/A'),
                    if (info['fecha_inicio'] != null) _buildDetailRow('Fecha Inicio (Licencia):', info['fecha_inicio']?.toString() ?? 'N/A'),
                    if (info['fecha_fin'] != null) _buildDetailRow('Fecha Fin (Licencia):', info['fecha_fin']?.toString() ?? 'N/A'),
                    if (info['observaciones'] != null) _buildDetailRow('Observaciones Extras:', info['observaciones']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 32),
          if (RoleService.currentRole != UserRole.ayudante)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showUpdateDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Actualizar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteAsset(a['id']),
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
