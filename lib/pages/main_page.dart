import 'package:flutter/material.dart';
import 'package:front_inventarios/components/side_menu.dart';
import 'package:front_inventarios/pages/asset_management_page.dart';
import 'package:front_inventarios/pages/maintenance_page.dart';

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
    const _HomePage(),
    const AssetManagementPage(),
    const MaintenancePage(),
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

/// Widget para la página principal
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory,
            size: 64,
            color: Colors.blue.shade800,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bienvenido a la aplicación',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'de Gestión de Inventarios',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Abrir el drawer
              Scaffold.of(context).openDrawer();
            },
            child: const Text('Abrir Menú'),
          ),
        ],
      ),
    );
  }
}

