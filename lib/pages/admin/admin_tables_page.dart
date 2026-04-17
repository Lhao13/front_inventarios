import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';

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
    final excludedCols = ['timestamp_created_at', 'timestamp_updated_at', 'user_on_update', 'user_on_creation'];
    if (_tableData.isNotEmpty) {
      columns = _tableData.first.keys.where((k) => k != 'id' && !excludedCols.contains(k)).toList();
    } else if (existingRow != null) {
      columns = existingRow.keys.where((k) => k != 'id' && !excludedCols.contains(k)).toList();
    }

    final Map<String, String> fieldValues = {
      for (var col in columns) col: existingRow?[col]?.toString() ?? '',
    };

    final isUpdate = existingRow != null;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setDialogState) {
            return AlertDialog(
              title: Text(isUpdate ? 'Actualizar Registro' : 'Nuevo Registro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: columns.map((col) {
                    if (_selectedTable == 'tipo_activo' && col == 'categoria') {
                      final currentVal = fieldValues[col] ?? '';
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
                            if (val != null) fieldValues[col] = val;
                          },
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        initialValue: fieldValues[col],
                        onChanged: (value) => fieldValues[col] = value,
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
                  onPressed: saving ? null : () async {
                    // Cerrar el teclado antes de cerrar para evitar conflictos con la animación de salida
                    FocusManager.instance.primaryFocus?.unfocus();
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          // Cerrar el teclado para evitar ANRs/cuelgues de ImeBackAnimationController en Android
                          FocusManager.instance.primaryFocus?.unfocus();
                          
                          setDialogState(() => saving = true);
                          final Map<String, dynamic> payload = {};
                          for (var col in columns) {
                            final text = fieldValues[col]?.trim() ?? '';
                            // Permitimos strings vacios si es actualizacion para borrar descripciones
                            if (text.isNotEmpty || isUpdate) {
                              payload[col] = text;
                            }
                          }

                          try {
                            if (isUpdate) {
                              await supabase.from(_selectedTable).update(payload).eq('id', existingRow['id']);
                              if (!mounted) return;
                              context.showSnackBar('Registro actualizado');
                            } else {
                              await supabase.from(_selectedTable).insert(payload);
                              if (!mounted) return;
                              context.showSnackBar('Registro insertado');
                            }
                            
                            // Esperar un instante para que el teclado se cierre correctamente antes de hacer pop
                            await Future.delayed(const Duration(milliseconds: 100));
                            if (mounted && Navigator.canPop(dialogContext)) {
                              Navigator.pop(dialogContext);
                            }
                            
                            _loadTableData(_selectedTable);
                          } catch (e) {
                            if (!mounted) return;
                            context.showSnackBar('Error al guardar: $e', isError: true);
                            // Solo actualizar estado si el diálogo sigue abierto
                            if (sbContext.mounted) {
                              setDialogState(() => saving = false);
                            }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: SafeArea(
          top: false,
          bottom: true,
          child: Container(
           color: Colors.blueGrey.shade50,
           child: Column(
             children: [
               Container(
                 padding: const EdgeInsets.only(top: 48, bottom: 16, left: 16, right: 16),
                 child: const Row(
                   children: [
                     Icon(Icons.inventory, color: Colors.blueGrey),
                     SizedBox(width: 10),
                     Text('Tablas Maestras', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                   ],
                 ),
               ),
               Expanded(
                 child: ListView.builder(
                   padding: EdgeInsets.zero,
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
                         Navigator.pop(context); // Cierra el drawer
                         _loadTableData(table);
                       },
                     );
                   },
                 ),
               ),
             ],
           ),
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        tooltip: 'Agregar Nuevo',
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Tabla: ${_selectedTable.toUpperCase()}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refrescar Datos',
                  onPressed: () => _loadTableData(_selectedTable),
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.view_sidebar),
                    tooltip: 'Cambiar Tabla',
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildDataTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (!SyncQueueService.instance.isOnlineNotifier.value) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Requiere conexión a internet para ver las tablas en vivo', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    if (_tableData.isEmpty) return const Center(child: Text('La tabla está vacía o sin datos.'));

    final columns = _tableData.first.keys.toList();

    final excludedCols = ['timestamp_created_at', 'timestamp_updated_at', 'user_on_update', 'user_on_creation'];

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            columns: [
              ...columns.where((col) => !excludedCols.contains(col)).map((col) => DataColumn(label: Text(col.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))),
              const DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _tableData.map((row) {
              return DataRow(
                cells: [
                  ...columns.where((col) => !excludedCols.contains(col)).map((col) => DataCell(Text(row[col]?.toString() ?? ''))),
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
