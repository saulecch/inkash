import 'package:sqflite/sqflite.dart';

/// Base de datos local compartida en toda la aplicación.
class AppDatabase {
  AppDatabase({this.factory, this.path = 'inkash.db'});

  static final AppDatabase instance = AppDatabase();

  // s16-01: el esquema es una LISTA de migraciones numeradas.
  // - Instalación nueva (onCreate): se aplican todas, de la 1 a la última.
  // - Instalación existente (onUpgrade): solo las que le faltan.
  // Así un teléfono nuevo y uno actualizado terminan con el MISMO esquema,
  // y nunca hay que escribir el CREATE TABLE dos veces.
  // Regla de oro: una migración publicada NO se edita; se agrega otra.
  static final Map<int, Future<void> Function(Database)> migraciones = {
    1: _v1TablasBase,
    2: _v2CacheTipoCambio,
    3: _v3Cuentas,
  };
  static int get versionActual => migraciones.length;

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
          // Subir la versión es la ÚNICA forma de cambiar el esquema en
          // teléfonos que ya tienen la app instalada (onCreate no se repite).
          version: versionActual,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          // sqflite corre onCreate/onUpgrade dentro de una transacción:
          // si una migración falla, no queda un esquema a medias.
          onCreate: (db, version) => _migrar(db, desde: 0, hasta: version),
          onUpgrade: (db, desde, hasta) =>
              _migrar(db, desde: desde, hasta: hasta),
        ),
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  static Future<void> _migrar(
    Database db, {
    required int desde,
    required int hasta,
  }) async {
    for (var v = desde + 1; v <= hasta; v++) {
      await migraciones[v]!(db);
    }
  }

  // v1 (S11): categorías y movimientos.
  static Future<void> _v1TablasBase(Database db) async {
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
  }

  // v2 (S14-03): último tipo de cambio recibido, para modo sin conexión.
  static Future<void> _v2CacheTipoCambio(Database db) async {
    await db.execute('''
      CREATE TABLE cache_tipo_cambio (
        moneda TEXT NOT NULL PRIMARY KEY,
        quetzales_diezmilesimas INTEGER NOT NULL,
        actualizado_ms INTEGER NOT NULL
      )
    ''');
  }

  // v3 (S16-01): cuentas (Efectivo, Banco, Tarjeta) y movimiento -> cuenta.
  static Future<void> _v3Cuentas(Database db) async {
    await db.execute('''
      CREATE TABLE cuentas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE CHECK (length(trim(nombre)) > 0),
        icono TEXT NOT NULL,
        saldo_inicial_centavos INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      INSERT INTO cuentas (nombre, icono) VALUES
        ('Efectivo', 'payments'),
        ('Banco', 'account_balance'),
        ('Tarjeta', 'credit_card')
    ''');
    // ALTER TABLE solo puede AGREGAR columnas, y la nueva no puede ser
    // NOT NULL sin DEFAULT: los movimientos viejos no tienen cuenta.
    await db.execute('''
      ALTER TABLE movimientos
      ADD COLUMN cuenta_id INTEGER REFERENCES cuentas (id)
    ''');
    // Los movimientos que ya existían quedan en "Efectivo" (decisión de
    // producto, documentada en ADR-0004), no huérfanos.
    await db.execute('''
      UPDATE movimientos
      SET cuenta_id = (SELECT id FROM cuentas WHERE nombre = 'Efectivo')
    ''');
    await db.execute(
      'CREATE INDEX idx_movimientos_cuenta_id ON movimientos (cuenta_id)',
    );
  }

  Future<void> close() async {
    final pending = _database;
    if (pending == null) return;
    final db = await pending;
    await db.close();
    _database = null;
  }
}
