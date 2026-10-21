import 'package:inkash/features/presupuesto/data/presupuesto_local_data_source.dart';
import 'package:inkash/features/presupuesto/domain/presupuesto_categoria.dart';

class PresupuestoRepository {
  PresupuestoRepository({PresupuestoLocalDataSource? localDataSource})
    : _local = localDataSource ?? PresupuestoLocalDataSource();

  final PresupuestoLocalDataSource _local;

  Future<List<PresupuestoCategoria>> obtenerDelMes(DateTime mes) =>
      _local.obtenerDelMes(mes);

  Future<void> definirLimite(int categoriaId, int? limiteCentavos) =>
      _local.definirLimite(categoriaId, limiteCentavos);
}
