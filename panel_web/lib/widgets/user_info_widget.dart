import 'package:flutter/material.dart';
import 'package:panel_web/auth/role_service.dart';
import 'package:panel_web/auth/auth_service.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    String roleText;
    Color badgeColor;

    switch (RoleService.currentRole) {
      case UserRole.admin:
        roleText = 'ADMIN';
        badgeColor = Colors.orange;
        break;
      case UserRole.ti:
        roleText = 'TI';
        badgeColor = Colors.green;
        break;
      default:
        roleText = 'N/A';
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
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

class UserInfoWidget extends StatelessWidget {
  final bool compact;

  const UserInfoWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final name = user?.userMetadata?['full_name']?.toString() ??
        user?.email?.split('@')[0] ??
        'Usuario';
    final email = user?.email ?? '';

    if (compact) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const RoleBadge(),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              const RoleBadge(),
            ],
          ),
        ),
      ],
    );
  }
}


