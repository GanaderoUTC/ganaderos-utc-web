import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ganaderos_utc/reports/report_service.dart';

import '../../../models/company_models.dart';
import '../../../models/cattle_models.dart';
import '../../../widgets/footer.dart';
import 'package:ganaderos_utc/repository/cattle_company_repository.dart';

import 'package:ganaderos_utc/views/companies_view/cattleXcompany/CattleTableViewByCompany.dart';
import 'package:ganaderos_utc/views/companies_view/collectionXcattleXcompany/CollectionTableViewByCattle.dart';
import 'package:ganaderos_utc/views/companies_view/checkupXcompany/CheckupTableViewByCattle.dart';
import 'package:ganaderos_utc/views/companies_view/diagnosisXcompany/diagnosis_table_view_by_company.dart';
import 'package:ganaderos_utc/views/companies_view/vaccineXcompany/VaccineTableViewByCattle.dart';
import 'package:ganaderos_utc/views/companies_view/weightXcompany/WeightTableViewByCattle.dart';
import 'package:ganaderos_utc/views/companies_view/userXcompany/UserTableViewByCompany.dart';

import '../companies_view.dart';

class CompanyDashboardPage extends StatefulWidget {
  final Company company;

  const CompanyDashboardPage({super.key, required this.company});

  @override
  State<CompanyDashboardPage> createState() => _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends State<CompanyDashboardPage> {
  List<Cattle> cattleList = [];
  bool loading = true;
  int? hoveredIndex;

  @override
  void initState() {
    super.initState();
    _loadCattle();
  }

  Future<void> _loadCattle() async {
    try {
      final data = await CattleCompanyRepository.getAllByCompany(
        widget.company.id!,
      );

      if (!mounted) return;

      setState(() {
        cattleList = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cargando ganado: $e")));
    }
  }

  Future<void> _exportPdf() async {
    if (cattleList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay ganado para exportar")),
      );
      return;
    }

    final rows =
        cattleList
            .map(
              (c) => {
                "Nombre": c.name,
                "Código": c.code,
                "Raza": c.breed?.name ?? "",
                "Género": c.gender,
                "Fecha Registro": c.date,
              },
            )
            .toList();

    await ReportService.printCompanyReport(
      companyName: widget.company.companyName,
      title: "Reporte General de Ganado",
      from: DateTime.now().subtract(const Duration(days: 30)),
      to: DateTime.now(),
      rows: rows,
      summary: {
        "Empresa": widget.company.companyName,
        "Total de ganado": "${cattleList.length}",
      },
    );
  }

  void _openCattleTable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CattleTableViewByCompany(companyId: widget.company.id!),
      ),
    ).then((_) => _loadCattle());
  }

  void _openCollection(Cattle cattle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CollectionTableViewByCattle(
              cattleId: cattle.id!,
              cattleName: cattle.name,
            ),
      ),
    );
  }

  void _openCheckup(Cattle cattle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CheckupTableViewByCattle(
              cattleId: cattle.id!,
              cattleName: cattle.name,
            ),
      ),
    );
  }

  void _openDiagnosis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => DiagnosisTableViewByCompany(
              companyName: widget.company.companyName,
            ),
      ),
    );
  }

  int _columns(double width) {
    if (width < 700) return 1;
    if (width < 1100) return 2;
    if (width < 1450) return 3;
    return 4;
  }

  double _ratio(double width) {
    if (width < 700) return 1.45;
    if (width < 1100) return 1.34;
    if (width < 1450) return 1.28;
    return 1.22;
  }

  EdgeInsets _padding(double width) {
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 12);
    if (width < 1000) return const EdgeInsets.symmetric(horizontal: 16);
    return const EdgeInsets.symmetric(horizontal: 20);
  }

  ButtonStyle _topButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
    );
  }

  ButtonStyle _chipStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.92),
      foregroundColor: const Color(0xFF5E4DB2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minimumSize: const Size(0, 34),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;
    final cols = _columns(width);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text("Registros del Ganado"),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/fondo_general.jpg",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.32)),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: const Color(0xFF102A1C).withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),

                Padding(
                  padding: _padding(width),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 20,
                      vertical: isMobile ? 16 : 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFDCEBD9).withOpacity(0.88),
                          const Color(0xFFC8DFC3).withOpacity(0.82),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Text(
                      "Bienvenido a la hacienda, ${widget.company.companyName}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2A2F),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: _padding(width),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE6EEF0).withOpacity(0.78),
                          const Color(0xFFD8E5E8).withOpacity(0.72),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          style: _topButtonStyle(const Color(0xFF0E8E8C)),
                          icon: const Icon(Icons.house_siding),
                          label: const Text("Regresar a las Haciendas"),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompaniesView(),
                              ),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          style: _topButtonStyle(const Color(0xFF138A9E)),
                          icon: const Icon(Icons.table_chart),
                          label: const Text("Ver tabla ganado"),
                          onPressed: _openCattleTable,
                        ),
                        ElevatedButton.icon(
                          style: _topButtonStyle(const Color(0xFF117A8B)),
                          icon: const Icon(Icons.manage_accounts),
                          label: const Text("Usuarios de la hacienda"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => UserTableViewByCompany(
                                      companyId: widget.company.id!,
                                      companyName: widget.company.companyName,
                                    ),
                              ),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          style: _topButtonStyle(const Color(0xFF0D9E8B)),
                          icon: const Icon(Icons.medical_information),
                          label: const Text("Diagnósticos"),
                          onPressed: _openDiagnosis,
                        ),
                        ElevatedButton.icon(
                          style: _topButtonStyle(const Color(0xFF0C8B94)),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("Exportar PDF"),
                          onPressed: _exportPdf,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: Padding(
                    padding: _padding(width),
                    child:
                        loading
                            ? const Center(child: CircularProgressIndicator())
                            : cattleList.isEmpty
                            ? Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.82),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  "No hay ganado registrado en esta empresa",
                                  style: TextStyle(
                                    color: Color(0xFF1E2A35),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            : GridView.builder(
                              itemCount: cattleList.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    mainAxisSpacing: 18,
                                    crossAxisSpacing: 18,
                                    childAspectRatio: _ratio(width),
                                  ),
                              itemBuilder: (context, index) {
                                final item = cattleList[index];
                                final isHovered = hoveredIndex == index;

                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) {
                                    setState(() {
                                      hoveredIndex = index;
                                    });
                                  },
                                  onExit: (_) {
                                    setState(() {
                                      hoveredIndex = null;
                                    });
                                  },
                                  child: GestureDetector(
                                    onTap: _openCattleTable,
                                    child: _CattleDashboardCard(
                                      item: item,
                                      isHovered: isHovered,
                                      isMobile: isMobile,
                                      chipStyle: _chipStyle(),
                                      onPeso: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => WeightTableViewByCattle(
                                                  companyId: widget.company.id!,
                                                  cattleId: item.id!,
                                                  cattleName: item.name,
                                                ),
                                          ),
                                        );
                                      },
                                      onVacuna: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => VaccineTableViewByCattle(
                                                  companyId: widget.company.id!,
                                                  cattleId: item.id!,
                                                  cattleName: item.name,
                                                ),
                                          ),
                                        );
                                      },
                                      onChequeo: () => _openCheckup(item),
                                      onRecoleccion:
                                          () => _openCollection(item),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ),

                const SizedBox(height: 10),
                const Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CattleDashboardCard extends StatelessWidget {
  final Cattle item;
  final bool isHovered;
  final bool isMobile;
  final ButtonStyle chipStyle;
  final VoidCallback onPeso;
  final VoidCallback onVacuna;
  final VoidCallback onChequeo;
  final VoidCallback onRecoleccion;

  const _CattleDashboardCard({
    required this.item,
    required this.isHovered,
    required this.isMobile,
    required this.chipStyle,
    required this.onPeso,
    required this.onVacuna,
    required this.onChequeo,
    required this.onRecoleccion,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isHovered ? Colors.black : const Color(0xFF163A22);
    final textColor = isHovered ? Colors.black87 : const Color(0xFF2F4F38);
    final iconColor = isHovered ? Colors.black : const Color(0xFF102C14);

    return AnimatedScale(
      scale: isHovered ? 1.015 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isHovered
                    ? [
                      const Color(0xFFA9D7A7).withOpacity(0.95),
                      const Color(0xFF8EC58D).withOpacity(0.92),
                    ]
                    : [
                      const Color(0xFF87C97D).withOpacity(0.90),
                      const Color(0xFF67B966).withOpacity(0.86),
                    ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isHovered ? const Color(0xFFE9FFF0) : const Color(0xFF2D7C33),
            width: isHovered ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? 0.22 : 0.14),
              blurRadius: isHovered ? 16 : 10,
              offset: Offset(0, isHovered ? 8 : 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final compact = c.maxWidth < 310;
            final iconSize = compact ? 34.0 : 40.0;
            final titleSize = compact ? 16.0 : 18.0;
            final bodySize = compact ? 12.5 : 13.5;

            return Padding(
              padding: EdgeInsets.all(compact ? 10 : 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets_rounded, size: iconSize, color: iconColor),
                  const SizedBox(height: 8),

                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleSize,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    "Raza: ${item.breed?.name ?? '-'}",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: bodySize,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),

                  Text(
                    "Código: ${item.code}",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: bodySize,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ElevatedButton.icon(
                        style: chipStyle,
                        icon: const Icon(Icons.monitor_weight, size: 16),
                        label: const Text("Peso"),
                        onPressed: onPeso,
                      ),
                      ElevatedButton.icon(
                        style: chipStyle,
                        icon: const Icon(Icons.vaccines, size: 16),
                        label: const Text("Vacuna"),
                        onPressed: onVacuna,
                      ),
                      ElevatedButton.icon(
                        style: chipStyle,
                        icon: const Icon(Icons.health_and_safety, size: 16),
                        label: const Text("Chequeo"),
                        onPressed: onChequeo,
                      ),
                      ElevatedButton.icon(
                        style: chipStyle,
                        icon: const Icon(Icons.local_drink, size: 16),
                        label: const Text("Recolección"),
                        onPressed: onRecoleccion,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isHovered
                              ? Colors.white.withOpacity(0.28)
                              : Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isHovered
                                ? Colors.white.withOpacity(0.90)
                                : Colors.black26,
                      ),
                    ),
                    child: Text(
                      "Clic para ver tabla general",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 11,
                        fontWeight: FontWeight.w700,
                        color: isHovered ? Colors.black : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
