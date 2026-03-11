import 'package:flutter/material.dart';

import '../models/breed_models.dart';
import '../repositories/breeds_repository.dart';
import '../views/breeds_view/breed_form.dart';

class BreedsTable extends StatefulWidget {
  final VoidCallback? onReload;

  const BreedsTable({super.key, this.onReload});

  @override
  State<BreedsTable> createState() => BreedsTableState();
}

class BreedsTableState extends State<BreedsTable> {
  final BreedsRepository repository = BreedsRepository();

  List<Breed> breeds = [];
  bool isLoading = true;
  bool isRefreshing = false;

  int currentPage = 1;
  final int rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    loadBreeds();
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> loadBreeds() async {
    if (!mounted || isRefreshing) return;

    isRefreshing = true;
    setState(() => isLoading = true);

    try {
      final data = await BreedsRepository.getAll();

      if (!mounted) return;

      setState(() {
        breeds = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage("Error al cargar razas: $e");
    } finally {
      isRefreshing = false;
    }
  }

  Future<void> _addBreed() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BreedForm(
          onSave: () {
            Navigator.of(dialogContext).pop(true);
          },
        );
      },
    );

    if (!mounted) return;

    if (ok == true) {
      await loadBreeds();
      widget.onReload?.call();
      showMessage("Raza guardada correctamente");
    }
  }

  Future<void> _editBreed(Breed breed) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BreedForm(
          breed: breed,
          onSave: () {
            Navigator.of(dialogContext).pop(true);
          },
        );
      },
    );

    if (!mounted) return;

    if (ok == true) {
      await loadBreeds();
      widget.onReload?.call();
      showMessage("Raza actualizada correctamente");
    }
  }

  Future<void> _deleteBreed(int id) async {
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
            title: const Text('Eliminar raza'),
            content: const Text('¿Seguro que deseas eliminar esta raza?'),
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
      final ok = await repository.deleteBreed(id);

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Raza eliminada correctamente')),
        );
        await loadBreeds();
        widget.onReload?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la raza')),
        );
      }
    }
  }

  List<Breed> get paginatedData {
    if (breeds.isEmpty) return [];

    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    return breeds.sublist(start, end > breeds.length ? breeds.length : end);
  }

  int get totalPages =>
      breeds.isEmpty ? 1 : (breeds.length / rowsPerPage).ceil();

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
            label: const Text('Agregar raza'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _addBreed,
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
            onPressed: loadBreeds,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BoxConstraints constraints) {
    if (breeds.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text(
              'No hay registros de razas.',
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
                      paginatedData.map((breed) {
                        final id = breed.id ?? 0;

                        return DataRow(
                          cells: [
                            DataCell(Text(id > 0 ? id.toString() : '-')),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  breed.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 320,
                                child: Text(
                                  breed.description.trim().isNotEmpty
                                      ? breed.description
                                      : '-',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
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
                                      tooltip: 'Editar raza',
                                      onPressed: () => _editBreed(breed),
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
                                      tooltip: 'Eliminar raza',
                                      onPressed: () => _deleteBreed(id),
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
