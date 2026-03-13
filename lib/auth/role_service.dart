import 'package:front_inventarios/main.dart';

enum UserRole { admin, ti, ayudante, unknown }

class RoleService {
  static UserRole? _currentRole;

  static UserRole get currentRole => _currentRole ?? UserRole.unknown;

  /// Define el rol del usuario después del login
  static Future<void> fetchAndSetUserRole(String userId) async {
    try {
      // Relación usuario_rol -> rol
      final response = await supabase
          .from('usuario_rol')
          .select('rol(nombre)')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['rol'] != null) {
        final roleName = response['rol']['nombre']?.toString().toUpperCase();
        switch (roleName) {
          case 'ADMIN':
            _currentRole = UserRole.admin;
            break;
          case 'TI':
            _currentRole = UserRole.ti;
            break;
          case 'PRESTAMO':
            _currentRole = UserRole.ayudante;
            break;
          default:
            _currentRole = UserRole.unknown;
        }
      } else {
        _currentRole = UserRole.unknown;
      }
    } catch (e) {
      _currentRole = UserRole.unknown;
    }
  }

  /// Limpiar rol en el logout
  static void clearRole() {
    _currentRole = null;
  }
}
