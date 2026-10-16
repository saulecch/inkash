import 'package:flutter/material.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/core/widgets/iconos.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/theme.dart';

// s15-03: antes era el método filaMovimiento() de HomePage. Ahora lo usan
// el Inicio y el Historial: un widget reutilizable (como ProductoPedido).
class MovimientoTile extends StatelessWidget {
  const MovimientoTile({required this.movimiento, super.key});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kIconoFondo,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(iconoDe(movimiento.icono), color: kLima),
      ),
      title: Text(movimiento.titulo, style: const TextStyle(color: kTexto)),
      subtitle: Text(
        movimiento.subtitulo,
        style: const TextStyle(color: kMuted),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatQuetzales(movimiento.montoFirmadoCentavos),
            style: TextStyle(
              fontSize: 13,
              color: movimiento.esIngreso ? kLima : kTexto,
            ),
          ),
          Text(
            movimiento.fecha,
            style: const TextStyle(fontSize: 10, color: kMuted),
          ),
        ],
      ),
    );
  }
}
