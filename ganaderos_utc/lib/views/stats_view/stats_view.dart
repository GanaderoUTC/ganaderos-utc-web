import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ganaderos_utc/models/stats_models.dart';
import 'package:ganaderos_utc/repository/stats_repository.dart';
import 'package:ganaderos_utc/utils/formatters.dart';

// ✅ Usa tus widgets existentes
import 'package:ganaderos_utc/widgets/navbar.dart';
import 'package:ganaderos_utc/widgets/sidebar.dart';

class StatsView extends StatefulWidget {
  final int? companyId; // null => admin global
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
      appBar: const Navbar(), // ✅ Navbar del proyecto
      drawer: const Sidebar(), // ✅ Sidebar del proyecto

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/fondo_general_2.jpg',
            ), // ✅ tu fondo
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // ✅ Contenido principal scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ✅ Header bonito dentro del body (título + acciones)
                        _HeaderStats(
                          days: days,
                          onChangeDays: (v) {
                            setState(() => days = v);
                            _load();
                          },
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

                        // ✅ Tarjeta que mejora legibilidad sobre fondo
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              123,
                              4,
                              235,
                              139,
                            ).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black12,
                                offset: Offset(0, 6),
                              ),
                            ],
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

            // ✅ Footer simple
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
    return _DashboardBody(data: dashboard!, days: days);
  }
}

// ---------------- HEADER ----------------

class _HeaderStats extends StatelessWidget {
  final int days;
  final ValueChanged<int> onChangeDays;
  final VoidCallback onRefresh;
  final VoidCallback onGoInicio;

  const _HeaderStats({
    required this.days,
    required this.onChangeDays,
    required this.onRefresh,
    required this.onGoInicio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Dashboard Estadístico',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          PopupMenuButton<int>(
            tooltip: 'Rango',
            onSelected: onChangeDays,
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 7, child: Text('Últimos 7 días')),
                  PopupMenuItem(value: 30, child: Text('Últimos 30 días')),
                  PopupMenuItem(value: 90, child: Text('Últimos 90 días')),
                ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 18),
                  const SizedBox(width: 8),
                  Text('Rango: $days'),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

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
      ),
    );
  }
}

// ---------------- FOOTER ----------------

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

// ---------------- DASHBOARD BODY (tu contenido tal cual) ----------------

class _DashboardBody extends StatelessWidget {
  final DashboardStatsResponse data;
  final int days;

  const _DashboardBody({required this.data, required this.days});

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
              title: 'Leche hoy',
              value: AppFormatters.litres(s.milkTodayLitres),
              icon: Icons.water_drop,
            ),
            _StatCard(
              title: 'Leche mes',
              value: AppFormatters.litres(s.milkMonthLitres),
              icon: Icons.show_chart,
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
          title: 'Producción de leche (últimos $days días)',
          child: SizedBox(
            height: 280,
            child: _MilkLineChart(items: data.milkByDay),
          ),
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
      width: 220,
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _MilkLineChart extends StatelessWidget {
  final List<MilkDayItem> items;
  const _MilkLineChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay datos de leche'));
    }

    final sorted = [...items]..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].litres));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final idx = s.x.toInt().clamp(0, sorted.length - 1);
                final d = sorted[idx].date;
                final litres = s.y;
                return LineTooltipItem(
                  '${AppFormatters.dayMonth(d)}\n${AppFormatters.litres(litres)}',
                  const TextStyle(fontWeight: FontWeight.w700),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget:
                  (value, meta) => Text(
                    AppFormatters.num0(value),
                    style: const TextStyle(fontSize: 10),
                  ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (sorted.length / 6).clamp(1, 999).toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sorted.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppFormatters.dayMonth(sorted[idx].date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: false),
            barWidth: 3,
          ),
        ],
      ),
    );
  }
}

class _CattleCategoryBarChart extends StatelessWidget {
  final List<CattleByCategoryItem> items;
  const _CattleCategoryBarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay datos por categoría'));
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

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x.toInt().clamp(0, items.length - 1);
              final item = items[idx];
              return BarTooltipItem(
                '${item.category}\n${AppFormatters.num0(item.count)}',
                const TextStyle(fontWeight: FontWeight.w700),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget:
                  (value, meta) => Text(
                    AppFormatters.num0(value),
                    style: const TextStyle(fontSize: 10),
                  ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                final label = items[i].category;
                final short =
                    label.length > 10 ? '${label.substring(0, 10)}…' : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(short, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: bars,
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

    final shown = items.length > 12 ? items.sublist(0, 12) : items;

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < shown.length; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: shown[i].avgWeight, width: 16)],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = shown[group.x.toInt()];
              return BarTooltipItem(
                '${item.cattleName}\n${AppFormatters.kg(item.avgWeight)}',
                const TextStyle(fontWeight: FontWeight.w700),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget:
                  (value, meta) => Text(
                    AppFormatters.num0(value),
                    style: const TextStyle(fontSize: 10),
                  ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= shown.length) return const SizedBox.shrink();
                final label = shown[i].cattleName;
                final short =
                    label.length > 10 ? '${label.substring(0, 10)}…' : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(short, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: bars,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
