import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';

class DynamicAssetForm extends StatefulWidget {
  final String? initialCategory;
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

  const DynamicAssetForm({super.key, required this.onSave, this.initialCategory});

  @override
  State<DynamicAssetForm> createState() => _DynamicAssetFormState();
}

class _DynamicAssetFormState extends State<DynamicAssetForm> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingMasterData = true;

  // Master Lists
  List<Map<String, dynamic>> _tiposActivo = [];
  List<Map<String, dynamic>> _condicionesActivo = [];
  List<Map<String, dynamic>> _custodios = [];
  List<Map<String, dynamic>> _ciudades = [];
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _marcas = [];

  // Dropdown States
  int? _tipoActivoId;
  int? _condicionActivoId;
  int? _custodioId;
  int? _ciudadActivoId;
  int? _sedeActivoId;
  int? _areaActivoId;
  int? _proveedorId;
  int? _marcaId;

  // Common Fields
  final _numeroSerieCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _fechaAdquisicionCtrl = TextEditingController();
  final _fechaEntregaCtrl = TextEditingController();
  final _coordenadaCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
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

  late String _categoria;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoria = widget.initialCategory ?? 'PC';
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    try {
      final futures = await Future.wait([
        supabase.from('tipo_activo').select('id, tipo, categoria').order('tipo'),
        supabase.from('condicion_activo').select('id, condicion').order('condicion'),
        supabase.from('custodio').select('id, nombre_completo').order('nombre_completo'),
        supabase.from('ciudad_activo').select('id, ciudad').order('ciudad'),
        supabase.from('sede_activo').select('id, sede').order('sede'),
        supabase.from('area_activo').select('id, area').order('area'),
        supabase.from('proveedor').select('id, nombre').order('nombre'),
        supabase.from('marca').select('id, marca_proveedor').order('marca_proveedor'),
      ]);

      if (mounted) {
        setState(() {
          _tiposActivo = List<Map<String, dynamic>>.from(futures[0]);
          _condicionesActivo = List<Map<String, dynamic>>.from(futures[1]);
          _custodios = List<Map<String, dynamic>>.from(futures[2]);
          _ciudades = List<Map<String, dynamic>>.from(futures[3]);
          _sedes = List<Map<String, dynamic>>.from(futures[4]);
          _areas = List<Map<String, dynamic>>.from(futures[5]);
          _proveedores = List<Map<String, dynamic>>.from(futures[6]);
          _marcas = List<Map<String, dynamic>>.from(futures[7]);
          _isLoadingMasterData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos maestros: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoadingMasterData = false);
      }
    }
  }

  @override
  void dispose() {
    _numeroSerieCtrl.dispose();
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _fechaAdquisicionCtrl.dispose();
    _fechaEntregaCtrl.dispose();
    _coordenadaCtrl.dispose();
    _ipCtrl.dispose();
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
          border: const OutlineInputBorder(),
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

  Widget _buildDropdown(
    String label, 
    int? value, 
    List<Map<String, dynamic>> items, 
    String displayKey, 
    ValueChanged<int?> onChanged, 
    {bool required = false}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem<int>(
            value: item['id'] as int,
            child: Text(item[displayKey]?.toString() ?? 'N/A'),
          );
        }).toList(),
        onChanged: onChanged,
        validator: required ? (val) => val == null ? 'Seleccione una opción' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMasterData) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              if (widget.initialCategory == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: DropdownButtonFormField<String>(
                  value: _categoria,
                  items: const [
                    DropdownMenuItem(value: 'PC', child: Text('PC')),
                    DropdownMenuItem(value: 'SOFTWARE', child: Text('SOFTWARE')),
                    DropdownMenuItem(value: 'COMUNICACION', child: Text('COMUNICACIÓN')),
                    DropdownMenuItem(value: 'GENERICO', child: Text('GENÉRICO')),
                  ],
                  onChanged: (value) {
                    if (value != null && value != _categoria) {
                       setState(() {
                         _categoria = value;
                         _tipoActivoId = null; // Reset tipoActivo since category changed
                       });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Categoría de Activo *', isDense: true, border: OutlineInputBorder()),
                ),
              ),
            
            /// Common Requirements Section
            const Text('Datos Generales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (_categoria != 'SOFTWARE') _buildTextField(_numeroSerieCtrl, 'Número de Serie', required: true),
            _buildTextField(_nombreCtrl, 'Nombre', required: true),
            _buildTextField(_codigoCtrl, 'Código', isNumber: true, required: true),
            
            _buildDropdown('Tipo de Activo', _tipoActivoId, _tiposActivo.where((t) => t['categoria'] == _categoria).toList(), 'tipo', (v) => setState(() => _tipoActivoId = v), required: true),
            _buildDropdown('Condición', _condicionActivoId, _condicionesActivo, 'condicion', (v) => setState(() => _condicionActivoId = v), required: true),
            _buildDropdown('Custodio', _custodioId, _custodios, 'nombre_completo', (v) => setState(() => _custodioId = v), required: true),
            _buildDropdown('Área', _areaActivoId, _areas, 'area', (v) => setState(() => _areaActivoId = v), required: true),
            _buildDropdown('Proveedor General', _proveedorId, _proveedores, 'nombre', (v) => setState(() => _proveedorId = v), required: true),
            
            if (_categoria != 'SOFTWARE') ...[
              _buildDropdown('Ciudad', _ciudadActivoId, _ciudades, 'ciudad', (v) => setState(() => _ciudadActivoId = v), required: true),
              _buildDropdown('Sede', _sedeActivoId, _sedes, 'sede', (v) => setState(() => _sedeActivoId = v), required: true),
              _buildTextField(_ipCtrl, 'IP (opcional)'),
              _buildDropdown('Marca', _marcaId, _marcas, 'marca_proveedor', (v) => setState(() => _marcaId = v), required: true),
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
                          tipoActivoId: _tipoActivoId ?? 0,
                          condicionActivoId: _condicionActivoId ?? 0,
                          custodioId: _custodioId ?? 0,
                          ciudadActivoId: _ciudadActivoId ?? 0,
                          sedeActivoId: _sedeActivoId ?? 0,
                          areaActivoId: _areaActivoId ?? 0,
                          proveedorId: _proveedorId ?? 0,
                          fechaAdquisicion: _fechaAdquisicionCtrl.text,
                          fechaEntrega: _fechaEntregaCtrl.text,
                          coordenada: _coordenadaCtrl.text,
                          nombre: _nombreCtrl.text,
                          codigo: int.tryParse(_codigoCtrl.text),
                          ip: _ipCtrl.text,
                          marcaId: _marcaId ?? 0,
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
