import 'package:flutter/material.dart';
import 'package:front_inventarios/auth/role_service.dart';

class GlobalAssetDataSource extends DataTableSource {
  final List<Map<String, dynamic>> assets;
  final BuildContext context;
  final Future<void> Function(String id)? onDelete;
  final void Function(Map<String, dynamic> asset)? onScheduleMaintenance;

  GlobalAssetDataSource({
    required this.assets,
    required this.context,
    this.onDelete,
    this.onScheduleMaintenance,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= assets.length) return null;
    final asset = assets[index];
    
    return DataRow(
      cells: [
        DataCell(Text(asset['numero_serie']?.toString() ?? 'N/A')),
        DataCell(Text(asset['nombre']?.toString() ?? 'N/A')),
        DataCell(Text(asset['codigo']?.toString() ?? 'N/A')),
        DataCell(Text(asset['tipo_activo']?['tipo']?.toString() ?? 'N/A')),
        DataCell(Text(asset['condicion_activo']?['condicion']?.toString() ?? 'N/A')),
        DataCell(Text(asset['custodio']?['nombre_completo']?.toString() ?? 'N/A')),
        DataCell(Text(asset['ciudad_activo']?['ciudad']?.toString() ?? 'N/A')),
        DataCell(Text(asset['sede_activo']?['sede']?.toString() ?? 'N/A')),
        DataCell(Text(asset['area_activo']?['area']?.toString() ?? 'N/A')),
        DataCell(Text(asset['proveedor']?['nombre']?.toString() ?? 'N/A')),
        DataCell(Text(asset['fecha_adquisicion']?.toString() ?? 'N/A')),
        DataCell(Text(asset['ip']?.toString() ?? 'N/A')),
        DataCell(Text(asset['fecha_entrega']?.toString() ?? 'N/A')),
        DataCell(Text(asset['coordenada']?.toString() ?? 'N/A')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onScheduleMaintenance != null)
                IconButton(
                  icon: const Icon(Icons.build_circle, color: Colors.blueGrey),
                  onPressed: () => onScheduleMaintenance!(asset),
                  tooltip: 'Programar Mantenimiento',
                ),
              if (RoleService.currentRole != UserRole.ayudante)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    if (onDelete != null) onDelete!(asset['id']);
                  },
                  tooltip: 'Eliminar',
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
