// barcode_scanner_screen - STUB para panel web.
// El escaneo QR es para dispositivos móviles, no para el panel web.
import 'package:flutter/material.dart';

class BarcodeScannerScreen extends StatelessWidget {
  final bool isOnlyNumeric;
  const BarcodeScannerScreen({super.key, this.isOnlyNumeric = false});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Escáner QR no disponible en panel web')),
    );
  }
}
