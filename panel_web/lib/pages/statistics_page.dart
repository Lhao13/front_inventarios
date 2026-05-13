import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Datos agrupados
  Map<String, int> _byArea = {};
  Map<String, int> _byCity = {};
  Map<String, int> _byCondition = {};
  Map<String, int> _bySede = {};
  Map<String, int> _byType = {};
  int _totalAssets = 0;

  // Paleta de colores
  static const List<Color> _palette = [
    Color(0xFF1565C0),
    Color(0xFF00897B),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFF2E7D32),
    Color(0xFF00695C),
    Color(0xFF4527A0),
    Color(0xFF283593),
    Color(0xFF37474F),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('activo')
          .select(
            'id, id_area_activo, id_ciudad_activo, id_condicion_activo, id_sede_activo, id_tipo_activo,'
            'area_activo(area), ciudad_activo(ciudad), condicion_activo(condicion),'
            'sede_activo(sede), tipo_activo(tipo)',
          );

      final assets = List<Map<String, dynamic>>.from(data);
      _totalAssets = assets.length;

      _byArea = _groupBy(assets, (a) => a['area_activo']?['area'] as String?);
      _byCity = _groupBy(assets, (a) => a['ciudad_activo']?['ciudad'] as String?);
      _byCondition = _groupBy(assets, (a) => a['condicion_activo']?['condicion'] as String?);
      _bySede = _groupBy(assets, (a) => a['sede_activo']?['sede'] as String?);
      _byType = _groupBy(assets, (a) => a['tipo_activo']?['tipo'] as String?);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, int> _groupBy(
      List<Map<String, dynamic>> data, String? Function(Map) key) {
    final result = <String, int>{};
    for (final item in data) {
      final k = key(item) ?? 'Sin datos';
      result[k] = (result[k] ?? 0) + 1;
    }
    final sorted = Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── HEADER ───
        Container(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      color: Color(0xFF1565C0), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_totalAssets activos totales',
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Actualizar datos',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF1565C0),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1565C0),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Por Área'),
                  Tab(text: 'Por Ciudad'),
                  Tab(text: 'Por Condición'),
                  Tab(text: 'Por Sede'),
                  Tab(text: 'Por Tipo de Activo'),
                ],
              ),
            ],
          ),
        ),

        // ─── CONTENT ───
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _StatTab(
                        data: _byArea,
                        title: 'Distribución por Área',
                        palette: _palette),
                    _StatTab(
                        data: _byCity,
                        title: 'Distribución por Ciudad',
                        palette: _palette),
                    _StatTab(
                        data: _byCondition,
                        title: 'Distribución por Condición',
                        palette: _palette),
                    _StatTab(
                        data: _bySede,
                        title: 'Distribución por Sede',
                        palette: _palette),
                    _StatTab(
                        data: _byType,
                        title: 'Distribución por Tipo de Activo',
                        palette: _palette),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Tab individual con gráfico de barras + donut + tabla
class _StatTab extends StatelessWidget {
  final Map<String, int> data;
  final String title;
  final List<Color> palette;

  const _StatTab({
    required this.data,
    required this.title,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles.', style: TextStyle(color: Colors.grey)),
      );
    }

    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 20),
          // ─── GRÁFICOS ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BAR CHART
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  height: 320,
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gráfico de Barras',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (entries.first.value * 1.2).toDouble(),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final label = entries[group.x].key;
                                  return BarTooltipItem(
                                    '$label\n${rod.toY.toInt()}',
                                    const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= entries.length) {
                                      return const SizedBox();
                                    }
                                    final label = entries[idx].key;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        label.length > 8
                                            ? '${label.substring(0, 8)}…'
                                            : label,
                                        style: const TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: true, reservedSize: 28),
                              ),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            barGroups: entries.asMap().entries.map((e) {
                              final color =
                                  palette[e.key % palette.length];
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.value.toDouble(),
                                    color: color,
                                    width: 32,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // DONUT CHART
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  height: 320,
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Distribución (%)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 55,
                            sections: entries.asMap().entries.map((e) {
                              final pct = e.value.value / total * 100;
                              final color = palette[e.key % palette.length];
                              return PieChartSectionData(
                                value: e.value.value.toDouble(),
                                color: color,
                                radius: 50,
                                title: pct >= 5
                                    ? '${pct.toStringAsFixed(1)}%'
                                    : '',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── TABLA RESUMEN ───
          Container(
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: const Text(
                    'Detalle por categoría',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                const Divider(height: 1),
                ...entries.asMap().entries.map((e) {
                  final pct = e.value.value / total * 100;
                  final color = palette[e.key % palette.length];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(e.value.key,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${e.value.value}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: e.value.value / entries.first.value,
                                color: color,
                                backgroundColor: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 48,
                              child: Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (e.key < entries.length - 1)
                        const Divider(height: 1, indent: 44),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
}


