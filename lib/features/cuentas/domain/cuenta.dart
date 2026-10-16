// Dónde está el dinero: Efectivo, Banco, Tarjeta…
class Cuenta {
  const Cuenta({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.saldoCentavos,
    this.saldoInicialCentavos = 0,
  });

  final int id;
  final String nombre;
  final String icono;

  // Saldo inicial + suma de sus movimientos. Lo calcula SQLite.
  final int saldoCentavos;

  // Lo que había al empezar a usar la app. Negativo = deuda (tarjeta).
  final int saldoInicialCentavos;
}

// Error de negocio con mensaje para humanos.
class CuentaException implements Exception {
  const CuentaException(this.mensaje);

  final String mensaje;
}
