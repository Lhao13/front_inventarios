import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
/// Servicio de autenticación para manejar validaciones de sesión de usuario.
/// 
/// Este servicio proporciona métodos para:
/// - Validar credenciales al iniciar sesión
/// - Verificar si el usuario mantiene una sesión activa
/// - Obtener información del usuario autenticado
/// - Cerrar sesión del usuario


class AuthService {
  /// Instancia estática del cliente de Supabase
  static final _supabase = supabase;

  /// Valida las credenciales del usuario e inicia sesión.
  ///   - [email]: Correo electrónico del usuario
  ///   - [password]: Contraseña del usuario
  ///   - [AuthException] si hay errores específicos de Supabase
  ///   - [Exception] para otros errores inesperados
  static Future<bool> validateAndSignIn(
    String email,
    String password,
  ) async {
    try {
      // Validar que los campos no estén vacíos
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email y contraseña son requeridos');
      }

      // Validar formato básico del email
      if (!_isValidEmail(email)) {
        throw Exception('El formato del email no es válido');
      }

      // Validar que la contraseña tenga al menos 6 caracteres
      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      // Intentar autenticación con Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Verificar que la sesión se creó correctamente
      if (response.session == null) {
        throw Exception('No se pudo establecer la sesión');
      }

      // Fetch user role
      await RoleService.fetchAndSetUserRole(response.session!.user.id);

      return true;
    } on AuthException catch (error) {
      // Manejar errores específicos de autenticación
      throw Exception('Error de autenticación: ${error.message}');
    } catch (error) {
      // Manejar cualquier otro error
      throw Exception('Error inesperado: $error');
    }
  }

  /// Verifica si el usuario tiene una sesión activa válida.
  static bool isUserLoggedIn() {
    try {
      // Obtener la sesión actual
      final session = _supabase.auth.currentSession;

      // Verificar que la sesión existe
      if (session == null) {
        return false;
      }

      // Verificar que el token de acceso no está expirado
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expiresAt <= now) {
          return false; // Token expirado
        }
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  /// Obtiene el usuario actualmente autenticado.

  static User? getCurrentUser() {
    try {
      return _supabase.auth.currentUser;
    } catch (error) {
      return null;
    }
  }

  /// Obtiene el email del usuario actualmente autenticado.

  static String? getCurrentUserEmail() {
    try {
      return _supabase.auth.currentUser?.email;
    } catch (error) {
      return null;
    }
  }

  /// Cierra la sesión del usuario.
  /// 
  /// Retorna:
  ///   - `true` si se cerró la sesión correctamente
  ///   - `false` si hubo un error
  /// 
  /// Lanza:
  ///   - [Exception] si hay algún error al cerrar sesión
  static Future<bool> signOut() async {
    try {
      // Verificar que hay una sesión activa antes de cerrar
      if (!isUserLoggedIn()) {
        return false;
      }

      // Cerrar sesión en Supabase
      await _supabase.auth.signOut();

      // Verificar que la sesión se cerró correctamente
      if (_supabase.auth.currentSession != null) {
        throw Exception('No se pudo cerrar la sesión correctamente');
      }

      return true;
    } on AuthException catch (error) {
      throw Exception('Error al cerrar sesión: ${error.message}');
    } catch (error) {
      throw Exception('Error inesperado: $error');
    }
  }

  /// Valida el formato del email usando una expresión regular.

  static bool _isValidEmail(String email) {
    // Expresión regular básica para validar emails
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
