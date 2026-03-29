import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Servicio local para el manejo Offline-First de Caché y Cola de Operaciones.
/// Utiliza un esquema tipo "Document Store" (collection, id, json_data) para no 
/// depender de decenas de tablas relacionales en el móvil.
class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventarios_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla caché estilo Document Store para lectura de todas las tablas
    await db.execute('''
      CREATE TABLE cache_storage (
        collection TEXT NOT NULL,
        id TEXT NOT NULL,
        json_data TEXT NOT NULL,
        PRIMARY KEY (collection, id)
      )
    ''');

    // Tabla de cola de operaciones offline para envíos pendientes
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        rpc_name TEXT NOT NULL,
        params_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // ==========================================================
  // 1. MANEJO DE CACHÉ (LECTURAS)
  // ==========================================================

  /// Guarda una colección completa (útil para cuando llega la info de internet)
  Future<void> saveCollection(String collection, List<Map<String, dynamic>> items, String idKey) async {
    final db = await instance.database;
    final batch = db.batch();

    // Limpiamos los anteriores para tener siempre los datos frescos
    batch.delete('cache_storage', where: 'collection = ?', whereArgs: [collection]);

    for (final item in items) {
      batch.insert('cache_storage', {
        'collection': collection,
        'id': item[idKey].toString(),
        'json_data': jsonEncode(item),
      });
    }

    await batch.commit(noResult: true);
  }

  /// Recupera una colección desde el caché local offline
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final db = await instance.database;
    final res = await db.query(
      'cache_storage',
      where: 'collection = ?',
      whereArgs: [collection],
    );

    return res.map((row) => jsonDecode(row['json_data'] as String) as Map<String, dynamic>).toList();
  }

  /// Limpia toda la base de datos local
  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('cache_storage');
    await db.delete('sync_queue');
  }

  // ==========================================================
  // 2. MANEJO DE COLA DE OPERACIONES (ESCRITURAS OFFLINE)
  // ==========================================================

  /// Añade una instrucción RPC a la cola para ser ejecutada cuando haya internet
  Future<void> enqueueOperation(String rpcName, Map<String, dynamic> params) async {
    final db = await instance.database;
    // Si la operación falla, se queda en pendiente ("pending")
    await db.insert('sync_queue', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(), // ID simple temporal
      'rpc_name': rpcName,
      'params_json': jsonEncode(params),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }

  /// Obtiene las operaciones pendientes
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await instance.database;
    return await db.query('sync_queue', where: 'status = ?', whereArgs: ['pending'], orderBy: 'created_at ASC');
  }

  /// Elimina una operación de la cola tras haberse completado con éxito online
  Future<void> removeOperation(String id) async {
    final db = await instance.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }
}
