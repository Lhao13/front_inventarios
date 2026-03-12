import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';

/// Página de Mantenimientos.
/// 
/// Esta página permite al usuario gestionar los mantenimientos de los activos.
class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _maintenances = [];

  final _formKey = GlobalKey<FormState>();
  final _idActivoController = TextEditingController();
  final _fechaProgramadaController = TextEditingController();
  final _tipoController = TextEditingController();
  final _estadoController = TextEditingController(text: 'Pendiente');
  final _observacionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaintenances();
  }

  @override
  void dispose() {
    _idActivoController.dispose();
    _fechaProgramadaController.dispose();
    _tipoController.dispose();
    _estadoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await supabase
          .from('mantenimiento')
          .select('*')
          .order('fecha_programada', ascending: false);
          
      if (!mounted) return;
      setState(() {
        _maintenances = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar mantenimientos: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createMaintenance() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await supabase.from('mantenimiento').insert({
        'id_activo': int.parse(_idActivoController.text.trim()),
        'fecha_programada': _fechaProgramadaController.text.trim(),
        'tipo': _tipoController.text.trim(),
        'estado': _estadoController.text.trim(),
        'observacion': _observacionController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      context.showSnackBar('Mantenimiento programado.');
      _loadMaintenances();
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Error: $e', isError: true);
    }
  }

  void _showAddMaintenanceDialog() {
    _idActivoController.clear();
    _fechaProgramadaController.clear();
    _tipoController.clear();
    _estadoController.text = 'Pendiente';
    _observacionController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Programar Mantenimiento'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _idActivoController,
                  decoration: const InputDecoration(labelText: 'ID Activo *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _fechaProgramadaController,
                  decoration: const InputDecoration(labelText: 'Fecha Programada (YYYY-MM-DD) *'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _tipoController,
                  decoration: const InputDecoration(labelText: 'Tipo (Preventivo, Correctivo) *'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _estadoController,
                  decoration: const InputDecoration(labelText: 'Estado *'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _observacionController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: _createMaintenance, child: const Text('Guardar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Expanded(
                child: Text('Mantenimientos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              if (RoleService.currentRole != UserRole.ayudante)
                ElevatedButton.icon(
                  onPressed: _showAddMaintenanceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Programar'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _maintenances.isEmpty
                      ? const Center(child: Text('No hay mantenimientos programados.'))
                      : ListView.builder(
                          itemCount: _maintenances.length,
                          itemBuilder: (context, index) {
                            final m = _maintenances[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: m['estado'] == 'Pendiente' ? Colors.orange : Colors.green,
                                  child: Icon(Icons.build, color: Colors.white, size: 20),
                                ),
                                title: Text('Activo ID: ${m['id_activo']} - ${m['tipo']}'),
                                subtitle: Text('Fecha Programada: ${m['fecha_programada']}\nEstado: ${m['estado']}'),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
