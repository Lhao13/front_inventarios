import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool isOnlyNumeric;
  
  const BarcodeScannerScreen({super.key, this.isOnlyNumeric = false});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  String? _scannedCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnlyNumeric ? 'Escanear Código de Barras' : 'Escanear QR / Código de Barras'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null) {
                  // If it must be numeric, validate that
                  if (widget.isOnlyNumeric) {
                    if (int.tryParse(rawValue) == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, escanee un código numérico válido'),
                            duration: Duration(seconds: 2)
                          ),
                        );
                      }
                      continue;
                    }
                  }
                  
                  if (_scannedCode == null) {
                    setState(() {
                      _scannedCode = rawValue;
                    });
                    Navigator.pop(context, rawValue);
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
