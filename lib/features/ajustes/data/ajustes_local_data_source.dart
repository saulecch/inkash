import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/ajustes/domain/ajustes.dart';
import 'package:sqflite/sqflite.dart';

class AjustesLocalDataSource {
  AjustesLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  static const _nombre = 'nombre';
  static const _limite = 'limite_mensual_centavos';
  static const _bienvenida = 'bienvenida_completa';

  Future<Ajustes> leer() async {
    final db = await _database.database;
    final valores = {
      for (final f in await db.query('ajustes'))
        f['clave']! as String: f['valor']! as String,
    };
    // Lo que no está guardado toma el valor por defecto.
    const d = Ajustes.porDefecto;
    return Ajustes(
      nombre: valores[_nombre] ?? d.nombre,
      limiteMensualCentavos:
          int.tryParse(valores[_limite] ?? '') ?? d.limiteMensualCentavos,
      bienvenidaCompleta: valores[_bienvenida] == '1',
    );
  }

  Future<void> guardarNombre(String nombre) => _guardar(_nombre, nombre);

  Future<void> guardarLimite(int centavos) =>
      _guardar(_limite, centavos.toString());

  Future<void> marcarBienvenidaCompleta() => _guardar(_bienvenida, '1');

  Future<void> _guardar(String clave, String valor) async {
    final db = await _database.database;
    await db.insert('ajustes', {
      'clave': clave,
      'valor': valor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Borra lo que el usuario registró. Las categorías y cuentas base se
  // quedan: son parte de la app, no datos del usuario.
  // Una transacción: o se borra todo, o nada.
  Future<void> borrarDatosDelUsuario() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final tabla in [
        'movimientos',
        'presupuestos',
        'metas',
        'ajustes',
        'cache_tipo_cambio',
      ]) {
        await txn.delete(tabla);
      }
    });
  }
}
