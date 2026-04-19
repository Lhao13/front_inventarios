import 'package:flutter/material.dart';

class AssetUtils {
  /// Retorna el ícono correspondiente a cada categoría de activo
  static IconData getIconForCategory(String? category) {
    switch (category?.toUpperCase()) {
      case 'PC':
        return Icons.computer;
      case 'SOFTWARE':
        return Icons.developer_board;
      case 'COMUNICACION':
        return Icons.router;
      case 'GENERICO':
        return Icons.devices_other;
      default:
        return Icons.inventory;
    }
  }
}
