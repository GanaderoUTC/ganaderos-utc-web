import 'package:flutter/material.dart';
import '../models/categories_models.dart';
import '../repositories/categories_repository.dart';
import '../views/categories_view/category_form.dart';

class CategoriesTable extends StatefulWidget {
  final Function()? onReload;

  const CategoriesTable({
    super.key,
    this.onReload,
    required Future<void> Function(dynamic category) onEdit,
  });

  @override
  CategoriesTableState createState() => CategoriesTableState();
}

class CategoriesTableState extends State<CategoriesTable> {
  final CategoriesRepository repository = CategoriesRepository();

  List<Category> categories = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  /// 🔹 Cargar todas las categorías
  Future<void> loadCategories() async {
    setState(() => isLoading = true);
    try {
      final data = await CategoriesRepository.getAll();
      setState(() {
        categories = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar categorías: $e')));
    }
  }

  /// 🔹 Crear nueva categoría
  void _addCategory() {
    showDialog(
      context: context,
      builder: (_) => CategoryForm(onSave: () => loadCategories()),
    );
  }

  /// 🔹 Editar categoría
  void _editCategory(Category category) {
    showDialog(
      context: context,
      builder:
          (_) =>
              CategoryForm(category: category, onSave: () => loadCategories()),
    );
  }

  /// 🔹 Eliminar categoría con confirmación
  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar Categoría'),
            content: const Text('¿Seguro que deseas eliminar esta categoría?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await repository.delete(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría eliminada correctamente')),
        );
        await loadCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la categoría')),
        );
      }
    }
  }

  /// 🔹 Datos paginados
  List<Category> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage);
    return categories.sublist(
      start,
      end > categories.length ? categories.length : end,
    );
  }

  int get totalPages =>
      (categories.isEmpty) ? 1 : (categories.length / rowsPerPage).ceil();

  void goToPage(int page) => setState(() => currentPage = page);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// 🔹 Barra de acciones superior
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Categoría'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                        255,
                        96,
                        227,
                        2,
                      ), // Verde
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addCategory,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(136, 110, 223, 5),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadCategories,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔹 Tabla principal
              Expanded(
                child:
                    categories.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay categorías registradas.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.88),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: DataTable(
                                  columnSpacing: 40,
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.black.withOpacity(0.85),
                                  ),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  dataRowColor: WidgetStateProperty.resolveWith<
                                    Color?
                                  >((Set<WidgetState> states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.grey.withOpacity(0.3);
                                    }
                                    return Colors.white.withOpacity(0.9);
                                  }),
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Descripción')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows:
                                      paginatedData.map((category) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                category.id?.toString() ?? '-',
                                              ),
                                            ),
                                            DataCell(Text(category.name)),
                                            DataCell(
                                              Text(category.description),
                                            ),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip: 'Editar categoría',
                                                    onPressed:
                                                        () => _editCategory(
                                                          category,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip:
                                                        'Eliminar categoría',
                                                    onPressed:
                                                        () => _deleteCategory(
                                                          category.id ?? 0,
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

              const SizedBox(height: 12),
              _buildPagination(),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Paginación inferior
  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    for (int i = 1; i <= totalPages; i++) {
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  i == currentPage
                      ? Colors.black87
                      : Colors.white.withOpacity(0.7),
              foregroundColor: i == currentPage ? Colors.white : Colors.black,
              side: const BorderSide(color: Colors.black54),
            ),
            onPressed: () => goToPage(i),
            child: Text('$i'),
          ),
        ),
      );
    }

    pageButtons.add(
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: OutlinedButton(
          onPressed:
              currentPage < totalPages ? () => goToPage(currentPage + 1) : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.7),
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
        children: pageButtons,
      ),
    );
  }
}
