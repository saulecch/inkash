class Ajustes {
  const Ajustes({
    required this.nombre,
    required this.limiteMensualCentavos,
    this.bienvenidaCompleta = false,
  });

  // Valores por defecto: lo que la app mostraba escrito a mano antes de S17.
  static const porDefecto = Ajustes(nombre: '', limiteMensualCentavos: 650000);

  final String nombre; // '' = el usuario no lo ha dicho
  final int limiteMensualCentavos;

  // s17-03: ¿ya pasó por la bienvenida? Al borrar los datos vuelve a false,
  // así que quien "empieza de cero" la ve otra vez.
  final bool bienvenidaCompleta;

  String get saludo => nombre.isEmpty ? 'Hola' : 'Hola, $nombre';
}
