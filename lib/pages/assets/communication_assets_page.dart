import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';

class CommsAssetsPage extends StatefulWidget {
  const CommsAssetsPage({super.key});

  @override
  State<CommsAssetsPage> createState() => _CommsAssetsPageState();
}

class _CommsAssetsPageState extends State<CommsAssetsPage> {
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('activo')
          .select('*, info_equipo_comunicacion(*)')
          .eq('categoria_activo', 'COMUNICACION');
      
      if (mounted) {
        setState(() {
          _assets = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading Comm assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipos de Comunicación'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? const Center(child: Text('No hay Equipos de Com. registrados'))
              : ListView.builder(
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    final info = asset['info_equipo_comunicacion'] != null && 
                            (asset['info_equipo_comunicacion'] as List).isNotEmpty 
                        ? (asset['info_equipo_comunicacion'] as List)[0] 
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.router, size: 40, color: Colors.orange),
                        title: Text(asset['nombre'] ?? 'Equipo Sin Nombre'),
                        subtitle: Text(
                          'S/N: ${asset['numero_serie'] ?? 'N/A'}\n'
                          'Puertos: ${info?['num_puertos'] ?? 'N/A'} - '
                          'Extensión: ${info?['tipo_extension'] ?? 'N/A'}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                             context.showSnackBar('La función de Update está en desarrollo para Comunicaciones');
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
