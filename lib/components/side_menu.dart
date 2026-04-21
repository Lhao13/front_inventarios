import 'package:flutter/material.dart';
import 'package:front_inventarios/auth/auth_service.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/pages/login_page.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/widgets/user_info_widget.dart';

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
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            /// Encabezado del drawer personalizado (full-bleed)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1465bd),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1465bd), Color(0xFF0d4586)],
                ),
              ),
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MENÚ PRINCIPAL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 20),
                      UserInfoWidget(),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
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

                  /// Elemento: Mantenimientos (Hidden for ayudante/PRESTADO)
                  if (RoleService.currentRole != UserRole.ayudante)
                    ListTile(
                      leading: const Icon(Icons.build),
                      title: const Text('Mantenimientos'),
                      selected: currentPageIndex == 2,
                      onTap: () {
                        onPageSelected(2);
                        Navigator.pop(context); // Cerrar drawer
                      },
                    ),

                  /// Elementos para ADMIN
                  if (RoleService.currentRole == UserRole.admin) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Administración',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Estado de activos'),
                      selected: currentPageIndex == 3,
                      onTap: () {
                        onPageSelected(3);
                        Navigator.pop(context); // Cerrar drawer
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.group),
                      title: const Text('Usuarios'),
                      selected: currentPageIndex == 4,
                      onTap: () {
                        onPageSelected(4);
                        Navigator.pop(context); // Cerrar drawer
                      },
                    ),
                  ],
                ],
              ),
            ),

            /// Elemento: Cerrar Sesión (al fondo)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
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
                              // Limpiar la caché local antes de cerrar sesión.
                              // Esto evita que el siguiente usuario vea datos del anterior
                              // mientras la nueva sesión descarga su propia caché.
                              await LocalDbService.instance.clearAll();

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
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
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
      ),
    );
  }
}
