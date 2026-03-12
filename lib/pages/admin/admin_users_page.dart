import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // In Supabase, getting auth.users directly from the client is restricted.
      // However, we can join usuario_rol, custadio, or use a custom RPC if necessary.
      // Let's first try to get from usuario_rol joined with rol
      final response = await supabase
          .from('usuario_rol')
          .select('user_id, rol(nombre)');
          
      if (!mounted) return;
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading users: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Registrados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No hay usuarios registrados.'));
    }

    return Card(
      child: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _users[index];
          final userId = user['user_id']?.toString() ?? 'ID Desconocido';
          final rolStr = user['rol']?['nombre']?.toString() ?? 'Desconocido';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(rolStr),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Usuario ID: $userId'),
            subtitle: Text('Rol: $rolStr'),
            trailing: Chip(
              label: Text(
                rolStr,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getRoleColor(rolStr),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.orange;
      case 'TI':
        return Colors.green;
      case 'PRESTADO':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
