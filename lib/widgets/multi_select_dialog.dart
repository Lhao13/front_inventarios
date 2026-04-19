import 'package:flutter/material.dart';

class MultiSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final List<T> initialSelectedIds;
  final String displayKey;
  final String valueKey;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    required this.initialSelectedIds,
    required this.displayKey,
    this.valueKey = 'id',
  });

  @override
  State<MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late List<T> _selectedIds;
  late List<Map<String, dynamic>> _filteredItems;

  late List<Map<String, dynamic>> _sortedItems;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
    _sortedItems = List.from(widget.items);
    _sortItems();
    _filteredItems = List.from(_sortedItems);
  }

  void _sortItems() {
    _sortedItems.sort((a, b) {
      final aSelected = _selectedIds.contains(a[widget.valueKey]);
      final bSelected = _selectedIds.contains(b[widget.valueKey]);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      final valA = a[widget.displayKey]?.toString().toLowerCase() ?? '';
      final valB = b[widget.displayKey]?.toString().toLowerCase() ?? '';
      return valA.compareTo(valB);
    });
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_sortedItems);
      } else {
        _filteredItems = _sortedItems.where((item) {
          final display =
              item[widget.displayKey]?.toString().toLowerCase() ?? '';
          return display.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.all(8),
              ),
              onChanged: _filterItems,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                SizedBox(
                  width: 100,
                  child: TextButton(
                    onPressed: () => setState(() => _selectedIds.clear()),
                    child: const Text('Limpiar Todo'),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextButton(
                    onPressed: () => setState(() {
                      final filteredIds = _filteredItems
                          .map((e) => e[widget.valueKey] as T)
                          .toList();
                      _selectedIds.addAll(
                        filteredIds.where((id) => !_selectedIds.contains(id)),
                      );
                    }),
                    child: const Text('Seleccionar Visibles'),
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final val = item[widget.valueKey] as T;
                    final display = item[widget.displayKey]?.toString() ?? '';

                    return CheckboxListTile(
                      title: Text(display),
                      value: _selectedIds.contains(val),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.add(val);
                          } else {
                            _selectedIds.remove(val);
                          }
                        });
                      },
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
