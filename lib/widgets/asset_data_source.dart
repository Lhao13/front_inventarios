import 'package:flutter/material.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/widgets/asset_data_table.dart';
import 'package:front_inventarios/widgets/map_dialog.dart';
import 'package:front_inventarios/main.dart';

class AssetDataSource extends DataTableSource {
  final List<Map<String, dynamic>> assets;
  final List<AssetColumnDef> visibleCols;
  final bool hasActions;
  final BuildContext context;
  final Future<void> Function(Map<String, dynamic> asset)? onEdit;
  final Future<void> Function(String id)? onDelete;

  AssetDataSource({
    required this.assets,
    required this.visibleCols,
    required this.hasActions,
    required this.context,
    this.onEdit,
    this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= assets.length) return null;
    final asset = assets[index];
    
    return DataRow(
      cells: [
        ...visibleCols.map(
          (col) {
            final String value = col.getValue(asset);
            if (col.label == 'Coordenada' && value != 'N/A' && value.isNotEmpty) {
              return DataCell(
                InkWell(
                  onTap: () {
                    try {
                      final parts = value.split(',');
                      if (parts.length == 2) {
                        final lat = double.tryParse(parts[0].trim());
                        final lng = double.tryParse(parts[1].trim());
                        if (lat != null && lng != null) {
                          showDialog(
                            context: context,
                            builder: (_) => MapDialog(
                              latitude: lat,
                              longitude: lng,
                              title: asset['nombre']?.toString() ?? asset['numero_serie']?.toString() ?? 'Activo',
                            ),
                          );
                          return;
                        }
                      }
                      throw Exception('Formato inválido');
                    } catch (e) {
                      if (context.mounted) {
                        context.showSnackBar('Coordenada inválida', isError: true);
                      }
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(value, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
              );
            }
            return DataCell(Text(value));
          },
        ),
        if (hasActions)
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar',
                    onPressed: () => onEdit!(asset),
                  ),
                if (onDelete != null &&
                    asset['id'] != null &&
                    RoleService.currentRole != UserRole.ayudante)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Eliminar',
                    onPressed: () => onDelete!(asset['id'] as String),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => assets.length;

  @override
  int get selectedRowCount => 0;
}
