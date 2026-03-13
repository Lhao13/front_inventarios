import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';

class SoftwareAssetsPage extends StatefulWidget {
  const SoftwareAssetsPage({super.key});

  @override
  State<SoftwareAssetsPage> createState() => _SoftwareAssetsPageState();
}

class _SoftwareAssetsPageState extends State<SoftwareAssetsPage> {
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
          .select('*, info_software(*)')
          .eq('categoria_activo', 'SOFTWARE');
      
      if (mounted) {
        setState(() {
          _assets = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading Software assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licencias de Software'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? const Center(child: Text('No hay Software registrado'))
              : ListView.builder(
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    final info = asset['info_software'] != null && (asset['info_software'] as List).isNotEmpty 
                        ? (asset['info_software'] as List)[0] 
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.developer_board, size: 40, color: Colors.green),
                        title: Text(asset['nombre'] ?? 'Software Sin Nombre'),
                        subtitle: Text(
                          'Proveedor: ${info?['proveedor'] ?? 'N/A'}\n'
                          'Inicio: ${info?['fecha_inicio'] ?? 'N/A'} - '
                          'Fin: ${info?['fecha_fin'] ?? 'N/A'}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                             context.showSnackBar('La función de Update está en desarrollo para Software');
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
