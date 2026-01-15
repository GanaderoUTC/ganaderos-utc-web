import 'package:flutter/material.dart';
import '../models/checkup_models.dart';
import '../repositories/checkup_repository.dart';
import '../views/checkup_view/checkup_form.dart';

class CheckupTable extends StatefulWidget {
  final Function()? onReload;
  final Future<void> Function(Checkup checkup)? onEdit;

  const CheckupTable({super.key, this.onReload, this.onEdit});

  @override
  CheckupTableState createState() => CheckupTableState();
}

class CheckupTableState extends State<CheckupTable> {
  final CheckupRepository repository = CheckupRepository();
  List<Checkup> checkupList = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadCheckups();
  }

  /// 🔹 Cargar registros de chequeos
  Future<void> loadCheckups() async {
    setState(() => isLoading = true);
    try {
      final data = await CheckupRepository.getAll();
      setState(() {
        checkupList = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar chequeos: $e')));
    }
  }

  /// 🔹 Agregar nuevo chequeo
  void _addCheckup() {
    showDialog(
      context: context,
      builder: (_) => CheckupForm(onSave: () => loadCheckups()),
    );
  }

  /// 🔹 Editar chequeo
  void _editCheckup(Checkup checkup) {
    showDialog(
      context: context,
      builder:
          (_) => CheckupForm(checkup: checkup, onSave: () => loadCheckups()),
    );
  }

  /// 🔹 Eliminar chequeo con confirmación
  Future<void> _deleteCheckup(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar chequeo'),
            content: const Text('¿Seguro que deseas eliminar este chequeo?'),
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
          const SnackBar(content: Text('Chequeo eliminado correctamente')),
        );
        await loadCheckups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el chequeo')),
        );
      }
    }
  }

  /// 🔹 Paginación
  List<Checkup> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage);
    return checkupList.sublist(
      start,
      end > checkupList.length ? checkupList.length : end,
    );
  }

  int get totalPages =>
      (checkupList.isEmpty) ? 1 : (checkupList.length / rowsPerPage).ceil();

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
              /// 🔹 Barra superior de acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Chequeo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6EDB44),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addCheckup,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2E735),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadCheckups,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔹 Tabla principal
              Expanded(
                child:
                    checkupList.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay registros de chequeos.',
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
                                    DataColumn(label: Text('Fecha')),
                                    DataColumn(label: Text('Síntoma')),
                                    DataColumn(label: Text('Diagnóstico')),
                                    DataColumn(label: Text('Tratamiento')),
                                    DataColumn(label: Text('Observación')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows:
                                      paginatedData.map((checkup) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                checkup.id?.toString() ?? '-',
                                              ),
                                            ),
                                            DataCell(Text(checkup.date)),
                                            DataCell(Text(checkup.symptom)),
                                            DataCell(Text(checkup.diagnosis)),
                                            DataCell(Text(checkup.treatment)),
                                            DataCell(
                                              Text(
                                                checkup.observation.isNotEmpty
                                                    ? checkup.observation
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
                                                    tooltip: 'Editar chequeo',
                                                    onPressed:
                                                        () => _editCheckup(
                                                          checkup,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip: 'Eliminar chequeo',
                                                    onPressed:
                                                        () => _deleteCheckup(
                                                          checkup.id ?? 0,
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
