import 'package:flutter/material.dart';
import '../models/collection_models.dart';
import '../repositories/collection_repository.dart';
import '../views/collection_view/collection_form.dart';

class CollectionTable extends StatefulWidget {
  final Function()? onReload;

  const CollectionTable({super.key, this.onReload});

  @override
  State<CollectionTable> createState() => CollectionTableState();
}

class CollectionTableState extends State<CollectionTable> {
  final CollectionRepository repository = CollectionRepository();
  List<Collection> collectionList = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadCollections();
  }

  /// 🔹 Cargar registros
  Future<void> loadCollections() async {
    setState(() => isLoading = true);
    try {
      final data = await CollectionRepository.getAll();
      setState(() {
        collectionList = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar recolecciones: $e')),
      );
    }
  }

  /// 🔹 Agregar nueva colección
  void _addCollection() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CollectionForm(
            onSave: () {
              Navigator.pop(context);
              loadCollections();
            },
          ),
    );
  }

  /// 🔹 Editar colección
  void _editCollection(Collection collection) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CollectionForm(
            collection: collection,
            onSave: () {
              Navigator.pop(context);
              loadCollections();
            },
          ),
    );
  }

  /// 🔹 Eliminar colección
  Future<void> _deleteCollection(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar recolección'),
            content: const Text(
              '¿Seguro que deseas eliminar esta recolección?',
            ),
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
          const SnackBar(content: Text('Recolección eliminada correctamente')),
        );
        await loadCollections();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la recolección')),
        );
      }
    }
  }

  /// 🔹 Paginación
  List<Collection> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage);
    return collectionList.sublist(
      start,
      end > collectionList.length ? collectionList.length : end,
    );
  }

  int get totalPages =>
      (collectionList.isEmpty)
          ? 1
          : (collectionList.length / rowsPerPage).ceil();

  void goToPage(int page) => setState(() => currentPage = page);

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

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
              // 🔹 Barra superior
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Recolección'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6EDB44),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addCollection,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2E735),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadCollections,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 🔹 Tabla de datos
              Expanded(
                child:
                    collectionList.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay registros de recolecciones.',
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
                                  color: Colors.white.withOpacity(0.9),
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
                                    DataColumn(label: Text('Fecha')),
                                    DataColumn(label: Text('Litros')),
                                    DataColumn(label: Text('Enfermedad')),
                                    DataColumn(label: Text('Densidad')),
                                    DataColumn(label: Text('Observación')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows:
                                      paginatedData.map((collection) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                collection.id?.toString() ??
                                                    '-',
                                              ),
                                            ),
                                            DataCell(Text(collection.date)),
                                            DataCell(
                                              Text(
                                                '${collection.litres.toStringAsFixed(2)} L',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                collection.illness
                                                        ?.toString() ??
                                                    '0',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                collection.density
                                                    .toStringAsFixed(2),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                (collection.observation !=
                                                            null &&
                                                        collection
                                                            .observation!
                                                            .isNotEmpty)
                                                    ? collection.observation!
                                                    : '-',
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip:
                                                        'Editar recolección',
                                                    onPressed:
                                                        () => _editCollection(
                                                          collection,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip:
                                                        'Eliminar recolección',
                                                    onPressed:
                                                        () => _deleteCollection(
                                                          collection.id ?? 0,
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

  /// 🔹 Controles de paginación
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
