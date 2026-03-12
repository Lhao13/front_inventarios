import 'package:flutter/material.dart';
import 'package:front_inventarios/auth/auth_service.dart';
import 'package:front_inventarios/pages/login_page.dart';

/// Widget de menú lateral (Drawer) para la navegación principal de la aplicación.
/// 
/// Este componente proporciona acceso a todas las secciones de la aplicación
/// con opciones de cerrar sesión al fondo.
class SideMenu extends StatelessWidget {
  /// Índice de la página actualmente seleccionada
  final int currentPageIndex;

  /// Callback cuando se selecciona una página
  final Function(int) onPageSelected;

  const SideMenu({
    super.key,
    required this.currentPageIndex,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          /// Encabezado del drawer
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue, // Main blue color for header
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Menú Principal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Gestión de Inventarios',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          /// Elemento: Página Principal
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Página Principal'),
            selected: currentPageIndex == 0,
            onTap: () {
              onPageSelected(0);
              Navigator.pop(context); // Cerrar drawer
            },
          ),

          /// Elemento: Gestión de Activos
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Gestión de Activos'),
            selected: currentPageIndex == 1,
            onTap: () {
              onPageSelected(1);
              Navigator.pop(context); // Cerrar drawer
            },
          ),

          /// Elemento: Mantenimientos
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Mantenimientos'),
            selected: currentPageIndex == 2,
            onTap: () {
              onPageSelected(2);
              Navigator.pop(context); // Cerrar drawer
            },
          ),

          /// Separador visual
          const Divider(),

          /// Espaciador para empujar el botón de cerrar sesión al fondo
          const Spacer(),

          /// Elemento: Cerrar Sesión (al fondo)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              // Guardar referencias al Navigator antes de operaciones asincrónicas
              final navigator = Navigator.of(context);

              // Cerrar el drawer
              Navigator.pop(context);

              // Mostrar cuadro de diálogo de confirmación
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirmar'),
                    content: const Text('¿Deseas cerrar la sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Cerrar el diálogo usando el contexto del diálogo
                          Navigator.pop(dialogContext);

                          try {
                            // Cerrar sesión usando AuthService
                            await AuthService.signOut();

                            // Usar la referencia guardada del navigator
                            navigator.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error.toString()),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          /// Padding inferior
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
