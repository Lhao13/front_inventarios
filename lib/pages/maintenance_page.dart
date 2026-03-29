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
  bool _isLoadingAssets = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _maintenances = [];
  List<Map<String, dynamic>> _assets = [];

  final _formKey = GlobalKey<FormState>();
  
  // Form state
  String? _selectedActivoId;
  DateTime? _selectedDate;
  String _selectedTipo = 'Preventivo';
  String _selectedEstado = 'Pendiente';
  final _observacionController = TextEditingController();
  String? _editingId;

  final List<String> _tipoOptions = ['Preventivo', 'Correctivo'];
  final List<String> _estadoOptions = ['Pendiente', 'En Proceso', 'Cancelado'];

  @override
  void initState() {
    super.initState();
    _loadMaintenances();
    _loadAssets();
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _loadMaintenances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await supabase
          .from('mantenimiento')
          .select('*, activo(numero_serie, tipo_activo(tipo))')
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

  Future<void> _loadAssets() async {
    try {
      final response = await supabase
          .from('activo')
          .select('id, numero_serie, tipo_activo(tipo)')
          .neq('categoria_activo', 'SOFTWARE')
          .order('numero_serie');
      if (mounted) {
        setState(() {
          _assets = List<Map<String, dynamic>>.from(response);
          _isLoadingAssets = false;
        });
      }
    } catch (e) {
      if (mounted) print('Error loading assets: $e');
    }
  }

  Future<void> _completeMaintenance(String id) async {
    try {
      await supabase
          .from('mantenimiento')
          .update({
            'estado': 'Completado',
            'fecha_realizada': _formatDate(DateTime.now()),
          })
          .eq('id', id);
      if (!mounted) return;
      context.showSnackBar('Mantenimiento marcado como completado.');
      _loadMaintenances();
    } catch (e) {
      if (mounted) context.showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _deleteMaintenance(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Mantenimiento'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('mantenimiento').delete().eq('id', id);
      if (!mounted) return;
      context.showSnackBar('Mantenimiento eliminado.');
      _loadMaintenances();
    } catch (e) {
      if (mounted) context.showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _saveMaintenance() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActivoId == null || _selectedDate == null) {
      context.showSnackBar('Por favor completa los campos obligatorios.', isError: true);
      return;
    }

    final data = {
      'id_activo': _selectedActivoId,
      'fecha_programada': _formatDate(_selectedDate!),
      'tipo': _selectedTipo,
      'estado': _selectedEstado,
      'observacion': _observacionController.text.trim(),
    };

    try {
      if (_editingId == null) {
        await supabase.from('mantenimiento').insert(data);
        if (!mounted) return;
        context.showSnackBar('Mantenimiento programado.');
      } else {
        await supabase.from('mantenimiento').update(data).eq('id', _editingId!);
        if (!mounted) return;
        context.showSnackBar('Mantenimiento actualizado.');
      }
      Navigator.pop(context);
      _loadMaintenances();
    } catch (e) {
      if (mounted) context.showSnackBar('Error: $e', isError: true);
    }
  }

  void _showAddMaintenanceDialog({Map<String, dynamic>? initialData}) {
    setState(() {
      if (initialData != null) {
        _editingId = initialData['id'] as String;
        _selectedActivoId = initialData['id_activo'] as String;
        _selectedDate = DateTime.parse(initialData['fecha_programada'].toString());
        _selectedTipo = initialData['tipo']?.toString() ?? 'Preventivo';
        _selectedEstado = initialData['estado']?.toString() ?? 'Pendiente';
        _observacionController.text = initialData['observacion']?.toString() ?? '';
      } else {
        _editingId = null;
        _selectedActivoId = null;
        _selectedDate = null;
        _selectedTipo = 'Preventivo';
        _selectedEstado = 'Pendiente';
        _observacionController.clear();
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(_editingId == null ? 'Programar Mantenimiento' : 'Editar Mantenimiento'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isLoadingAssets
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _selectedActivoId,
                            decoration: const InputDecoration(
                              labelText: 'Activo (S/N - Tipo) *',
                              border: OutlineInputBorder(),
                            ),
                            items: _assets.map((a) {
                              final sn = a['numero_serie'] ?? 'S/S';
                              final tipo = a['tipo_activo']?['tipo'] ?? 'Desconocido';
                              return DropdownMenuItem<String>(
                                value: a['id'] as String,
                                child: Text('$sn - $tipo', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setDialogState(() => _selectedActivoId = v);
                              setState(() => _selectedActivoId = v);
                            },
                            validator: (v) => v == null ? 'Requerido' : null,
                          ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => _selectedDate = picked);
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha Programada *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate == null ? 'Seleccionar fecha' : _formatDate(_selectedDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Mantenimiento *',
                        border: OutlineInputBorder(),
                      ),
                      items: _tipoOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) {
                        setDialogState(() => _selectedTipo = v!);
                        setState(() => _selectedTipo = v!);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado *',
                        border: OutlineInputBorder(),
                      ),
                      items: () {
                        final items = _estadoOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList();
                        // Si el estado actual es 'Completado', lo añadimos temporalmente para evitar el error de Flutter
                        if (_selectedEstado == 'Completado') {
                          items.add(const DropdownMenuItem(value: 'Completado', child: Text('Completado')));
                        }
                        return items;
                      }(),
                      onChanged: (v) {
                        setDialogState(() => _selectedEstado = v!);
                        setState(() => _selectedEstado = v!);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observacionController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(onPressed: _saveMaintenance, child: const Text('Guardar')),
            ],
          );
        },
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
                                  backgroundColor: m['estado'] == 'Pendiente'
                                      ? Colors.orange
                                      : m['estado'] == 'Completado'
                                          ? Colors.green
                                          : Colors.blue,
                                  child: Icon(
                                    m['estado'] == 'Completado' ? Icons.check : Icons.build,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text('${m['activo']?['numero_serie'] ?? 'ID: ${m['id_activo']}'} - ${m['tipo']}'),
                                subtitle: Text(
                                  'Tipo Activo: ${m['activo']?['tipo_activo']?['tipo'] ?? 'N/A'}\n'
                                  'Programado: ${m['fecha_programada']} | Estado: ${m['estado']}'
                                  '${m['fecha_realizada'] != null ? '\nRealizado: ${m['fecha_realizada']}' : ''}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (RoleService.currentRole != UserRole.ayudante)
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        tooltip: 'Editar',
                                        onPressed: () => _showAddMaintenanceDialog(initialData: m),
                                      ),
                                    if (m['estado'] != 'Completado' && RoleService.currentRole != UserRole.ayudante)
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                        tooltip: 'Marcar como Completado',
                                        onPressed: () => _completeMaintenance(m['id'] as String),
                                      ),
                                    if (RoleService.currentRole != UserRole.ayudante)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'Eliminar',
                                        onPressed: () => _deleteMaintenance(m['id'] as String),
                                      ),
                                  ],
                                ),
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
