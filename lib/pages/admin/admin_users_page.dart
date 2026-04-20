import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  final ScrollController _usersScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _usersScrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
      // Consultamos una vista SQL personalizada para poder extraer el nombre desde auth.users
      final response = await Supabase.instance.client
          .from('vista_usuarios_admin')
          .select();

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

  Future<void> _changeUserRole(
    String userId,
    int newRoleId,
    String newRoleName,
  ) async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await Supabase.instance.client
          .from('usuario_rol')
          .update({'rol_id': newRoleId})
          .eq('user_id', userId);

      if (mounted) {
        Navigator.pop(context); // close loader
        context.showSnackBar('Rol actualizado a $newRoleName');
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        context.showSnackBar('Error al actualizar rol: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Usuarios Registrados',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadUsers,
                  tooltip: 'Refrescar Lista',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!SyncQueueService.instance.isOnlineNotifier.value) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Requiere conexión a internet para gestionar usuarios',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

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

    final filteredUsers = _users.where((user) {
      final name = (user['nombre_usuario'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('No se encontraron usuarios coincidentes.'),
      );
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Card(
      child: Scrollbar(
        controller: _usersScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8,
        child: ListView.separated(
          controller: _usersScrollController,
          itemCount: filteredUsers.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final userId = user['user_id']?.toString() ?? 'ID Desconocido';
            final rolStr =
                user['rol']?.toString().toUpperCase() ?? 'DESCONOCIDO';
            final email = user['email']?.toString() ?? 'Sin Email';
            final nombre = user['nombre_usuario']?.toString() ?? 'Sin Nombre';

            int currentRoleId = 3; // Default PRESTAMO
            if (rolStr == 'ADMIN') currentRoleId = 1;
            if (rolStr == 'TI') currentRoleId = 2;

            final isCurrentUser = userId == currentUserId;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(rolStr),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text('$nombre '),
              subtitle: Text(
                isCurrentUser
                    ? 'Este es tu usuario'
                    : 'Email: $email\nRol: $rolStr\nID: $userId',
              ),
              isThreeLine: true,
              trailing: isCurrentUser
                  ? Chip(
                      label: Text(
                        rolStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _getRoleColor(rolStr),
                    )
                  : DropdownButton<int>(
                      value: currentRoleId,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            'TI',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(
                            'PRESTAMO',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (int? newValue) {
                        if (newValue != null && newValue != currentRoleId) {
                          String newName = 'PRESTAMO';
                          if (newValue == 1) newName = 'ADMIN';
                          if (newValue == 2) newName = 'TI';
                          _changeUserRole(userId, newValue, newName);
                        }
                      },
                    ),
            );
          },
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.orange;
      case 'TI':
        return Colors.green;
      case 'PRESTAMO':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
