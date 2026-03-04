import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';

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

  /// Inserta un activo y su registro en una sola tabla hija (según categoría).
  ///
  /// Esto respeta la regla de negocio que tienes en triggers:
  /// - Debe existir en solo una tabla hija.
  /// - La tabla hija debe coincidir con la categoría del activo.
  Future<void> _createAssetWithDetail({
    required int assetId,
    required String numeroSerie,
    required int tipoActivoId,
    required String categoria,
    required int detailId,
    String? nombre,
    int? codigo,
    String? ip,
  }) async {
    await supabase.from('activo').insert({
      'id': assetId,
      'numero_serie': numeroSerie,
      'id_tipo_activo': tipoActivoId,
      'categoria_activo': categoria,
      'nombre': (nombre == null || nombre.trim().isEmpty) ? null : nombre.trim(),
      'codigo': codigo,
      'ip': (ip == null || ip.trim().isEmpty) ? null : ip.trim(),
    });

    String childTable;
    switch (categoria) {
      case 'PC':
        childTable = 'info_pc';
        break;
      case 'SOFTWARE':
        childTable = 'info_software';
        break;
      case 'COMUNICACION':
        childTable = 'info_equipo_comunicacion';
        break;
      default:
        childTable = 'info_equipo_generico';
    }

    try {
      await supabase.from(childTable).insert({
        'id': detailId,
        'id_activo': assetId,
      });
    } catch (error) {
      await supabase.from('activo').delete().eq('id', assetId);
      rethrow;
    }
  }

  /// Muestra formulario para agregar activo.
  Future<void> _showAddAssetDialog() async {
    final formKey = GlobalKey<FormState>();

    final idController = TextEditingController();
    final detailIdController = TextEditingController();
    final serieController = TextEditingController();
    final tipoActivoController = TextEditingController();
    final nombreController = TextEditingController();
    final codigoController = TextEditingController();
    final ipController = TextEditingController();

    String categoria = 'PC';
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar un activo'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: idController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'ID de activo *'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            if (int.tryParse(value.trim()) == null) {
                              return 'Debe ser numérico';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: detailIdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ID registro detalle *',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            if (int.tryParse(value.trim()) == null) {
                              return 'Debe ser numérico';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: serieController,
                          decoration: const InputDecoration(
                            labelText: 'Número de serie *',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: tipoActivoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ID tipo activo *',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            if (int.tryParse(value.trim()) == null) {
                              return 'Debe ser numérico';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: categoria,
                          items: const [
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
                            setDialogState(() {
                              categoria = value;
                            });
                          },
                          decoration:
                              const InputDecoration(labelText: 'Categoría *'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: nombreController,
                          decoration:
                              const InputDecoration(labelText: 'Nombre (opcional)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: codigoController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Código (opcional)'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            if (int.tryParse(value.trim()) == null) {
                              return 'Debe ser numérico';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: ipController,
                          decoration:
                              const InputDecoration(labelText: 'IP (opcional)'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await _createAssetWithDetail(
                              assetId: int.parse(idController.text.trim()),
                              detailId: int.parse(detailIdController.text.trim()),
                              numeroSerie: serieController.text.trim(),
                              tipoActivoId:
                                  int.parse(tipoActivoController.text.trim()),
                              categoria: categoria,
                              nombre: nombreController.text,
                              codigo: codigoController.text.trim().isEmpty
                                  ? null
                                  : int.parse(codigoController.text.trim()),
                              ip: ipController.text,
                            );

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            context.showSnackBar('Activo creado correctamente.');
                            await _loadAssets();
                          } catch (error) {
                            if (!mounted) return;
                            context.showSnackBar(
                              'No fue posible crear el activo: $error',
                              isError: true,
                            );
                            setDialogState(() {
                              saving = false;
                            });
                          }
                        },
                  child: Text(saving ? 'Guardando...' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    idController.dispose();
    detailIdController.dispose();
    serieController.dispose();
    tipoActivoController.dispose();
    nombreController.dispose();
    codigoController.dispose();
    ipController.dispose();
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
