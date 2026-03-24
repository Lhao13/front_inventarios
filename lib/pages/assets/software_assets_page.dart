import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/assets/dynamic_asset_form.dart';

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

  final TextEditingController _nombreFilterController = TextEditingController();

  int? _selectedTipoActivo;
  int? _selectedCondicion;
  int? _selectedArea;

  List<Map<String, dynamic>> _tiposActivo = [];
  List<Map<String, dynamic>> _condiciones = [];
  List<Map<String, dynamic>> _areas = [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    _nombreFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        supabase.from('tipo_activo').select('id, tipo').order('tipo'),
        supabase.from('condicion_activo').select('id, condicion').order('condicion'),
        supabase.from('area_activo').select('id, area').order('area'),
        supabase.from('activo').select('''
          *,
          info_software(*),
          tipo_activo(tipo),
          condicion_activo(condicion),
          ciudad_activo(ciudad),
          sede_activo(sede),
          area_activo(area),
          proveedor(nombre),
          custodio(nombre_completo)
        ''').eq('categoria_activo', 'SOFTWARE').order('id')
      ]);
      
      if (mounted) {
        setState(() {
          _tiposActivo = List<Map<String, dynamic>>.from(responses[0] as List);
          _condiciones = List<Map<String, dynamic>>.from(responses[1] as List);
          _areas = List<Map<String, dynamic>>.from(responses[2] as List);

          _allAssets = List<Map<String, dynamic>>.from(responses[3] as List);
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
    final nombreText = _nombreFilterController.text.trim().toLowerCase();

    final result = _allAssets.where((asset) {
      final matchesNombre = nombreText.isEmpty || (asset['nombre'] ?? '').toString().toLowerCase().contains(nombreText);
      final matchesTipo = _selectedTipoActivo == null || asset['id_tipo_activo'] == _selectedTipoActivo;
      final matchesCondicion = _selectedCondicion == null || asset['id_condicion_activo'] == _selectedCondicion;
      final matchesArea = _selectedArea == null || asset['id_area_activo'] == _selectedArea;
      
      return matchesNombre && matchesTipo && matchesCondicion && matchesArea;
    }).toList();

    setState(() {
      _filteredAssets = result;
    });
  }

  Future<void> _deleteAsset(int id) async {
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
      await supabase.rpc('eliminar_activo', params: {'p_id_activo': id});
      if (mounted) context.showSnackBar('Software eliminado correctamente.');
      _loadAssets();
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Future<void> _showAssetDialog({Map<String, dynamic>? existingAsset}) async {
    final isUpdate = existingAsset != null;
    
    if (isUpdate) {
       context.showSnackBar('Precaución: Refresque todos los campos en este formulario para el Activo ${existingAsset['nombre']} antes de guardar.');
    }

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
                    Text(isUpdate ? 'Actualizar Software' : 'Agregar Especial - Software', 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogContext))
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DynamicAssetForm(
                    initialCategory: 'SOFTWARE',
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
                          await supabase.rpc('actualizar_activo_software', params: params);
                          if (!mounted) return;
                          context.showSnackBar('Activo actualizado correctamente.');
                        } else {
                          await supabase.rpc('crear_activo_software', params: params);
                          if (!mounted) return;
                          context.showSnackBar('Activo creado correctamente.');
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

  Widget _buildDropdownFilter(String label, int? value, List<Map<String, dynamic>> items, String displayKey, ValueChanged<int?> onChanged) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        isExpanded: true,
        items: items.map((item) {
          return DropdownMenuItem<int>(
            value: item['id'] as int,
            child: Text(item[displayKey]?.toString() ?? '', overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (val) {
          onChanged(val);
          _applyFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licencias de Software'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// Filtros
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
              child: ExpansionTile(
                title: const Text('Filtros de Búsqueda', style: TextStyle(fontWeight: FontWeight.bold)),
                leading: const Icon(Icons.filter_list),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(width: 160, child: TextField(controller: _nombreFilterController, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(), isDense: true), onChanged: (_) => _applyFilters())),
                      
                      _buildDropdownFilter('Tipo Activo', _selectedTipoActivo, _tiposActivo, 'tipo', (v) => _selectedTipoActivo = v),
                      _buildDropdownFilter('Condición', _selectedCondicion, _condiciones, 'condicion', (v) => _selectedCondicion = v),
                      _buildDropdownFilter('Área', _selectedArea, _areas, 'area', (v) => _selectedArea = v),

                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _nombreFilterController.clear();
                            _selectedTipoActivo = null;
                            _selectedCondicion = null;
                            _selectedArea = null;
                          });
                          _applyFilters();
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /// Header y Toggle
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

            /// Data Layout
            Expanded(child: _isTableView ? _buildTableSection() : _buildListSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredAssets.isEmpty) return const Center(child: Text('No hay activos para mostrar.'));

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Tipo Activo')),
              DataColumn(label: Text('Condición')),
              DataColumn(label: Text('Área')),
              DataColumn(label: Text('Proveedor (General)')),
              DataColumn(label: Text('Proveedor Sw.')),
              DataColumn(label: Text('Fecha Inicio')),
              DataColumn(label: Text('Fecha Fin')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: _filteredAssets.map((asset) {
              final info = asset['info_software'] != null && (asset['info_software'] as List).isNotEmpty ? (asset['info_software'] as List)[0] : null;

              return DataRow(
                cells: [
                  DataCell(Text(asset['nombre']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['tipo_activo']?['tipo']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['condicion_activo']?['condicion']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['area_activo']?['area']?.toString() ?? 'N/A')),
                  DataCell(Text(asset['proveedor']?['nombre']?.toString() ?? 'N/A')),
                  DataCell(Text(info?['proveedor']?.toString() ?? 'N/A')),
                  DataCell(Text(info?['fecha_inicio']?.toString() ?? 'N/A')),
                  DataCell(Text(info?['fecha_fin']?.toString() ?? 'N/A')),
                  DataCell(
                    Row(
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
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListSection() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredAssets.isEmpty) return const Center(child: Text('No hay activos para mostrar.'));

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
