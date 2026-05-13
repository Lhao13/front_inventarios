import 'package:flutter/material.dart';
import 'package:panel_web/auth/role_service.dart';
import 'package:panel_web/auth/auth_service.dart';
import 'package:panel_web/pages/login_page.dart';
import 'package:panel_web/widgets/user_info_widget.dart';

/// Índices de sección del panel web
class WebSection {
  static const int home = 0;
  static const int assets = 1;
  static const int maintenance = 2;
  static const int statistics = 3;
  static const int reports = 4;
  static const int history = 5;
  static const int adminTables = 6;
  static const int adminUsers = 7;
}

class WebSidebar extends StatelessWidget {
  final int currentSection;
  final ValueChanged<int> onSectionSelected;

  const WebSidebar({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final role = RoleService.currentRole;
    final isAdmin = role == UserRole.admin;
    final isTiOrAdmin = role == UserRole.admin || role == UserRole.ti;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        boxShadow: [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── LOGO / HEADER ───
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E3A5F), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'InventarioSys',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const UserInfoWidget(),
              ],
            ),
          ),

          // ─── NAV ITEMS ───
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarSection(label: 'PRINCIPAL'),
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Inicio',
                  index: WebSection.home,
                  current: currentSection,
                  onTap: onSectionSelected,
                ),
                _SidebarItem(
                  icon: Icons.inventory_rounded,
                  label: 'Gestión de Activos',
                  index: WebSection.assets,
                  current: currentSection,
                  onTap: onSectionSelected,
                ),
                if (isTiOrAdmin)
                  _SidebarItem(
                    icon: Icons.build_circle_rounded,
                    label: 'Mantenimientos',
                    index: WebSection.maintenance,
                    current: currentSection,
                    onTap: onSectionSelected,
                  ),

                _SidebarSection(label: 'ANÁLISIS'),
                if (isTiOrAdmin) ...[
                  _SidebarItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Estadísticas',
                    index: WebSection.statistics,
                    current: currentSection,
                    onTap: onSectionSelected,
                  ),
                  _SidebarItem(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Informes PDF',
                    index: WebSection.reports,
                    current: currentSection,
                    onTap: onSectionSelected,
                  ),
                  _SidebarItem(
                    icon: Icons.history_rounded,
                    label: 'Historial',
                    index: WebSection.history,
                    current: currentSection,
                    onTap: onSectionSelected,
                  ),
                ],

                if (isAdmin) ...[
                  _SidebarSection(label: 'ADMINISTRACIÓN'),
                  _SidebarItem(
                    icon: Icons.table_chart_rounded,
                    label: 'Tablas Maestras',
                    index: WebSection.adminTables,
                    current: currentSection,
                    onTap: onSectionSelected,
                  ),
                  _SidebarItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Usuarios',
                    index: WebSection.adminUsers,
                    current: currentSection,
                    onTap: onSectionSelected,
                  ),
                ],
              ],
            ),
          ),

          // ─── LOGOUT ───
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1E3A5F), width: 1),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF5350), size: 20),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Deseas cerrar la sesión actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              RoleService.clearRole();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF546E7A),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.current;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1565C0)
                : _hovering
                    ? const Color(0xFF1E3A5F)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : _hovering
                        ? Colors.white70
                        : const Color(0xFF90A4AE),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : _hovering
                            ? Colors.white70
                            : const Color(0xFF90A4AE),
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


