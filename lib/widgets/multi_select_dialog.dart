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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
    _filteredItems = List.from(widget.items);
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          final display = item[widget.displayKey]?.toString().toLowerCase() ?? '';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedIds.clear()),
                  child: const Text('Limpiar Todo'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    final filteredIds = _filteredItems.map((e) => e[widget.valueKey] as T).toList();
                    _selectedIds.addAll(filteredIds.where((id) => !_selectedIds.contains(id)));
                  }),
                  child: const Text('Seleccionar Visibles'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
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
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                },
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
