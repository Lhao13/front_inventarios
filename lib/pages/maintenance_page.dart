import 'package:flutter/material.dart';

/// Página de Mantenimientos.
/// 
/// Esta página permite al usuario gestionar los mantenimientos de los activos.
class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mantenimientos'),
      ),
      body: const Center(
        child: Text('Página de Mantenimientos'),
      ),
    );
  }
}
