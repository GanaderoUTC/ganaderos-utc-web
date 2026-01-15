import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/categories_table.dart';
import 'category_form.dart';
import '../../models/categories_models.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  // Clave global para refrescar la tabla después de CRUD
  final GlobalKey<CategoriesTableState> _tableKey =
      GlobalKey<CategoriesTableState>();

  /// 🔹 Abre el formulario modal para editar una categoría
  Future<void> _openCategoryForm({Category? category}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CategoryForm(
            category: category,
            onSave: () {
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      _tableKey.currentState?.loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      backgroundColor: const Color.fromARGB(155, 161, 207, 131),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Encabezado superior sin botón de agregar
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Categorías',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 🔹 Contenedor principal con la tabla
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CategoriesTable(
                      key: _tableKey,
                      onEdit:
                          (category) => _openCategoryForm(category: category),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Footer(),
            ],
          ),
        ),
      ),
    );
  }
}
