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
    'usuario_rol',
    'rol',
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
      // Try ordering without id if id column doesn't exist
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablas Maestras'),
      ),
      body: Row(
        children: [
          // Sidebar para seleccionar tabla
          Container(
            width: 200,
            color: Colors.white,
            child: ListView.builder(
              itemCount: _tablas.length,
              itemBuilder: (context, index) {
                final table = _tablas[index];
                return ListTile(
                  title: Text(table),
                  selected: _selectedTable == table,
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
          const VerticalDivider(width: 1),
          // Área de visualización de datos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tabla: $_selectedTable',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildDataTable(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_tableData.isEmpty) {
      return const Center(child: Text('La tabla está vacía.'));
    }

    final columns = _tableData.first.keys.toList();

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: columns.map((String columnName) {
              return DataColumn(label: Text(columnName, style: const TextStyle(fontWeight: FontWeight.bold)));
            }).toList(),
            rows: _tableData.map((Map<String, dynamic> row) {
              return DataRow(
                cells: columns.map((String columnName) {
                  return DataCell(Text(row[columnName]?.toString() ?? ''));
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
