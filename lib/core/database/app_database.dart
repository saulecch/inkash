import 'package:sqflite/sqflite.dart';

/// Base de datos local compartida en toda la aplicación.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, this.path = 'inkash.db'})
    : _factory = factory ?? databaseFactory;

  static final AppDatabase instance = AppDatabase();

  final DatabaseFactory _factory;
  final String path;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    try {
      // sqflite encuentra el path a la base de datos.
      return await _factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          // configuración
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          // en la creación
          onCreate: (db, version) async {
            // solo id, nombre que no sea nulo e icono tampoco nulo
            await db.execute('''
              CREATE TABLE categorias (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL UNIQUE CHECK (length(trim(nombre)) > 0),
                icono TEXT NOT NULL
              )
            ''');
            // id, titulo, monto, fecha en milisegundos para guardar hora, categoria
            await db.execute('''
              CREATE TABLE movimientos (
                id TEXT NOT NULL PRIMARY KEY,
                titulo TEXT NOT NULL,
                monto_centavos INTEGER NOT NULL,
                fecha INTEGER NOT NULL,
                categoria_id INTEGER NOT NULL,
                FOREIGN KEY (categoria_id) REFERENCES categorias (id)
                  ON DELETE RESTRICT
              )
            ''');
            await db.execute('''
              CREATE INDEX idx_movimientos_categoria_id
              ON movimientos (categoria_id)
            ''');
          },
        ),
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final pending = _database;
    if (pending == null) return;
    final db = await pending;
    await db.close();
    _database = null;
  }
}
