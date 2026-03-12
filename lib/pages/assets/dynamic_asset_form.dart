import 'package:flutter/material.dart';

class DynamicAssetForm extends StatefulWidget {
  final Future<void> Function({
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
    // PC Specific
    String? procesador,
    String? ram,
    String? almacenamiento,
    String? cargadorCodigo,
    int? numPuertos,
    // Communication Specific
    String? tipoExtension,
    // Generic Specific
    int? numConexiones,
    String? varImpresoraColor,
    String? varMonitorTipoConexion,
    // Software Specific
    String? proveedorSoftware,
    String? fechaInicio,
    String? fechaFin,
  }) onSave;

  const DynamicAssetForm({super.key, required this.onSave});

  @override
  State<DynamicAssetForm> createState() => _DynamicAssetFormState();
}

class _DynamicAssetFormState extends State<DynamicAssetForm> {
  final _formKey = GlobalKey<FormState>();

  // Common Fields
  final _numeroSerieCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _tipoActivoIdCtrl = TextEditingController();
  final _condicionActivoIdCtrl = TextEditingController();
  final _custodioIdCtrl = TextEditingController();
  final _ciudadActivoIdCtrl = TextEditingController();
  final _sedeActivoIdCtrl = TextEditingController();
  final _areaActivoIdCtrl = TextEditingController();
  final _proveedorIdCtrl = TextEditingController();
  final _fechaAdquisicionCtrl = TextEditingController();
  final _fechaEntregaCtrl = TextEditingController();
  final _coordenadaCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _marcaIdCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  // PC Specific
  final _procesadorCtrl = TextEditingController();
  final _ramCtrl = TextEditingController();
  final _almacenamientoCtrl = TextEditingController();
  final _cargadorCodigoCtrl = TextEditingController();
  final _numPuertosCtrl = TextEditingController();

  // Communication Specific
  final _tipoExtensionCtrl = TextEditingController();

  // Generic Specific
  final _numConexionesCtrl = TextEditingController();
  final _varImpresoraColorCtrl = TextEditingController();
  final _varMonitorTipoConexionCtrl = TextEditingController();

  // Software Specific
  final _proveedorSoftwareCtrl = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();

  String _categoria = 'PC';
  bool _saving = false;

