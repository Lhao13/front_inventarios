// quick_search_result_page no se usa en el panel web - stub mínimo
import 'package:flutter/material.dart';

class QuickSearchResultPage extends StatelessWidget {
  final String searchQuery;
  const QuickSearchResultPage({super.key, required this.searchQuery});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Búsqueda: $searchQuery')),
      body: const Center(child: Text('Búsqueda rápida no disponible en panel web')),
    );
  }
}

