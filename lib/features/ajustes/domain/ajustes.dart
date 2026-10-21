class Ajustes {
  const Ajustes({required this.nombre, required this.limiteMensualCentavos});

  // Valores por defecto: lo que la app mostraba escrito a mano antes de S17.
  static const porDefecto = Ajustes(nombre: '', limiteMensualCentavos: 650000);

  final String nombre; // '' = el usuario no lo ha dicho
  final int limiteMensualCentavos;

  String get saludo => nombre.isEmpty ? 'Hola' : 'Hola, $nombre';
}
