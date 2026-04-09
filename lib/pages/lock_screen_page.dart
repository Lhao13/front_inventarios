import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/pages/login_page.dart';
import 'package:front_inventarios/pages/main_page.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'dart:convert';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _verifyPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      context.showSnackBar('Por favor ingresa tu contraseña', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = await LocalDbService.instance.database;
      final result = await db.query('cache_storage', where: 'id = ?', whereArgs: ['user_lock_hash']);
      
      if (result.isNotEmpty) {
        final storedHash = result.first['json_data'] as String;
        // Simple XOR check to match the saved one
        final bytes = utf8.encode(password);
        final xorBytes = bytes.map((b) => b ^ 0x55).toList();
        final checkHash = base64Encode(xorBytes);

        if (checkHash == storedHash) {
          // Contraseña correcta, entramos!
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
          }
        } else {
          if (mounted) context.showSnackBar('Contraseña incorrecta', isError: true);
        }
      } else {
        // No hash found? Force login again to generate it.
        await supabase.auth.signOut();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Error al validar: $e', isError: true);
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
                  'Ingresa tu contraseña para acceder a la aplicación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.password),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _verifyPassword(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPassword,
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Desbloquear', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _forceLogout,
                  child: const Text('Cerrar sesión e ingresar con otra cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
