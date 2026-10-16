// Lo necesario para "Deshacer" un borrado. Para la UI es una caja cerrada:
// no sabe qué hay adentro, solo se la devuelve al repositorio.
class MovimientoEliminado {
  const MovimientoEliminado(this.fila);

  // La fila tal cual estaba en SQLite (mismo id, misma categoría y fecha).
  // Restaurar con la fila original evita "parecidos": es EL mismo registro.
  final Map<String, Object?> fila;
}
