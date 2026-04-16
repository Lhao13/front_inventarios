import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/pages/login_page.dart';
import 'package:front_inventarios/pages/main_page.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:local_auth/local_auth.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      _biometricAvailable = supported && canCheck;
      setState(() {});
    } catch (e) {
      _biometricAvailable = false;
    }
  }

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Autentícate para acceder a la aplicación',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
      } else {
        if (mounted) {
          context.showSnackBar('Autenticación fallida', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error de autenticación biométrica: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      context.showSnackBar('Por favor ingresa tu contraseña', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = await LocalDbService.instance.database;
      final result = await db.query(
        'cache_storage',
        where: 'id = ?',
        whereArgs: ['user_lock_hash'],
      );

      if (result.isNotEmpty) {
        final storedHash = result.first['json_data'] as String;
        final bytes = utf8.encode(password);
        final xorBytes = bytes.map((b) => b ^ 0x55).toList();
        final checkHash = base64Encode(xorBytes);

        if (checkHash == storedHash) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
          }
        } else {
          if (mounted) {
            context.showSnackBar('Contraseña incorrecta', isError: true);
          }
        }
      } else {
        await supabase.auth.signOut();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al validar la contraseña: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forceLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'Bienvenido de vuelta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Desbloquea la app con biometría o contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (_biometricAvailable)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(_isLoading ? 'Autenticando...' : 'Autenticar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  )
                else
                  const Text(
                    'No hay biometría disponible en este dispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.password),
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) => _verifyPassword(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Usar contraseña', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _forceLogout,
                  child: const Text('Cambiar de usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
