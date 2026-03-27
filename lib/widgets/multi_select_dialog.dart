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

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedIds.clear()),
                  child: const Text('Limpiar Todo'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedIds = widget.items.map((e) => e[widget.valueKey] as T).toList();
                  }),
                  child: const Text('Seleccionar Todo'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
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
