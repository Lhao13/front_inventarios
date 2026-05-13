// LocalDbService - STUB para panel web.
// En el panel web todo se maneja directamente con Supabase.
// Este archivo existe solo para compatibilidad de compilación.

class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  Future<void> enqueueOperation(String name, Map<String, dynamic> params) async {
    throw UnimplementedError('LocalDbService no está disponible en el panel web.');
  }

  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    throw UnimplementedError('LocalDbService no está disponible en el panel web.');
  }
}
