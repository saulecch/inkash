import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/parse_monto.dart';
import 'package:inkash/core/widgets/iconos.dart';
import 'package:inkash/features/ajustes/domain/ajustes.dart';
import 'package:inkash/features/ajustes/presentation/ajustes_controller.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_provider.dart';
import 'package:inkash/theme.dart';

/// s17-03: la primera vez que se abre la app. Tres preguntas en orden, y
/// cada una deja algo listo para que el Inicio no empiece vacío:
/// 1. ¿Cómo te llamas?  2. ¿Cuánto quieres gastar al mes?
/// 3. ¿Cuánto tienes hoy en cada cuenta?
class BienvenidaPage extends ConsumerStatefulWidget {
  const BienvenidaPage({super.key});

  @override
  ConsumerState<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends ConsumerState<BienvenidaPage> {
  static const _pasos = 3;
  final _paginas = PageController();
  final _nombre = TextEditingController();
  final _limite = TextEditingController(
    text: '${Ajustes.porDefecto.limiteMensualCentavos ~/ 100}',
  );
  final _saldos = <int, TextEditingController>{}; // por id de cuenta
  int _paso = 0;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _limite.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _paginas.dispose();
    _nombre.dispose();
    _limite.dispose();
    for (final c in _saldos.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _saldo(Cuenta c) =>
      _saldos.putIfAbsent(c.id, TextEditingController.new);

  // Cada paso decide si se puede avanzar.
  bool get _pasoValido => switch (_paso) {
    1 => parseMontoCentavos(_limite.text) != null,
    _ => true, // el nombre y los saldos son opcionales
  };

  Future<void> _siguiente(List<Cuenta> cuentas) async {
    FocusScope.of(context).unfocus();
    if (_paso < _pasos - 1) {
      setState(() => _paso++);
      await _paginas.animateToPage(
        _paso,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (_guardando) return;
    setState(() => _guardando = true);
    await ref
        .read(ajustesProvider.notifier)
        .completarBienvenida(
          nombre: _nombre.text,
          limiteMensualCentavos: parseMontoCentavos(_limite.text)!,
          saldosIniciales: [
            for (final c in cuentas)
              if (parseMontoCentavos(_saldo(c).text) case final centavos?)
                (c, centavos),
          ],
        );
    // No hace falta navegar: la raíz de la app hace watch de Ajustes y,
    // al quedar bienvenidaCompleta = true, muestra las pestañas.
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final cuentas = ref.watch(cuentasProvider).value ?? const <Cuenta>[];

    Widget pregunta(String titulo, String ayuda, Widget campo) {
      return ListView(
        padding: const EdgeInsets.all(Espacio.xl),
        children: [
          Text(titulo, style: texto.headlineSmall),
          const SizedBox(height: Espacio.s),
          Text(ayuda, style: texto.bodyMedium?.copyWith(color: kMuted)),
          const SizedBox(height: Espacio.xl),
          campo,
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de avance: es una secuencia real de 3 pasos.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espacio.xl,
                Espacio.xl,
                Espacio.xl,
                0,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _pasos; i++) ...[
                    if (i > 0) const SizedBox(width: Espacio.s),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _paso ? kLima : kBorde,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _paginas,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  pregunta(
                    'Te damos la bienvenida a Inkash',
                    'Lleva tus gastos en quetzales. Todo se queda en tu '
                        'teléfono. Para empezar, ¿cómo te llamas?',
                    TextField(
                      controller: _nombre,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre (opcional)',
                      ),
                    ),
                  ),
                  pregunta(
                    '¿Cuánto quieres gastar al mes?',
                    'Es tu límite. El Inicio te dirá cuánto te queda. '
                        'Lo puedes cambiar en Ajustes.',
                    TextField(
                      controller: _limite,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: texto.headlineSmall,
                      decoration: const InputDecoration(prefixText: 'Q '),
                    ),
                  ),
                  pregunta(
                    '¿Cuánto tienes hoy?',
                    'Así tus cuentas empiezan con el saldo real. '
                        'Puedes dejarlo en blanco.',
                    Column(
                      children: [
                        for (final c in cuentas)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Espacio.m),
                            child: TextField(
                              controller: _saldo(c),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: c.nombre,
                                prefixText: 'Q ',
                                prefixIcon: Icon(iconoDe(c.icono)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Espacio.xl),
              child: Row(
                children: [
                  if (_paso > 0)
                    TextButton(
                      onPressed: () {
                        setState(() => _paso--);
                        _paginas.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: const Text('Atrás'),
                    ),
                  const SizedBox(width: Espacio.m),
                  Expanded(
                    child: FilledButton(
                      onPressed: _pasoValido && !_guardando
                          ? () => _siguiente(cuentas)
                          : null,
                      child: Text(
                        _paso == _pasos - 1 ? 'Empezar' : 'Continuar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
