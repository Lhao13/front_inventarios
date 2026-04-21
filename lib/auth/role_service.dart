import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

enum UserRole { admin, ti, ayudante, unknown }

class RoleService {
  static final ValueNotifier<UserRole?> _currentRoleNotifier = ValueNotifier<UserRole?>(null);

  /// Reactivo. Los componentes pueden hacer `ValueListenableBuilder<UserRole?>`(valueListenable: RoleService.notifier, ...)
  static ValueNotifier<UserRole?> get notifier => _currentRoleNotifier;

  static UserRole get currentRole => _currentRoleNotifier.value ?? UserRole.unknown;

  /// Define el rol del usuario después del login o en el inicio de la app
  static Future<void> fetchAndSetUserRole(String userId) async {
    try {
      // Intentar leer de Supabase (Online)
      final response = await Supabase.instance.client
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
        _currentRoleNotifier.value = UserRole.unknown;
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
          _currentRoleNotifier.value = UserRole.unknown;
        }
      } catch (_) {
        _currentRoleNotifier.value = UserRole.unknown;
      }
    }
  }

  static UserRole roleFromName(String? roleName) {
    if (roleName == null) {
      return UserRole.unknown;
    }

    switch (roleName.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'TI':
        return UserRole.ti;
      case 'PRESTAMO':
        return UserRole.ayudante;
      default:
        return UserRole.unknown;
    }
  }

  static void _assignRole(String? roleName) {
    _currentRoleNotifier.value = roleFromName(roleName);
  }

  /// Limpiar rol en el logout
  static Future<void> clearRole() async {
    _currentRoleNotifier.value = null;
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
