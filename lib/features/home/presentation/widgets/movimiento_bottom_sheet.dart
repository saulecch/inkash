import 'package:flutter/material.dart';
import 'package:inkash/core/format/parse_monto.dart';
import 'package:inkash/core/widgets/iconos.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:inkash/theme.dart';

class MovimientoBottomSheet extends StatefulWidget {
  const MovimientoBottomSheet({
    required this.onGuardar,
    this.cuentas = const [],
    this.categorias = const [],
    this.onNuevaCategoria,
    super.key,
  });

  // El formulario NO conoce SQLite ni el repositorio: recibe una función.
  // Así se puede probar con una función falsa (ver test/).
  final Future<void> Function(NuevoMovimiento nuevo) onGuardar;

  // s16-01: las cuentas llegan por parámetro (igual que onGuardar):
  // el formulario sigue sin conocer providers ni SQLite.
  final List<Cuenta> cuentas;

  // s16-02: las categorías vienen de la base (por parámetro, como cuentas).
  final List<Categoria> categorias;

  // "+ Nueva": crea una categoría sin salir del formulario. Devuelve la
  // categoría creada (o null si el usuario canceló).
  final Future<Categoria?> Function(TipoCategoria tipo)? onNuevaCategoria;

  @override
  State<MovimientoBottomSheet> createState() => _MovimientoBottomSheetState();
}

class _MovimientoBottomSheetState extends State<MovimientoBottomSheet> {
  // Copia local: "+ Nueva" agrega aquí la recién creada.
  late final List<Categoria> _todas = [...widget.categorias];

  // Solo las activas del tipo elegido: en modo Gasto no aparece "Salario".
  List<Categoria> get _categorias => [
    for (final c in _todas)
      if (!c.archivada && c.esIngreso == _esIngreso) c,
  ];

  Future<void> _nuevaCategoria() async {
    final creada = await widget.onNuevaCategoria!(
      _esIngreso ? TipoCategoria.ingreso : TipoCategoria.gasto,
    );
    if (creada == null || !mounted) return;
    setState(() {
      _todas.add(creada);
      _categoria = creada.nombre;
    });
  }

  final _montoController = TextEditingController();
  final _tituloController = TextEditingController();

  bool _esIngreso = false;
  String? _categoria;
  // La primera cuenta (Efectivo) viene seleccionada: un toque menos.
  late int? _cuentaId = widget.cuentas.firstOrNull?.id;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();

