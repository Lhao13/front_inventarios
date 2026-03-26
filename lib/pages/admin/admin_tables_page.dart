import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';

class AdminTablesPage extends StatefulWidget {
  const AdminTablesPage({super.key});

  @override
  State<AdminTablesPage> createState() => _AdminTablesPageState();
}

class _AdminTablesPageState extends State<AdminTablesPage> {
  final List<String> _tablas = [
    'proveedor',
    'area_activo',
    'sede_activo',
    'ciudad_activo',
    'tipo_activo',
    'condicion_activo',
    'custodio',
    'marca',
  ];

  String _selectedTable = 'proveedor';
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSidebarVisible = false;

  @override
  void initState() {
    super.initState();
    _loadTableData(_selectedTable);
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await supabase.from(tableName).select().order('id');
      if (!mounted) return;
      setState(() {
        _tableData = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (!mounted) return;
      try {
        final response = await supabase.from(tableName).select();
        if (!mounted) return;
        setState(() {
          _tableData = List<Map<String, dynamic>>.from(response);
        });
      } catch (innerE) {
         setState(() {
          _errorMessage = 'Error loading table $tableName: $innerE';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRow(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
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
      await supabase.from(_selectedTable).delete().eq('id', id);
      if (mounted) context.showSnackBar('Registro eliminado');
      _loadTableData(_selectedTable);
    } catch (e) {
      if (mounted) context.showSnackBar('Error al eliminar: $e', isError: true);
    }
  }

  Future<void> _showFormDialog({Map<String, dynamic>? existingRow}) async {
    // Determine columns dynamically. Default to just 'nombre' if empty.
    List<String> columns = ['nombre', 'descripcion'];
    if (_tableData.isNotEmpty) {
      columns = _tableData.first.keys.where((k) => k != 'id' && k != 'created_at' && k != 'user_on_creation').toList();
    } else if (existingRow != null) {
      columns = existingRow.keys.where((k) => k != 'id' && k != 'created_at' && k != 'user_on_creation').toList();
    }

    final Map<String, TextEditingController> controllers = {};
    for (var col in columns) {
      controllers[col] = TextEditingController(text: existingRow?[col]?.toString() ?? '');
    }

    final isUpdate = existingRow != null;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isUpdate ? 'Actualizar Registro' : 'Nuevo Registro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: columns.map((col) {
                    if (_selectedTable == 'tipo_activo' && col == 'categoria') {
                      final currentVal = controllers[col]!.text;
                      final validOptions = ['PC', 'COMUNICACION', 'SOFTWARE', 'GENERICO'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DropdownButtonFormField<String>(
                          value: validOptions.contains(currentVal) ? currentVal : (validOptions.isNotEmpty ? validOptions.first : null),
                          decoration: InputDecoration(
                            labelText: col.toUpperCase(),
                            border: const OutlineInputBorder(),
                          ),
                          items: validOptions.map((opt) {
                            return DropdownMenuItem(value: opt, child: Text(opt));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controllers[col]!.text = val;
                          },
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextField(
                        controller: controllers[col],
                        decoration: InputDecoration(
                          labelText: col.toUpperCase(),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }).toList(),
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
                          setDialogState(() => saving = true);
                          final Map<String, dynamic> payload = {};
                          for (var col in columns) {
                            final text = controllers[col]!.text.trim();
                            if (text.isNotEmpty) {
                              payload[col] = text;
                            }
                          }

                          try {
                            if (isUpdate) {
                              await supabase.from(_selectedTable).update(payload).eq('id', existingRow!['id']);
                              if (!mounted) return;
                              context.showSnackBar('Registro actualizado');
                            } else {
                              await supabase.from(_selectedTable).insert(payload);
                              if (!mounted) return;
                              context.showSnackBar('Registro insertado');
                            }
                            Navigator.pop(dialogContext);
                            _loadTableData(_selectedTable);
                          } catch (e) {
                            if (!mounted) return;
                            context.showSnackBar('Error al guardar: $e', isError: true);
                            setDialogState(() => saving = false);
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

    for (var controller in controllers.values) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Maestras'),
        actions: [
          IconButton(
            icon: Icon(_isSidebarVisible ? Icons.fullscreen : Icons.view_sidebar),
            tooltip: 'Alternar menú lateral',
            onPressed: () {
              setState(() {
                _isSidebarVisible = !_isSidebarVisible;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        tooltip: 'Agregar Nuevo',
        child: const Icon(Icons.add),
      ),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tabla: ${_selectedTable.toUpperCase()}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _loadTableData(_selectedTable),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildDataTable(),
                  ),
                ],
              ),
            ),
          ),
          if (_isSidebarVisible) const VerticalDivider(width: 1),
          if (_isSidebarVisible)
            Container(
              width: 250,
              color: Colors.blueGrey.shade50,
              child: ListView.builder(
                itemCount: _tablas.length,
                itemBuilder: (context, index) {
                  final table = _tablas[index];
                  return ListTile(
                    leading: const Icon(Icons.table_rows, color: Colors.blueGrey),
                    title: Text(table, style: const TextStyle(fontWeight: FontWeight.w600)),
                    selected: _selectedTable == table,
                    selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                    onTap: () {
                      setState(() {
                        _selectedTable = table;
                      });
                      _loadTableData(table);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    if (_tableData.isEmpty) return const Center(child: Text('La tabla está vacía o sin datos.'));

    final columns = _tableData.first.keys.toList();

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            columns: [
              ...columns.where((col) => col != 'created_at' && col != 'user_on_creation').map((col) => DataColumn(label: Text(col.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))),
              const DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _tableData.map((row) {
              return DataRow(
                cells: [
                  ...columns.where((col) => col != 'created_at' && col != 'user_on_creation').map((col) => DataCell(Text(row[col]?.toString() ?? ''))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showFormDialog(existingRow: row),
                        ),
                        if (row['id'] != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRow(int.parse(row['id'].toString())),
                          ),
                      ],
                    ),
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
