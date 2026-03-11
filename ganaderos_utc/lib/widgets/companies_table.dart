import 'package:flutter/material.dart';
import '../models/company_models.dart';
import '../repositories/company_repository.dart';
import '../views/companies_view/company_form.dart';
import '../widgets/footer.dart';

class CompanyTable extends StatefulWidget {
  final VoidCallback? onBack;

  const CompanyTable({super.key, this.onBack});

  @override
  State<CompanyTable> createState() => _CompanyTableState();
}

class _CompanyTableState extends State<CompanyTable> {
  final CompanyRepository repository = CompanyRepository();

  List<Company> companies = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 9;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
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

  Future<void> _deleteCompany(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Eliminar hacienda'),
            content: const Text('¿Seguro que deseas eliminar esta hacienda?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await repository.delete(id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hacienda eliminada correctamente')),
        );
        await _loadCompanies();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la hacienda')),
        );
      }
    }
  }

  List<Company> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    if (companies.isEmpty || start >= companies.length) return [];

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

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Regresar a las empresas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed:
                widget.onBack ??
                () {
                  Navigator.pop(context);
                },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar hacienda'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _addCompany,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _loadCompanies,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BoxConstraints constraints) {
    if (companies.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text(
              'No hay haciendas registradas.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowHeight: 54,
                  dataRowMinHeight: 58,
                  dataRowMaxHeight: 72,
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF1F2937),
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => Colors.white,
                  ),
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Código')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Responsable')),
                    DataColumn(label: Text('Cédula')),
                    DataColumn(label: Text('Contacto')),
                    DataColumn(label: Text('Correo')),
                    DataColumn(label: Text('Ciudad')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows:
                      paginatedData.map((company) {
                        final int id = company.id ?? 0;

                        return DataRow(
                          cells: [
                            DataCell(Text(id > 0 ? '$id' : '-')),
                            DataCell(
                              SizedBox(
                                width: 90,
                                child: Text(
                                  company.companyCode,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  company.companyName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 160,
                                child: Text(
                                  company.responsible,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 110,
                                child: Text(
                                  company.dni,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 110,
                                child: Text(
                                  company.contact,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  company.email,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 160,
                                child: Text(
                                  company.city ?? '-',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar hacienda',
                                      onPressed: () => _editCompany(company),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Eliminar hacienda',
                                      onPressed: () => _deleteCompany(id),
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
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    final bool isMobile = MediaQuery.of(context).size.width < 700;

    final pagesToShow = _pagesWindow(
      current: currentPage,
      total: totalPages,
      maxButtons: isMobile ? 5 : 8,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed:
                  currentPage > 1 ? () => goToPage(currentPage - 1) : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade400),
              ),
              child: const Text('Anterior'),
            ),
            const SizedBox(width: 6),
            ...pagesToShow.map((p) {
              final selected = p == currentPage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: () => goToPage(p),
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        selected ? const Color(0xFF1F2937) : Colors.white,
                    foregroundColor: selected ? Colors.white : Colors.black87,
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: Text('$p'),
                ),
              );
            }),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed:
                  currentPage < totalPages
                      ? () => goToPage(currentPage + 1)
                      : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade400),
              ),
              child: const Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (_, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondo1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionBar(),
                  const SizedBox(height: 16),
                  _buildTable(constraints),
                  const SizedBox(height: 10),
                  _buildPagination(),
                  const SizedBox(height: 8),
                  const Footer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
