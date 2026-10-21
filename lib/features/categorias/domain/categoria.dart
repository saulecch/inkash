enum TipoCategoria { gasto, ingreso }

class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.tipo,
    this.archivada = false,
  });

  final int id;
  final String nombre;
  final String icono;
  final TipoCategoria tipo;

  // Archivada = ya no se ofrece al registrar, pero sus movimientos siguen.
  final bool archivada;

  bool get esIngreso => tipo == TipoCategoria.ingreso;
}

class CategoriaException implements Exception {
  const CategoriaException(this.mensaje);

  final String mensaje;
}
