import 'package:flutter/material.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/theme.dart';

/// Un monto en quetzales con números tabulares. Ingresos en lima, deudas y
/// gastos negativos en rojo: el color repite lo que dice el signo.
class Monto extends StatelessWidget {
  const Monto(this.centavos, {this.estilo, this.colorear = false, super.key});

  final int centavos;
  final TextStyle? estilo;

  /// true: positivo en lima y negativo en rojo (saldos, movimientos).
  final bool colorear;

  @override
  Widget build(BuildContext context) {
    final base = estilo ?? DefaultTextStyle.of(context).style;
    final color = !colorear
        ? null
        : centavos < 0
        ? kPeligro
        : centavos > 0
        ? kLima
        : null;
    return Text(
      formatQuetzales(centavos),
      style: base.copyWith(color: color, fontFeatures: kNumerosTabulares),
    );
  }
}
