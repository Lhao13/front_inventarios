import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panel_web/widgets/single_select_search_dialog.dart';
import 'package:panel_web/main.dart';

class DynamicAssetForm extends StatefulWidget {
  /// If passed, the form will be pre-populated with the existing asset's data.
  final Map<String, dynamic>? initialData;
  final String? initialCategory;
  final Future<void> Function({
    String? numeroSerie,
    required String categoria,
    required int tipoActivoId,
    int? condicionActivoId,
    int? custodioId,
    int? ciudadActivoId,
    int? sedeActivoId,
    int? areaActivoId,
    int? proveedorId,
    String? fechaAdquisicion,
    String? fechaEntrega,
    String? coordenada,
    String? nombre,
    String? codigo,
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
  })
  onSave;

  const DynamicAssetForm({
    super.key,
    required this.onSave,
    this.initialCategory,
    this.initialData,
  });

  @override
  State<DynamicAssetForm> createState() => _DynamicAssetFormState();
}

class _DynamicAssetFormState extends State<DynamicAssetForm> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingMasterData = true;
  final ScrollController _scrollController = ScrollController();

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

  // Date state (stored as DateTime? for the picker, formatted as String for API)
  DateTime? _fechaAdquisicion;
  DateTime? _fechaEntrega;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Common Fields
  final _numeroSerieCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _coordenadaCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  // Date Controllers for manual entry
  final _fechaAdquisicionCtrl = TextEditingController();
  final _fechaEntregaCtrl = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();

  // PC Specific
  final _procesadorCtrl = TextEditingController();
  final _cargadorCodigoCtrl = TextEditingController();
  final _numPuertosCtrl = TextEditingController();
  String? _selectedRam;
  String? _selectedAlmacenamiento;

  static const List<String> _ramOptions = [
    '4GB',
    '8GB',
    '12GB',
    '16GB',
    '32GB',
    '64GB',
    '128GB',
    '256GB',
  ];
  static const List<String> _storageOptions = [
    '128GB',
    '256GB',
    '512GB',
    '1TB',
    '2TB',
    '4TB',
    '10TB',
  ];

  // Communication Specific
  final _tipoExtensionCtrl = TextEditingController();

  // Generic Specific
  final _numConexionesCtrl = TextEditingController();
  final _varImpresoraColorCtrl = TextEditingController();
  final _varMonitorTipoConexionCtrl = TextEditingController();

  // Software Specific
  final _proveedorSoftwareCtrl = TextEditingController();

  late String _categoria;
  bool _saving = false;

  // Format a DateTime to YYYY-MM-DD string for API
  String _fmtDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // Format a DateTime to DD/MM/YYYY string for Display
  String _fmtDisplayDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  // Parse DD/MM/YYYY string to DateTime safely
  DateTime? _parseDisplayDate(String s) {
    if (s.length != 10) return null;
    try {
      final parts = s.split('/');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  // Try to parse a date string safely
  DateTime? _tryParse(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _categoria = widget.initialCategory ?? 'PC';
    _loadMasterData();
  }

  /// Pre-populate form fields once master data is loaded and initialData exists.
  void _populateFromInitialData() {
    final d = widget.initialData;
    if (d == null) return;

    _numeroSerieCtrl.text = d['numero_serie']?.toString() ?? '';
    _nombreCtrl.text = d['nombre']?.toString() ?? '';
    _codigoCtrl.text = d['codigo']?.toString() ?? '';
    _coordenadaCtrl.text = d['coordenada']?.toString() ?? '';
    _ipCtrl.text = d['ip']?.toString() ?? '';
    _observacionesCtrl.text = d['observaciones']?.toString() ?? '';

    _fechaAdquisicion = _tryParse(d['fecha_adquisicion']?.toString());
    if (_fechaAdquisicion != null) {
      _fechaAdquisicionCtrl.text = _fmtDisplayDate(_fechaAdquisicion!);
    }

    _fechaEntrega = _tryParse(d['fecha_entrega']?.toString());
    if (_fechaEntrega != null) {
      _fechaEntregaCtrl.text = _fmtDisplayDate(_fechaEntrega!);
    }

    _tipoActivoId = d['id_tipo_activo'] as int?;
    _condicionActivoId = d['id_condicion_activo'] as int?;
    _custodioId = d['id_custodio'] as int?;
    _ciudadActivoId = d['id_ciudad_activo'] as int?;
    _sedeActivoId = d['id_sede_activo'] as int?;
    _areaActivoId = d['id_area_activo'] as int?;
    _proveedorId = d['id_provedor'] as int?;

    // Category-specific fields
    List? infoList;
    if (_categoria == 'PC') {
      infoList = d['info_pc'] as List?;
    } else if (_categoria == 'COMUNICACION') {
      infoList = d['info_equipo_comunicacion'] as List?;
    } else if (_categoria == 'GENERICO') {
      infoList = d['info_equipo_generico'] as List?;
    } else if (_categoria == 'SOFTWARE') {
      infoList = d['info_software'] as List?;
    }

    final info = (infoList != null && infoList.isNotEmpty)
        ? infoList[0] as Map<String, dynamic>
        : null;

    if (info != null) {
      _modeloCtrl.text = info['modelo']?.toString() ?? '';
      _marcaId = info['id_marca'] as int?;

      // If observations exist in the specific info table, use them
      if (info['observaciones'] != null) {
        _observacionesCtrl.text = info['observaciones'].toString();
      }

      // PC
      _procesadorCtrl.text = info['procesador']?.toString() ?? '';
      _cargadorCodigoCtrl.text = info['cargador_codigo']?.toString() ?? '';
      _numPuertosCtrl.text = info['num_puertos']?.toString() ?? '';

      final ramVal = info['ram']?.toString();
      _selectedRam = _ramOptions.contains(ramVal) ? ramVal : null;

      final storageVal = info['almacenamiento']?.toString();
      _selectedAlmacenamiento = _storageOptions.contains(storageVal)
          ? storageVal
          : null;

      // Communication
      _tipoExtensionCtrl.text = info['tipo_extension']?.toString() ?? '';

      // Generic
      _numConexionesCtrl.text = info['num_conexiones']?.toString() ?? '';
      _varImpresoraColorCtrl.text =
          info['var_impresora_color']?.toString() ?? '';
      _varMonitorTipoConexionCtrl.text =
          info['var_monitor_tipo_conexion']?.toString() ?? '';

      // Software
      _proveedorSoftwareCtrl.text = info['proveedor']?.toString() ?? '';
      _fechaInicio = _tryParse(info['fecha_inicio']?.toString());
      if (_fechaInicio != null) {
        _fechaInicioCtrl.text = _fmtDisplayDate(_fechaInicio!);
      }
      _fechaFin = _tryParse(info['fecha_fin']?.toString());
      if (_fechaFin != null) {
        _fechaFinCtrl.text = _fmtDisplayDate(_fechaFin!);
      }
    }
  }

  Future<void> _loadMasterData() async {
    try {
      final supabase = Supabase.instance.client;
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
        _populateFromInitialData();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Error al cargar datos maestros: $e',
          isError: true,
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
    _coordenadaCtrl.dispose();
    _ipCtrl.dispose();
    _modeloCtrl.dispose();
    _observacionesCtrl.dispose();
    _procesadorCtrl.dispose();
    _cargadorCodigoCtrl.dispose();
    _numPuertosCtrl.dispose();
    _tipoExtensionCtrl.dispose();
    _numConexionesCtrl.dispose();
    _varImpresoraColorCtrl.dispose();
    _varMonitorTipoConexionCtrl.dispose();
    _proveedorSoftwareCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ──────────────── Widget helpers ────────────────

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool isNumericOnly = false,
    bool required = false,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: (isNumber || isNumericOnly)
            ? TextInputType.number
            : TextInputType.text,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
          filled: required,
          fillColor: required ? Colors.blue.withValues(alpha: 0.05) : null,
          labelStyle: required
              ? const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
              : null,
          enabledBorder: required
              ? OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade300),
                )
              : const OutlineInputBorder(),
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon ??
              (readOnly && controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => controller.clear(),
                    )
                  : null),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) return 'Requerido';
                if (isNumber && int.tryParse(value.trim()) == null) {
                  return 'Debe ser numérico';
                }
                return null;
              }
            : (value) {
                if (value != null &&
                    value.trim().isNotEmpty &&
                    isNumber &&
                    int.tryParse(value.trim()) == null) {
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
    ValueChanged<int?> onChanged, {
    bool required = false,
  }) {
    final validValue = items.any((item) => item['id'] == value) ? value : null;

    final dropdownItems = items.map((item) {
      return DropdownMenuItem<int?>(
        value: item['id'],
        child: Text(
          item[displayKey]?.toString() ?? '',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<int?>(
        value: validValue,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
          filled: required,
          fillColor: required ? Colors.blue.withValues(alpha: 0.05) : null,
          labelStyle: required
              ? const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
              : null,
          enabledBorder: required
              ? OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade300),
                )
              : const OutlineInputBorder(),
          border: const OutlineInputBorder(),
          suffixIcon: (!required && validValue != null)
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        items: dropdownItems,
        onChanged: onChanged,
        validator: required
            ? (val) => val == null ? 'Seleccione una opción' : null
            : null,
      ),
    );
  }

  Widget _buildSearchableDropdown(
    String label,
    int? value,
    List<Map<String, dynamic>> items,
    String displayKey,
    ValueChanged<int?> onChanged, {
    bool required = false,
  }) {
    final validValue = items.any((item) => item['id'] == value) ? value : null;
    return SearchableDropdownFormField<int>(
      label: label,
      items: items,
      displayKey: displayKey,
      value: validValue,
      onChanged: onChanged,
      required: required,
      validator: required
          ? (val) => val == null ? 'Seleccione una opción' : null
          : null,
    );
  }

  Widget _buildStringDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    final validValue = items.contains(value) ? value : null;

    final dropdownItems = items.map((item) {
      return DropdownMenuItem<String?>(
        value: item,
        child: Text(item, overflow: TextOverflow.ellipsis),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String?>(
        value: validValue,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
          filled: required,
          fillColor: required ? Colors.blue.withValues(alpha: 0.05) : null,
          labelStyle: required
              ? const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
              : null,
          enabledBorder: required
              ? OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade300),
                )
              : const OutlineInputBorder(),
          border: const OutlineInputBorder(),
          suffixIcon: (!required && validValue != null)
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        items: dropdownItems,
        onChanged: onChanged,
        validator: required
            ? (val) => val == null ? 'Seleccione una opción' : null
            : null,
      ),
    );
  }

  // Coordenada: campo de texto manual
  Widget _buildDatePicker(
    String label,
    DateTime? currentValue,
    TextEditingController controller,
    void Function(DateTime?) onDateChanged, {
    bool allowFuture = true,
    bool required = false,
  }) {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          DateInputFormatter(),
        ],
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: 'DD/MM/AAAA',
          isDense: true,
          filled: required,
          fillColor: required ? Colors.blue.withValues(alpha: 0.05) : null,
          labelStyle: required
              ? const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
              : null,
          enabledBorder: required
              ? OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade300),
                )
              : const OutlineInputBorder(),
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    onDateChanged(null);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 18),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: currentValue ?? today,
                    firstDate: DateTime(2000),
                    lastDate: allowFuture ? DateTime(2100) : today,
                    locale: const Locale('es', 'ES'),
                    helpText: label,
                    cancelText: 'CANCELAR',
                    confirmText: 'ACEPTAR',
                    fieldLabelText: 'Ingresar fecha',
                    fieldHintText: 'Día/Mes/Año',
                    initialEntryMode: DatePickerEntryMode.calendar,
                  );
                  if (picked != null) {
                    controller.text = _fmtDisplayDate(picked);
                    onDateChanged(picked);
                  }
                },
              ),
            ],
          ),
        ),
        onChanged: (val) {
          final d = _parseDisplayDate(val);
          onDateChanged(d);
        },
        validator: required
            ? (val) {
                if (val == null || val.isEmpty) return 'Ingrese la fecha';
                if (_parseDisplayDate(val) == null) {
                  return 'Formato inválido (DD/MM/AAAA)';
                }
                return null;
              }
            : (val) {
                if (val != null &&
                    val.isNotEmpty &&
                    _parseDisplayDate(val) == null) {
                  return 'Formato inválido';
                }
                return null;
              },
      ),
    );
  }

  // ──────────────────── build ────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMasterData) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
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
                      if (value != null && value != _categoria) {
                        setState(() {
                          _categoria = value;
                          _tipoActivoId = null;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Categoría de Activo *',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              const Text(
                'Datos Generales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              if (_categoria != 'SOFTWARE')
                _buildTextField(
                  _numeroSerieCtrl,
                  'Número de Serie',
                  required: true,
                ),
              _buildTextField(_nombreCtrl, 'Nombre'),
              _buildTextField(
                _codigoCtrl,
                'Código',
                isNumericOnly: true,
              ),
              _buildDropdown(
                'Tipo de Activo',
                _tipoActivoId,
                _tiposActivo
                    .where((t) => t['categoria'] == _categoria)
                    .toList(),
                'tipo',
                (v) => setState(() => _tipoActivoId = v),
                required: true,
              ),
              _buildDropdown(
                'Condición',
                _condicionActivoId,
                _condicionesActivo,
                'condicion',
                (v) => setState(() => _condicionActivoId = v),
              ),
              _buildSearchableDropdown(
                'Custodio',
                _custodioId,
                _custodios,
                'nombre_completo',
                (v) => setState(() => _custodioId = v),
              ),
              _buildSearchableDropdown(
                'Área',
                _areaActivoId,
                _areas,
                'area',
                (v) => setState(() => _areaActivoId = v),
              ),
              _buildDropdown(
                'Proveedor General',
                _proveedorId,
                _proveedores,
                'nombre',
                (v) => setState(() => _proveedorId = v),
              ),

              if (_categoria != 'SOFTWARE') ...[
                _buildDropdown(
                  'Ciudad',
                  _ciudadActivoId,
                  _ciudades,
                  'ciudad',
                  (v) => setState(() => _ciudadActivoId = v),
                ),
                _buildSearchableDropdown(
                  'Sede',
                  _sedeActivoId,
                  _sedes,
                  'sede',
                  (v) => setState(() => _sedeActivoId = v),
                ),
                if (_categoria == 'PC' || _categoria == 'COMUNICACION')
                  _buildTextField(_ipCtrl, 'IP'),
                _buildDropdown(
                  'Marca',
                  _marcaId,
                  _marcas,
                  'marca_proveedor',
                  (v) => setState(() => _marcaId = v),
                ),
                _buildTextField(_modeloCtrl, 'Modelo'),
                // Date pickers — adquisicion must be ≤ today
                _buildDatePicker(
                  'Fecha de Adquisición',
                  _fechaAdquisicion,
                  _fechaAdquisicionCtrl,
                  (d) => setState(() => _fechaAdquisicion = d),
                  allowFuture: false,
                ),
                _buildDatePicker(
                  'Fecha de Entrega',
                  _fechaEntrega,
                  _fechaEntregaCtrl,
                  (d) => setState(() => _fechaEntrega = d),
                  allowFuture: true,
                ),
                _buildTextField(
                  _coordenadaCtrl,
                  'Coordenada (lat,lng)',
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'Detalles Específicos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),

              if (_categoria == 'PC') ...[
                _buildTextField(_procesadorCtrl, 'Procesador'),
                _buildStringDropdown(
                  'RAM',
                  _selectedRam,
                  _ramOptions,
                  (v) => setState(() => _selectedRam = v),
                ),
                _buildStringDropdown(
                  'Almacenamiento',
                  _selectedAlmacenamiento,
                  _storageOptions,
                  (v) => setState(() => _selectedAlmacenamiento = v),
                ),
                _buildTextField(
                  _cargadorCodigoCtrl,
                  'Código Cargador',
                ),
                _buildTextField(
                  _numPuertosCtrl,
                  'Número de Puertos',
                  isNumber: true,
                ),
              ],

              if (_categoria == 'COMUNICACION') ...[
                _buildTextField(
                  _numPuertosCtrl,
                  'Número de Puertos',
                  isNumber: true,
                ),
                _buildTextField(_tipoExtensionCtrl, 'Tipo Extensión'),
              ],

              if (_categoria == 'GENERICO') ...[
                _buildTextField(
                  _cargadorCodigoCtrl,
                  'Código Cargador',
                ),
                _buildTextField(
                  _numConexionesCtrl,
                  'Número de Conexiones',
                  isNumber: true,
                ),
                _buildTextField(_varImpresoraColorCtrl, 'Impresora Color'),
                _buildTextField(
                  _varMonitorTipoConexionCtrl,
                  'Monitor Tipo Conexión',
                ),
              ],

              if (_categoria == 'SOFTWARE') ...[
                _buildTextField(
                  _proveedorSoftwareCtrl,
                  'Proveedor de Software',
                ),
                _buildDatePicker(
                  'Fecha Inicio Licencia',
                  _fechaInicio,
                  _fechaInicioCtrl,
                  (d) => setState(() => _fechaInicio = d),
                ),
                _buildDatePicker(
                  'Fecha Fin Licencia',
                  _fechaFin,
                  _fechaFinCtrl,
                  (d) => setState(() => _fechaFin = d),
                ),
              ],

              _buildTextField(_observacionesCtrl, 'Observaciones'),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _saving = true);
                        try {
                          // Validar número de serie con Supabase
                          if (_categoria != 'SOFTWARE') {
                            final currentSerial = _numeroSerieCtrl.text.trim();
                            if (currentSerial.isNotEmpty) {
                              final res = await Supabase.instance.client
                                  .from('activo')
                                  .select('id')
                                  .eq('numero_serie', currentSerial)
                                  .neq('id', widget.initialData?['id']?.toString() ?? '');
                              final isDuplicate = (res as List).isNotEmpty;

                              if (isDuplicate) {
                                if (!context.mounted) return;
                                context.showSnackBar(
                                  'Error: El Número de Serie ya existe en el inventario.',
                                  isError: true,
                                );
                                setState(() => _saving = false);
                                return;
                              }
                            }
                          }

                          await widget.onSave(
                            numeroSerie: _categoria == 'SOFTWARE'
                                ? ''
                                : _numeroSerieCtrl.text,
                            categoria: _categoria,
                            tipoActivoId: _tipoActivoId ?? 0,
                            condicionActivoId: _condicionActivoId,
                            custodioId: _custodioId,
                            ciudadActivoId: _ciudadActivoId,
                            sedeActivoId: _sedeActivoId,
                            areaActivoId: _areaActivoId,
                            proveedorId: _proveedorId,
                            fechaAdquisicion: _fechaAdquisicion != null
                                ? _fmtDate(_fechaAdquisicion!)
                                : null,
                            fechaEntrega: _fechaEntrega != null
                                ? _fmtDate(_fechaEntrega!)
                                : null,
                            coordenada: _coordenadaCtrl.text.isEmpty
                                ? null
                                : _coordenadaCtrl.text,
                            nombre: _nombreCtrl.text.isEmpty
                                ? null
                                : _nombreCtrl.text,
                            codigo: _codigoCtrl.text.isEmpty
                                ? null
                                : _codigoCtrl.text,
                            ip: _ipCtrl.text.isEmpty ? null : _ipCtrl.text,
                            marcaId: _marcaId,
                            modelo: _modeloCtrl.text.isEmpty
                                ? null
                                : _modeloCtrl.text,
                            observaciones: _observacionesCtrl.text.isEmpty
                                ? null
                                : _observacionesCtrl.text,
                            procesador: _procesadorCtrl.text.isEmpty
                                ? null
                                : _procesadorCtrl.text,
                            ram: _selectedRam,
                            almacenamiento: _selectedAlmacenamiento,
                            cargadorCodigo: _cargadorCodigoCtrl.text.isEmpty
                                ? null
                                : _cargadorCodigoCtrl.text,
                            numPuertos: int.tryParse(_numPuertosCtrl.text),
                            tipoExtension: _tipoExtensionCtrl.text.isEmpty
                                ? null
                                : _tipoExtensionCtrl.text,
                            numConexiones: int.tryParse(
                              _numConexionesCtrl.text,
                            ),
                            varImpresoraColor:
                                _varImpresoraColorCtrl.text.isEmpty
                                ? null
                                : _varImpresoraColorCtrl.text,
                            varMonitorTipoConexion:
                                _varMonitorTipoConexionCtrl.text.isEmpty
                                ? null
                                : _varMonitorTipoConexionCtrl.text,
                            proveedorSoftware:
                                _proveedorSoftwareCtrl.text.isEmpty
                                ? null
                                : _proveedorSoftwareCtrl.text,
                            fechaInicio: _fechaInicio != null
                                ? _fmtDate(_fechaInicio!)
                                : null,
                            fechaFin: _fechaFin != null
                                ? _fmtDate(_fechaFin!)
                                : null,
                          );
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_saving ? 'Guardando...' : 'Guardar Activo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formateador automático para fechas DD/MM/AAAA
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Si está borrando, permitir la acción sin formatear
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Quitar cualquier cosa que no sea número para procesar
    var newText = text.replaceAll('/', '');

    // Limitar a 8 dígitos (DDMMYYYY)
    if (newText.length > 8) {
      newText = newText.substring(0, 8);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      // Insertar barra después del día (2 chars) y mes (4 chars)
      if ((i == 1 || i == 3) && i != newText.length - 1) {
        buffer.write('/');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}


