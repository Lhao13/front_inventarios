import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';

class PcAssetsPage extends StatefulWidget {
  const PcAssetsPage({super.key});

  @override
  State<PcAssetsPage> createState() => _PcAssetsPageState();
}

class _PcAssetsPageState extends State<PcAssetsPage> {
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
          .select('*, info_pc(*)')
          .eq('categoria_activo', 'PC');
      
      if (mounted) {
        setState(() {
          _assets = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading PC assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipos PC'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? const Center(child: Text('No hay PCs registrados'))
              : ListView.builder(
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    final infoPc = asset['info_pc'] != null && (asset['info_pc'] as List).isNotEmpty 
                        ? (asset['info_pc'] as List)[0] 
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.computer, size: 40, color: Colors.blue),
                        title: Text(asset['nombre'] ?? 'PC Sin Nombre'),
                        subtitle: Text(
                          'S/N: ${asset['numero_serie'] ?? 'N/A'}\n'
                          'Procesador: ${infoPc?['procesador'] ?? 'N/A'} - '
                          'RAM: ${infoPc?['ram'] ?? 'N/A'} - '
                          'Almacenamiento: ${infoPc?['almacenamiento'] ?? 'N/A'}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                             context.showSnackBar('La función de Update está en desarrollo para PCs');
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
