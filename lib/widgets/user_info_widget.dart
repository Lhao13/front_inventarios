import 'package:flutter/material.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/auth/auth_service.dart';

/// Un badge que muestra el rol del usuario con colores distintivos.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    String roleText = 'Desconocido';
    Color badgeColor = Colors.grey;

    switch (RoleService.currentRole) {
      case UserRole.admin:
        roleText = 'ADMIN';
        badgeColor = Colors.orange;
        break;
      case UserRole.ti:
        roleText = 'TI';
        badgeColor = Colors.green;
        break;
      case UserRole.ayudante:
        roleText = 'PRESTAMO';
        badgeColor = Colors.purple;
        break;
      case UserRole.unknown:
        roleText = 'N/A';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        roleText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget que muestra el nombre del usuario y su badge de rol.
/// Ideal para encabezados de menú o dashboards.
class UserInfoWidget extends StatelessWidget {
  final Color textColor;
  final CrossAxisAlignment crossAxisAlignment;

  const UserInfoWidget({
    super.key,
    this.textColor = Colors.white,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    // Intentar obtener el nombre del metadata, si no, usar el email
    String name =
        user?.userMetadata?['full_name']?.toString() ??
        user?.email?.split('@')[0] ??
        'Usuario';

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Nombre: $name',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        const RoleBadge(),
      ],
    );
  }
}
