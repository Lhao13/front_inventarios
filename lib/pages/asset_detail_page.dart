import 'package:flutter/material.dart';
import 'package:front_inventarios/utils/asset_utils.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:front_inventarios/widgets/maintenance_form_dialog.dart';

class AssetDetailPage extends StatefulWidget {
  final Map<String, dynamic> asset;

  const AssetDetailPage({super.key, required this.asset});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  late Map<String, dynamic> _currentAsset;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteAsset(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Activo'),
        content: const Text('¿Deseas eliminar este activo permanentemente?'),
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
      if (!mounted) return;
      context.showSnackBar('Activo eliminado localmente.');
      Navigator.pop(context, true); // Retorna true para indicar que se eliminó
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Future<void> _showUpdateDialog() async {
    final String category = (_currentAsset['categoria_activo'] ?? 'PC')
        .toString();

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
                        'Actualizar Activo',
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
                    initialData: _currentAsset,
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
                                'p_id_activo': _currentAsset['id'],
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
                                'p_procesador': procesador,
                                'p_ram': ram,
                                'p_almacenamiento': almacenamiento,
                                'p_id_marca': marcaId,
                                'p_modelo': modelo,
                                'p_cargador_codigo': cargadorCodigo,
                                'p_num_puertos': numPuertos,
                                'p_observaciones': observaciones,
                              };
                            } else if (category == 'SOFTWARE') {
                              rpcName = 'actualizar_activo_software';
                              params = {
                                'p_id_activo': _currentAsset['id'],
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
                                'p_id_activo': _currentAsset['id'],
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
                                'p_id_activo': _currentAsset['id'],
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
                                'p_observaciones': observaciones,
                                'p_cargador_codigo': cargadorCodigo,
                                'p_num_conexiones': numConexiones,
                                'p_var_impresora_color': varImpresoraColor,
                                'p_var_monitor_tipo_conexion':
                                    varMonitorTipoConexion,
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
                                'Activo actualizado localmente.',
                              );

                              // Recargar la data local para mostrar en esta pantalla de detalle
                              final updatedAssets = await LocalDbService
                                  .instance
                                  .getCollection('activo');
                              final updatedMatch = updatedAssets.firstWhere(
                                (a) => a['id'] == _currentAsset['id'],
                              );

                              if (mounted) {
                                setState(() {
                                  _currentAsset = updatedMatch;
                                });
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              }
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

  Map<String, dynamic>? _getSpecificInfo(
    Map<String, dynamic> asset,
    String category,
  ) {
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
    if (list is List && list.isNotEmpty) {
      return list[0] as Map<String, dynamic>?;
    }
    return null;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _currentAsset;
    final cat = a['categoria_activo']?.toString() ?? 'Desconocida';
    final info = _getSpecificInfo(a, cat);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Activo'), elevation: 0),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Encabezado Visual
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AssetUtils.getIconForCategory(cat),
                  size: 64,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nombre: ${a['nombre']?.toString() ?? 'Sin Nombre'}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Card Datos Generales
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Datos Generales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Número de Serie:',
                        a['numero_serie']?.toString() ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Código:',
                        a['codigo']?.toString() ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Tipo Activo:',
                        a['tipo_activo'] is Map
                            ? a['tipo_activo']['tipo']?.toString() ?? 'N/A'
                            : a['tipo_activo']?.toString() ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Condición:',
                        a['condicion_activo'] is Map
                            ? a['condicion_activo']['condicion']?.toString() ??
                                  'N/A'
                            : a['condicion_activo']?.toString() ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Custodio:',
                        a['custodio'] is Map
                            ? a['custodio']['nombre_completo']?.toString() ??
                                  'N/A'
                            : a['custodio']?.toString() ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Sede:',
                        a['sede_activo'] is Map
                            ? a['sede_activo']['sede']?.toString() ?? 'N/A'
                            : a['sede_activo']?.toString() ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Área:',
                        a['area_activo'] is Map
                            ? a['area_activo']['area']?.toString() ?? 'N/A'
                            : a['area_activo']?.toString() ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Fecha Adquisición:',
                        a['fecha_adquisicion']?.toString() ?? 'N/A',
                      ),
                      _buildDetailRow('IP:', a['ip']?.toString() ?? 'N/A'),
                      _buildDetailRow(
                        'Fecha Entrega:',
                        a['fecha_entrega']?.toString() ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card Datos Específicos
              if (info != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Datos Específicos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (info['marca'] != null)
                          _buildDetailRow(
                            'Marca:',
                            info['marca'] is Map
                                ? (info['marca']['marca_proveedor']?.toString() ??
                                      'N/A')
                                : (info['marca_proveedor']?.toString() ?? 'N/A'),
                          ),
                        if (info['modelo'] != null)
                          _buildDetailRow(
                            'Modelo:',
                            info['modelo']?.toString() ?? 'N/A',
                          ),
                        if (info['procesador'] != null)
                          _buildDetailRow(
                            'Procesador:',
                            info['procesador']?.toString() ?? 'N/A',
                          ),
                        if (info['ram'] != null)
                          _buildDetailRow(
                            'RAM:',
                            info['ram']?.toString() ?? 'N/A',
                          ),
                        if (info['almacenamiento'] != null)
                          _buildDetailRow(
                            'Almacenamiento:',
                            info['almacenamiento']?.toString() ?? 'N/A',
                          ),
                        if (info['cargador_codigo'] != null)
                          _buildDetailRow(
                            'Cód. Cargador:',
                            info['cargador_codigo']?.toString() ?? 'N/A',
                          ),
                        if (info['num_puertos'] != null)
                          _buildDetailRow(
                            'Num. Puertos:',
                            info['num_puertos']?.toString() ?? 'N/A',
                          ),
                        if (info['tipo_extension'] != null)
                          _buildDetailRow(
                            'Tipo Extensión:',
                            info['tipo_extension']?.toString() ?? 'N/A',
                          ),
                        if (info['num_conexiones'] != null)
                          _buildDetailRow(
                            'Num. Conexiones:',
                            info['num_conexiones']?.toString() ?? 'N/A',
                          ),
                        if (info['var_impresora_color'] != null)
                          _buildDetailRow(
                            'Impresora Color:',
                            info['var_impresora_color']?.toString() ?? 'N/A',
                          ),
                        if (info['var_monitor_tipo_conexion'] != null)
                          _buildDetailRow(
                            'Conexión Monitor:',
                            info['var_monitor_tipo_conexion']?.toString() ??
                                'N/A',
                          ),
                        if (info['proveedor'] != null)
                          _buildDetailRow(
                            'Prov. Software:',
                            info['proveedor']?.toString() ?? 'N/A',
                          ),
                        if (info['fecha_inicio'] != null)
                          _buildDetailRow(
                            'Inicio Licencia:',
                            info['fecha_inicio']?.toString() ?? 'N/A',
                          ),
                        if (info['fecha_fin'] != null)
                          _buildDetailRow(
                            'Fin Licencia:',
                            info['fecha_fin']?.toString() ?? 'N/A',
                          ),
                        _buildDetailRow(
                          'Observaciones:',
                          info['observaciones']?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Acciones
              if (RoleService.currentRole != UserRole.ayudante)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showUpdateDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text(
                          'ACTUALIZAR DATOS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (cat.toUpperCase() != 'SOFTWARE')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    MaintenanceFormDialog(initialAssetId: a['id']),
                              );
                            },
                            icon: const Icon(Icons.build_circle),
                            label: const Text(
                              'PROGRAMAR MANTENIMIENTO',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteAsset(a['id']),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text(
                          'ELIMINAR ACTIVO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
