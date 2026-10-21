import 'package:flutter/material.dart';
import 'package:inkash/core/widgets/selector_icono.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';
import 'package:inkash/theme.dart';

typedef DatosCategoria = ({String nombre, String icono, TipoCategoria tipo});

// Crear (categoria == null) o editar una categoría. Al guardar hace
// pop(nombre) para que quien la abrió pueda seleccionarla de inmediato.
class CategoriaSheet extends StatefulWidget {
  const CategoriaSheet({
    required this.onGuardar,
    this.categoria,
    this.tipoInicial = TipoCategoria.gasto,
    this.onArchivar,
    this.onEliminar,
    super.key,
  });

  final Categoria? categoria;
  final TipoCategoria tipoInicial;
  final Future<void> Function(DatosCategoria datos) onGuardar;
  final Future<void> Function()? onArchivar;
  final Future<void> Function()? onEliminar;

  static const iconos = [
    'directions_bus',
    'shopping_cart',
    'restaurant',
    'local_cafe',
    'movie',
    'bolt',
    'home',
    'school',
    'health',
    'pets',
    'phone',
    'gift',
    'work',
    'arrow_upward',
    'attach_money',
  ];

  @override
  State<CategoriaSheet> createState() => _CategoriaSheetState();
}

class _CategoriaSheetState extends State<CategoriaSheet> {
  late final _nombre = TextEditingController(text: widget.categoria?.nombre);
  late String _icono = widget.categoria?.icono ?? CategoriaSheet.iconos.first;
  late TipoCategoria _tipo = widget.categoria?.tipo ?? widget.tipoInicial;
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombre.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(
    Future<void> Function() accion, {
    String? resultado,
  }) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await accion();
      if (mounted) Navigator.of(context).pop(resultado);
    } on CategoriaException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoria = widget.categoria;
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
            categoria == null ? 'Nueva categoría' : 'Editar categoría',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SegmentedButton<TipoCategoria>(
            segments: const [
              ButtonSegment(value: TipoCategoria.gasto, label: Text('Gasto')),
              ButtonSegment(
                value: TipoCategoria.ingreso,
                label: Text('Ingreso'),
              ),
            ],
            selected: {_tipo},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _tipo = s.single),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombre,
            autofocus: categoria == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Mascotas',
            ),
          ),
          const SizedBox(height: 16),
          SelectorIcono(
            opciones: CategoriaSheet.iconos,
            seleccionado: _icono,
            onSeleccionar: (i) => setState(() => _icono = i),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kPeligro)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _nombre.text.trim().isEmpty || _ocupado
                ? null
                : () => _ejecutar(
                    () => widget.onGuardar((
                      nombre: _nombre.text,
                      icono: _icono,
                      tipo: _tipo,
                    )),
                    resultado: _nombre.text.trim(),
                  ),
            child: Text(
              categoria == null ? 'Crear categoría' : 'Guardar cambios',
            ),
          ),
          if (categoria != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onArchivar != null)
                  TextButton(
                    onPressed: _ocupado
                        ? null
                        : () => _ejecutar(widget.onArchivar!),
                    child: Text(categoria.archivada ? 'Restaurar' : 'Archivar'),
                  ),
                if (widget.onEliminar != null)
                  TextButton(
                    onPressed: _ocupado
                        ? null
                        : () => _ejecutar(widget.onEliminar!),
                    style: TextButton.styleFrom(foregroundColor: kPeligro),
                    child: const Text('Eliminar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
