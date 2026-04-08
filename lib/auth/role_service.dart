import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:sqflite/sqflite.dart';

enum UserRole { admin, ti, ayudante, unknown }

class RoleService {
  static UserRole? _currentRole;

  static UserRole get currentRole => _currentRole ?? UserRole.unknown;

  /// Define el rol del usuario después del login o en el inicio de la app
  static Future<void> fetchAndSetUserRole(String userId) async {
    try {
      // Intentar leer de Supabase (Online)
      final response = await supabase
          .from('usuario_rol')
          .select('rol(nombre)')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['rol'] != null) {
        final roleName = response['rol']['nombre']?.toString().toUpperCase();
        _assignRole(roleName);
        
        // Guardar el rol en caché para cuando estemos offline
        final db = await LocalDbService.instance.database;
        await db.insert(
          'cache_storage',
          {
            'collection': 'auth_config',
            'id': 'user_role',
            'json_data': roleName,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        _currentRole = UserRole.unknown;
      }
    } catch (e) {
      // Modo Offline: Si falla Supabase, recuperamos de Sqflite
      try {
        final db = await LocalDbService.instance.database;
        final res = await db.query(
          'cache_storage',
          where: 'collection = ? AND id = ?',
          whereArgs: ['auth_config', 'user_role'],
        );
        if (res.isNotEmpty) {
          final roleName = res.first['json_data'] as String?;
          _assignRole(roleName);
        } else {
          _currentRole = UserRole.unknown;
        }
      } catch (_) {
        _currentRole = UserRole.unknown;
      }
    }
  }

  static void _assignRole(String? roleName) {
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
  }

  /// Limpiar rol en el logout
  static Future<void> clearRole() async {
    _currentRole = null;
    try {
      final db = await LocalDbService.instance.database;
      await db.delete(
        'cache_storage',
        where: 'collection = ? AND id = ?',
        whereArgs: ['auth_config', 'user_role'],
      );
    } catch (_) {}
  }
}
