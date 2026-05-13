import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedReport = 'completo';
  bool _isGenerating = false;
  String? _selectedArea;
  String? _selectedSede;
  String? _selectedCondicion;
  String? _selectedTipo;

  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _condiciones = [];
  List<Map<String, dynamic>> _tipos = [];
  bool _loadingFilters = true;

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'id': 'completo',
      'label': 'Inventario Completo',
      'desc': 'Todos los activos activos con sus datos',
      'icon': Icons.list_alt_rounded,
    },
    {
      'id': 'por_tipo',
      'label': 'Por Tipo de Activo',
      'desc': 'Filtrado por tipo específico',
      'icon': Icons.category_rounded,
    },
    {
      'id': 'por_area',
      'label': 'Por Área',
      'desc': 'Activos agrupados por área',
      'icon': Icons.business_rounded,
    },
    {
      'id': 'por_sede',
      'label': 'Por Sede',
      'desc': 'Activos por sede',
      'icon': Icons.location_city_rounded,
    },
    {
      'id': 'por_condicion',
      'label': 'Por Condición',
      'desc': 'Activos en determinada condición',
      'icon': Icons.info_outline_rounded,
    },
    {
      'id': 'eliminados',
      'label': 'Activos Eliminados',
      'desc': 'Listado de activos dados de baja',
      'icon': Icons.delete_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait([
        Supabase.instance.client.from('area_activo').select('id, area').order('area'),
        Supabase.instance.client.from('sede_activo').select('id, sede').order('sede'),
        Supabase.instance.client.from('condicion_activo').select('id, condicion').order('condicion'),
        Supabase.instance.client.from('tipo_activo').select('id, tipo').order('tipo'),
      ]);
      if (mounted) {
        setState(() {
          _areas = List<Map<String, dynamic>>.from(results[0]);
          _sedes = List<Map<String, dynamic>>.from(results[1]);
          _condiciones = List<Map<String, dynamic>>.from(results[2]);
          _tipos = List<Map<String, dynamic>>.from(results[3]);
          _loadingFilters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    try {
      List<Map<String, dynamic>> assets = await _fetchData();
      final doc = await _buildPdf(assets);
      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generando informe: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    if (_selectedReport == 'eliminados') {
      final hist = await Supabase.instance.client
          .from('historial_activo')
          .select('id, id_activo, timestamp_changed_at, snapshot_json')
          .eq('tipo_operacion', 'DELETE')
          .order('timestamp_changed_at', ascending: false);
      return List<Map<String, dynamic>>.from(hist);
    }

    var query = Supabase.instance.client.from('activo').select(
      'codigo, nombre, numero_serie, categoria_activo,'
      'tipo_activo(tipo), area_activo(area), sede_activo(sede),'
      'condicion_activo(condicion), custodio(nombre_completo)',
    );

    if (_selectedReport == 'por_area' && _selectedArea != null) {
      query = query.eq('id_area_activo', _selectedArea!) as dynamic;
    }
    if (_selectedReport == 'por_sede' && _selectedSede != null) {
      query = query.eq('id_sede_activo', _selectedSede!) as dynamic;
    }
    if (_selectedReport == 'por_condicion' && _selectedCondicion != null) {
      query = query.eq('id_condicion_activo', _selectedCondicion!) as dynamic;
    }
    if (_selectedReport == 'por_tipo' && _selectedTipo != null) {
      query = query.eq('id_tipo_activo', _selectedTipo!) as dynamic;
    }

    final result = await query.order('nombre');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<pw.Document> _buildPdf(List<Map<String, dynamic>> assets) async {
    final doc = pw.Document();
    final reportLabel = _reportTypes
        .firstWhere((r) => r['id'] == _selectedReport)['label'] as String;
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1565C0'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    'IS',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Sistema de Inventarios',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    pw.Text(
                      'Informe: $reportLabel',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Text('Generado: $now',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
          ],
        ),
        build: (ctx) {
          if (_selectedReport == 'eliminados') {
            return _buildDeletedTable(assets);
          }
          return _buildAssetsTable(assets);
        },
      ),
    );

    return doc;
  }

  List<pw.Widget> _buildAssetsTable(List<Map<String, dynamic>> assets) {
    final headers = [
      'Código', 'Nombre', 'N° Serie', 'Categoría',
      'Tipo', 'Área', 'Sede', 'Condición', 'Custodio',
    ];
    final cellStyle = const pw.TextStyle(fontSize: 9);
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 9,
      color: PdfColors.white,
    );

    return [
      pw.Text(
        '${assets.length} activo(s) encontrado(s)',
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#1565C0'),
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1.5),
          5: const pw.FlexColumnWidth(1.5),
          6: const pw.FlexColumnWidth(1.5),
          7: const pw.FlexColumnWidth(1.5),
          8: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1565C0'),
            ),
            children: headers.map((h) => pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(h, style: headerStyle),
            )).toList(),
          ),
          ...assets.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            final bg = i.isOdd ? PdfColors.grey50 : PdfColors.white;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _cell(a['codigo']?.toString() ?? '', cellStyle),
                _cell(a['nombre']?.toString() ?? '', cellStyle),
                _cell(a['numero_serie']?.toString() ?? '', cellStyle),
                _cell(a['categoria_activo']?.toString() ?? '', cellStyle),
                _cell(a['tipo_activo']?['tipo']?.toString() ?? '', cellStyle),
                _cell(a['area_activo']?['area']?.toString() ?? '', cellStyle),
                _cell(a['sede_activo']?['sede']?.toString() ?? '', cellStyle),
                _cell(a['condicion_activo']?['condicion']?.toString() ?? '', cellStyle),
                _cell(a['custodio']?['nombre_completo']?.toString() ?? '', cellStyle),
              ],
            );
          }),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildDeletedTable(List<Map<String, dynamic>> records) {
    final headers = ['Nombre', 'Código', 'Categoría', 'Área', 'Fecha Eliminación'];
    final cellStyle = const pw.TextStyle(fontSize: 9);
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 9,
      color: PdfColors.white,
    );

    return [
      pw.Text(
        '${records.length} activo(s) eliminado(s)',
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#C62828'),
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#C62828')),
            children: headers.map((h) => pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(h, style: headerStyle),
            )).toList(),
          ),
          ...records.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final snap = r['snapshot_json'] as Map<String, dynamic>? ?? {};
            final bg = i.isOdd ? PdfColors.grey50 : PdfColors.white;
            final fecha = r['timestamp_changed_at'] != null
                ? DateFormat('dd/MM/yyyy HH:mm')
                    .format(DateTime.parse(r['timestamp_changed_at']))
                : '';
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _cell(snap['nombre']?.toString() ?? '', cellStyle),
                _cell(snap['codigo']?.toString() ?? '', cellStyle),
                _cell(snap['categoria_activo']?.toString() ?? '', cellStyle),
                _cell(snap['id_area_activo']?.toString() ?? '', cellStyle),
                _cell(fecha, cellStyle),
              ],
            );
          }),
        ],
      ),
    ];
  }

  pw.Widget _cell(String text, pw.TextStyle style) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text, style: style),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── HEADER ───
        Container(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  color: Color(0xFFC62828), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Informes PDF',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ─── CONTENT ───
        Expanded(
          child: _loadingFilters
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SELECTOR DE TIPO DE INFORME
                    Container(
                      width: 280,
                      color: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _reportTypes.length,
                        itemBuilder: (_, i) {
                          final rt = _reportTypes[i];
                          final isSelected = _selectedReport == rt['id'];
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor:
                                const Color(0xFF1565C0).withOpacity(0.08),
                            leading: Icon(
                              rt['icon'] as IconData,
                              color: isSelected
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey,
                            ),
                            title: Text(
                              rt['label'] as String,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : null,
                              ),
                            ),
                            subtitle: Text(rt['desc'] as String,
                                style: const TextStyle(fontSize: 11)),
                            onTap: () => setState(
                                () => _selectedReport = rt['id'] as String),
                          );
                        },
                      ),
                    ),
                    const VerticalDivider(width: 1),

                    // CONFIGURACIÓN Y BOTÓN
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _reportTypes.firstWhere(
                                      (r) => r['id'] == _selectedReport)['label']
                                  as String,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _reportTypes.firstWhere(
                                  (r) => r['id'] == _selectedReport)['desc'] as String,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 24),

                            // FILTROS OPCIONALES
                            if (_selectedReport == 'por_area')
                              _buildDropdown(
                                'Área',
                                _selectedArea,
                                _areas,
                                'area',
                                (v) => setState(() => _selectedArea = v),
                              ),
                            if (_selectedReport == 'por_sede')
                              _buildDropdown(
                                'Sede',
                                _selectedSede,
                                _sedes,
                                'sede',
                                (v) => setState(() => _selectedSede = v),
                              ),
                            if (_selectedReport == 'por_condicion')
                              _buildDropdown(
                                'Condición',
                                _selectedCondicion,
                                _condiciones,
                                'condicion',
                                (v) => setState(() => _selectedCondicion = v),
                              ),
                            if (_selectedReport == 'por_tipo')
                              _buildDropdown(
                                'Tipo de Activo',
                                _selectedTipo,
                                _tipos,
                                'tipo',
                                (v) => setState(() => _selectedTipo = v),
                              ),

                            const Spacer(),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isGenerating ? null : _generateReport,
                                icon: _isGenerating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.picture_as_pdf_rounded),
                                label: Text(_isGenerating
                                    ? 'Generando informe...'
                                    : 'Generar y Previsualizar PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC62828),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<Map<String, dynamic>> items,
    String displayKey,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos')),
          ...items.map((item) => DropdownMenuItem(
                value: item['id'].toString(),
                child: Text(item[displayKey]?.toString() ?? ''),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}


