import 'package:flutter/material.dart';
import 'package:front_inventarios/components/side_menu.dart';
import 'package:front_inventarios/pages/asset_management_page.dart';
import 'package:front_inventarios/pages/maintenance_page.dart';
import 'package:front_inventarios/pages/admin/admin_tables_page.dart';
import 'package:front_inventarios/pages/admin/admin_users_page.dart';
import 'package:front_inventarios/main.dart';

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
    _HomePage(
      onNavigateToAssets: () => setState(() => _currentPageIndex = 1),
    ),
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

/// Widget para la página principal (Dashboard)
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
      final response = await supabase
          .from('activo')
          .select('id');

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel de Control',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildStatCard(
                  context,
                  title: 'Total de Activos',
                  value: _totalAssets.toString(),
                  icon: Icons.computer,
                  color: Colors.blue.shade800,
                ),
          const SizedBox(height: 32),
          const Text(
            'Acciones Rápidas',
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
                title: 'Ver Activos',
                icon: Icons.list_alt,
                onTap: widget.onNavigateToAssets,
              ),
              _buildActionCard(
                context,
                title: 'Nuevo Activo',
                icon: Icons.add_circle_outline,
                onTap: () {
                  widget.onNavigateToAssets();
                  // Ideally, a state management solution could command the list
                  // view to open the dialogue. For now users can navigate to the page
                  // and manually click the add button. 
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue.shade600),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

