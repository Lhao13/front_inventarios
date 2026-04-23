import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/pages/sign_up.dart';
import 'package:front_inventarios/pages/main_page.dart';
import 'package:front_inventarios/auth/auth_service.dart';
import 'package:front_inventarios/exceptions/app_exceptions.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _passwordController =
      TextEditingController();

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Validar credenciales usando el servicio de autenticación
      await AuthService.validateAndSignIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Guardar hash local (XOR) de la contraseña para Offline LockScreen
      try {
        final password = _passwordController.text.trim();
        final bytes = utf8.encode(password);
        final xorBytes = bytes.map((b) => b ^ 0x55).toList();
        final db = await LocalDbService.instance.database;
        await db.insert('cache_storage', {
          'collection': 'system',
          'id': 'user_lock_hash',
          'json_data': base64Encode(xorBytes),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (e) {
        debugPrint('Error saving local hash: $e');
      }

      if (mounted) {
        context.showSnackBar('¡Login exitoso!');
        _emailController.clear();
        _passwordController.clear();

        // Navegar a la página principal después del login exitoso
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));

        // Forzar descarga inmediata de caché al iniciar sesión.
        // Esto garantiza que los datos estén actualizados sin esperar al
        // listener de conectividad (que no se dispara si ya había internet).
        SyncQueueService.instance.forceSyncAndRefresh();
      }
    } on AppException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar('$error', isError: true);
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _obscurePassword = true;

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
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Inicio de sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa tus credenciales para acceder',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: SyncQueueService.instance.isOnlineNotifier,
                  builder: (context, isOnline, child) {
                    if (isOnline) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.signal_wifi_off,
                                  color: Colors.orange, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Sin conexión detectada. El inicio de sesión inicial requiere internet. Si ya tienes una sesión activa guardada, podrás ingresar tras recuperar la señal.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade900,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
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
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _signIn();
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('¿No tienes una cuenta?'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: const Text('Regístrate aquí'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
