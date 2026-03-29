import 'package:flutter/material.dart';
import 'package:front_inventarios/components/side_menu.dart';
import 'package:front_inventarios/pages/asset_management_page.dart';
import 'package:front_inventarios/pages/maintenance_page.dart';
import 'package:front_inventarios/pages/admin/admin_tables_page.dart';
import 'package:front_inventarios/pages/admin/admin_users_page.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/widgets/barcode_scanner_screen.dart';
import 'package:front_inventarios/pages/quick_search_result_page.dart';
import 'package:front_inventarios/pages/assets/pc_assets_page.dart';
import 'package:front_inventarios/pages/assets/communication_assets_page.dart';
import 'package:front_inventarios/pages/assets/generic_assets_page.dart';
import 'package:front_inventarios/pages/assets/software_assets_page.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';

/// Página principal de la aplicación.
///
/// Esta es la página que se muestra cuando el usuario ha iniciado sesión
/// correctamente y sus credenciales son válidas.
/// Contiene un menú lateral (drawer) con opciones de navegación.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  /// Índice de la página actual
  int _currentPageIndex = 0;

  /// Lista de páginas disponibles
  late final List<Widget> _pages = [
    _HomePage(onNavigateToAssets: () => setState(() => _currentPageIndex = 1)),
    const AssetManagementPage(),
    const MaintenancePage(),
    const AdminTablesPage(),
    const AdminUsersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Inventarios'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: SyncQueueService.instance.isOnlineNotifier,
            builder: (context, isOnline, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: SyncQueueService.instance.isSyncingNotifier,
                builder: (context, isSyncing, _) {
                  if (!isOnline) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Offline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  } else if (isSyncing) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                          SizedBox(width: 8),
                          Text('Sincronizando...', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_done, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Online', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),

      /// Drawer (menú lateral)
      drawer: SideMenu(
        currentPageIndex: _currentPageIndex,
        onPageSelected: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
      ),

      /// Cuerpo: muestra la página actual según el índice
      body: _pages[_currentPageIndex],
    );
  }
}

class _HomePage extends StatefulWidget {
  final VoidCallback onNavigateToAssets;

  const _HomePage({required this.onNavigateToAssets});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _totalAssets = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await supabase.from('activo').select('id');
      if (mounted) {
        setState(() {
          _totalAssets = (response as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleQuickSearch(bool isOnlyNumeric) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(isOnlyNumeric: isOnlyNumeric),
      ),
    );
    if (result != null && result is String) {
      if (!mounted) return;
      // Navegar a la página de resultados de búsqueda rápida
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuickSearchResultPage(
            searchValue: result,
            isNumericCode: isOnlyNumeric,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECCIÓN 1: STATS HEADER
          const Text(
            'Panel de Control',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildStatCard(
                  context,
                  title: 'Total de Activos Registrados',
                  value: _totalAssets.toString(),
                  icon: Icons.inventory_2_rounded,
                  color: Colors.blue.shade800,
                ),
          const SizedBox(height: 32),

          // SECCIÓN 2: MENÚ DE NAVEGACIÓN (MÓDULOS) POR ROLES
          const Text(
            'Módulos Principales',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard(
                context,
                title: 'Gestión de Activos',
                icon: Icons.inventory,
                onTap: widget.onNavigateToAssets,
              ),
              if (RoleService.currentRole != UserRole.ayudante)
                _buildActionCard(
                  context,
                  title: 'Mantenimientos',
                  icon: Icons.build_circle,
                  onTap: () {
                    // Navigate to maintenance. It's index 2 in main_page.dart
                    final mainPageState = context
                        .findAncestorStateOfType<_MainPageState>();
                    mainPageState?.setState(() {
                      mainPageState._currentPageIndex = 2;
                    });
                  },
                ),
              if (RoleService.currentRole == UserRole.admin) ...[
                _buildActionCard(
                  context,
                  title: 'Tablas Maestras',
                  icon: Icons.settings,
                  onTap: () {
                    final mainPageState = context
                        .findAncestorStateOfType<_MainPageState>();
                    mainPageState?.setState(() {
                      mainPageState._currentPageIndex = 3;
                    });
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Usuarios',
                  icon: Icons.group,
                  onTap: () {
                    final mainPageState = context
                        .findAncestorStateOfType<_MainPageState>();
                    mainPageState?.setState(() {
                      mainPageState._currentPageIndex = 4;
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // SECCIÓN 3: CATEGORÍAS DE ACTIVOS
          const Text(
            'Categorías de Clasificación de activos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCategoryCard(
            context,
            title: 'PC',
            description:
                'Computadoras de escritorio, laptops y equipos de cómputo.',
            icon: Icons.computer,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PcAssetsPage()),
            ),
          ),
          _buildCategoryCard(
            context,
            title: 'Software',
            description: 'Licencias y aplicaciones de software registradas.',
            icon: Icons.developer_board,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SoftwareAssetsPage()),
            ),
          ),
          _buildCategoryCard(
            context,
            title: 'Comunicación',
            description: 'Routers, switches, teléfonos y equipos de red.',
            icon: Icons.router,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommsAssetsPage()),
            ),
          ),
          _buildCategoryCard(
            context,
            title: 'Genérico',
            description: 'Otros equipos, monitores, impresoras y dispositivos.',
            icon: Icons.devices_other,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GenericAssetsPage()),
            ),
          ),
          const SizedBox(height: 32),

          // SECCIÓN 4: BÚSQUEDA RÁPIDA (BARCODE / QR)
          const Text(
            'Búsqueda Rápida',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickSearchCard(
                  context,
                  title: 'Por Número de Serie',
                  subtitle: 'Escanea el SN',
                  icon: Icons.qr_code_scanner,
                  color: Colors.indigo,
                  onTap: () => _handleQuickSearch(false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickSearchCard(
                  context,
                  title: 'Por Código',
                  subtitle: 'Escanea el ID',
                  icon: Icons.document_scanner,
                  color: Colors.indigo,
                  onTap: () => _handleQuickSearch(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withBlue(color.blue + 50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.white),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 32, color: Colors.blueGrey.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickSearchCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
