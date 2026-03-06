import 'package:flutter/material.dart';
import '../models/company_models.dart';
import '../repositories/company_repository.dart';
import '../views/companies_view/company_form.dart';
import '../widgets/footer.dart';

class CompanyTable extends StatefulWidget {
  const CompanyTable({super.key});

  @override
  State<CompanyTable> createState() => _CompanyTableState();
}

class _CompanyTableState extends State<CompanyTable> {
  final CompanyRepository repository = CompanyRepository();
  List<Company> companies = [];
  bool isLoading = true;
  int currentPage = 1;
  final int rowsPerPage = 10;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await repository.getAll();
      if (!mounted) return;
      setState(() {
        companies = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar empresas: $e')));
    }
  }

  Future<void> _deleteCompany(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Eliminar Hacienda'),
            content: const Text('¿Seguro que deseas eliminar esta hacienda?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await repository.delete(id);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hacienda eliminada exitosamente')),
        );
        await _loadCompanies();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la hacienda')),
        );
      }
    }
  }

  Future<void> _editCompany(Company company) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CompanyForm(
            company: company,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true) {
      await _loadCompanies();
    }
  }

  Future<void> _addCompany() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompanyForm(onSave: () => Navigator.pop(context, true)),
    );

    if (result == true) {
      await _loadCompanies();
    }
  }

  List<Company> get paginatedData {
    if (companies.isEmpty) return [];
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= companies.length) return [];
    final end = (start + rowsPerPage);
    return companies.sublist(
      start,
      end > companies.length ? companies.length : end,
    );
  }

  int get totalPages =>
      companies.isEmpty ? 1 : (companies.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;
    setState(() => currentPage = page);
  }

  List<int> _pagesWindow({
    required int current,
    required int total,
    required int maxButtons,
  }) {
    if (total <= maxButtons) {
      return List.generate(total, (i) => i + 1);
    }
    final half = maxButtons ~/ 2;
    int start = current - half;
    int end = current + half;

    if (start < 1) {
      start = 1;
      end = maxButtons;
    }
    if (end > total) {
      end = total;
      start = total - maxButtons + 1;
    }
    return [for (int i = start; i <= end; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haciendas Generales'),
        backgroundColor: const Color.fromARGB(255, 20, 106, 128),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // ✅ Acciones superiores responsive
            Padding(
              padding: EdgeInsets.all(isMobile ? 10 : 16),
              child:
                  isMobile
                      ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _addCompany,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Hacienda'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  2,
                                  97,
                                  170,
                                ),
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _loadCompanies,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Recargar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  179,
                                  3,
                                  76,
                                  213,
                                ),
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Regresar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  179,
                                  2,
                                  182,
                                  206,
                                ),
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addCompany,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Hacienda'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                2,
                                97,
                                170,
                              ),
                              foregroundColor: Colors.black87,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _loadCompanies,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Recargar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                179,
                                3,
                                76,
                                213,
                              ),
                              foregroundColor: Colors.black87,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Regresar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                179,
                                2,
                                182,
                                206,
                              ),
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ],
                      ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : companies.isEmpty
                      ? const Center(
                        child: Text(
                          'No hay haciendas registradas.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                      : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 16,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Scrollbar(
                            controller: _verticalController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _verticalController,
                              child: Scrollbar(
                                controller: _horizontalController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: isMobile ? 18 : 20,
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.black87,
                                    ),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    dataRowMinHeight: isMobile ? 48 : 56,
                                    dataRowMaxHeight: isMobile ? 72 : 86,
                                    columns: [
                                      const DataColumn(label: Text('ID')),
                                      const DataColumn(label: Text('Código')),
                                      const DataColumn(label: Text('Nombre')),
                                      if (!isMobile)
                                        const DataColumn(
                                          label: Text('Responsable'),
                                        ),
                                      if (!isMobile)
                                        const DataColumn(label: Text('DNI')),
                                      const DataColumn(label: Text('Contacto')),
                                      if (!isMobile)
                                        const DataColumn(label: Text('Correo')),
                                      if (!isMobile)
                                        const DataColumn(
                                          label: Text('Dirección'),
                                        ),
                                      const DataColumn(label: Text('Acciones')),
                                    ],
                                    rows:
                                        paginatedData.map((company) {
                                          final id = company.id ?? 0;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(id > 0 ? '$id' : '-'),
                                              ),
                                              DataCell(
                                                Text(company.companyCode),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: isMobile ? 180 : 220,
                                                  child: Text(
                                                    company.companyName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              if (!isMobile)
                                                DataCell(
                                                  Text(company.responsible),
                                                ),
                                              if (!isMobile)
                                                DataCell(Text(company.dni)),
                                              DataCell(Text(company.contact)),
                                              if (!isMobile)
                                                DataCell(Text(company.email)),
                                              if (!isMobile)
                                                DataCell(Text(company.address)),
                                              DataCell(
                                                isMobile
                                                    ? PopupMenuButton<String>(
                                                      tooltip: 'Acciones',
                                                      onSelected: (v) {
                                                        if (v == 'edit') {
                                                          _editCompany(company);
                                                        }
                                                        if (v == 'delete') {
                                                          _deleteCompany(id);
                                                        }
                                                      },
                                                      itemBuilder:
                                                          (_) => const [
                                                            PopupMenuItem(
                                                              value: 'edit',
                                                              child: Text(
                                                                'Editar',
                                                              ),
                                                            ),
                                                            PopupMenuItem(
                                                              value: 'delete',
                                                              child: Text(
                                                                'Eliminar',
                                                              ),
                                                            ),
                                                          ],
                                                      child: const Icon(
                                                        Icons.more_vert,
                                                      ),
                                                    )
                                                    : Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.edit,
                                                            color: Colors.blue,
                                                          ),
                                                          tooltip:
                                                              'Editar hacienda',
                                                          onPressed:
                                                              () =>
                                                                  _editCompany(
                                                                    company,
                                                                  ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                          ),
                                                          tooltip:
                                                              'Eliminar hacienda',
                                                          onPressed:
                                                              () =>
                                                                  _deleteCompany(
                                                                    id,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
            ),

            const SizedBox(height: 10),

            _buildPagination(isMobile),

            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(bool isMobile) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pagesToShow = _pagesWindow(
      current: currentPage,
      total: totalPages,
      maxButtons: isMobile ? 5 : 10,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: currentPage > 1 ? () => goToPage(currentPage - 1) : null,
            child: const Text('Anterior'),
          ),
          const SizedBox(width: 8),
          ...pagesToShow.map((p) {
            final selected = p == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                onPressed: () => goToPage(p),
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected ? Colors.black87 : Colors.white70,
                  foregroundColor: selected ? Colors.white : Colors.black,
                  side: const BorderSide(color: Colors.black54),
                ),
                child: Text('$p'),
              ),
            );
          }),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed:
                currentPage < totalPages
                    ? () => goToPage(currentPage + 1)
                    : null,
            child: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}
