import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  final int? initialSortColumnIndex;
  final bool initialSortAscending;
  final Function(int? index, bool ascending)? onSortChanged;
  final Future<void> Function(Map<String, dynamic> asset)? onEdit;
  final Future<void> Function(String id)? onDelete;
  final Future<void> Function(Map<String, dynamic> asset)? onRowTap;
  final List<Widget> Function(Map<String, dynamic> asset)? customActionsBuilder;

  const AssetDataTable({
    super.key,
    required this.assets,
    required this.columns,
    this.isLoading = false,
    this.initialSortColumnIndex,
    this.initialSortAscending = true,
    this.onSortChanged,
    this.onEdit,
    this.onDelete,
    this.onRowTap,
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
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _visibleLabels = {
      for (final col in widget.columns)
        if (col.visibleByDefault) col.label,
    };
    _sortColumnIndex = widget.initialSortColumnIndex;
    _sortAscending = widget.initialSortAscending;
  }

  /// When the column list changes (e.g. page navigation), re-init.
  @override
  void didUpdateWidget(AssetDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.columns, widget.columns)) {
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
    if (!listEquals(oldWidget.assets, widget.assets)) {
      if (mounted) {
        setState(() => _currentPage = 0);
      }
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
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

  double _getColWidth(String label) {
    // Generous widths to avoid alignment drift. Base + extra for icon and padding.
    switch (label) {
      case 'Acciones':
        return 140;
      case 'S/N':
        return 120;
      case 'Nombre':
        return 200;
      case 'Código':
        return 140;
      case 'Tipo Activo':
        return 170;
      case 'Condición':
        return 170;
      case 'Custodio':
        return 180;
      case 'Ciudad':
        return 140;
      case 'Sede':
        return 140;
      case 'Área':
        return 170;
      case 'Proveedor':
        return 180;
      case 'Fe. Adquisición':
        return 150;
      case 'IP':
        return 140;
      case 'Fe. Entrega':
        return 150;
      case 'Coordenada':
        return 170;
      case 'Cód. Cargador':
        return 180;
      case 'Num. Puertos':
        return 160;
      case 'Marca':
        return 160;
      case 'Modelo':
        return 180;
      default:
        // Let categories like Observations be wider
        if (label.length > 15) return 220;
        return 160;
    }
  }

  /// Builds a [DataRow] for one asset, replicating the logic that was in
  /// [AssetDataSource.getRow].
  DataRow _buildRow(
    Map<String, dynamic> asset,
    List<AssetColumnDef> visibleCols,
    bool hasActions,
  ) {
    return DataRow(
      onSelectChanged: widget.onRowTap != null ? (selected) => widget.onRowTap!(asset) : null,
      mouseCursor: widget.onRowTap != null ? WidgetStateMouseCursor.clickable : null,
      cells: [
        if (hasActions)
          DataCell(
            SizedBox(
              width: _getColWidth('Acciones'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
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
                            child: Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 22,
                            ),
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
                            child: Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ...visibleCols.map((col) {
          final String value = col.getValue(asset);
          final double width = _getColWidth(col.label);

          Widget cellContent;
          // Special case: coordinate column shows a tappable map link
          if (col.label == 'Coordenada' && value != 'N/A' && value.isNotEmpty) {
            cellContent = InkWell(
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
                          title:
                              asset['nombre']?.toString() ??
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
                  Expanded(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            cellContent = Text(value, overflow: TextOverflow.ellipsis);
          }

          return DataCell(
            SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: cellContent,
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Map<String, dynamic>> _getSortedAssets(
    List<AssetColumnDef> visibleCols,
  ) {
    if (_sortColumnIndex == null) return widget.assets;

    final hasActions =
        widget.onEdit != null ||
        widget.onDelete != null ||
        widget.customActionsBuilder != null;

    final int colIdx = hasActions ? _sortColumnIndex! - 1 : _sortColumnIndex!;
    if (colIdx < 0 || colIdx >= visibleCols.length) return widget.assets;

    final colDef = visibleCols[colIdx];
    final sortedList = List<Map<String, dynamic>>.from(widget.assets);

    sortedList.sort((a, b) {
      final valA = colDef.getValue(a);
      final valB = colDef.getValue(b);

      // Handle nulls / NAs (always push to bottom)
      final isNullA = valA == 'N/A' || valA.isEmpty;
      final isNullB = valB == 'N/A' || valB.isEmpty;

      if (isNullA && isNullB) return 0;
      if (isNullA) return 1; // a is null, b is not -> a comes later
      if (isNullB) return -1; // b is null, a is not -> a comes earlier

      // Natural Sort Logic
      final int comparison = _naturalCompare(valA, valB);
      return _sortAscending ? comparison : -comparison;
    });

    return sortedList;
  }

  int _naturalCompare(String a, String b) {
    // Try to parse as numbers first
    final numA = double.tryParse(a.replaceAll(RegExp(r'[^0-9.]'), ''));
    final numB = double.tryParse(b.replaceAll(RegExp(r'[^0-9.]'), ''));

    if (numA != null && numB != null) {
      return numA.compareTo(numB);
    }

    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  void _onSort(
    int columnIndex,
    bool ascending,
    List<AssetColumnDef> visibleCols,
  ) {
    if (mounted) {
      setState(() {
        if (_sortColumnIndex == columnIndex) {
          if (_sortAscending) {
            // Already Asc -> Desc
            _sortAscending = false;
          } else {
            // Already Desc -> None
            _sortColumnIndex = null;
            _sortAscending = true;
          }
        } else {
          // New column -> Asc
          _sortColumnIndex = columnIndex;
          _sortAscending = true;
        }
      });
      if (widget.onSortChanged != null) {
        widget.onSortChanged!(_sortColumnIndex, _sortAscending);
      }
    }
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

    final sortedAssets = _getSortedAssets(visibleCols);

    final hasActions =
        widget.onEdit != null ||
        widget.onDelete != null ||
        widget.customActionsBuilder != null;

    // ── Pagination math ────────────────────────────────────────────────────
    final totalItems = sortedAssets.length;
    final totalPages = totalItems == 0 ? 1 : (totalItems / _rowsPerPage).ceil();

    final effectivePage = _currentPage.clamp(
      0,
      totalPages > 0 ? totalPages - 1 : 0,
    );

    final startIndex = effectivePage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
    final pageAssets = sortedAssets.sublist(startIndex, endIndex);

    final datatableTheme = Theme.of(context).copyWith(
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
      ),
      dataTableTheme: DataTableThemeData(
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered) && widget.onRowTap != null) {
            return Theme.of(context).colorScheme.primary.withAlpha(20);
          }
          return null;
        }),
      ),
    );

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
                '${sortedAssets.length} registro(s)',
                style: const TextStyle(color: Colors.black87, fontSize: 13),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // ── Sticky Header + Scrollable Body (horizontal unified scroll) ──
        Expanded(
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FIXED HEADER ---
                  Theme(
                    data: datatableTheme,
                    child: DataTable(
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      headingRowHeight: 56, // Fixed height for both
                      // Remove built-in sort to prevent layout shift
                      sortColumnIndex: null,
                      sortAscending: _sortAscending,
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withAlpha(128),
                      ),
                      columns: [
                        if (hasActions)
                          DataColumn(
                            label: SizedBox(
                              width: _getColWidth('Acciones'),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  'Acciones',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ...visibleCols.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final col = entry.value;
                          final colIdx = hasActions ? idx + 1 : idx;
                          final isSorted = _sortColumnIndex == colIdx;

                          return DataColumn(
                            // Remove onSort to eliminate the 16x16 RichText spacing
                            label: InkWell(
                              onTap: () =>
                                  _onSort(colIdx, _sortAscending, visibleCols),
                              child: SizedBox(
                                width: _getColWidth(col.label),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          col.label,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        isSorted
                                            ? (_sortAscending
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward)
                                            : Icons.sort,
                                        size: 14,
                                        color: isSorted
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      rows: const [], // No data rows in header component
                    ),
                  ),

                  // --- SCROLLABLE BODY ---
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      child: Theme(
                        data: datatableTheme,
                        child: DataTable(
                          headingRowHeight: 0, // Hide the header in body
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 52,
                          columnSpacing: 0,
                          horizontalMargin: 0,
                          sortColumnIndex: null, // Unified alignment
                          sortAscending: _sortAscending,
                          showCheckboxColumn: false,
                          border: TableBorder(
                            verticalInside: BorderSide(
                              color: Colors.grey.withAlpha(80),
                              width: 1,
                            ),
                          ),
                          columns: [
                            if (hasActions)
                              DataColumn(
                                label: SizedBox(
                                  width: _getColWidth('Acciones'),
                                ),
                              ),
                            ...visibleCols.map(
                              (col) => DataColumn(
                                label: SizedBox(width: _getColWidth(col.label)),
                              ),
                            ),
                          ],
                          rows: pageAssets
                              .map(
                                (asset) =>
                                    _buildRow(asset, visibleCols, hasActions),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Pagination footer ─────────────────────────────────────────────
        MaterialListPaginator(
          rowsPerPage: _rowsPerPage,
          currentPage: effectivePage,
          totalItems: totalItems,
          rowsPerPageOptions: const [10, 20, 30, 40, 50, 100],
          onRowsPerPageChanged: (v) => setState(() {
            _rowsPerPage = v;
            _currentPage = 0;
          }),
          onFirst: () => setState(() => _currentPage = 0),
          onPrevious: () => setState(() => _currentPage = effectivePage - 1),
          onNext: () => setState(() => _currentPage = effectivePage + 1),
          onLast: () => setState(() => _currentPage = totalPages - 1),
        ),
      ],
    );
  }
}