  // Estado del guardado: mientras es true el botón se deshabilita.
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Reconstruir al escribir para habilitar/deshabilitar el botón.
    _montoController.addListener(_refrescar);
    _tituloController.addListener(_refrescar);
  }

  @override
  void dispose() {
    _montoController.dispose();
    _tituloController.dispose();
    super.dispose();
  }

  void _refrescar() => setState(() {});

  int? get _montoCentavos => parseMontoCentavos(_montoController.text);

  bool get _formularioValido =>
      _montoCentavos != null &&
      _tituloController.text.trim().isNotEmpty &&
      _categoria != null;

  Future<void> _guardar() async {
    // Guard contra doble toque: se revisa ANTES del primer await.
    // Si se revisara después, dos toques rápidos pasarían los dos.
    if (_guardando || !_formularioValido) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    // Fecha y hora vienen de selectores distintos: se combinan aquí.
    final fecha = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    try {
      await widget.onGuardar(
        NuevoMovimiento(
          titulo: _tituloController.text.trim(),
          montoCentavos: _montoCentavos!,
          esIngreso: _esIngreso,
          categoria: _categoria!,
          cuentaId: _cuentaId,
          fecha: fecha,
        ),
      );
      // Después de un await la pantalla pudo cerrarse: siempre preguntar.
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      // El formulario conserva lo escrito para que el usuario reintente.
      if (mounted) {
        setState(() => _error = 'No se pudo guardar. Intenta otra vez.');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    FocusScope.of(context).unfocus();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );

    if (fecha == null || !mounted) return;

    setState(() {
      _fecha = fecha;
    });
  }

  Future<void> _seleccionarHora() async {
    FocusScope.of(context).unfocus();
    final hora = await showTimePicker(context: context, initialTime: _hora);
    if (hora == null || !mounted) return;

    setState(() {
      _hora = hora;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fechaTexto = DateUtils.isSameDay(_fecha, DateTime.now())
        ? 'Hoy'
        : MaterialLocalizations.of(context).formatMediumDate(_fecha);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nuevo movimiento',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: kTexto,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: kMuted),
                  ),
                ],
              ),
              const Text(
                'Lleva el control de lo que entra y sale.',
                style: TextStyle(color: kMuted),
              ),
              const SizedBox(height: 24),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.arrow_upward_rounded),
                    label: Text('Gasto'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.arrow_downward_rounded),
                    label: Text('Ingreso'),
                  ),
                ],
                selected: {_esIngreso},
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: kLima,
                  selectedForegroundColor: kFondo,
                  foregroundColor: kMuted,
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: kBorde),
                ),
                onSelectionChanged: (seleccion) {
                  setState(() {
                    _esIngreso = seleccion.single;
                    // La categoría elegida ya no es del tipo: se limpia.
                    if (!_categorias.any((c) => c.nombre == _categoria)) {
                      _categoria = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _montoController,
                decoration: _decoracion('Monto', hint: '0.00').copyWith(
                  // Solo mostramos error si ya escribió algo inválido.
                  errorText:
                      _montoController.text.isNotEmpty && _montoCentavos == null
                      ? 'Monto inválido: mayor a 0 y hasta 2 decimales'
                      : null,
                  prefixText: 'Q ',
                  prefixStyle: const TextStyle(color: kMuted, fontSize: 28),
                  helperText: 'En quetzales · Usa hasta 2 decimales',
                  helperMaxLines: 2,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: kTexto,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tituloController,
                decoration: _decoracion(
                  'Título',
                  hint: 'Ej. Compra de la semana',
                ).copyWith(prefixIcon: const Icon(Icons.edit_outlined)),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 24),
              Text(
                'Categoría',
                style: theme.textTheme.titleSmall?.copyWith(color: kTexto),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final categoria in _categorias)
                    ChoiceChip(
                      label: Text(categoria.nombre),
                      avatar: Icon(
                        iconoDe(categoria.icono),
                        size: 18,
                        color: _categoria == categoria.nombre ? kLima : kMuted,
                      ),
                      selected: _categoria == categoria.nombre,
                      selectedColor: kIconoFondo,
                      backgroundColor: kSuperficie,
                      labelStyle: TextStyle(
                        color: _categoria == categoria.nombre ? kLima : kTexto,
                      ),
                      side: BorderSide(
                        color: _categoria == categoria.nombre ? kLima : kBorde,
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _categoria = selected ? categoria.nombre : null;
                        });
                      },
                    ),
                  if (widget.onNuevaCategoria != null)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18, color: kLima),
                      label: const Text('Nueva'),
                      backgroundColor: kSuperficie,
                      side: const BorderSide(color: kBorde),
                      onPressed: _nuevaCategoria,
                    ),
                ],
              ),
              // s16-01: selector de cuenta (solo si hay cuentas).
              if (widget.cuentas.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Cuenta',
                  style: theme.textTheme.titleSmall?.copyWith(color: kTexto),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final cuenta in widget.cuentas)
                      ChoiceChip(
                        label: Text(cuenta.nombre),
                        selected: _cuentaId == cuenta.id,
                        selectedColor: kIconoFondo,
                        backgroundColor: kSuperficie,
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _cuentaId = cuenta.id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final apilar =
                      constraints.maxWidth < 320 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20;
                  final fecha = _selectorTemporal(
                    label: 'Fecha',
                    value: fechaTexto,
                    icon: Icons.calendar_today_outlined,
                    onTap: _seleccionarFecha,
                  );
                  final hora = _selectorTemporal(
                    label: 'Hora',
                    value: _hora.format(context),
                    icon: Icons.schedule_outlined,
                    onTap: _seleccionarHora,
                  );
                  if (apilar) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [fecha, const SizedBox(height: 12), hora],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: fecha),
                      const SizedBox(width: 12),
                      Expanded(child: hora),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // null deshabilita el botón: inválido o guardando.
              FilledButton.icon(
                onPressed: _formularioValido && !_guardando ? _guardar : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _guardando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _guardando
                      ? 'Guardando…'
                      : _esIngreso
                      ? 'Guardar ingreso'
                      : 'Guardar gasto',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kPeligro, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: kFondo,
      labelStyle: const TextStyle(color: kMuted),
      hintStyle: const TextStyle(color: kMuted),
      contentPadding: const EdgeInsets.all(16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kLima, width: 2),
      ),
    );
  }

  Widget _selectorTemporal({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: kTexto,
        padding: const EdgeInsets.all(16),
        side: const BorderSide(color: kBorde),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: kMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
