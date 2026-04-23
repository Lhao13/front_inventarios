import 'package:flutter/material.dart';

/// Un diálogo que permite buscar y seleccionar un único elemento de una lista grande.
/// Devuelve el valor `T` seleccionado, o null si se canceló.
class SingleSelectSearchDialog<T> extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String displayKey;

  const SingleSelectSearchDialog({
    super.key,
    required this.title,
    required this.items,
    required this.displayKey,
  });

  @override
  State<SingleSelectSearchDialog<T>> createState() => _SingleSelectSearchDialogState<T>();
}

class _SingleSelectSearchDialogState<T> extends State<SingleSelectSearchDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredItems = List.from(widget.items));
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final val = (item[widget.displayKey] ?? '').toString().toLowerCase();
        return val.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filter('');
                  },
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(child: Text('No hay resultados'))
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final id = item['id'] as T;
                          return ListTile(
                            title: Text((item[widget.displayKey] ?? 'N/A').toString()),
                            onTap: () {
                              Navigator.pop(context, id);
                            },
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
      ],
    );
  }
}

/// Un componente envolvente (Wrapper) que actúa como FormField pero previene Overflows.
/// Abre un [SingleSelectSearchDialog] al pulsarlo y maneja su estado.
class SearchableDropdownFormField<T> extends FormField<T> {
  SearchableDropdownFormField({
    super.key,
    required String label,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required T? value,
    required ValueChanged<T?> onChanged,
    super.validator,
    bool required = false,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<T> state) {
            String displayVal = ''; // Vacío para que el label se muestre dentro (como hint)
            if (state.value != null) {
              final selectedItem = items.cast<Map<String,dynamic>?>().firstWhere(
                (item) => item != null && item['id'] == state.value,
                orElse: () => null,
              );
              if (selectedItem != null) {
                displayVal = selectedItem[displayKey]?.toString() ?? 'N/A';
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () async {
                  final result = await showDialog<T>(
                    context: state.context,
                    builder: (ctx) => SingleSelectSearchDialog<T>(
                      title: 'Seleccionar $label',
                      items: items,
                      displayKey: displayKey,
                    ),
                  );
                  if (result != null) {
                    state.didChange(result);
                    onChanged(result);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: required ? '$label *' : label,
                    isDense: true,
                    filled: required,
                    fillColor: required ? Colors.blue.withValues(alpha: 0.05) : null,
                    labelStyle: required
                        ? const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                        : null,
                    enabledBorder: required
                        ? OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          )
                        : const OutlineInputBorder(),
                    border: const OutlineInputBorder(),
                    errorText: state.errorText,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  isEmpty: state.value == null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayVal,
                          style: const TextStyle(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (state.value != null && !required)
                        InkWell(
                          onTap: () {
                            state.didChange(null);
                            onChanged(null);
                          },
                          child: const Icon(Icons.clear, size: 20, color: Colors.grey),
                        )
                      else
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        );
}
