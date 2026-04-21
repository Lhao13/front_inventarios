import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:front_inventarios/widgets/barcode_scanner_screen.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/widgets/single_select_search_dialog.dart';
import 'package:front_inventarios/main.dart';

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
  bool _gettingLocation = false;

  // Format a DateTime to YYYY-MM-DD string
  String _fmtDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

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
    _fechaEntrega = _tryParse(d['fecha_entrega']?.toString());

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
      _fechaFin = _tryParse(info['fecha_fin']?.toString());
    }
  }

  Future<void> _loadMasterData() async {
    try {
      final futures = await Future.wait([
        LocalDbService.instance.getCollection('tipo_activo'),
        LocalDbService.instance.getCollection('condicion_activo'),
        LocalDbService.instance.getCollection('custodio'),
        LocalDbService.instance.getCollection('ciudad_activo'),
        LocalDbService.instance.getCollection('sede_activo'),
        LocalDbService.instance.getCollection('area_activo'),
        LocalDbService.instance.getCollection('proveedor'),
        LocalDbService.instance.getCollection('marca'),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: (isNumber || isNumericOnly)
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
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

    dropdownItems.insert(
      0,
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('-- Ninguno --', style: TextStyle(color: Colors.grey)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<int?>(
        value: validValue,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
          border: const OutlineInputBorder(),
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

    dropdownItems.insert(
      0,
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('-- Ninguno --', style: TextStyle(color: Colors.grey)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String?>(
        value: validValue,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: dropdownItems,
        onChanged: onChanged,
        validator: required
            ? (val) => val == null ? 'Seleccione una opción' : null
            : null,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          context.showSnackBar(
            'Servicio de ubicación desactivado',
            isError: true,
          );
        }
        setState(() => _gettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            context.showSnackBar(
              'Permiso de ubicación denegado',
              isError: true,
            );
          }
          setState(() => _gettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          context.showSnackBar(
            'Permisos de ubicación denegados permanentemente',
            isError: true,
          );
        }
        setState(() => _gettingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _coordenadaCtrl.text = '${position.latitude},${position.longitude}';
      });
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Error obteniendo ubicación: $e', isError: true);
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  /// Date picker field. [allowFuture] controls if future dates are selectable.
  /// When [allowFuture] is false, the last selectable date is today.
  Widget _buildDatePicker(
    String label,
    DateTime? currentValue,
    ValueChanged<DateTime?> onChanged, {
    bool allowFuture = true,
    bool required = false,
  }) {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: currentValue ?? today,
            firstDate: DateTime(2000),
            lastDate: allowFuture ? DateTime(2100) : today,
            helpText: label,
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: currentValue != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => onChanged(null),
                  )
                : const Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(
            currentValue != null
                ? _fmtDate(currentValue)
                : 'Toca para seleccionar',
            style: TextStyle(
              color: currentValue != null ? null : Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Escanear Número de Serie',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarcodeScannerScreen(),
                      ),
                    );
                    if (result != null && result is String) {
                      setState(() => _numeroSerieCtrl.text = result);
                    }
                  },
                ),
              ),
            _buildTextField(_nombreCtrl, 'Nombre (opcional)'),
            _buildTextField(
              _codigoCtrl,
              'Código (opcional)',
              isNumericOnly: true,
              suffixIcon: _categoria == 'SOFTWARE'
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Escanear Código Numérico',
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const BarcodeScannerScreen(isOnlyNumeric: true),
                          ),
                        );
                        if (result != null && result is String) {
                          setState(() => _codigoCtrl.text = result);
                        }
                      },
                    ),
            ),
            _buildDropdown(
              'Tipo de Activo',
              _tipoActivoId,
              _tiposActivo.where((t) => t['categoria'] == _categoria).toList(),
              'tipo',
              (v) => setState(() => _tipoActivoId = v),
              required: true,
            ),
            _buildDropdown(
              'Condición (opcional)',
              _condicionActivoId,
              _condicionesActivo,
              'condicion',
              (v) => setState(() => _condicionActivoId = v),
            ),
            _buildSearchableDropdown(
              'Custodio (opcional)',
              _custodioId,
              _custodios,
              'nombre_completo',
              (v) => setState(() => _custodioId = v),
            ),
            _buildSearchableDropdown(
              'Área (opcional)',
              _areaActivoId,
              _areas,
              'area',
              (v) => setState(() => _areaActivoId = v),
            ),
            _buildDropdown(
              'Proveedor General (opcional)',
              _proveedorId,
              _proveedores,
              'nombre',
              (v) => setState(() => _proveedorId = v),
            ),

            if (_categoria != 'SOFTWARE') ...[
              _buildDropdown(
                'Ciudad (opcional)',
                _ciudadActivoId,
                _ciudades,
                'ciudad',
                (v) => setState(() => _ciudadActivoId = v),
              ),
              _buildSearchableDropdown(
                'Sede (opcional)',
                _sedeActivoId,
                _sedes,
                'sede',
                (v) => setState(() => _sedeActivoId = v),
              ),
              _buildTextField(_ipCtrl, 'IP (opcional)'),
              _buildDropdown(
                'Marca (opcional)',
                _marcaId,
                _marcas,
                'marca_proveedor',
                (v) => setState(() => _marcaId = v),
              ),
              _buildTextField(_modeloCtrl, 'Modelo (opcional)'),
              // Date pickers — adquisicion must be ≤ today
              _buildDatePicker(
                'Fecha de Adquisición (opcional)',
                _fechaAdquisicion,
                (d) => setState(() => _fechaAdquisicion = d),
                allowFuture: false,
              ),
              _buildDatePicker(
                'Fecha de Entrega (opcional)',
                _fechaEntrega,
                (d) => setState(() => _fechaEntrega = d),
                allowFuture: true,
              ),
              _buildTextField(
                _coordenadaCtrl,
                'Coordenada (opcional)',
                suffixIcon: IconButton(
                  icon: _gettingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  tooltip: 'Obtener mi ubicación actual',
                  onPressed: _gettingLocation ? null : _getCurrentLocation,
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Detalles Específicos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),

            if (_categoria == 'PC') ...[
              _buildTextField(_procesadorCtrl, 'Procesador (opcional)'),
              _buildStringDropdown(
                'RAM (opcional)',
                _selectedRam,
                _ramOptions,
                (v) => setState(() => _selectedRam = v),
              ),
              _buildStringDropdown(
                'Almacenamiento (opcional)',
                _selectedAlmacenamiento,
                _storageOptions,
                (v) => setState(() => _selectedAlmacenamiento = v),
              ),
              _buildTextField(
                _cargadorCodigoCtrl,
                'Código Cargador (opcional)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Escanear Código',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const BarcodeScannerScreen(isOnlyNumeric: true),
                      ),
                    );
                    if (result != null && result is String) {
                      setState(() => _cargadorCodigoCtrl.text = result);
                    }
                  },
                ),
              ),
              _buildTextField(
                _numPuertosCtrl,
                'Número de Puertos (opcional)',
                isNumber: true,
              ),
            ],

            if (_categoria == 'COMUNICACION') ...[
              _buildTextField(
                _numPuertosCtrl,
                'Número de Puertos (opcional)',
                isNumber: true,
              ),
              _buildTextField(_tipoExtensionCtrl, 'Tipo Extensión (opcional)'),
            ],

            if (_categoria == 'GENERICO') ...[
              _buildTextField(
                _cargadorCodigoCtrl,
                'Código Cargador (opcional)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Escanear Código',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const BarcodeScannerScreen(isOnlyNumeric: true),
                      ),
                    );
                    if (result != null && result is String) {
                      setState(() => _cargadorCodigoCtrl.text = result);
                    }
                  },
                ),
              ),
              _buildTextField(
                _numConexionesCtrl,
                'Número de Conexiones (opcional)',
                isNumber: true,
              ),
              _buildTextField(
                _varImpresoraColorCtrl,
                'Impresora Color (opcional)',
              ),
              _buildTextField(
                _varMonitorTipoConexionCtrl,
                'Monitor Tipo Conexión (opcional)',
              ),
            ],

            if (_categoria == 'SOFTWARE') ...[
              _buildTextField(
                _proveedorSoftwareCtrl,
                'Proveedor de Software (opcional)',
              ),
              _buildDatePicker(
                'Fecha Inicio Licencia (opcional)',
                _fechaInicio,
                (d) => setState(() => _fechaInicio = d),
              ),
              _buildDatePicker(
                'Fecha Fin Licencia (opcional)',
                _fechaFin,
                (d) => setState(() => _fechaFin = d),
              ),
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
                        // PRE-VALIDACIÓN OFFLINE: Evitar números de serie duplicados revisando Caché
                        if (_categoria != 'SOFTWARE') {
                          final currentSerial = _numeroSerieCtrl.text.trim();
                          if (currentSerial.isNotEmpty) {
                            final allAssets = await LocalDbService.instance
                                .getCollection('activo');
                            final isDuplicate = allAssets.any(
                              (a) =>
                                  a['numero_serie']?.toString().trim() ==
                                      currentSerial &&
                                  a['id']?.toString() !=
                                      widget.initialData?['id']?.toString(),
                            );

                            if (isDuplicate) {
                              if (!context.mounted) return;
                              context.showSnackBar(
                                'Error: El Número de Serie ya existe en el inventario.',
                                isError: true,
                              );
                              
                              setState(() => _saving = false);
                              return; // Detenemos el guardado
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
                          numConexiones: int.tryParse(_numConexionesCtrl.text),
                          varImpresoraColor: _varImpresoraColorCtrl.text.isEmpty
                              ? null
                              : _varImpresoraColorCtrl.text,
                          varMonitorTipoConexion:
                              _varMonitorTipoConexionCtrl.text.isEmpty
                              ? null
                              : _varMonitorTipoConexionCtrl.text,
                          proveedorSoftware: _proveedorSoftwareCtrl.text.isEmpty
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
