import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:panel_web/exceptions/app_exceptions.dart';

/// Roles permitidos en el panel web.
/// prestamo y ayudante no tienen acceso.
enum UserRole { admin, ti, unknown }

class RoleService {
  static final ValueNotifier<UserRole?> _currentRoleNotifier =
      ValueNotifier<UserRole?>(null);

  static ValueNotifier<UserRole?> get notifier => _currentRoleNotifier;
  static UserRole get currentRole =>
      _currentRoleNotifier.value ?? UserRole.unknown;

  /// Obtiene el rol del usuario desde Supabase.
  /// Lanza [AccessDeniedException] si el rol es prestamo o ayudante.
  static Future<void> fetchAndSetUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('usuario_rol')
          .select('rol(nombre)')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['rol'] != null) {
        final roleName = response['rol']['nombre']?.toString().toUpperCase();

        // Bloquear roles no permitidos en el panel web
        if (roleName == 'PRESTAMO' || roleName == 'AYUDANTE') {
          await Supabase.instance.client.auth.signOut();
          _currentRoleNotifier.value = UserRole.unknown;
          throw const AccessDeniedException(
            'Acceso denegado. Este panel es exclusivo para Administradores y personal de TI.',
          );
        }

        _assignRole(roleName);
      } else {
        _currentRoleNotifier.value = UserRole.unknown;
      }
    } on AccessDeniedException {
      rethrow;
    } catch (e) {
      _currentRoleNotifier.value = UserRole.unknown;
      rethrow;
    }
  }

  static UserRole roleFromName(String? roleName) {
    if (roleName == null) return UserRole.unknown;
    switch (roleName.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'TI':
        return UserRole.ti;
      default:
        return UserRole.unknown;
    }
  }

  static void _assignRole(String? roleName) {
    _currentRoleNotifier.value = roleFromName(roleName);
  }

  static Future<void> clearRole() async {
    _currentRoleNotifier.value = null;
  }

  /// Nombre legible del rol actual
  static String get currentRoleName {
    switch (currentRole) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.ti:
        return 'TI';
      case UserRole.unknown:
        return 'Sin rol';
    }
  }
}


