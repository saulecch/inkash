import 'package:flutter/material.dart';
import 'package:inkash/core/format/parse_monto.dart';
import 'package:inkash/core/widgets/selector_icono.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:inkash/theme.dart';

// Datos que el formulario de cuenta devuelve al guardar.
typedef DatosCuenta = ({String nombre, String icono, int saldoInicialCentavos});

// Formulario de cuenta en una hoja inferior: crear (cuenta == null) o editar.
// Igual que el formulario de movimientos: recibe funciones, no conoce SQLite.
class CuentaSheet extends StatefulWidget {
  const CuentaSheet({
    required this.onGuardar,
    this.cuenta,
    this.onEliminar,
    super.key,
  });

  final Cuenta? cuenta;
  final Future<void> Function(DatosCuenta datos) onGuardar;
  final Future<void> Function()? onEliminar;

  static const iconos = [
    'payments',
    'account_balance',
    'credit_card',
    'savings',
    'wallet',
  ];

  @override
  State<CuentaSheet> createState() => _CuentaSheetState();
}

class _CuentaSheetState extends State<CuentaSheet> {
  late final _nombre = TextEditingController(text: widget.cuenta?.nombre);
  late final _saldo = TextEditingController(
    text: switch (widget.cuenta?.saldoInicialCentavos.abs()) {
      null || 0 => '',
      final c => '${c ~/ 100}.${(c % 100).toString().padLeft(2, '0')}',
    },
  );
  late String _icono = widget.cuenta?.icono ?? CuentaSheet.iconos.first;
  late bool _esDeuda = (widget.cuenta?.saldoInicialCentavos ?? 0) < 0;
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombre.addListener(() => setState(() {}));
    _saldo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    _saldo.dispose();
    super.dispose();
  }

  // Saldo inicial: vacío o "0" = 0; si no, el mismo parser sin double.
  int? get _saldoCentavos {
    final texto = _saldo.text.trim();
    if (texto.isEmpty || RegExp(r'^0+(\.0*)?$').hasMatch(texto)) return 0;
    final centavos = parseMontoCentavos(texto);
    if (centavos == null) return null;
    return _esDeuda ? -centavos : centavos;
  }

  bool get _valido => _nombre.text.trim().isNotEmpty && _saldoCentavos != null;

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_ocupado) return; // guard de doble toque, como en movimientos
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await accion();
      if (mounted) Navigator.of(context).pop();
    } on CuentaException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.cuenta != null;
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
            editando ? 'Editar cuenta' : 'Nueva cuenta',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nombre,
            autofocus: !editando,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Banco Industrial',
            ),
          ),
          const SizedBox(height: 16),
          SelectorIcono(
            opciones: CuentaSheet.iconos,
            seleccionado: _icono,
            onSeleccionar: (i) => setState(() => _icono = i),
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Tengo')),
              ButtonSegment(value: true, label: Text('Debo')),
            ],
            selected: {_esDeuda},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _esDeuda = s.single),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _saldo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _esDeuda ? 'Deuda al empezar' : 'Saldo al empezar',
              prefixText: 'Q ',
              helperText: 'Lo que había antes de registrar movimientos',
              errorText: _saldoCentavos == null ? 'Monto inválido' : null,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kPeligro)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _valido && !_ocupado
                ? () => _ejecutar(
                    () => widget.onGuardar((
                      nombre: _nombre.text,
                      icono: _icono,
                      saldoInicialCentavos: _saldoCentavos!,
                    )),
                  )
                : null,
            child: Text(editando ? 'Guardar cambios' : 'Crear cuenta'),
          ),
          if (widget.onEliminar != null)
            TextButton(
              onPressed: _ocupado ? null : () => _ejecutar(widget.onEliminar!),
              style: TextButton.styleFrom(foregroundColor: kPeligro),
              child: const Text('Eliminar cuenta'),
            ),
        ],
      ),
    );
  }
}
