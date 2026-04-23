import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/pages/login_page.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';

class SignUpPage extends StatefulWidget {
	const SignUpPage({super.key});

	@override
	State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
	bool _isLoading = false;
	late final TextEditingController _nameController = TextEditingController();
	late final TextEditingController _emailController = TextEditingController();
	late final TextEditingController _passwordController =
			TextEditingController();
	late final TextEditingController _confirmPasswordController =
			TextEditingController();

	Future<void> _signUp() async {
		if (_passwordController.text != _confirmPasswordController.text) {
			context.showSnackBar('Las contraseñas no coinciden', isError: true);
			return;
		}
		if (_nameController.text.trim().isEmpty) {
			context.showSnackBar('Por favor ingresa tu nombre', isError: true);
			return;
		}
		try {
			setState(() {
				_isLoading = true;
			});
			final response = await Supabase.instance.client.auth.signUp(
				email: _emailController.text.trim(),
				password: _passwordController.text.trim(),
				data: {'name': _nameController.text.trim()},
			);

      // Guardar hash local (XOR) para permitir desbloqueo offline inmediato
      if (response.user != null) {
        try {
          final password = _passwordController.text.trim();
          final bytes = utf8.encode(password);
          final xorBytes = Uint8List.fromList(bytes.map((b) => b ^ 0x55).toList());
          final db = await LocalDbService.instance.database;
          await db.insert('cache_storage', {
            'collection': 'system',
            'id': 'user_lock_hash',
            'json_data': base64Encode(xorBytes),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          debugPrint('Error saving local hash during signUp: $e');
        }
      }

			if (mounted) {
				context.showSnackBar('Cuenta creada');
				_nameController.clear();
				_emailController.clear();
				_passwordController.clear();
				_confirmPasswordController.clear();
				Future.delayed(const Duration(seconds: 2), () {
					if (mounted) {
						Navigator.of(context).pushReplacement(
							MaterialPageRoute(builder: (_) => const LoginPage()),
						);
					}
				});
			}


		} on AuthException catch (error) {
			if (mounted) context.showSnackBar(error.message, isError: true);
		} catch (error) {
			if (mounted) {
				context.showSnackBar('Error inesperado', isError: true);
			}
		} finally {
			if (mounted) {
				setState(() {
					_isLoading = false;
				});
			}
		}
	}

	@override
	void dispose() {
		_nameController.dispose();
		_emailController.dispose();
		_passwordController.dispose();
		_confirmPasswordController.dispose();
		super.dispose();
	}

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                Icon(Icons.person_add_alt_1_outlined, size: 64, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa tus datos para registrarte',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _signUp();
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Crear cuenta', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
