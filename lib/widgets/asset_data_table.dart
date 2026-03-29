import 'package:flutter/material.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/widgets/map_dialog.dart';

/// Defines a single column in the [AssetDataTable].
/// [label] is the header text. [getValue] extracts the display value from an
/// asset map. [visibleByDefault] controls the initial visibility.
class AssetColumnDef {
  final String label;
  final String Function(Map<String, dynamic> asset) getValue;
  final bool visibleByDefault;

  const AssetColumnDef({
    required this.label,
    required this.getValue,
    this.visibleByDefault = true,
  });
}

/// A reusable, stateful DataTable widget for asset pages.
/// 
/// Features:
/// - Column visibility selector (toggle columns on/off via a dialog)
/// - Horizontal + vertical scroll for mobile
/// - Edit / Delete action buttons (delete gated by role)
/// - Loading and empty states
class AssetDataTable extends StatefulWidget {
  final List<Map<String, dynamic>> assets;
  final List<AssetColumnDef> columns;
  final bool isLoading;
  final Future<void> Function(Map<String, dynamic> asset)? onEdit;
  final Future<void> Function(String id)? onDelete;

  const AssetDataTable({
    super.key,
    required this.assets,
    required this.columns,
    this.isLoading = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AssetDataTable> createState() => _AssetDataTableState();
}

class _AssetDataTableState extends State<AssetDataTable> {
  // Tracks which column labels are currently visible.
  late Set<String> _visibleLabels;

  @override
  void initState() {
    super.initState();
    _visibleLabels = {
      for (final col in widget.columns)
        if (col.visibleByDefault) col.label,
    };
  }

  // When the column list changes (e.g. page navigation), re-init.
  @override
  void didUpdateWidget(AssetDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columns != widget.columns) {
      _visibleLabels = {
        for (final col in widget.columns)
          if (col.visibleByDefault) col.label,
      };
    }
  }

  Future<void> _showColumnSelector() async {
    // Work on a temporary copy so we can cancel.
    final tempVisible = Set<String>.from(_visibleLabels);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Columnas visibles'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: widget.columns.map((col) {
                    final isChecked = tempVisible.contains(col.label);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(col.label),
                      value: isChecked,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            tempVisible.add(col.label);
                          } else {
                            // Prevent hiding all columns.
                            if (tempVisible.length > 1) {
                              tempVisible.remove(col.label);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Select all
                    setDialogState(() {
                      tempVisible.addAll(widget.columns.map((c) => c.label));
                    });
                  },
                  child: const Text('Seleccionar todas'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _visibleLabels = Set.from(tempVisible));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.assets.isEmpty) {
      return const Center(
        child: Text(
          'No hay activos para mostrar. Modifique los filtros.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final visibleCols = widget.columns
        .where((c) => _visibleLabels.contains(c.label))
        .toList();

    final hasActions = widget.onEdit != null || widget.onDelete != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar row: count + column selector button
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Text(
                '${widget.assets.length} registro(s)',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _showColumnSelector,
                icon: const Icon(Icons.view_column, size: 18),
                label: Text(
                  'Columnas (${_visibleLabels.length}/${widget.columns.length})',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // Data table
        Expanded(
          child: Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                  columns: [
                    ...visibleCols.map(
                      (col) => DataColumn(
                        label: Text(
                          col.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (hasActions)
                      const DataColumn(
                        label: Text(
                          'Acciones',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                  rows: widget.assets.map((asset) {
                    return DataRow(
                      cells: [
                        ...visibleCols.map(
                          (col) {
                            final String value = col.getValue(asset);
                            if (col.label == 'Coordenada' && value != 'N/A' && value.isNotEmpty) {
                              return DataCell(
                                InkWell(
                                  onTap: () {
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
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordenada inválida')));
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
                                if (widget.onEdit != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Editar',
                                    onPressed: () => widget.onEdit!(asset),
                                  ),
                                if (widget.onDelete != null &&
                                    asset['id'] != null &&
                                    RoleService.currentRole != UserRole.ayudante)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Eliminar',
                                    onPressed: () =>
                                        widget.onDelete!(asset['id'] as String),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
