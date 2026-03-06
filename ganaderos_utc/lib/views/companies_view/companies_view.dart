import 'package:flutter/material.dart';
import 'package:ganaderos_utc/views/companies_view/cattleXcompany/company_dashboard_page.dart';
import '../../models/company_models.dart';
import '../../repositories/company_repository.dart';
import '../../repository/cattle_company_repository.dart';
import '../../widgets/companies_table.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';

class CompaniesView extends StatefulWidget {
  const CompaniesView({super.key});

  @override
  State<CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends State<CompaniesView> {
  List<Company> _companies = [];
  Map<int, int> _cattleCount = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() {
      _loading = true;
    });

    try {
      final repo = CompanyRepository();
      final companies = await repo.getAll();

      Map<int, int> counts = {};

      for (var c in companies) {
        try {
          final cattle = await CattleCompanyRepository.getAllByCompany(
            c.id ?? 0,
          );

          counts[c.id ?? 0] = cattle.length;
        } catch (_) {
          counts[c.id ?? 0] = 0;
        }
      }

      if (!mounted) return;

      setState(() {
        _companies = companies;
        _cattleCount = counts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar empresas: $e")));
    }
  }

  void _goToWelcome(Company company) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompanyDashboardPage(company: company)),
    );
  }

  Future<void> _goToCompaniesTable() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompanyTable()),
    );

    // cuando regrese recarga
    _fetchCompanies();
  }

  int _crossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  double _childAspectRatio(double width) {
    if (width < 600) return 4 / 1.8;
    if (width < 900) return 4 / 2.1;
    return 4 / 2.4;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Scaffold(
      drawer: const Sidebar(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: Navbar(),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text(
          "Nueva Hacienda",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: _goToCompaniesTable,
      ),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo1.jpg'),
            fit: BoxFit.cover,
            opacity: 0.85,
          ),
        ),

        padding: EdgeInsets.all(isMobile ? 12 : 24),

        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// HEADER PROFESIONAL
                    if (isMobile) ...[
                      const Text(
                        "Haciendas Registradas",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 1, 97, 34),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _fetchCompanies,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Actualizar"),
                          ),
                          ElevatedButton.icon(
                            onPressed: _goToCompaniesTable,
                            icon: const Icon(Icons.table_chart_outlined),
                            label: const Text("Ver Tabla"),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                () => Navigator.pushNamed(context, '/user'),
                            icon: const Icon(Icons.person),
                            label: const Text("Administrar usuarios"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Haciendas Registradas",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 97, 34),
                            ),
                          ),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _fetchCompanies,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Actualizar"),
                              ),

                              const SizedBox(width: 10),

                              ElevatedButton.icon(
                                onPressed: _goToCompaniesTable,
                                icon: const Icon(Icons.table_chart_outlined),
                                label: const Text("Ver Tabla"),
                              ),

                              const SizedBox(width: 10),

                              ElevatedButton.icon(
                                onPressed:
                                    () => Navigator.pushNamed(context, '/user'),
                                icon: const Icon(Icons.person),
                                label: const Text("Administrar usuarios"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    /// GRID
                    Expanded(
                      child:
                          _companies.isEmpty
                              ? const Center(
                                child: Text(
                                  "No hay haciendas registradas",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                              : GridView.builder(
                                itemCount: _companies.length,

                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _crossAxisCount(w),
                                      mainAxisSpacing: 18,
                                      crossAxisSpacing: 18,
                                      childAspectRatio: _childAspectRatio(w),
                                    ),

                                itemBuilder: (context, index) {
                                  final company = _companies[index];

                                  final cattle =
                                      _cattleCount[company.id ?? 0] ?? 0;

                                  return GestureDetector(
                                    onTap: () => _goToWelcome(company),

                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),

                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.blue.shade300,
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.15,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(3, 5),
                                          ),
                                        ],
                                      ),

                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          isMobile ? 12 : 16,
                                        ),

                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,

                                          children: [
                                            Icon(
                                              Icons.house_siding,
                                              size: isMobile ? 40 : 46,
                                              color: Colors.blue.shade700,
                                            ),

                                            const SizedBox(height: 10),

                                            Text(
                                              company.companyName,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: isMobile ? 16 : 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade900,
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            Text(
                                              "Responsable: ${company.responsible}",
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            Text(
                                              "Tel: ${company.contact}",
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            Text(
                                              "Dirección: ${company.address}",
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blueGrey.shade700,
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "🐄 Vacas registradas: $cattle",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      "© 2025 UTC GEN APP - Todos los derechos reservados",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(179, 0, 0, 0),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