  @override
  void dispose() {
    _numeroSerieCtrl.dispose();
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _tipoActivoIdCtrl.dispose();
    _condicionActivoIdCtrl.dispose();
    _custodioIdCtrl.dispose();
    _ciudadActivoIdCtrl.dispose();
    _sedeActivoIdCtrl.dispose();
    _areaActivoIdCtrl.dispose();
    _proveedorIdCtrl.dispose();
    _fechaAdquisicionCtrl.dispose();
    _fechaEntregaCtrl.dispose();
    _coordenadaCtrl.dispose();
    _ipCtrl.dispose();
    _marcaIdCtrl.dispose();
    _modeloCtrl.dispose();
    _observacionesCtrl.dispose();
    
    _procesadorCtrl.dispose();
    _ramCtrl.dispose();
    _almacenamientoCtrl.dispose();
    _cargadorCodigoCtrl.dispose();
    _numPuertosCtrl.dispose();

    _tipoExtensionCtrl.dispose();

    _numConexionesCtrl.dispose();
    _varImpresoraColorCtrl.dispose();
    _varMonitorTipoConexionCtrl.dispose();

    _proveedorSoftwareCtrl.dispose();
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    super.dispose();
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) return 'Requerido';
                if (isNumber && int.tryParse(value.trim()) == null) return 'Debe ser numérico';
                return null;
              }
            : (value) {
                if (value != null && value.trim().isNotEmpty && isNumber && int.tryParse(value.trim()) == null) {
                  return 'Debe ser numérico';
                }
                return null;
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _categoria,
              items: const [
                DropdownMenuItem(value: 'PC', child: Text('PC')),
                DropdownMenuItem(value: 'SOFTWARE', child: Text('SOFTWARE')),
                DropdownMenuItem(value: 'COMUNICACION', child: Text('COMUNICACIÓN')),
                DropdownMenuItem(value: 'GENERICO', child: Text('GENÉRICO')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _categoria = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Categoría de Activo *', isDense: true),
            ),
            const SizedBox(height: 16),
            
            /// Common Requirements Section
            const Text('Datos Generales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (_categoria != 'SOFTWARE') _buildTextField(_numeroSerieCtrl, 'Número de Serie', required: true),
            _buildTextField(_nombreCtrl, 'Nombre', required: true),
            _buildTextField(_codigoCtrl, 'Código', isNumber: true, required: true),
            _buildTextField(_tipoActivoIdCtrl, 'ID Tipo Activo', isNumber: true, required: true),
            _buildTextField(_condicionActivoIdCtrl, 'ID Condición Activo', isNumber: true, required: true),
            _buildTextField(_custodioIdCtrl, 'ID Custodio', isNumber: true, required: true),
            _buildTextField(_areaActivoIdCtrl, 'ID Área Activo', isNumber: true, required: true),
            _buildTextField(_proveedorIdCtrl, 'ID Proveedor', isNumber: true, required: true),
            
            if (_categoria != 'SOFTWARE') ...[
              _buildTextField(_ciudadActivoIdCtrl, 'ID Ciudad Activo', isNumber: true, required: true),
              _buildTextField(_sedeActivoIdCtrl, 'ID Sede Activo', isNumber: true, required: true),
              _buildTextField(_ipCtrl, 'IP (opcional)'),
              _buildTextField(_marcaIdCtrl, 'ID Marca', isNumber: true, required: true),
              _buildTextField(_modeloCtrl, 'Modelo', required: true),
              _buildTextField(_fechaAdquisicionCtrl, 'Fecha Adquisición (YYYY-MM-DD)', required: true),
              _buildTextField(_fechaEntregaCtrl, 'Fecha Entrega (YYYY-MM-DD)', required: true),
              _buildTextField(_coordenadaCtrl, 'Coordenada (lat,lng)', required: true),
            ],

            const SizedBox(height: 16),
            const Text('Detalles Específicos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            
            /// Specific Requirements Section
            if (_categoria == 'PC') ...[
              _buildTextField(_procesadorCtrl, 'Procesador', required: true),
              _buildTextField(_ramCtrl, 'RAM', required: true),
              _buildTextField(_almacenamientoCtrl, 'Almacenamiento', required: true),
              _buildTextField(_cargadorCodigoCtrl, 'Código Cargador', required: true),
              _buildTextField(_numPuertosCtrl, 'Número de Puertos', required: true, isNumber: true),
            ],

            if (_categoria == 'COMUNICACION') ...[
              _buildTextField(_numPuertosCtrl, 'Número de Puertos', required: true, isNumber: true),
              _buildTextField(_tipoExtensionCtrl, 'Tipo Extensión', required: true),
            ],

            if (_categoria == 'GENERICO') ...[
              _buildTextField(_cargadorCodigoCtrl, 'Código Cargador', required: true),
              _buildTextField(_numConexionesCtrl, 'Número de Conexiones', required: true, isNumber: true),
              _buildTextField(_varImpresoraColorCtrl, 'Impresora Color (opcional)'),
              _buildTextField(_varMonitorTipoConexionCtrl, 'Monitor Tipo Conexión (opcional)'),
            ],

            if (_categoria == 'SOFTWARE') ...[
              _buildTextField(_proveedorSoftwareCtrl, 'Proveedor de Software', required: true),
              _buildTextField(_fechaInicioCtrl, 'Fecha Inicio (YYYY-MM-DD)', required: true),
              _buildTextField(_fechaFinCtrl, 'Fecha Fin (YYYY-MM-DD)', required: true),
            ],

            _buildTextField(_observacionesCtrl, 'Observaciones (opcional)'),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      try {
                        await widget.onSave(
                          numeroSerie: _numeroSerieCtrl.text,
                          categoria: _categoria,
                          tipoActivoId: int.parse(_tipoActivoIdCtrl.text),
                          condicionActivoId: int.parse(_condicionActivoIdCtrl.text),
                          custodioId: int.parse(_custodioIdCtrl.text),
                          ciudadActivoId: int.tryParse(_ciudadActivoIdCtrl.text) ?? 0,
                          sedeActivoId: int.tryParse(_sedeActivoIdCtrl.text) ?? 0,
                          areaActivoId: int.parse(_areaActivoIdCtrl.text),
                          proveedorId: int.parse(_proveedorIdCtrl.text),
                          fechaAdquisicion: _fechaAdquisicionCtrl.text,
                          fechaEntrega: _fechaEntregaCtrl.text,
                          coordenada: _coordenadaCtrl.text,
                          nombre: _nombreCtrl.text,
                          codigo: int.tryParse(_codigoCtrl.text),
                          ip: _ipCtrl.text,
                          marcaId: int.tryParse(_marcaIdCtrl.text),
                          modelo: _modeloCtrl.text,
                          observaciones: _observacionesCtrl.text,
                          procesador: _procesadorCtrl.text,
                          ram: _ramCtrl.text,
                          almacenamiento: _almacenamientoCtrl.text,
                          cargadorCodigo: _cargadorCodigoCtrl.text,
                          numPuertos: int.tryParse(_numPuertosCtrl.text),
                          tipoExtension: _tipoExtensionCtrl.text,
                          numConexiones: int.tryParse(_numConexionesCtrl.text),
                          varImpresoraColor: _varImpresoraColorCtrl.text,
                          varMonitorTipoConexion: _varMonitorTipoConexionCtrl.text,
                          proveedorSoftware: _proveedorSoftwareCtrl.text,
                          fechaInicio: _fechaInicioCtrl.text,
                          fechaFin: _fechaFinCtrl.text,
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_saving ? 'Guardando...' : 'Guardar Activo'),
            )
          ],
        ),
      ),
    );
  }
}
