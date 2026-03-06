import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ganaderos_utc/models/stats_models.dart';
import 'package:ganaderos_utc/repository/stats_repository.dart';
import 'package:ganaderos_utc/utils/formatters.dart';

import 'package:ganaderos_utc/widgets/navbar.dart';
import 'package:ganaderos_utc/widgets/sidebar.dart';

class StatsView extends StatefulWidget {
  final int? companyId;
  const StatsView({super.key, this.companyId});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  late final StatsRepository repo;

  bool loading = true;
  String? error;
  DashboardStatsResponse? dashboard;

  int days = 30;

  @override
  void initState() {
    super.initState();
    repo = StatsRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await repo.getDashboard(
        companyId: widget.companyId,
        days: days,
      );
      setState(() => dashboard = data);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_general_2.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderStats(
                          days: days,
                          onRefresh: _load,
                          onGoInicio: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/inicio',
                              (route) => false,
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              123,
                              4,
                              235,
                              139,
                            ).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: _buildBody(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const _SimpleFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _ErrorState(error: error!, onRetry: _load);
    if (dashboard == null) return const Center(child: Text('Sin datos'));

    return _DashboardBody(data: dashboard!, companyId: widget.companyId);
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardStatsResponse data;
  final int? companyId;

  const _DashboardBody({required this.data, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final s = data.summary;

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              title: 'Ganado',
              value: AppFormatters.num0(s.totalCattle),
              icon: Icons.pets,
            ),
            _StatCard(
              title: 'Peso promedio',
              value: AppFormatters.kg(s.avgWeight),
              icon: Icons.monitor_weight,
            ),
            _StatCard(
              title: 'Chequeos',
              value: AppFormatters.num0(s.totalCheckups),
              icon: Icons.medical_services,
            ),
            _StatCard(
              title: 'Vacunas',
              value: AppFormatters.num0(s.totalVaccines),
              icon: Icons.vaccines,
            ),
          ],
        ),

        const SizedBox(height: 18),

        _Section(
          title: 'Producción de leche',
          child: _MilkSummary(items: data.milkByDay, companyId: companyId),
        ),

        const SizedBox(height: 18),

        _Section(
          title: 'Ganado por categoría',
          child: SizedBox(
            height: 280,
            child: _CattleCategoryBarChart(items: data.cattleByCategory),
          ),
        ),

        const SizedBox(height: 18),

        _Section(
          title: 'Peso promedio por ganado',
          child: SizedBox(
            height: 280,
            child: _AvgWeightBarChart(items: data.avgWeightByCattle),
          ),
        ),
      ],
    );
  }
}

class _MilkSummary extends StatelessWidget {
  final List<MilkDayItem> items;
  final int? companyId;

  const _MilkSummary({required this.items, required this.companyId});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text("No existen registros de producción de leche.");
    }

    final filtered =
        companyId == null
            ? items
            : items.where((e) => e.companyId == companyId).toList();

    if (filtered.isEmpty) {
      return const Text("Esta empresa no tiene registros de producción.");
    }

    double total = 0;
    double max = 0;
    double min = filtered.first.litres;

    final Map<int, double> productionByCattle = {};
    final Map<int, List<int>> collectionsByCattle = {};

    for (var item in filtered) {
      total += item.litres;

      if (item.litres > max) max = item.litres;
      if (item.litres < min) min = item.litres;

      productionByCattle[item.cattleId] =
          (productionByCattle[item.cattleId] ?? 0) + item.litres;

      collectionsByCattle[item.cattleId] ??= [];
      collectionsByCattle[item.cattleId]!.add(item.collectionId);
    }

    final promedio = total / filtered.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Empresa ID: ${companyId ?? "Todas"}"),
        const SizedBox(height: 8),
        Text("Total recolectado: ${AppFormatters.num0(total)} litros"),
        Text("Promedio por registro: ${AppFormatters.num0(promedio)} litros"),
        Text("Total de registros: ${filtered.length}"),
        Text("Producción máxima: ${AppFormatters.num0(max)} litros"),
        Text("Producción mínima: ${AppFormatters.num0(min)} litros"),
        const SizedBox(height: 12),

        const Text(
          "Producción por ganado",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        ...productionByCattle.entries.map((e) {
          final cattleId = e.key;
          final litres = e.value;
          final collections = collectionsByCattle[cattleId] ?? [];

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ganado ID $cattleId → ${AppFormatters.num0(litres)} litros",
                ),
                Text("Collections: ${collections.join(", ")}"),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvgWeightBarChart extends StatelessWidget {
  final List<AvgWeightByCattleItem> items;

  const _AvgWeightBarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay datos de pesos'));
    }

    final bars = <BarChartGroupData>[];

    for (int i = 0; i < items.length; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: items[i].avgWeight, width: 14)],
        ),
      );
    }

    return RotatedBox(
      quarterTurns: 1,
      child: BarChart(BarChartData(barGroups: bars)),
    );
  }
}

class _CattleCategoryBarChart extends StatelessWidget {
  final List<CattleByCategoryItem> items;

  const _CattleCategoryBarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text("No hay datos por categoría"));
    }

    final bars = <BarChartGroupData>[];

    for (int i = 0; i < items.length; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: items[i].count.toDouble(), width: 16)],
        ),
      );
    }

    return BarChart(BarChartData(barGroups: bars));
  }
}

class _HeaderStats extends StatelessWidget {
  final int days;
  final VoidCallback onRefresh;
  final VoidCallback onGoInicio;

  const _HeaderStats({
    required this.days,
    required this.onRefresh,
    required this.onGoInicio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.bar_chart, color: Colors.white),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Tabla Estadística',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
        IconButton(
          tooltip: 'Inicio',
          onPressed: onGoInicio,
          icon: const Icon(Icons.home, color: Colors.white),
        ),
      ],
    );
  }
}

class _SimpleFooter extends StatelessWidget {
  const _SimpleFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.black.withOpacity(0.55),
      child: const Text(
        '© 2025 UTC GEN APP - Todos los derechos reservados',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 44),
          const SizedBox(height: 10),
          Text(
            'Error cargando dashboard:\n$error',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
