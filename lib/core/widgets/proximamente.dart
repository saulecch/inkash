import 'package:flutter/material.dart';
import 'package:inkash/theme.dart';

// Pantalla temporal para pestañas que aún no existen. Mejor esto que un
// botón que no hace nada: el usuario sabe que no es un error.
class ProximamentePage extends StatelessWidget {
  const ProximamentePage({
    required this.titulo,
    required this.icono,
    super.key,
  });

  final String titulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: kMuted, size: 40),
            const SizedBox(height: 12),
            Text(titulo, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            const Text('Próximamente', style: TextStyle(color: kMuted)),
          ],
        ),
      ),
    );
  }
}
