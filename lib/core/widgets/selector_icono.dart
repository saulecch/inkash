import 'package:flutter/material.dart';
import 'package:inkash/core/widgets/iconos.dart';
import 'package:inkash/theme.dart';

// Rejilla de iconos para elegir uno. La usan Cuentas y Categorías.
class SelectorIcono extends StatelessWidget {
  const SelectorIcono({
    required this.opciones,
    required this.seleccionado,
    required this.onSeleccionar,
    super.key,
  });

  final List<String> opciones; // claves de iconosDisponibles
  final String seleccionado;
  final ValueChanged<String> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final clave in opciones)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSeleccionar(clave),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: clave == seleccionado ? kIconoFondo : kFondo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: clave == seleccionado ? kLima : kBorde,
                ),
              ),
              child: Icon(
                iconoDe(clave),
                size: 20,
                color: clave == seleccionado ? kLima : kMuted,
              ),
            ),
          ),
      ],
    );
  }
}
