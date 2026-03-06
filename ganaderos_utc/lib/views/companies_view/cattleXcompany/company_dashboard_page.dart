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

      setState(() {
        cattleList = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cargando ganado: $e")));
    }
  }

  /// ---------------------------
  /// PDF REPORT
  /// ---------------------------
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

  /// ---------------------------
  /// NAVIGATION
  /// ---------------------------

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

  /// ---------------------------
  /// RESPONSIVE
  /// ---------------------------

  int _columns(double width) {
    if (width < 600) return 1;
    if (width < 1000) return 2;
    return 3;
  }

  double _ratio(double width) {
    if (width < 600) return 1.35;
    if (width < 1000) return 1.20;
    return 1.15;
  }

  EdgeInsets _padding(double width) {
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 12);
    return const EdgeInsets.symmetric(horizontal: 20);
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.teal.shade600,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _chipStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  /// ---------------------------
  /// UI
  /// ---------------------------

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = _columns(width);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text("Registros del Ganado"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Exportar PDF",
            onPressed: _exportPdf,
          ),
        ],
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/fondo_general.jpg",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// BIENVENIDA
                Padding(
                  padding: _padding(width),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green[100]!.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Bienvenido, ${widget.company.companyName}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width < 600 ? 20 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// BOTONES SUPERIORES
                Padding(
                  padding: _padding(width),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        style: _btnStyle(),
                        icon: const Icon(Icons.business),
                        label: const Text("Regresar a Empresas"),
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
                        style: _btnStyle(),
                        icon: const Icon(Icons.table_chart),
                        label: const Text("Ver tabla ganado"),
                        onPressed: _openCattleTable,
                      ),
                      ElevatedButton.icon(
                        style: _btnStyle(),
                        icon: const Icon(Icons.manage_accounts),
                        label: const Text("Usuarios de empresa"),
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
                        style: _btnStyle(),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Exportar PDF"),
                        onPressed: _exportPdf,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                /// GRID GANADO
                Expanded(
                  child: Padding(
                    padding: _padding(width),
                    child:
                        loading
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                              itemCount: cattleList.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: _ratio(width),
                                  ),
                              itemBuilder: (context, index) {
                                final item = cattleList[index];

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.pets_rounded,
                                        size: 40,
                                        color: Colors.black,
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Text("Raza: ${item.breed?.name ?? ""}"),
                                      Text("Código: ${item.code}"),

                                      const SizedBox(height: 10),

                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          ElevatedButton.icon(
                                            style: _chipStyle(),
                                            icon: const Icon(
                                              Icons.monitor_weight,
                                            ),
                                            label: const Text("Peso"),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          WeightTableViewByCattle(
                                                            companyId:
                                                                widget
                                                                    .company
                                                                    .id!,
                                                            cattleId: item.id!,
                                                            cattleName:
                                                                item.name,
                                                          ),
                                                ),
                                              );
                                            },
                                          ),

                                          ElevatedButton.icon(
                                            style: _chipStyle(),
                                            icon: const Icon(Icons.vaccines),
                                            label: const Text("Vacuna"),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          VaccineTableViewByCattle(
                                                            companyId:
                                                                widget
                                                                    .company
                                                                    .id!,
                                                            cattleId: item.id!,
                                                            cattleName:
                                                                item.name,
                                                          ),
                                                ),
                                              );
                                            },
                                          ),

                                          ElevatedButton.icon(
                                            style: _chipStyle(),
                                            icon: const Icon(
                                              Icons.health_and_safety,
                                            ),
                                            label: const Text("Chequeo"),
                                            onPressed: () => _openCheckup(item),
                                          ),

                                          ElevatedButton.icon(
                                            style: _chipStyle(),
                                            icon: const Icon(Icons.local_drink),
                                            label: const Text("Recolección"),
                                            onPressed:
                                                () => _openCollection(item),
                                          ),

                                          ElevatedButton.icon(
                                            style: _chipStyle(),
                                            icon: const Icon(
                                              Icons.medical_information,
                                            ),
                                            label: const Text("Diagnóstico"),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          DiagnosisTableViewByCompany(
                                                            companyName:
                                                                widget
                                                                    .company
                                                                    .companyName,
                                                          ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ),

                const Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
