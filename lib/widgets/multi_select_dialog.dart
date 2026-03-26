import 'package:flutter/material.dart';

class MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final List<int> initialSelectedIds;
  final String displayKey;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    required this.initialSelectedIds,
    required this.displayKey,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<int> _selectedIds;

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
                    _selectedIds = widget.items.map((e) => e['id'] as int).toList();
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
                  final id = item['id'] as int;
                  final display = item[widget.displayKey]?.toString() ?? '';

                  return CheckboxListTile(
                    title: Text(display),
                    value: _selectedIds.contains(id),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedIds.add(id);
                        } else {
                          _selectedIds.remove(id);
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
