import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:front_inventarios/main.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool isOnlyNumeric;
  
  const BarcodeScannerScreen({super.key, this.isOnlyNumeric = false});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  String? _scannedCode;
  DateTime? _lastErrorTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnlyNumeric ? 'Escanear Código numérico' : 'Escanear QR / Código de Barras'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null) {
                  // Si tiene que ser solo numero, validar eso
                  if (widget.isOnlyNumeric) {
                    if (int.tryParse(rawValue) == null) {
                      final now = DateTime.now();
                      if (_lastErrorTime == null || now.difference(_lastErrorTime!) > const Duration(seconds: 3)) {
                        _lastErrorTime = now;
                        if (mounted) {
                          context.showSnackBar(
                            'Por favor, escanee un código numérico válido',
                            isError: true,
                          );
                        }
                      }
                      continue;
                    }
                  }
                  
                  if (_scannedCode == null) {
                    setState(() {
                      _scannedCode = rawValue;
                    });
                    if (mounted) {
                      // SnackBar overlay maneja su propio ciclo de vida
                      Navigator.pop(context, rawValue);
                    }
                  }
                }
              }
            },
          ),
          // Overlay to guide the user
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Apunte la cámara al código',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, backgroundColor: Colors.black54),
              ),
            ),
          )
        ],
      ),
    );
  }
}
