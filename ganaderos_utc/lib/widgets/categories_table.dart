import 'package:flutter/material.dart';

import '../models/categories_models.dart';
import '../repositories/categories_repository.dart';
import '../views/categories_view/category_form.dart';

class CategoriesTable extends StatefulWidget {
  final VoidCallback? onReload;

  const CategoriesTable({super.key, this.onReload});

  @override
  CategoriesTableState createState() => CategoriesTableState();
}

class CategoriesTableState extends State<CategoriesTable> {
  final CategoriesRepository repository = CategoriesRepository();

  List<Category> categories = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> loadCategories() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await CategoriesRepository.getAll();

      if (!mounted) return;

      setState(() {
        categories = data;
        isLoading = false;
        currentPage = 1;
      });

      widget.onReload?.call();
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage('Error al cargar categorías: $e');
    }
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder:
          (_) => CategoryForm(
            onSave: () async {
              await loadCategories();
              widget.onReload?.call();
            },
          ),
    );
  }

  void _editCategory(Category category) {
    showDialog(
      context: context,
      builder:
          (_) => CategoryForm(
            category: category,
            onSave: () async {
              await loadCategories();
              widget.onReload?.call();
            },
          ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    if (id <= 0) {
      showMessage('ID inválido');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Eliminar categoría'),
            content: const Text('¿Seguro que deseas eliminar esta categoría?'),
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

  List<Category> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    if (categories.isEmpty || start >= categories.length) return [];

    return categories.sublist(
      start,
      end > categories.length ? categories.length : end,
    );
  }

  int get totalPages =>
      categories.isEmpty ? 1 : (categories.length / rowsPerPage).ceil();

  void goToPage(int page) => setState(() => currentPage = page);

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
            icon: const Icon(Icons.add),
            label: const Text('Agregar categoría'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _addCategory,
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
            onPressed: loadCategories,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BoxConstraints constraints) {
    if (categories.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text(
              'No hay registros de categorías.',
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
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 68,
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
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Descripción')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows:
                      paginatedData.map((category) {
                        final id = category.id ?? 0;

                        return DataRow(
                          cells: [
                            DataCell(Text(id > 0 ? id.toString() : '-')),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  category.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 320,
                                child: Text(
                                  category.description.trim().isNotEmpty
                                      ? category.description
                                      : '-',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
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
                                      tooltip: 'Editar categoría',
                                      onPressed: () => _editCategory(category),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                      tooltip: 'Eliminar categoría',
                                      onPressed: () => _deleteCategory(id),
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

    final List<Widget> pageButtons = [];

    pageButtons.add(
      OutlinedButton(
        onPressed: currentPage > 1 ? () => goToPage(currentPage - 1) : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade400),
        ),
        child: const Text('Anterior'),
      ),
    );

    for (int i = 1; i <= totalPages; i++) {
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  i == currentPage ? const Color(0xFF1F2937) : Colors.white,
              foregroundColor: i == currentPage ? Colors.white : Colors.black87,
              side: BorderSide(color: Colors.grey.shade400),
            ),
            onPressed: () => goToPage(i),
            child: Text('$i'),
          ),
        ),
      );
    }

    pageButtons.add(
      OutlinedButton(
        onPressed:
            currentPage < totalPages ? () => goToPage(currentPage + 1) : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade400),
        ),
        child: const Text('Siguiente'),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pageButtons,
        ),
      ),
    );
  }

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
              _buildActionBar(),
              const SizedBox(height: 16),
              _buildTable(constraints),
              const SizedBox(height: 10),
              _buildPagination(),
            ],
          ),
        );
      },
    );
  }
}
