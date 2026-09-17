import 'package:flutter/material.dart';

// Usamos StatefulWidget porque el formulario cambia mientras lo llenamos.
class MovimientoBottomSheet extends StatefulWidget {
  const MovimientoBottomSheet({super.key});

  @override
  State<MovimientoBottomSheet> createState() => _MovimientoBottomSheetState();
}

class _MovimientoBottomSheetState extends State<MovimientoBottomSheet> {
  // Por ahora las categorías están aquí, después vendrán de la BD.
  final _categorias = [
    'Transporte',
    'Súper y comida',
    'Ingreso',
    'Entretenimiento',
    'Servicios',
    'Hogar',
  ];

  bool _esIngreso = false;
  String? _categoria;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );

    // Si cancelamos o ya cerramos el formulario, no hacemos nada.
    if (fecha == null || !mounted) return;

    // setState le dice a Flutter que muestre el nuevo valor.
    setState(() {
      _fecha = fecha;
    });
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);
    if (hora == null || !mounted) return;

    setState(() {
      _hora = hora;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Dejamos espacio para que el teclado no tape los campos.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        // Si no cabe todo, podemos deslizar el formulario.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nuevo movimiento'),
              // Apagado = gasto. Encendido = ingreso.
              SwitchListTile(
                title: Text(_esIngreso ? 'Ingreso' : 'Gasto'),
                value: _esIngreso,
                onChanged: (valor) {
                  setState(() {
                    _esIngreso = valor;
                  });
                },
              ),
              const TextField(decoration: InputDecoration(labelText: 'Título')),
              const TextField(
                decoration: InputDecoration(labelText: 'Monto (Q)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              // Creamos una opción por cada categoría de la lista.
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Selecciona una categoría'),
                value: _categoria,
                items: [
                  for (final categoria in _categorias)
                    DropdownMenuItem(value: categoria, child: Text(categoria)),
                ],
                onChanged: (valor) {
                  setState(() {
                    _categoria = valor;
                  });
                },
              ),
              TextButton(
                onPressed: _seleccionarFecha,
                child: Text(
                  'Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}',
                ),
              ),
              TextButton(
                onPressed: _seleccionarHora,
                child: Text('Hora: ${_hora.format(context)}'),
              ),
              // null deja el botón desactivado. Todavía no vamos a guardar.
              const ElevatedButton(
                onPressed: null,
                child: Text('Guardar movimiento'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
