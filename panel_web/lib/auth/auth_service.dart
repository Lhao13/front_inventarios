import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panel_web/auth/role_service.dart';
import 'package:panel_web/exceptions/app_exceptions.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static Future<bool> validateAndSignIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw const ValidationException('Email y contraseña son requeridos');
      }
      if (!_isValidEmail(email)) {
        throw const ValidationException('El formato del email no es válido');
      }
      if (password.length < 6) {
        throw const ValidationException(
          'La contraseña debe tener al menos 6 caracteres',
        );
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.session == null) {
        throw const AuthenticationException('No se pudo establecer la sesión');
      }

      await RoleService.fetchAndSetUserRole(response.session!.user.id);

      return true;
    } on AuthException catch (error, stackTrace) {
      throw AuthenticationException(
        'Error de autenticación: ${error.message}',
        originalException: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        'Error inesperado durante el inicio de sesión',
        originalException: error,
        stackTrace: stackTrace,
      );
    }
  }

  static bool isUserLoggedIn() {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expiresAt <= now) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static User? getCurrentUser() {
    try {
      return _supabase.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String? getCurrentUserEmail() {
    try {
      return _supabase.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> signOut() async {
    try {
      if (!isUserLoggedIn()) return false;
      await _supabase.auth.signOut();
      return true;
    } on AuthException catch (error, stackTrace) {
      throw AuthenticationException(
        'Error al cerrar sesión: ${error.message}',
        originalException: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw AppException(
        'Error inesperado al cerrar sesión',
        originalException: error,
        stackTrace: stackTrace,
      );
    }
  }

  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}


