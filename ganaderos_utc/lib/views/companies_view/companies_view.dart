import 'package:flutter/material.dart';
import 'package:ganaderos_utc/views/companies_view/cattleXcompany/company_dashboard_page.dart';
import '../../models/company_models.dart';
import '../../repositories/company_repository.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    final repo = CompanyRepository();
    final companies = await repo.getAll();
    setState(() {
      _companies = companies;
      _loading = false;
    });
  }

  void _goToWelcome(Company company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CompanyDashboardPage(
              company: company, // Pasamos toda la empresa
            ),
      ),
    );
  }

  void _goToCompaniesTable() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompanyTable()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          "Nueva Empresa",
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
        padding: const EdgeInsets.all(24),
        child:
            _loading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🧭 Encabezado con título y botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Empresas Registradas",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 1, 97, 34),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _fetchCompanies,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Actualizar"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  52,
                                  132,
                                  213,
                                ).withOpacity(0.9),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            ElevatedButton.icon(
                              onPressed: _goToCompaniesTable,
                              icon: const Icon(Icons.table_chart_outlined),
                              label: const Text("Ver Tabla"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  57,
                                  132,
                                  207,
                                ).withOpacity(0.9),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 🧑‍💼 NUEVO BOTÓN: ADMINISTRAR USUARIOS
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/user');
                              },
                              icon: const Icon(Icons.person),
                              label: const Text("Administrar usuarios"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.withOpacity(0.9),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🧱 Contenedor de tarjetas
                    Expanded(
                      child:
                          _companies.isEmpty
                              ? const Center(
                                child: Text(
                                  "No hay empresas registradas.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                              : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                itemCount: _companies.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 18,
                                      crossAxisSpacing: 18,
                                      childAspectRatio: 4 / 2.3,
                                    ),
                                itemBuilder: (context, index) {
                                  final company = _companies[index];
                                  return GestureDetector(
                                    onTap: () => _goToWelcome(company),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeInOut,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          92,
                                          210,
                                          216,
                                        ).withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(18),
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
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.apartment_rounded,
                                              size: 46,
                                              color: Colors.blue.shade700,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              company.companyName,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Responsable: ${company.responsible}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Tel: ${company.contact}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black45,
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

                    const SizedBox(height: 20),

                    // 🔸 Footer elegante
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "© 2025 UTC GEN APP - Todos los derechos reservados",
                        style: TextStyle(
                          color: Color.fromARGB(179, 0, 0, 0),
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
