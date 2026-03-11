import 'dart:ui';
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
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() => _loading = true);

    try {
      final repo = CompanyRepository();
      final companies = await repo.getAll();

      final Map<int, int> counts = {};

      for (final c in companies) {
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

      setState(() => _loading = false);

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
    _fetchCompanies();
  }

  int _crossAxisCount(double width) {
    if (width < 640) return 1;
    if (width < 980) return 2;
    if (width < 1320) return 3;
    return 4;
  }

  double _childAspectRatio(double width) {
    if (width < 640) return 1.70;
    if (width < 980) return 1.55;
    if (width < 1320) return 1.48;
    return 1.42;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 640;
    final isTablet = w >= 640 && w < 980;

    return Scaffold(
      drawer: const Sidebar(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: Navbar(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text(
          "Nueva Hacienda",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: _goToCompaniesTable,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo1.jpg', fit: BoxFit.cover),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.34)),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: const Color(0xFF0B1F33).withOpacity(0.10),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeaderPanel(
                            isMobile: isMobile,
                            isTablet: isTablet,
                            onRefresh: _fetchCompanies,
                            onTable: _goToCompaniesTable,
                            onUsers:
                                () => Navigator.pushNamed(context, '/user'),
                          ),
                          const SizedBox(height: 18),

                          Expanded(
                            child:
                                _companies.isEmpty
                                    ? const _EmptyPanel()
                                    : GridView.builder(
                                      itemCount: _companies.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: _crossAxisCount(w),
                                            mainAxisSpacing: 18,
                                            crossAxisSpacing: 18,
                                            childAspectRatio: _childAspectRatio(
                                              w,
                                            ),
                                          ),
                                      itemBuilder: (context, index) {
                                        final company = _companies[index];
                                        final cattle =
                                            _cattleCount[company.id ?? 0] ?? 0;
                                        final isHovered =
                                            _hoveredIndex == index;

                                        return MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          onEnter: (_) {
                                            setState(
                                              () => _hoveredIndex = index,
                                            );
                                          },
                                          onExit: (_) {
                                            setState(
                                              () => _hoveredIndex = null,
                                            );
                                          },
                                          child: GestureDetector(
                                            onTap: () => _goToWelcome(company),
                                            child: _CompanyCard(
                                              company: company,
                                              cattle: cattle,
                                              isHovered: isHovered,
                                              isMobile: isMobile,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFE7EEF7).withOpacity(0.76),
                                  const Color(0xFFD7E3F2).withOpacity(0.72),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              "© 2025 UTC GEN APP - Todos los derechos reservados",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF263238),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final VoidCallback onRefresh;
  final VoidCallback onTable;
  final VoidCallback onUsers;

  const _HeaderPanel({
    required this.isMobile,
    required this.isTablet,
    required this.onRefresh,
    required this.onTable,
    required this.onUsers,
  });

  @override
  Widget build(BuildContext context) {
    final panel = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE7EEF7).withOpacity(0.84),
          const Color(0xFFD2DFEF).withOpacity(0.78),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.28)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.13),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business_center, color: Color(0xFF0B5E2B), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Haciendas Registradas",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B5E2B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeaderButton(
                  onPressed: onRefresh,
                  icon: Icons.refresh,
                  label: "Actualizar",
                  color: const Color(0xFF6A5ACD),
                ),
                _HeaderButton(
                  onPressed: onTable,
                  icon: Icons.table_chart_outlined,
                  label: "Ver Tabla",
                  color: const Color(0xFF7E57C2),
                ),
                _HeaderButton(
                  onPressed: onUsers,
                  icon: Icons.person,
                  label: "Administrar usuarios",
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: panel,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business_center, color: Color(0xFF0B5E2B), size: 26),
              SizedBox(width: 10),
              Text(
                "Haciendas Registradas",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B5E2B),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderButton(
                onPressed: onRefresh,
                icon: Icons.refresh,
                label: "Actualizar",
                color: const Color(0xFF6A5ACD),
              ),
              _HeaderButton(
                onPressed: onTable,
                icon: Icons.table_chart_outlined,
                label: "Ver Tabla",
                color: const Color(0xFF7E57C2),
              ),
              _HeaderButton(
                onPressed: onUsers,
                icon: Icons.person,
                label: "Administrar usuarios",
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 1.5,
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE7EEF7).withOpacity(0.84),
              const Color(0xFFD6E2F0).withOpacity(0.80),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.26)),
        ),
        child: const Text(
          "No hay haciendas registradas",
          style: TextStyle(
            color: Color(0xFF1E2A35),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final int cattle;
  final bool isHovered;
  final bool isMobile;

  const _CompanyCard({
    required this.company,
    required this.cattle,
    required this.isHovered,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isHovered ? Colors.black : const Color(0xFF103B67);
    final Color textColor =
        isHovered ? Colors.black87 : const Color(0xFF31475B);
    final Color softTextColor =
        isHovered ? Colors.black87 : const Color(0xFF455A64);
    final Color iconColor = isHovered ? Colors.black87 : Colors.blue.shade700;
    final Color badgeTextColor =
        isHovered ? Colors.black : Colors.green.shade800;

    return AnimatedScale(
      scale: isHovered ? 1.018 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isHovered
                    ? [
                      const Color(0xFFA9BDD0).withOpacity(0.96),
                      const Color(0xFF8EA6BC).withOpacity(0.94),
                    ]
                    : [
                      const Color(0xFFC7D8E8).withOpacity(0.93),
                      const Color(0xFFABC1D8).withOpacity(0.90),
                    ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isHovered
                    ? const Color(0xFF2F5D86)
                    : const Color(0xFF7EA2C2).withOpacity(0.95),
            width: isHovered ? 2 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? 0.20 : 0.13),
              blurRadius: isHovered ? 18 : 10,
              offset: Offset(0, isHovered ? 9 : 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 250 || constraints.maxHeight < 180;
            final iconSize = compact ? 34.0 : (isMobile ? 38.0 : 44.0);
            final titleSize = compact ? 15.5 : (isMobile ? 16.5 : 18.0);
            final bodySize = compact ? 12.2 : 13.6;
            final citySize = compact ? 11.6 : 12.4;

            return Padding(
              padding: EdgeInsets.all(compact ? 12 : 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? 9 : 11),
                    decoration: BoxDecoration(
                      color:
                          isHovered
                              ? Colors.white.withOpacity(0.24)
                              : Colors.white.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: Icon(
                      Icons.house_siding,
                      size: iconSize,
                      color: iconColor,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 12),

                  Text(
                    company.companyName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),

                  _InfoLine(
                    text: "Responsable: ${company.responsible}",
                    color: textColor,
                    size: bodySize,
                    bold: true,
                  ),
                  const SizedBox(height: 4),
                  _InfoLine(
                    text: "Tel: ${company.contact}",
                    color: textColor,
                    size: bodySize,
                  ),
                  const SizedBox(height: 4),
                  _InfoLine(
                    text: "Ciudad: ${company.city ?? '-'}",
                    color: softTextColor,
                    size: citySize,
                  ),

                  SizedBox(height: compact ? 10 : 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isHovered
                              ? Colors.white.withOpacity(0.25)
                              : Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isHovered
                                ? Colors.white.withOpacity(0.22)
                                : Colors.green.withOpacity(0.20),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "🐄 Vacas registradas: $cattle",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 12.2 : 13,
                          color: badgeTextColor,
                        ),
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

class _InfoLine extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  final bool bold;

  const _InfoLine({
    required this.text,
    required this.color,
    required this.size,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        height: 1.15,
      ),
    );
  }
}
