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
  final int rowsPerPage = 7;

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

    setState(() {
      isLoading = true;
    });

    try {
      final data = await BreedsRepository.getAll();

      if (!mounted) return;

      final maxPages = data.isEmpty ? 1 : (data.length / rowsPerPage).ceil();

      setState(() {
        breeds = data;
        isLoading = false;

        if (currentPage > maxPages) currentPage = maxPages;
        if (currentPage < 1) currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

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
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text("Eliminar raza"),
            content: const Text("¿Seguro que desea eliminar esta raza?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Eliminar"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final ok = await repository.deleteBreed(id);

      if (!mounted) return;

      if (ok) {
        await loadBreeds();
        showMessage("Raza eliminada");
      } else {
        showMessage("No se pudo eliminar");
      }
    }
  }

  List<Breed> get paginatedData {
    if (breeds.isEmpty) return [];

    final start = (currentPage - 1) * rowsPerPage;
    if (start >= breeds.length) return [];

    final end = start + rowsPerPage;
    return breeds.sublist(start, end > breeds.length ? breeds.length : end);
  }

  int get totalPages =>
      breeds.isEmpty ? 1 : (breeds.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;
    if (page < 1 || page > totalPages) return;

    setState(() {
      currentPage = page;
    });
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

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar Raza"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 96, 227, 2),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: _addBreed,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Recargar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(136, 110, 223, 5),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: loadBreeds,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Expanded(
                  child:
                      breeds.isEmpty
                          ? const Center(
                            child: Text(
                              "No hay razas registradas.",
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
                                        paginatedData.map((breed) {
                                          final id = breed.id ?? 0;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(id > 0 ? "$id" : "-"),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: isMobile ? 180 : 220,
                                                  child: Text(
                                                    breed.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: isMobile ? 220 : 420,
                                                  child: Text(
                                                    breed.description,
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
                                                          _editBreed(breed);
                                                        }
                                                        if (v == "delete") {
                                                          _deleteBreed(id);
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
                                                              () => _editBreed(
                                                                breed,
                                                              ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  _deleteBreed(
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
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
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
            child: const Text("Anterior"),
          ),
          const SizedBox(width: 8),
          ...pagesToShow.map((p) {
            final selected = p == currentPage;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selected ? Colors.black87 : Colors.white.withOpacity(0.7),
                  foregroundColor: selected ? Colors.white : Colors.black,
                ),
                onPressed: () => goToPage(p),
                child: Text("$p"),
              ),
            );
          }),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed:
                currentPage < totalPages
                    ? () => goToPage(currentPage + 1)
                    : null,
            child: const Text("Siguiente"),
          ),
        ],
      ),
    );
  }
}
