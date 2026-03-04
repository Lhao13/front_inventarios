import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/pages/login_page.dart';

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
			await supabase.auth.signUp(
				email: _emailController.text.trim(),
				password: _passwordController.text.trim(),
			);
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

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Center(
				child: ListView(
					shrinkWrap: true,
					physics: const NeverScrollableScrollPhysics(),
					padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
					children: [
						const Text(
							'Crea tu cuenta',
							textAlign: TextAlign.center,
							style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
						),
						const SizedBox(height: 30),
						const Text(
							'Ingresa tus datos para registrarte',
							textAlign: TextAlign.center,
						),
						const SizedBox(height: 18),
						TextFormField(
							controller: _nameController,
							decoration: const InputDecoration(labelText: 'Nombre'),
						),
						const SizedBox(height: 18),
						TextFormField(
							controller: _emailController,
							decoration: const InputDecoration(labelText: 'Email'),
							keyboardType: TextInputType.emailAddress,
						),
						const SizedBox(height: 18),
						TextFormField(
							controller: _passwordController,
							decoration: const InputDecoration(labelText: 'Contraseña'),
							obscureText: true,
						),
						const SizedBox(height: 18),
						TextFormField(
							controller: _confirmPasswordController,
							decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
							obscureText: true,
						),
						const SizedBox(height: 18),
						ElevatedButton(
							onPressed: _isLoading ? null : _signUp,
							child: Text(_isLoading ? 'Creando...' : 'Crear cuenta'),
						),
					],
				),
			),
		);
	}
}
