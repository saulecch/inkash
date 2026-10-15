/// Convierte una fecha guardada (epoch ms) en la etiqueta corta del dashboard.
///
/// Hoy · Ayer · Lun 20 (esta semana) · Jul 15 (más antiguo).
/// `ahora` se puede inyectar para que las pruebas no dependan del reloj.
String etiquetaFecha(DateTime fecha, {DateTime? ahora}) {
  final hoy = _soloDia(ahora ?? DateTime.now());
  final dia = _soloDia(fecha);
  final diferencia = hoy.difference(dia).inDays;

  if (diferencia == 0) return 'Hoy';
  if (diferencia == 1) return 'Ayer';
  if (diferencia > 1 && diferencia < 7) {
    return '${_dias[fecha.weekday - 1]} ${fecha.day}';
  }
  return '${_meses[fecha.month - 1]} ${fecha.day}';
}

DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _meses = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];
