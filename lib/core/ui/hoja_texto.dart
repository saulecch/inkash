import 'package:flutter/material.dart';
import 'package:inkash/core/ui/hoja_formulario.dart';

/// Pide un texto corto en una hoja inferior. Devuelve el texto o null.
/// Igual que pedirMonto: el State es dueño de su TextEditingController.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  String? descripcion,
  String inicial = '',
  String etiqueta = '',
  String accion = 'Guardar',
}) {
  return mostrarHoja<String>(
    context,
    (_) => _HojaTexto(
      titulo: titulo,
      descripcion: descripcion,
      inicial: inicial,
      etiqueta: etiqueta,
      accion: accion,
    ),
  );
}

class _HojaTexto extends StatefulWidget {
  const _HojaTexto({
    required this.titulo,
    required this.descripcion,
    required this.inicial,
    required this.etiqueta,
    required this.accion,
  });

  final String titulo;
  final String? descripcion;
  final String inicial;
  final String etiqueta;
  final String accion;

  @override
  State<_HojaTexto> createState() => _HojaTextoState();
}

class _HojaTextoState extends State<_HojaTexto> {
  late final _controller = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return HojaFormulario(
      titulo: widget.titulo,
      descripcion: widget.descripcion,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: widget.etiqueta),
          onSubmitted: (_) => _guardar(),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _guardar, child: Text(widget.accion)),
      ],
    );
  }
}
