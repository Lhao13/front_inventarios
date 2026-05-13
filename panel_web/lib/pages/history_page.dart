import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  const Icon(Icons.history_rounded,
                      color: Color(0xFF00695C), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Historial de Activos',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF00695C),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF00695C),
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.timeline_rounded), text: 'Historial por Activo'),
                  Tab(icon: Icon(Icons.delete_sweep_rounded), text: 'Activos Eliminados'),
                ],
              ),
            ],
          ),
        ),

        // ─── CONTENT ───
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _ActiveHistoryTab(),
              _DeletedAssetsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB 1: HISTORIAL POR ACTIVO ACTIVO
// ──────────────────────────────────────────────────────────────────────────────
class _ActiveHistoryTab extends StatefulWidget {
  const _ActiveHistoryTab();

  @override
  State<_ActiveHistoryTab> createState() => _ActiveHistoryTabState();
}

class _ActiveHistoryTabState extends State<_ActiveHistoryTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedAsset;
  List<Map<String, dynamic>> _history = [];
  bool _isSearching = false;
  bool _isLoadingHistory = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) return;
    setState(() => _isSearching = true);
    try {
      final res = await Supabase.instance.client
          .from('activo')
          .select('id, nombre, codigo, numero_serie, categoria_activo')
          .or('nombre.ilike.%$query%,codigo.ilike.%$query%,numero_serie.ilike.%$query%')
          .limit(20);
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(res);
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadHistory(Map<String, dynamic> asset) async {
    setState(() {
      _selectedAsset = asset;
      _isLoadingHistory = true;
      _history = [];
      _searchResults = [];
      _searchCtrl.clear();
    });
    try {
      final res = await Supabase.instance.client
          .from('historial_activo')
          .select('id, tipo_operacion, timestamp_changed_at, user_on_change, snapshot_json')
          .eq('id_activo', asset['id'])
          .neq('tipo_operacion', 'DELETE')
          .order('timestamp_changed_at', ascending: false);

      if (mounted) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(res);
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // PANEL IZQUIERDO: búsqueda
        Container(
          width: 320,
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar activo (nombre, código, serie)...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _search,
                ),
              ),
              if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final a = _searchResults[i];
                      return ListTile(
                        leading: const Icon(Icons.inventory_2_outlined,
                            size: 20),
                        title: Text(a['nombre']?.toString() ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${a['codigo'] ?? ''} · ${a['categoria_activo'] ?? ''}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => _loadHistory(a),
                      );
                    },
                  ),
                )
              else if (_selectedAsset != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF00695C).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Activo seleccionado:',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF00695C))),
                        const SizedBox(height: 4),
                        Text(
                          _selectedAsset!['nombre']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _selectedAsset!['codigo']?.toString() ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedAsset = null),
                          child: const Text('Cambiar activo →',
                              style: TextStyle(
                                  color: Color(0xFF00695C), fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Busca un activo para\nver su historial',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),

        // PANEL DERECHO: timeline
        Expanded(
          child: _selectedAsset == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline_rounded,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Selecciona un activo para ver su historial',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? const Center(
                          child: Text('No hay historial para este activo.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _history.length,
                          itemBuilder: (_, i) {
                            return _HistoryItem(
                              record: _history[i],
                              isLast: i == _history.length - 1,
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB 2: ACTIVOS ELIMINADOS
// ──────────────────────────────────────────────────────────────────────────────
class _DeletedAssetsTab extends StatefulWidget {
  const _DeletedAssetsTab();

  @override
  State<_DeletedAssetsTab> createState() => _DeletedAssetsTabState();
}

class _DeletedAssetsTabState extends State<_DeletedAssetsTab> {
  List<Map<String, dynamic>> _deletedAssets = [];
  bool _isLoading = true;
  Map<String, dynamic>? _expandedId;
  List<Map<String, dynamic>> _expandedHistory = [];
  bool _loadingExpandedHistory = false;

  @override
  void initState() {
    super.initState();
    _loadDeleted();
  }

  Future<void> _loadDeleted() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('historial_activo')
          .select('id, id_activo, timestamp_changed_at, user_on_change, snapshot_json')
          .eq('tipo_operacion', 'DELETE')
          .order('timestamp_changed_at', ascending: false);

      if (mounted) {
        setState(() {
          _deletedAssets = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExpandedHistory(String activoId) async {
    setState(() => _loadingExpandedHistory = true);
    try {
      final res = await Supabase.instance.client
          .from('historial_activo')
          .select('id, tipo_operacion, timestamp_changed_at, user_on_change')
          .eq('id_activo', activoId)
          .order('timestamp_changed_at', ascending: false);
      if (mounted) {
        setState(() {
          _expandedHistory = List<Map<String, dynamic>>.from(res);
          _loadingExpandedHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExpandedHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_deletedAssets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No hay activos eliminados registrados.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _deletedAssets.length,
      itemBuilder: (_, i) {
        final record = _deletedAssets[i];
        final snap = record['snapshot_json'] as Map<String, dynamic>? ?? {};
        final nombre = snap['nombre']?.toString() ?? 'Sin nombre';
        final codigo = snap['codigo']?.toString() ?? '';
        final categoria = snap['categoria_activo']?.toString() ?? '';
        final fecha = record['timestamp_changed_at'] != null
            ? DateFormat('dd/MM/yyyy HH:mm')
                .format(DateTime.parse(record['timestamp_changed_at']))
            : 'Desconocida';
        final userId = record['user_on_change']?.toString();
        final isExpanded = _expandedId?['id'] == record['id'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.red, size: 20),
                ),
                title: Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (codigo.isNotEmpty) Text('Código: $codigo'),
                    Text('Categoría: $categoria'),
                    Text('Eliminado el: $fecha',
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                    if (userId != null)
                      Text(
                        'Por usuario: $userId',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    if (isExpanded) {
                      setState(() {
                        _expandedId = null;
                        _expandedHistory = [];
                      });
                    } else {
                      setState(() => _expandedId = record);
                      _loadExpandedHistory(record['id_activo']?.toString() ?? '');
                    }
                  },
                  tooltip: isExpanded ? 'Ocultar historial' : 'Ver historial completo',
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                if (_loadingExpandedHistory)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Historial completo:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        ..._expandedHistory.map((h) {
                          final hFecha = h['timestamp_changed_at'] != null
                              ? DateFormat('dd/MM/yyyy HH:mm')
                                  .format(DateTime.parse(h['timestamp_changed_at']))
                              : '';
                          final hUser = h['user_on_change']?.toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                _operationChip(h['tipo_operacion'] as String?),
                                const SizedBox(width: 10),
                                Text(hFecha,
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 10),
                                if (hUser != null)
                                  Text(
                                    'Usuario: $hUser',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// WIDGET: Item de historial en timeline
// ──────────────────────────────────────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool isLast;

  const _HistoryItem({required this.record, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final op = record['tipo_operacion'] as String? ?? '';
    final fecha = record['timestamp_changed_at'] != null
        ? DateFormat('dd/MM/yyyy HH:mm')
            .format(DateTime.parse(record['timestamp_changed_at']))
        : 'Fecha desconocida';
    final userId = record['user_on_change']?.toString();
    final snap = record['snapshot_json'] as Map<String, dynamic>? ?? {};

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIMELINE LINE
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _opColor(op).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _opColor(op), width: 2),
                ),
                child: Icon(_opIcon(op), size: 16, color: _opColor(op)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // CARD
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _operationChip(op),
                      const SizedBox(width: 12),
                      Text(
                        fecha,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  if (userId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Usuario: $userId',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                  if (snap.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (snap['nombre'] != null)
                          _snapField('Nombre', snap['nombre']),
                        if (snap['codigo'] != null)
                          _snapField('Código', snap['codigo']),
                        if (snap['numero_serie'] != null)
                          _snapField('Serie', snap['numero_serie']),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapField(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value.toString(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _opColor(String op) {
    switch (op.toUpperCase()) {
      case 'INSERT':
        return const Color(0xFF2E7D32);
      case 'UPDATE':
        return const Color(0xFF1565C0);
      case 'DELETE':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  IconData _opIcon(String op) {
    switch (op.toUpperCase()) {
      case 'INSERT':
        return Icons.add_circle_outline_rounded;
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'DELETE':
        return Icons.delete_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}

Widget _operationChip(String? op) {
  Color color;
  String label;
  switch ((op ?? '').toUpperCase()) {
    case 'INSERT':
      color = const Color(0xFF2E7D32);
      label = 'Creado';
      break;
    case 'UPDATE':
      color = const Color(0xFF1565C0);
      label = 'Actualizado';
      break;
    case 'DELETE':
      color = const Color(0xFFC62828);
      label = 'Eliminado';
      break;
    default:
      color = Colors.grey;
      label = op ?? '';
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}


