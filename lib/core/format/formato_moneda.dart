/// Convierte un monto en centavos a texto legible en Quetzales (Q).
///
/// Ejemplo: [370350] -> 'Q3,703.50'
String formatQuetzales(int centavos) {
  final esNegativo = centavos < 0;
  final absoluto = centavos.abs();

  final entero = absoluto ~/ 100;
  final decimales = (absoluto % 100).toString().padLeft(2, '0');
  final miles = entero.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );

  if (esNegativo) {
    return '−Q$miles.$decimales';
  }
  return 'Q$miles.$decimales';
}
