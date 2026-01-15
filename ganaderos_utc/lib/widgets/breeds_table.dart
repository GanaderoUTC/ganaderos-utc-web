import 'package:flutter/material.dart';
import '../models/breed_models.dart';
import '../repositories/breeds_repository.dart';
import '../views/breeds_view/breed_form.dart';

class BreedsTable extends StatefulWidget {
  final Function()? onReload;

  const BreedsTable({
    super.key,
    this.onReload,
    required Future<void> Function(dynamic breed) onEdit,
  });

  @override
  BreedsTableState createState() => BreedsTableState();
}

class BreedsTableState extends State<BreedsTable> {
  final BreedsRepository repository = BreedsRepository();

  List<Breed> breeds = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadBreeds();
  }

  /// 🔹 Cargar todas las razas
  Future<void> loadBreeds() async {
    setState(() => isLoading = true);
    try {
      final data = await BreedsRepository.getAll();
      setState(() {
        breeds = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar razas: $e')));
    }
  }

  /// 🔹 Crear nueva raza
  void _addBreed() {
    showDialog(
      context: context,
      builder: (_) => BreedForm(onSave: () => loadBreeds()),
    );
  }

  /// 🔹 Editar raza
  void _editBreed(Breed breed) {
    showDialog(
      context: context,
      builder: (_) => BreedForm(breed: breed, onSave: () => loadBreeds()),
    );
  }

  /// 🔹 Eliminar raza con confirmación
  Future<void> _deleteBreed(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar Raza'),
            content: const Text('¿Seguro que deseas eliminar esta raza?'),
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
      final success = await repository.deleteBreed(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Raza eliminada correctamente')),
        );
        await loadBreeds();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la raza')),
        );
      }
    }
  }

  /// 🔹 Datos paginados
  List<Breed> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage);
    return breeds.sublist(start, end > breeds.length ? breeds.length : end);
  }

  int get totalPages =>
      (breeds.isEmpty) ? 1 : (breeds.length / rowsPerPage).ceil();

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
                    label: const Text('Agregar Raza'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 96, 227, 2),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addBreed,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(136, 110, 223, 5),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadBreeds,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔹 Tabla principal
              Expanded(
                child:
                    breeds.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay razas registradas.',
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
                                      paginatedData.map((breed) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(breed.id?.toString() ?? '-'),
                                            ),
                                            DataCell(Text(breed.name)),
                                            DataCell(Text(breed.description)),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip: 'Editar raza',
                                                    onPressed:
                                                        () => _editBreed(breed),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip: 'Eliminar raza',
                                                    onPressed:
                                                        () => _deleteBreed(
                                                          breed.id ?? 0,
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
