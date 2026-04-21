import 'package:flutter/material.dart';

class AssetUtils {
  /// Retorna el ícono correspondiente a cada categoría de activo
  static IconData getIconForCategory(String? category) {
    switch (category?.toUpperCase()) {
      case 'PC':
        return Icons.computer;
      case 'SOFTWARE':
        return Icons.developer_board;
      case 'GENERICO':
        return Icons.devices_other;
      default:
        return Icons.inventory;
    }
  }

  /// Retorna el color distintivo para cada categoría de activo
  static Color getColorForCategory(String? category) {
    switch (category?.toUpperCase()) {
      case 'PC':
        return const Color(0xFF673AB7); // Deep Purple
      case 'SOFTWARE':
        return Colors.orange.shade700;
      case 'COMUNICACION':
        return Colors.teal.shade600;
      case 'GENERICO':
        return Colors.blueGrey.shade600;
      default:
        return const Color(0xFF1465bd); // App Blue
    }
  }
}
