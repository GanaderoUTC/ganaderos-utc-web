import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ganaderos_utc/models/stats_models.dart';
import 'package:ganaderos_utc/reports/report_service.dart';
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
  bool generatingPdf = false;
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

      if (!mounted) return;
      setState(() => dashboard = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _printStatsPdf() async {
    if (dashboard == null || generatingPdf) return;

    setState(() => generatingPdf = true);

    try {
      final data = dashboard!;
      final now = DateTime.now();
      final from = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days - 1));
      final to = now;

      final summary = {
        'Total ganado': data.summary.totalCattle.toString(),
        'Total empresas': data.summary.totalCompanies.toString(),
        'Total usuarios': data.summary.totalUsers.toString(),
        'Chequeos': data.summary.totalCheckups.toString(),
        'Vacunas': data.summary.totalVaccines.toString(),
        'Leche hoy': '${data.summary.milkTodayLitres.toStringAsFixed(2)} L',
        'Leche período': '${data.summary.milkMonthLitres.toStringAsFixed(2)} L',
        'Peso promedio': '${data.summary.avgWeight.toStringAsFixed(2)} kg',
      };

      final milkRows =
          data.milkByDay
              .map(
                (e) => {
                  'date':
                      '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}',
                  'litres': e.litres.toStringAsFixed(2),
                },
              )
              .toList();

      final categoryRows =
          data.cattleByCategory
              .map((e) => {'category': e.category, 'count': e.count.toString()})
              .toList();

      final weightRows =
          data.avgWeightByCattle
              .map(
                (e) => {
                  'cattleName': e.cattleName,
                  'avgWeight': e.avgWeight.toStringAsFixed(2),
                },
              )
              .toList();

      final breedRows =
          data.cattleByBreed
              .map((e) => {'breed': e.breed, 'count': e.count.toString()})
              .toList();

      await ReportService.printStatsReport(
        companyName:
            widget.companyId == null
                ? 'General'
                : 'Empresa_${widget.companyId}',
        title: 'Reporte estadístico del sistema',
        from: from,
        to: to,
        summary: summary,
        milkRows: milkRows,
        categoryRows: categoryRows,
        weightRows: weightRows,
        breedRows: breedRows,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() => generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_general_2.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.36)),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: const Color(0xFF0D2A1C).withOpacity(0.10),
              ),
            ),
          ),

          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1250),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeaderStats(
                            days: days,
                            generatingPdf: generatingPdf,
                            onRefresh: _load,
                            onPrintPdf: _printStatsPdf,
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
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFDCEEDB).withOpacity(0.88),
                                  const Color(0xFFC7DFC8).withOpacity(0.80),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            child: _buildBody(isMobile),
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
        ],
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return _ErrorState(error: error!, onRetry: _load);
    }

    if (dashboard == null) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('Sin datos')),
      );
    }

    return _DashboardBody(
      data: dashboard!,
      companyId: widget.companyId,
      isMobile: isMobile,
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardStatsResponse data;
  final int? companyId;
  final bool isMobile;

  const _DashboardBody({
    required this.data,
    required this.companyId,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final s = data.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
            _StatCard(
              title: 'Leche hoy',
              value: '${s.milkTodayLitres.toStringAsFixed(2)} L',
              icon: Icons.local_drink,
            ),
            _StatCard(
              title: 'Leche período',
              value: '${s.milkMonthLitres.toStringAsFixed(2)} L',
              icon: Icons.water_drop,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Producción de leche registrada',
          child: _MilkSummary(items: data.milkByDay, companyId: companyId),
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Ganado por categoría',
          child: SizedBox(
            height: isMobile ? 280 : 320,
            child: _CattleCategoryBarChart(items: data.cattleByCategory),
          ),
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Peso promedio por ganado',
          child: SizedBox(
            height: isMobile ? 300 : 340,
            child: _AvgWeightBarChart(items: data.avgWeightByCattle),
          ),
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Distribución de razas',
          child: SizedBox(
            height: isMobile ? 460 : 360,
            child: _BreedPieChart(items: data.cattleByBreed),
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
      return const Text('No existen registros de producción de leche.');
    }

    final filtered =
        companyId == null
            ? items
            : items.where((e) => e.companyId == companyId).toList();

    if (filtered.isEmpty) {
      return const Text('Esta empresa no tiene registros de producción.');
    }

    double total = 0;
    double max = 0;
    double min = filtered.first.litres;

    for (final item in filtered) {
      total += item.litres;
      if (item.litres > max) max = item.litres;
      if (item.litres < min) min = item.litres;
    }

    final promedio = total / filtered.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MiniInfoCard(
              title: 'Empresa',
              value: companyId == null ? 'Todas' : '$companyId',
              icon: Icons.business,
            ),
            _MiniInfoCard(
              title: 'Total recolectado',
              value: '${total.toStringAsFixed(2)} L',
              icon: Icons.local_drink,
            ),
            _MiniInfoCard(
              title: 'Promedio por registro',
              value: '${promedio.toStringAsFixed(2)} L',
              icon: Icons.analytics,
            ),
            _MiniInfoCard(
              title: 'Total registros',
              value: '${filtered.length}',
              icon: Icons.list_alt,
            ),
            _MiniInfoCard(
              title: 'Producción máxima',
              value: '${max.toStringAsFixed(2)} L',
              icon: Icons.arrow_upward,
            ),
            _MiniInfoCard(
              title: 'Producción mínima',
              value: '${min.toStringAsFixed(2)} L',
              icon: Icons.arrow_downward,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Detalle de producción diaria',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.green.shade100),
            columns: const [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Litros')),
              DataColumn(label: Text('Ganado ID')),
              DataColumn(label: Text('Collection ID')),
            ],
            rows:
                filtered.map((e) {
                  final date =
                      '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}';
                  return DataRow(
                    cells: [
                      DataCell(Text(date)),
                      DataCell(Text(e.litres.toStringAsFixed(2))),
                      DataCell(Text('${e.cattleId}')),
                      DataCell(Text('${e.collectionId}')),
                    ],
                  );
                }).toList(),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        double cardWidth;

        if (screenWidth < 600) {
          cardWidth = double.infinity;
        } else if (screenWidth < 900) {
          cardWidth = 230;
        } else {
          cardWidth = 250;
        }

        return SizedBox(
          width: cardWidth,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 30, color: Colors.green.shade800),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
      },
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width =
        screenWidth < 600
            ? double.infinity
            : screenWidth < 900
            ? 170.0
            : 180.0;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.green.shade700),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
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

    final visibleItems = items.take(10).toList();

    final double maxValue = visibleItems
        .map((e) => e.avgWeight.toDouble())
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    final double maxY = maxValue <= 0 ? 100.0 : (maxValue + 30.0);
    final double interval = maxY > 100 ? (maxY / 6).ceil().toDouble() : 20.0;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        right: isMobile ? 6 : 12,
        left: isMobile ? 0 : 4,
        bottom: 8,
      ),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceEvenly,
          groupsSpace: isMobile ? 10 : 18,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.35),
                strokeWidth: 1,
                dashArray: [6, 4],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.20),
                strokeWidth: 1,
                dashArray: [6, 4],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = visibleItems[group.x.toInt()];
                return BarTooltipItem(
                  '${item.cattleName}\n${item.avgWeight.toStringAsFixed(1)} kg',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: !isMobile,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visibleItems.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      visibleItems[index].avgWeight.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 32 : 42,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 48 : 58,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visibleItems.length) {
                    return const SizedBox.shrink();
                  }

                  final name = visibleItems[index].cattleName;
                  final shortName =
                      name.length > (isMobile ? 7 : 10)
                          ? '${name.substring(0, isMobile ? 7 : 10)}...'
                          : name;

                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      shortName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(visibleItems.length, (i) {
            final item = visibleItems[i];

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: item.avgWeight.toDouble(),
                  width: isMobile ? 20 : 34,
                  color: Colors.orange.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
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

    final visibleItems = items.take(10).toList();

    final double maxValue = visibleItems
        .map((e) => e.count.toDouble())
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    final double maxY = maxValue <= 0 ? 10.0 : (maxValue + 3.0);
    final double interval = maxY > 10 ? (maxY / 5).ceil().toDouble() : 2.0;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        right: isMobile ? 6 : 12,
        left: isMobile ? 0 : 4,
        bottom: 8,
      ),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceEvenly,
          groupsSpace: isMobile ? 10 : 18,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.35),
                strokeWidth: 1,
                dashArray: [6, 4],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.20),
                strokeWidth: 1,
                dashArray: [6, 4],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = visibleItems[group.x.toInt()];
                return BarTooltipItem(
                  '${item.category}\n${item.count}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: !isMobile,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visibleItems.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${visibleItems[index].count}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 28 : 34,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 48 : 52,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visibleItems.length) {
                    return const SizedBox.shrink();
                  }

                  final name = visibleItems[index].category;
                  final shortName =
                      name.length > (isMobile ? 8 : 12)
                          ? '${name.substring(0, isMobile ? 8 : 12)}...'
                          : name;

                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      shortName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(visibleItems.length, (i) {
            final item = visibleItems[i];

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: item.count.toDouble(),
                  width: isMobile ? 20 : 34,
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _BreedPieChart extends StatefulWidget {
  final List<CattleByBreedItem> items;

  const _BreedPieChart({required this.items});

  @override
  State<_BreedPieChart> createState() => _BreedPieChartState();
}

class _BreedPieChartState extends State<_BreedPieChart> {
  int touchedIndex = -1;

  final List<Color> colors = const [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFFFFC107),
    Color(0xFF795548),
    Color(0xFF3F51B5),
    Color(0xFF8BC34A),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('No hay datos de razas'));
    }

    final total = widget.items.fold<int>(0, (sum, e) => sum + e.count);
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: List.generate(widget.items.length, (index) {
                  final item = widget.items[index];
                  final isTouched = index == touchedIndex;
                  final radius = isTouched ? 88.0 : 78.0;
                  final percent = total == 0 ? 0 : (item.count * 100 / total);

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: item.count.toDouble(),
                    title: '${percent.toStringAsFixed(1)}%',
                    radius: radius,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(widget.items.length, (index) {
                  final item = widget.items[index];
                  final color = colors[index % colors.length];
                  final percent = total == 0 ? 0 : (item.count * 100 / total);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.breed} (${item.count}) - ${percent.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final isTouched = index == touchedIndex;
                final radius = isTouched ? 105.0 : 95.0;
                final percent = total == 0 ? 0 : (item.count * 100 / total);

                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: item.count.toDouble(),
                  title: '${percent.toStringAsFixed(1)}%',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final color = colors[index % colors.length];
                final percent = total == 0 ? 0 : (item.count * 100 / total);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.breed} (${item.count}) - ${percent.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final int days;
  final bool generatingPdf;
  final VoidCallback onRefresh;
  final VoidCallback onPrintPdf;
  final VoidCallback onGoInicio;

  const _HeaderStats({
    required this.days,
    required this.generatingPdf,
    required this.onRefresh,
    required this.onPrintPdf,
    required this.onGoInicio,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E5C3A).withOpacity(0.92),
            const Color(0xFF2E7D4E).withOpacity(0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.bar_chart, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Tabla Estadística',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: generatingPdf ? null : onPrintPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                icon:
                    generatingPdf
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.picture_as_pdf),
                label: const Text('Generar PDF'),
              ),
              ElevatedButton.icon(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
              ElevatedButton.icon(
                onPressed: onGoInicio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade800,
                ),
                icon: const Icon(Icons.home),
                label: const Text('Inicio'),
              ),
            ],
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.50),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
      ),
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(16),
        ),
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
