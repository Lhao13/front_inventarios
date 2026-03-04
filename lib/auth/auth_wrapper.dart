import 'package:flutter/material.dart';
import 'package:front_inventarios/auth/auth_service.dart';

/// Widget que maneja la navegación basada en el estado de autenticación. 
/// Este widget verifica si el usuario tiene una sesión activa y lo redirige

class AuthWrapper extends StatelessWidget {
  /// Página a mostrar cuando el usuario está autenticado
  final Widget authenticatedPage;

  /// Página a mostrar cuando el usuario no está autenticado
  final Widget unauthenticatedPage;

  const AuthWrapper({
    super.key,
    required this.authenticatedPage,
    required this.unauthenticatedPage,
  });

  @override
  Widget build(BuildContext context) {
    // Verificar si el usuario está autenticado
    if (AuthService.isUserLoggedIn()) {
      return authenticatedPage;
    } else {
      return unauthenticatedPage;
    }
  }
}
