import 'package:flutter/material.dart';
import 'package:inkash/theme.dart';

class MovimientoBottomSheet extends StatefulWidget {
  const MovimientoBottomSheet({super.key});

  @override
  State<MovimientoBottomSheet> createState() => _MovimientoBottomSheetState();
}

class _MovimientoBottomSheetState extends State<MovimientoBottomSheet> {
  // Por ahora las categorías están aquí, después vendrán de la BD.
  static const _categorias = {
    'Transporte': Icons.directions_bus_outlined,
    'Súper y comida': Icons.shopping_basket_outlined,
    'Ingreso': Icons.payments_outlined,
    'Entretenimiento': Icons.movie_outlined,
    'Servicios': Icons.bolt_outlined,
    'Hogar': Icons.home_outlined,
  };

  bool _esIngreso = false;
  String? _categoria;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();

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
                  setState(() => _esIngreso = seleccion.single);
                },
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: _decoracion('Monto', hint: '0.00').copyWith(
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
                  for (final categoria in _categorias.entries)
                    ChoiceChip(
                      label: Text(categoria.key),
                      avatar: Icon(
                        categoria.value,
                        size: 18,
                        color: _categoria == categoria.key ? kLima : kMuted,
                      ),
                      selected: _categoria == categoria.key,
                      selectedColor: kIconoFondo,
                      backgroundColor: kSuperficie,
                      labelStyle: TextStyle(
                        color: _categoria == categoria.key ? kLima : kTexto,
                      ),
                      side: BorderSide(
                        color: _categoria == categoria.key ? kLima : kBorde,
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _categoria = selected ? categoria.key : null;
                        });
                      },
                    ),
                ],
              ),
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
              // Se habilitará cuando esté conectado el guardado.
              FilledButton.icon(
                onPressed: null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(_esIngreso ? 'Guardar ingreso' : 'Guardar gasto'),
              ),
              const SizedBox(height: 10),
              const Text(
                'El guardado de movimientos estará disponible pronto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted, fontSize: 12),
              ),
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
