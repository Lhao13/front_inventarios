import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panel_web/auth/role_service.dart';
import 'package:panel_web/components/side_menu.dart';
import 'package:panel_web/pages/assets/pc_assets_page.dart';
import 'package:panel_web/pages/assets/communication_assets_page.dart';
import 'package:panel_web/pages/assets/generic_assets_page.dart';
import 'package:panel_web/pages/assets/software_assets_page.dart';
import 'package:panel_web/widgets/user_info_widget.dart';

class HomePage extends StatefulWidget {
  final void Function(int) onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _totalAssets = 0;
  int _totalMaintenance = 0;
  bool _isLoading = true;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      final results = await Future.wait([
        Supabase.instance.client.from('activo').select('id'),
        Supabase.instance.client.from('mantenimiento').select('id'),
      ]);
      if (mounted) {
        setState(() {
          _totalAssets = (results[0] as List).length;
          _totalMaintenance = (results[1] as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = RoleService.currentRole;
    final isAdmin = role == UserRole.admin;
    final isTiOrAdmin = role == UserRole.admin || role == UserRole.ti;

    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ───
            _buildPageHeader(),
            const SizedBox(height: 28),

            // ─── KPI CARDS ───
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildKpiRow(isTiOrAdmin),
            const SizedBox(height: 36),

            // ─── GESTIÓN DE ACTIVOS ───
            _sectionTitle('Gestión de Activos', 'Administra el inventario por categoría'),
            const SizedBox(height: 16),
            _buildAssetGrid(context),
            const SizedBox(height: 36),

            // ─── OPERACIÓN Y CONTROL ───
            if (isTiOrAdmin) ...[
              _sectionTitle('Operación y Control', 'Accesos rápidos a funciones clave'),
              const SizedBox(height: 16),
              _buildQuickAccessGrid(context, isTiOrAdmin, isAdmin),
              const SizedBox(height: 36),
            ],

            // ─── ADMINISTRACIÓN ───
            if (isAdmin) ...[
              _sectionTitle('Panel Administrativo', 'Configuración y usuarios del sistema'),
              const SizedBox(height: 16),
              _buildAdminGrid(context),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel de Control',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sistema de Inventarios',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const UserInfoWidget(compact: true),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(bool isTiOrAdmin) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Total Activos',
            value: '$_totalAssets',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 16),
        if (isTiOrAdmin) ...[
          Expanded(
            child: _KpiCard(
              label: 'Mantenimientos',
              value: '$_totalMaintenance',
              icon: Icons.build_circle_rounded,
              color: const Color(0xFFE65100),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: _KpiCard(
            label: 'Rol Actual',
            value: RoleService.currentRoleName,
            icon: Icons.badge_rounded,
            color: const Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 3.5,
      children: [
        _DashboardCard(
          title: 'Activos Globales',
          subtitle: 'Ver todo el inventario',
          icon: Icons.inventory_rounded,
          color: const Color(0xFF1565C0),
          highlighted: true,
          onTap: () => widget.onNavigate(WebSection.assets),
        ),
        _DashboardCard(
          title: 'Equipos PC',
          subtitle: 'Laptops, desktops y servidores',
          icon: Icons.computer_rounded,
          color: const Color(0xFF455A64),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PcAssetsPage()),
          ),
        ),
        _DashboardCard(
          title: 'Software y Licencias',
          subtitle: 'Aplicaciones y registros digitales',
          icon: Icons.developer_board_rounded,
          color: const Color(0xFF455A64),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SoftwareAssetsPage()),
          ),
        ),
        _DashboardCard(
          title: 'Comunicaciones',
          subtitle: 'Red, telefonía y conectividad',
          icon: Icons.router_rounded,
          color: const Color(0xFF455A64),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommsAssetsPage()),
          ),
        ),
        _DashboardCard(
          title: 'Activos Genéricos',
          subtitle: 'Otros dispositivos y periféricos',
          icon: Icons.devices_other_rounded,
          color: const Color(0xFF455A64),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GenericAssetsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, bool isTiOrAdmin, bool isAdmin) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 3,
      children: [
        _DashboardCard(
          title: 'Mantenimientos',
          subtitle: 'Agenda y programación',
          icon: Icons.build_circle_rounded,
          color: const Color(0xFFE65100),
          onTap: () => widget.onNavigate(WebSection.maintenance),
        ),
        _DashboardCard(
          title: 'Estadísticas',
          subtitle: 'Gráficos y análisis',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF6A1B9A),
          onTap: () => widget.onNavigate(WebSection.statistics),
        ),
        _DashboardCard(
          title: 'Informes PDF',
          subtitle: 'Exportar reportes',
          icon: Icons.picture_as_pdf_rounded,
          color: const Color(0xFFC62828),
          onTap: () => widget.onNavigate(WebSection.reports),
        ),
        _DashboardCard(
          title: 'Historial',
          subtitle: 'Registro de operaciones',
          icon: Icons.history_rounded,
          color: const Color(0xFF00695C),
          onTap: () => widget.onNavigate(WebSection.history),
        ),
      ],
    );
  }

  Widget _buildAdminGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 3,
      children: [
        _DashboardCard(
          title: 'Tablas Maestras',
          subtitle: 'Áreas, sedes, condiciones...',
          icon: Icons.table_chart_rounded,
          color: const Color(0xFF37474F),
          onTap: () => widget.onNavigate(WebSection.adminTables),
        ),
        _DashboardCard(
          title: 'Gestión de Usuarios',
          subtitle: 'Control de acceso y roles',
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFF37474F),
          onTap: () => widget.onNavigate(WebSection.adminUsers),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ─── KPI CARD ───
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── DASHBOARD CARD ───
class _DashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool highlighted;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.highlighted
                  ? widget.color
                  : _hovering
                      ? widget.color.withOpacity(0.4)
                      : Colors.transparent,
              width: widget.highlighted ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovering
                    ? widget.color.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _hovering ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: widget.highlighted
                            ? widget.color
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


