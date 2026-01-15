import 'package:flutter/material.dart';
import 'package:ganaderos_utc/views/weight_view/weight_form.dart';
import '../models/weight_models.dart';
import '../repositories/weight_repository.dart';

class WeightTable extends StatefulWidget {
  final Function()? onReload;
  final Future<void> Function(Weight weight)? onEdit;

  const WeightTable({super.key, this.onReload, this.onEdit});

  @override
  WeightTableState createState() => WeightTableState();
}

class WeightTableState extends State<WeightTable> {
  final WeightRepository repository = WeightRepository();
  List<Weight> weightList = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadWeights();
  }

  /// Cargar registros
  Future<void> loadWeights() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await WeightRepository.getAll();

      if (!mounted) return;
      setState(() {
        weightList = data;
        currentPage = 1; // reset paginación
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar pesos: $e')));
    }
  }

  /// Agregar registro
  void _addWeight() {
    showDialog(
      context: context,
      builder: (_) => WeightForm(onSave: () => loadWeights()),
    );
  }

  /// Editar registro
  void _editWeight(Weight weight) {
    showDialog(
      context: context,
      builder: (_) => WeightForm(weight: weight, onSave: () => loadWeights()),
    );
  }

  /// Eliminar registro
  Future<void> _deleteWeight(int? id) async {
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar registro de peso'),
            content: const Text('¿Seguro que deseas eliminar este registro?'),
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

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado correctamente')),
        );
        await loadWeights();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el registro')),
        );
      }
    }
  }

  /// Paginación segura
  List<Weight> get paginatedData {
    if (weightList.isEmpty) return [];

    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, weightList.length);

    if (start >= weightList.length) return [];

    return weightList.sublist(start, end);
  }

  int get totalPages {
    if (weightList.isEmpty) return 1;
    return (weightList.length / rowsPerPage).ceil();
  }

  void goToPage(int page) {
    if (!mounted) return;
    if (page < 1 || page > totalPages) return;

    setState(() => currentPage = page);
  }

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
              /// Botones superiores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Registro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6EDB44),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addWeight,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2E735),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadWeights,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// Tabla
              Expanded(
                child:
                    weightList.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay registros de peso.',
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
                                  >((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.grey.withOpacity(0.3);
                                    }
                                    return Colors.white.withOpacity(0.9);
                                  }),
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Fecha')),
                                    DataColumn(label: Text('Peso (kg)')),
                                    DataColumn(label: Text('Cód. Ganado')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows:
                                      paginatedData.map((weight) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                weight.id?.toString() ?? '-',
                                              ),
                                            ),
                                            DataCell(Text(weight.date)),
                                            DataCell(
                                              Text(weight.weight.toString()),
                                            ),
                                            DataCell(
                                              Text(weight.cattleId.toString()),
                                            ),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip: 'Editar registro',
                                                    onPressed:
                                                        () =>
                                                            _editWeight(weight),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip:
                                                        'Eliminar registro',
                                                    onPressed:
                                                        () => _deleteWeight(
                                                          weight.id,
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

  /// Paginación visual
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
