import 'package:flutter/material.dart';
import 'package:inkash/theme.dart';

/// Tarjeta pequeña del Inicio: etiqueta + valor, y se puede tocar.
/// Las de Cuentas y Metas eran dos copias del mismo Container.
class TarjetaResumen extends StatelessWidget {
  const TarjetaResumen({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.onTap,
    super.key,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Espacio.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 20, color: kLima),
                const SizedBox(height: Espacio.m),
                Text(etiqueta, style: texto.bodySmall),
                const SizedBox(height: Espacio.xs),
                Text(
                  valor,
                  style: texto.titleLarge?.copyWith(
                    fontFeatures: kNumerosTabulares,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
