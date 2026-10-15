import 'package:sqflite/sqflite.dart';

/// Base de datos local compartida en toda la aplicación.
class AppDatabase {
  AppDatabase({this.factory, this.path = 'inkash.db'});

  static final AppDatabase instance = AppDatabase();

  // Se resuelve al ABRIR, no al construir: así crear el datasource en una
  // prueba de widget no exige tener sqflite inicializado.
  final DatabaseFactory? factory;
  final String path;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    try {
      // sqflite encuentra el path a la base de datos.
      return await (factory ?? databaseFactory).openDatabase(
        path,
        options: OpenDatabaseOptions(
          // S14-03: versión 2 agrega la tabla cache_tipo_cambio.
          // Subir la versión es la ÚNICA forma de cambiar el esquema en
          // teléfonos que ya tienen la app instalada (onCreate no se repite).
          version: 2,
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
            // Instalación nueva: se crea todo, incluido lo de la versión 2.
            await _crearCacheTipoCambio(db);
          },
          // Instalación existente: solo se aplica lo que le falta.
          // Nunca se borran tablas: se perderían los movimientos del usuario.
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) await _crearCacheTipoCambio(db);
          },
        ),
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  static Future<void> _crearCacheTipoCambio(Database db) async {
    await db.execute('''
      CREATE TABLE cache_tipo_cambio (
        moneda TEXT NOT NULL PRIMARY KEY,
        quetzales_diezmilesimas INTEGER NOT NULL,
        actualizado_ms INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final pending = _database;
    if (pending == null) return;
    final db = await pending;
    await db.close();
    _database = null;
  }
}
