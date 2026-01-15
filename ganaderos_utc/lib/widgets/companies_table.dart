import 'package:flutter/material.dart';
import '../models/company_models.dart';
import '../repositories/company_repository.dart';
import '../views/companies_view/company_form.dart';
import '../widgets/footer.dart'; // Asumiendo que tu footer está aquí

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

  // 🔹 ScrollControllers
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
    setState(() => isLoading = true);
    try {
      final data = await repository.getAll();
      setState(() {
        companies = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
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
            title: const Text('Eliminar Empresa'),
            content: const Text('¿Seguro que deseas eliminar esta empresa?'),
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
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa eliminada exitosamente')),
        );
        await _loadCompanies();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la empresa')),
        );
      }
    }
  }

  void _editCompany(Company company) async {
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

  void _addCompany() async {
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
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage);
    return companies.sublist(
      start,
      end > companies.length ? companies.length : end,
    );
  }

  int get totalPages =>
      (companies.isEmpty) ? 1 : (companies.length / rowsPerPage).ceil();

  void goToPage(int page) => setState(() => currentPage = page);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compañia General'),
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
            // 🔹 Acciones superiores
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addCompany,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Empresa'),
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
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Tabla principal
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : companies.isEmpty
                      ? const Center(
                        child: Text(
                          'No hay empresas registradas.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    columnSpacing: 20,
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.black87,
                                    ),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    dataRowColor:
                                        WidgetStateProperty.resolveWith<Color?>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(
                                              WidgetState.hovered,
                                            )) {
                                              return Colors.grey.withOpacity(
                                                0.2,
                                              );
                                            }
                                            return Colors.white.withOpacity(
                                              0.9,
                                            );
                                          },
                                        ),
                                    columns: const [
                                      DataColumn(label: Text('ID')),
                                      DataColumn(label: Text('Código')),
                                      DataColumn(label: Text('Nombre')),
                                      DataColumn(label: Text('Responsable')),
                                      DataColumn(label: Text('DNI')),
                                      DataColumn(label: Text('Contacto')),
                                      DataColumn(label: Text('Correo')),
                                      DataColumn(label: Text('Dirección')),
                                      DataColumn(label: Text('Acciones')),
                                    ],
                                    rows:
                                        paginatedData.map((company) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(company.id.toString()),
                                              ),
                                              DataCell(
                                                Text(company.companyCode),
                                              ),
                                              DataCell(
                                                Text(company.companyName),
                                              ),
                                              DataCell(
                                                Text(company.responsible),
                                              ),
                                              DataCell(Text(company.dni)),
                                              DataCell(Text(company.contact)),
                                              DataCell(Text(company.email)),
                                              DataCell(Text(company.address)),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.blue,
                                                      ),
                                                      tooltip: 'Editar empresa',
                                                      onPressed:
                                                          () => _editCompany(
                                                            company,
                                                          ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      tooltip:
                                                          'Eliminar empresa',
                                                      onPressed:
                                                          () => _deleteCompany(
                                                            company.id!,
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

            const SizedBox(height: 12),

            // 🔹 Paginación
            _buildPagination(),

            // 🔹 Footer
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    List<Widget> buttons = [];

    for (int i = 1; i <= totalPages; i++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            onPressed: () => goToPage(i),
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  i == currentPage ? Colors.black87 : Colors.white70,
              foregroundColor: i == currentPage ? Colors.white : Colors.black,
              side: const BorderSide(color: Colors.black54),
            ),
            child: Text('$i'),
          ),
        ),
      );
    }

    buttons.add(
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: OutlinedButton(
          onPressed:
              currentPage < totalPages ? () => goToPage(currentPage + 1) : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white70,
            foregroundColor: Colors.black,
          ),
          child: const Text('Siguiente'),
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      ),
    );
  }
}
