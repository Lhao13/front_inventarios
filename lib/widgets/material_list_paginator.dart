import 'package:flutter/material.dart';

/// A Material-style pagination footer that visually matches
/// [PaginatedDataTable]'s built-in footer.
///
/// Shows:
///  • "Filas por página:" label + rows-per-page dropdown
///  • "X–Y de Z" range indicator
///  • First / Previous / Next / Last page icon buttons
class MaterialListPaginator extends StatelessWidget {
  final int rowsPerPage;
  final int currentPage;
  final int totalItems;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onRowsPerPageChanged;
  final VoidCallback onFirst;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLast;

  const MaterialListPaginator({
    super.key,
    required this.rowsPerPage,
    required this.currentPage,
    required this.totalItems,
    required this.rowsPerPageOptions,
    required this.onRowsPerPageChanged,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages =
        totalItems == 0 ? 1 : (totalItems / rowsPerPage).ceil();
    final startRow = totalItems == 0 ? 0 : currentPage * rowsPerPage + 1;
    final endRow = ((currentPage + 1) * rowsPerPage).clamp(0, totalItems);

    final textStyle = Theme.of(context).textTheme.bodySmall;
    final isFirstPage = currentPage <= 0;
    final isLastPage = currentPage >= totalPages - 1;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
          // "Filas por página:" label
          Text('Filas por página:', style: textStyle),
          const SizedBox(width: 8),

          // Rows-per-page dropdown (no underline to match PaginatedDataTable)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 36),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: rowsPerPage,
                style: textStyle,
                items: rowsPerPageOptions
                    .map(
                      (v) => DropdownMenuItem<int>(
                        value: v,
                        child: Text('$v', style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRowsPerPageChanged(v);
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Range indicator
          Text(
            totalItems == 0 ? '0 de 0' : '$startRow\u2013$endRow de $totalItems',
            style: textStyle,
          ),

          const SizedBox(width: 4),

          // First page
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 24,
            tooltip: 'Primera página',
            onPressed: isFirstPage ? null : onFirst,
          ),

          // Previous page
          IconButton(
            icon: const Icon(Icons.navigate_before),
            iconSize: 24,
            tooltip: 'Página anterior',
            onPressed: isFirstPage ? null : onPrevious,
          ),

          // Next page
          IconButton(
            icon: const Icon(Icons.navigate_next),
            iconSize: 24,
            tooltip: 'Página siguiente',
            onPressed: isLastPage ? null : onNext,
          ),

          // Last page
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 24,
            tooltip: 'Última página',
            onPressed: isLastPage ? null : onLast,
          ),

          const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
