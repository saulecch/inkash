import 'package:flutter/material.dart';
import 'package:inkash/core/format/parse_monto.dart';
import 'package:inkash/features/metas/domain/meta.dart';
import 'package:inkash/theme.dart';

typedef DatosMeta = ({String nombre, int objetivoCentavos});

// Crear (meta == null) o editar el nombre y objetivo de una meta.
class MetaSheet extends StatefulWidget {
  const MetaSheet({
    required this.onGuardar,
    this.meta,
    this.onEliminar,
    super.key,
  });

  final Meta? meta;
  final Future<void> Function(DatosMeta datos) onGuardar;
  final Future<void> Function()? onEliminar;

  @override
  State<MetaSheet> createState() => _MetaSheetState();
}

class _MetaSheetState extends State<MetaSheet> {
  late final _nombre = TextEditingController(text: widget.meta?.nombre);
  late final _objetivo = TextEditingController(
    text: switch (widget.meta?.objetivoCentavos) {
      null => '',
      final c => '${c ~/ 100}.${(c % 100).toString().padLeft(2, '0')}',
    },
  );
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _nombre.addListener(() => setState(() {}));
    _objetivo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  int? get _objetivoCentavos => parseMontoCentavos(_objetivo.text);

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await accion();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valido = _nombre.text.trim().isNotEmpty && _objetivoCentavos != null;
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
          Text(
            widget.meta == null ? 'Nueva meta' : 'Editar meta',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nombre,
            autofocus: widget.meta == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Viaje a Tikal',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _objetivo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Objetivo',
              prefixText: 'Q ',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: valido && !_ocupado
                ? () => _ejecutar(
                    () => widget.onGuardar((
                      nombre: _nombre.text,
                      objetivoCentavos: _objetivoCentavos!,
                    )),
                  )
                : null,
            child: Text(widget.meta == null ? 'Crear meta' : 'Guardar cambios'),
          ),
          if (widget.onEliminar != null)
            TextButton(
              onPressed: _ocupado ? null : () => _ejecutar(widget.onEliminar!),
              style: TextButton.styleFrom(foregroundColor: kPeligro),
              child: const Text('Eliminar meta'),
            ),
        ],
      ),
    );
  }
}
