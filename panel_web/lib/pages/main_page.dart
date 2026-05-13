import 'package:flutter/material.dart';
import 'package:panel_web/components/side_menu.dart';
import 'package:panel_web/pages/home_page.dart';
import 'package:panel_web/pages/asset_management_page.dart';
import 'package:panel_web/pages/maintenance_page.dart';
import 'package:panel_web/pages/statistics_page.dart';
import 'package:panel_web/pages/reports_page.dart';
import 'package:panel_web/pages/history_page.dart';
import 'package:panel_web/pages/admin/admin_tables_page.dart';
import 'package:panel_web/pages/admin/admin_users_page.dart';
import 'package:panel_web/auth/role_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _currentSection = WebSection.home;
  final GlobalKey<ScaffoldState> _assetScaffoldKey =
      GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _maintenanceScaffoldKey =
      GlobalKey<ScaffoldState>();

  void navigateTo(int section) {
    setState(() => _currentSection = section);
  }

  Widget _buildCurrentPage() {
    final role = RoleService.currentRole;
    final isTiOrAdmin = role == UserRole.admin || role == UserRole.ti;
    final isAdmin = role == UserRole.admin;

    switch (_currentSection) {
      case WebSection.home:
        return HomePage(onNavigate: navigateTo);
      case WebSection.assets:
        return AssetManagementPage(scaffoldKey: _assetScaffoldKey);
      case WebSection.maintenance:
        if (!isTiOrAdmin) return _buildAccessDenied();
        return MaintenancePage(scaffoldKey: _maintenanceScaffoldKey);
      case WebSection.statistics:
        if (!isTiOrAdmin) return _buildAccessDenied();
        return const StatisticsPage();
      case WebSection.reports:
        if (!isTiOrAdmin) return _buildAccessDenied();
        return const ReportsPage();
      case WebSection.history:
        if (!isTiOrAdmin) return _buildAccessDenied();
        return const HistoryPage();
      case WebSection.adminTables:
        if (!isAdmin) return _buildAccessDenied();
        return const AdminTablesPage();
      case WebSection.adminUsers:
        if (!isAdmin) return _buildAccessDenied();
        return const AdminUsersPage();
      default:
        return HomePage(onNavigate: navigateTo);
    }
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_outline_rounded, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Acceso Denegado',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('No tienes permisos para acceder a esta sección.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ─── SIDEBAR FIJO ───
          WebSidebar(
            currentSection: _currentSection,
            onSectionSelected: (index) => setState(() => _currentSection = index),
          ),

          // ─── CONTENIDO PRINCIPAL ───
          Expanded(
            child: Container(
              color: const Color(0xFFF0F2F5),
              child: _buildCurrentPage(),
            ),
          ),
        ],
      ),
    );
  }
}



