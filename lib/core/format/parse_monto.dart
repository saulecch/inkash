/// Convierte el texto del campo "Monto" a centavos **sin pasar por double**.
///
/// Ejemplos: '12.5' -> 1250 · '12.50' -> 1250 · '1,250' -> 125000.
/// Devuelve `null` si el texto no es un monto válido:
/// vacío, cero, negativo, más de 2 decimales o mayor que [maximoCentavos].
///
/// ¿Por qué no `(double.parse(texto) * 100).round()`? Porque en binario
/// 0.1 + 0.2 != 0.3 y con montos grandes el redondeo puede fallar.
/// Aquí separamos parte entera y decimales como texto y armamos un entero.
int? parseMontoCentavos(String texto, {int maximoCentavos = 100000000}) {
  // Aceptamos separador de miles con coma, como lo muestra formatQuetzales.
  final limpio = texto.trim().replaceAll(',', '');
  final match = RegExp(r'^(\d{1,9})(?:\.(\d{0,2}))?$').firstMatch(limpio);
  if (match == null) return null;

  final quetzales = int.parse(match.group(1)!);
  // '5' -> 50 centavos, '05' -> 5 centavos, '' -> 0.
  final decimales = (match.group(2) ?? '').padRight(2, '0');
  final centavos = quetzales * 100 + int.parse(decimales);

  if (centavos <= 0 || centavos > maximoCentavos) return null;
  return centavos;
}
