import 'package:flutter/material.dart';
import 'package:front_inventarios/main.dart';

class GenericAssetsPage extends StatefulWidget {
  const GenericAssetsPage({super.key});

  @override
  State<GenericAssetsPage> createState() => _GenericAssetsPageState();
}

class _GenericAssetsPageState extends State<GenericAssetsPage> {
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
          .select('*, info_equipo_generico(*)')
          .eq('categoria_activo', 'GENERICO');
      
      if (mounted) {
        setState(() {
          _assets = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error loading Generic assets: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipos Genéricos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? const Center(child: Text('No hay Equipos Genéricos registrados'))
              : ListView.builder(
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    final info = asset['info_equipo_generico'] != null && 
                            (asset['info_equipo_generico'] as List).isNotEmpty 
                        ? (asset['info_equipo_generico'] as List)[0] 
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.devices_other, size: 40, color: Colors.purple),
                        title: Text(asset['nombre'] ?? 'Equipo Sin Nombre'),
                        subtitle: Text(
                          'S/N: ${asset['numero_serie'] ?? 'N/A'}\n'
                          'Conexiones: ${info?['num_conexiones'] ?? 'N/A'} - '
                          'Impresora Color: ${info?['var_impresora_color'] ?? 'N/A'} - '
                          'Monitor Conexión: ${info?['var_monitor_tipo_conexion'] ?? 'N/A'}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                             context.showSnackBar('La función de Update está en desarrollo para Genéricos');
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
