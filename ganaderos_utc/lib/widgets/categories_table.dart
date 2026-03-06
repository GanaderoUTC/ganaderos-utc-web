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
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void showMessage(String msg) {
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

        final maxPages =
            categories.isEmpty ? 1 : (categories.length / rowsPerPage).ceil();

        if (currentPage > maxPages) currentPage = maxPages;
        if (currentPage < 1) currentPage = 1;
      });

      widget.onReload?.call();
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage("Error al cargar categorías: $e");
    }
  }

  /// 🔹 Agregar categoría (igual que OriginTable)
  void _addCategory() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CategoryForm(onSave: () => Navigator.pop(dialogContext, true));
      },
    ).then((ok) async {
      if (ok == true) await loadCategories();
    });
  }

  /// 🔹 Editar categoría
  void _editCategory(Category category) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CategoryForm(
          category: category,
          onSave: () => Navigator.pop(dialogContext, true),
        );
      },
    ).then((ok) async {
      if (ok == true) await loadCategories();
    });
  }

  /// 🔹 Eliminar categoría
  Future<void> _deleteCategory(int id) async {
    if (id <= 0) {
      showMessage("ID inválido");
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text("Eliminar categoría"),
            content: const Text("¿Seguro que desea eliminar esta categoría?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Eliminar"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final ok = await repository.delete(id);

      if (!mounted) return;

      if (ok) {
        showMessage("Categoría eliminada");
        await loadCategories();
      } else {
        showMessage("No se pudo eliminar");
      }
    }
  }

  List<Category> get paginatedData {
    if (categories.isEmpty) return [];

    final start = (currentPage - 1) * rowsPerPage;

    if (start >= categories.length) return [];

    final end = start + rowsPerPage;

    return categories.sublist(
      start,
      end > categories.length ? categories.length : end,
    );
  }

  int get totalPages =>
      categories.isEmpty ? 1 : (categories.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;

    if (page < 1 || page > totalPages) return;

    setState(() => currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 700;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
          width: constraints.maxWidth,
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondo1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Barra acciones (igual estilo)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar Categoría"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 96, 227, 2),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addCategory,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Recargar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(136, 110, 223, 5),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadCategories,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// TABLA
              Expanded(
                child:
                    categories.isEmpty
                        ? const Center(
                          child: Text(
                            "No hay categorías registradas.",
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
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: DataTable(
                                  columnSpacing: isMobile ? 18 : 40,
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.black.withOpacity(0.85),
                                  ),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text("ID")),
                                    DataColumn(label: Text("Nombre")),
                                    DataColumn(label: Text("Descripción")),
                                    DataColumn(label: Text("Acciones")),
                                  ],
                                  rows:
                                      paginatedData.map((category) {
                                        final id = category.id ?? 0;

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(id > 0 ? "$id" : "-"),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: isMobile ? 200 : 240,
                                                child: Text(
                                                  category.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: isMobile ? 220 : 420,
                                                child: Text(
                                                  category.description,
                                                  maxLines: isMobile ? 2 : 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              isMobile
                                                  ? PopupMenuButton<String>(
                                                    onSelected: (v) {
                                                      if (v == "edit") {
                                                        _editCategory(category);
                                                      }
                                                      if (v == "delete") {
                                                        _deleteCategory(id);
                                                      }
                                                    },
                                                    itemBuilder:
                                                        (_) => const [
                                                          PopupMenuItem(
                                                            value: "edit",
                                                            child: Text(
                                                              "Editar",
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: "delete",
                                                            child: Text(
                                                              "Eliminar",
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
                                                        onPressed:
                                                            () =>
                                                                _deleteCategory(
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

              const SizedBox(height: 10),
              _buildPagination(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagination(bool isMobile) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: currentPage > 1 ? () => goToPage(currentPage - 1) : null,
          child: const Text("Anterior"),
        ),
        const SizedBox(width: 10),
        Text("Página $currentPage / $totalPages"),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed:
              currentPage < totalPages ? () => goToPage(currentPage + 1) : null,
          child: const Text("Siguiente"),
        ),
      ],
    );
  }
}
