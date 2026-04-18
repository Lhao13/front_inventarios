import 'package:flutter/material.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/widgets/map_dialog.dart';
import 'package:front_inventarios/widgets/material_list_paginator.dart';

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
/// - Edit / Delete / custom action buttons (delete gated by role)
/// - Pagination via [MaterialListPaginator] (rows-per-page + first/prev/next/last)
/// - Loading and empty states
class AssetDataTable extends StatefulWidget {
  final List<Map<String, dynamic>> assets;
  final List<AssetColumnDef> columns;
  final bool isLoading;
  final Future<void> Function(Map<String, dynamic> asset)? onEdit;
  final Future<void> Function(String id)? onDelete;
  final List<Widget> Function(Map<String, dynamic> asset)? customActionsBuilder;

  const AssetDataTable({
    super.key,
    required this.assets,
    required this.columns,
    this.isLoading = false,
    this.onEdit,
    this.onDelete,
    this.customActionsBuilder,
  });

  @override
  State<AssetDataTable> createState() => _AssetDataTableState();
}

class _AssetDataTableState extends State<AssetDataTable> {
  /// Tracks which column labels are currently visible.
  late Set<String> _visibleLabels;

  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _visibleLabels = {
      for (final col in widget.columns)
        if (col.visibleByDefault) col.label,
    };
  }

  /// When the column list changes (e.g. page navigation), re-init.
  @override
  void didUpdateWidget(AssetDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columns != widget.columns) {
      if (mounted) {
        setState(() {
          _visibleLabels = {
            for (final col in widget.columns)
              if (col.visibleByDefault) col.label,
          };
        });
      }
    }
    // Reset to first page when the data changes
    if (oldWidget.assets != widget.assets) {
      if (mounted) {
        setState(() => _currentPage = 0);
      }
    }
  }

  Future<void> _showColumnSelector() async {
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
                    if (mounted) {
                      setState(() => _visibleLabels = Set.from(tempVisible));
                    }
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

  /// Builds a [DataRow] for one asset, replicating the logic that was in
  /// [AssetDataSource.getRow].
  DataRow _buildRow(Map<String, dynamic> asset, List<AssetColumnDef> visibleCols, bool hasActions) {
    return DataRow(
      cells: [
        if (hasActions)
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onEdit != null)
                  Tooltip(
                    message: 'Editar',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => widget.onEdit!(asset),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.edit, color: Colors.blue, size: 22),
                      ),
                    ),
                  ),
                if (widget.customActionsBuilder != null) ...[
                  if (widget.onEdit != null) const SizedBox(width: 4),
                  ...widget.customActionsBuilder!(asset),
                ],
                if (widget.onDelete != null &&
                    asset['id'] != null &&
                    RoleService.currentRole != UserRole.ayudante) ...[
                  if (widget.onEdit != null ||
                      (widget.customActionsBuilder != null &&
                          widget.customActionsBuilder!(asset).isNotEmpty))
                    const SizedBox(width: 4),
                  Tooltip(
                    message: 'Eliminar',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => widget.onDelete!(asset['id'] as String),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.delete, color: Colors.red, size: 22),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ...visibleCols.map((col) {
          final String value = col.getValue(asset);

          // Special case: coordinate column shows a tappable map link
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
                            title: asset['nombre']?.toString() ??
                                asset['numero_serie']?.toString() ??
                                'Activo',
                          ),
                        );
                        return;
                      }
                    }
                    throw Exception('Formato inválido');
                  } catch (_) {
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
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return DataCell(Text(value));
        }),
      ],
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

    final hasActions =
        widget.onEdit != null ||
        widget.onDelete != null ||
        widget.customActionsBuilder != null;

    // ── Pagination math ────────────────────────────────────────────────────
    final totalItems = widget.assets.length;
    final totalPages = (totalItems / _rowsPerPage).ceil().clamp(1, 999999);

    if (_currentPage >= totalPages) _currentPage = totalPages - 1;
    if (_currentPage < 0) _currentPage = 0;

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
    final pageAssets = widget.assets.sublist(startIndex, endIndex);
    // ───────────────────────────────────────────────────────────────────────

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toolbar: record count + column selector ──────────────────────
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

        // ── Scrollable DataTable (horizontal + vertical) ─────────────────
        Expanded(
          child: SingleChildScrollView(
            // vertical scroll
            child: SingleChildScrollView(
              // horizontal scroll for wide tables
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(context).copyWith(
                  cardTheme: const CardThemeData(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Colors.transparent,
                  ),
                ),
                child: DataTable(
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.resolveWith(
                    (states) => Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withAlpha(128),
                  ),
                  columns: [
                    if (hasActions)
                      const DataColumn(
                        label: Text(
                          'Acciones',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ...visibleCols.map(
                      (col) => DataColumn(
                        label: Text(
                          col.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  rows: pageAssets
                      .map((asset) => _buildRow(asset, visibleCols, hasActions))
                      .toList(),
                ),
              ),
            ),
          ),
        ),

        // ── Pagination footer ─────────────────────────────────────────────
        MaterialListPaginator(
          rowsPerPage: _rowsPerPage,
          currentPage: _currentPage,
          totalItems: totalItems,
          rowsPerPageOptions: const [10, 20, 30, 40, 50, 100],
          onRowsPerPageChanged: (v) => setState(() {
            _rowsPerPage = v;
            _currentPage = 0;
          }),
          onFirst: () => setState(() => _currentPage = 0),
          onPrevious: () => setState(() => _currentPage--),
          onNext: () => setState(() => _currentPage++),
          onLast: () => setState(() => _currentPage = totalPages - 1),
        ),
      ],
    );
  }
}
