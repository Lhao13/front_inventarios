import 'package:flutter/material.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:front_inventarios/widgets/single_select_search_dialog.dart';
import 'package:front_inventarios/main.dart';
import 'package:uuid/uuid.dart';

class MaintenanceFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? initialAssetId;
  final VoidCallback? onSaved;

  const MaintenanceFormDialog({
    super.key,
    this.initialData,
    this.initialAssetId,
    this.onSaved,
  });

  @override
  State<MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends State<MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoadingAssets = true;
  List<Map<String, dynamic>> _assets = [];
  
  String? _editingId;
  String? _selectedActivoId;
  DateTime? _selectedDate;
  String _selectedTipo = 'Preventivo';
  String _selectedEstado = 'Pendiente';
  final _observacionController = TextEditingController();

  final List<String> _tipoOptions = ['Preventivo', 'Correctivo'];

  /// Opciones base para el estado del mantenimiento.
  /// 'Completado' se añade dinámicamente solo cuando se está editando
  /// un registro ya completado, para evitar entries duplicadas.
  static const List<String> _baseEstadoOptions = [
    'Pendiente',
    'En Proceso',
    'Cancelado',
  ];

  /// Retorna la lista de items del dropdown de Estado, sin duplicados.
  List<DropdownMenuItem<String>> _buildEstadoItems() {
    // Cuando se edita un mantenimiento Completado, se incluye esa opción.
    // Cuando se crea uno nuevo, 'Completado' no aparece (se usa el botón de la lista).
    final options = [..._baseEstadoOptions];
    if (_editingId != null && !options.contains(_selectedEstado)) {
      options.add(_selectedEstado); // agrega 'Completado' (u otro estado inesperado) sin duplicar
    }
    return options
        .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initData();
    _loadAssets();
  }

  void _initData() {
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _editingId = d['id'] as String?;
      _selectedActivoId = d['id_activo'] as String?;
      _selectedDate = d['fecha_programada'] != null ? DateTime.parse(d['fecha_programada'].toString()) : null;
      _selectedTipo = d['tipo']?.toString() ?? 'Preventivo';
      _selectedEstado = d['estado']?.toString() ?? 'Pendiente';
      _observacionController.text = d['observacion']?.toString() ?? '';
    } else {
      _selectedActivoId = widget.initialAssetId;
    }
  }

  Future<void> _loadAssets() async {
    try {
      final localActivos = await LocalDbService.instance.getCollection('activo');
      final filtered = localActivos
        ..sort((a, b) {
          final sA = a['numero_serie']?.toString() ?? '';
          final sB = b['numero_serie']?.toString() ?? '';
          return sA.compareTo(sB);
        });

      if (mounted) {
        setState(() {
          _assets = filtered.map((a) {
            final sn = a['categoria_activo'] == 'SOFTWARE' 
                ? (a['nombre'] ?? 'Sin Nombre') 
                : (a['numero_serie'] ?? 'S/S');
            final tipo = a['tipo_activo']?['tipo'] ?? (a['categoria_activo'] ?? 'Desconocido');
            return {
              'id': a['id'],
              'display': '$sn - $tipo',
            };
          }).toList();
          _isLoadingAssets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAssets = false);
      }
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

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
        data['id'] = const Uuid().v4();
        await LocalDbService.instance.enqueueOperation('table:mantenimiento:insert', data);
        if (mounted) context.showSnackBar('Mantenimiento programado (Cola Local).');
      } else {
        data['id'] = _editingId;
        await LocalDbService.instance.enqueueOperation('table:mantenimiento:update', data);
        if (mounted) context.showSnackBar('Mantenimiento actualizado (Cola Local).');
      }
      if (SyncQueueService.instance.isOnline) SyncQueueService.instance.syncPendingOperations();

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Error en la base de datos local: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  : SearchableDropdownFormField<String>(
                      label: 'Activo (S/N - Tipo)',
                      value: _selectedActivoId,
                      items: _assets,
                      displayKey: 'display',
                      required: true,
                      onChanged: (v) => setState(() => _selectedActivoId = v),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha Programada *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                      isDense: true,
                    ),
                    child: Text(
                      _selectedDate == null ? 'Seleccionar fecha' : _formatDate(_selectedDate!),
                    ),
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Mantenimiento *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _tipoOptions
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTipo = v);
                },
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(
                  labelText: 'Estado *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              items: _buildEstadoItems(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedEstado = v);
                },
              ),
              const SizedBox(height: 12),
              
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _saveMaintenance, child: const Text('Guardar')),
      ],
    );
  }
}
