import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repository/cattle_company_repository.dart';
import 'package:ganaderos_utc/views/companies_view/cattleXcompany/CattleTableViewByCompany.dart';
import 'package:ganaderos_utc/views/companies_view/collectionXcattleXcompany/CollectionTableViewByCattle.dart';
import 'package:ganaderos_utc/views/companies_view/checkupXcompany/CheckupTableViewByCattle.dart';
import 'package:ganaderos_utc/views/companies_view/diagnosisXcompany/diagnosis_table_view_by_company.dart';
import 'package:ganaderos_utc/views/companies_view/vaccineXcompany/VaccineTableViewByCattle.dart';
import 'package:ganaderos_utc/views/companies_view/weightXcompany/WeightTableViewByCattle.dart';
import 'package:ganaderos_utc/views/companies_view/userXcompany/UserTableViewByCompany.dart';
import '../../../models/company_models.dart';
import '../../../models/cattle_models.dart';
import '../../../widgets/footer.dart';
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
    if (!mounted) return;
    setState(() => loading = true);

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
      ).showSnackBar(SnackBar(content: Text('Error al cargar ganado: $e')));
    }
  }

  void _openCattleTable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CattleTableViewByCompany(companyId: widget.company.id!),
      ),
    ).then((_) => _loadCattle());
  }

  void _openCollectionByCattle(Cattle item) {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este ganado no tiene ID válido')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CollectionTableViewByCattle(
              cattleId: item.id!,
              cattleName: item.name,
            ),
      ),
    );
  }

  void _openCheckupByCattle(Cattle item) {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este ganado no tiene ID válido')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CheckupTableViewByCattle(
              cattleId: item.id!,
              cattleName: item.name,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String companyName = widget.company.companyName;

    return Scaffold(
      // ✅ importante para que no “pinte” fondo sólido detrás
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('Dashboard de Ganado'),
      ),
      body: Stack(
        children: [
          // ✅ Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_general.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // ✅ Overlay suave (mejor lectura)
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.08)),
          ),

          // ✅ Contenido
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green[100]!.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Text(
                      "Bienvenido, $companyName 👋",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 62, 143, 146),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.business),
                          label: const Text('Regresar a Empresas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompaniesView(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.table_view),
                          label: const Text('Ver Tabla de Ganado'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _openCattleTable,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.manage_accounts),
                          label: Text(
                            'Administración de usuario (${widget.company.companyName})',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child:
                        loading
                            ? const Center(child: CircularProgressIndicator())
                            : cattleList.isEmpty
                            ? const Center(
                              child: Text(
                                "No hay ganado registrado.",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            )
                            : LayoutBuilder(
                              builder: (context, constraints) {
                                final maxCrossAxisExtent =
                                    constraints.maxWidth / 3.2;

                                return GridView.builder(
                                  itemCount: cattleList.length,
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: maxCrossAxisExtent,
                                        mainAxisSpacing: 15,
                                        crossAxisSpacing: 15,
                                        childAspectRatio: 1.15,
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = cattleList[index];

                                    return GestureDetector(
                                      onTap: _openCattleTable,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.70),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.30,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (item.urlImage != null &&
                                                item.urlImage!.isNotEmpty)
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  item.urlImage!,
                                                  height: 45,
                                                  width: 70,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            else
                                              const Icon(
                                                Icons.agriculture,
                                                size: 38,
                                                color: Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                              ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.name,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              "Raza: ${item.breed?.name ?? item.breedId}",
                                              textAlign: TextAlign.center,
                                            ),
                                            Text("Código: ${item.code}"),
                                            Text("Fecha: ${item.date}"),

                                            const SizedBox(height: 10),

                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              alignment: WrapAlignment.center,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              _,
                                                            ) => WeightTableViewByCattle(
                                                              companyId:
                                                                  widget
                                                                      .company
                                                                      .id!,
                                                              cattleId:
                                                                  item.id!,
                                                              cattleName:
                                                                  item.name,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.monitor_weight,
                                                    size: 18,
                                                  ),
                                                  label: const Text("Peso"),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              _,
                                                            ) => VaccineTableViewByCattle(
                                                              companyId:
                                                                  widget
                                                                      .company
                                                                      .id!,
                                                              cattleId:
                                                                  item.id!,
                                                              cattleName:
                                                                  item.name,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.vaccines,
                                                    size: 18,
                                                  ),
                                                  label: const Text("Vacuna"),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed:
                                                      () =>
                                                          _openCheckupByCattle(
                                                            item,
                                                          ),
                                                  icon: const Icon(
                                                    Icons.health_and_safety,
                                                    size: 18,
                                                  ),
                                                  label: const Text("Chequeo"),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              _,
                                                            ) => DiagnosisTableViewByCompany(
                                                              companyName:
                                                                  widget
                                                                      .company
                                                                      .companyName,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.medical_information,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    "Diagnóstico",
                                                  ),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed:
                                                      () =>
                                                          _openCollectionByCattle(
                                                            item,
                                                          ),
                                                  icon: const Icon(
                                                    Icons.local_drink,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    "Recolección",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
