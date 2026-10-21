import 'package:flutter/material.dart';
import 'package:inkash/core/format/parse_monto.dart';
import 'package:inkash/theme.dart';

/// Resultado de [pedirMonto]: qué botón se tocó y el monto en centavos.
typedef RespuestaMonto = ({String accion, int? centavos});

/// Pide un monto en una hoja inferior. La última acción es la principal y
/// solo se habilita con un monto válido; las demás (p. ej. "Quitar") no
/// necesitan monto.
///
/// ¿Por qué un StatefulWidget? El State es dueño del TextEditingController
/// y lo libera cuando la hoja realmente desaparece. Si el controller se
/// crea en la función y se hace dispose() al volver, la hoja todavía se
/// anima al cerrarse y usa un controller destruido.
Future<RespuestaMonto?> pedirMonto(
  BuildContext context, {
  required String titulo,
  String? ayuda,
  int? inicialCentavos,
  List<String> acciones = const ['Guardar'],
}) {
  return showModalBottomSheet<RespuestaMonto>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: kSuperficie,
    builder: (_) => _HojaMonto(
      titulo: titulo,
      ayuda: ayuda,
      inicialCentavos: inicialCentavos,
      acciones: acciones,
    ),
  );
}

class _HojaMonto extends StatefulWidget {
  const _HojaMonto({
    required this.titulo,
    required this.ayuda,
    required this.inicialCentavos,
    required this.acciones,
  });

  final String titulo;
  final String? ayuda;
  final int? inicialCentavos;
  final List<String> acciones;

  @override
  State<_HojaMonto> createState() => _HojaMontoState();
}

class _HojaMontoState extends State<_HojaMonto> {
  late final _controller = TextEditingController(
    text: switch (widget.inicialCentavos) {
      null => '',
      final c => '${c ~/ 100}.${(c % 100).toString().padLeft(2, '0')}',
    },
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _centavos => parseMontoCentavos(_controller.text);

  @override
  Widget build(BuildContext context) {
    final principal = widget.acciones.last;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.titulo, style: Theme.of(context).textTheme.titleLarge),
          if (widget.ayuda != null) ...[
            const SizedBox(height: 4),
            Text(widget.ayuda!, style: const TextStyle(color: kMuted)),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: 'Q ',
              hintText: '0.00',
              errorText: _controller.text.isNotEmpty && _centavos == null
                  ? 'Mayor a 0 y hasta 2 decimales'
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final accion in widget.acciones.take(
                widget.acciones.length - 1,
              ))
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, (
                      accion: accion,
                      centavos: _centavos,
                    )),
                    child: Text(accion),
                  ),
                ),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _centavos == null
                      ? null
                      : () => Navigator.pop(context, (
                          accion: principal,
                          centavos: _centavos,
                        )),
                  child: Text(principal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
