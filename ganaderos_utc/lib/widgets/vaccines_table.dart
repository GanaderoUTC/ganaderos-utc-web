import 'package:flutter/material.dart';
import 'package:ganaderos_utc/views/vaccines_view/vaccine_form.dart';
import '../models/vaccine_models.dart';
import '../repositories/vaccine_repository.dart';

class VaccineTable extends StatefulWidget {
  final Function()? onReload;
  final Future<void> Function(Vaccine vaccine)? onEdit;

  const VaccineTable({super.key, this.onReload, this.onEdit});

  @override
  VaccineTableState createState() => VaccineTableState();
}

class VaccineTableState extends State<VaccineTable> {
  final VaccineRepository repository = VaccineRepository();
  List<Vaccine> vaccineList = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadVaccines();
  }

  /// 🔹 Cargar vacunas desde la API
  Future<void> loadVaccines() async {
    setState(() => isLoading = true);
    try {
      final data = await VaccineRepository.getAll();
      setState(() {
        vaccineList = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar vacunas: $e')));
    }
  }

  /// 🔹 Agregar nueva vacuna
  void _addVaccine() {
    showDialog(
      context: context,
      builder: (_) => VaccineForm(onSave: () => loadVaccines()),
    );
  }

  /// 🔹 Editar vacuna
  void _editVaccine(Vaccine vaccine) {
    showDialog(
      context: context,
      builder:
          (_) => VaccineForm(vaccine: vaccine, onSave: () => loadVaccines()),
    );
  }

  /// 🔹 Eliminar vacuna con confirmación
  Future<void> _deleteVaccine(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar vacuna'),
            content: const Text('¿Seguro que deseas eliminar esta vacuna?'),
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
          const SnackBar(content: Text('Vacuna eliminada correctamente')),
        );
        await loadVaccines();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la vacuna')),
        );
      }
    }
  }

  /// 🔹 Paginación
  List<Vaccine> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage);
    return vaccineList.sublist(
      start,
      end > vaccineList.length ? vaccineList.length : end,
    );
  }

  int get totalPages =>
      (vaccineList.isEmpty) ? 1 : (vaccineList.length / rowsPerPage).ceil();

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
                    label: const Text('Agregar Vacuna'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6EDB44),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addVaccine,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2E735),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadVaccines,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔹 Tabla principal
              Expanded(
                child:
                    vaccineList.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay registros de vacunas.',
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
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Observación')),
                                    DataColumn(label: Text('Sync')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows:
                                      paginatedData.map((vaccine) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                vaccine.id?.toString() ?? '-',
                                              ),
                                            ),
                                            DataCell(Text(vaccine.date)),
                                            DataCell(Text(vaccine.name)),
                                            DataCell(
                                              Text(
                                                vaccine.observation.isNotEmpty
                                                    ? vaccine.observation
                                                    : '-',
                                              ),
                                            ),
                                            DataCell(
                                              Text(vaccine.sync ? '✔' : '✖'),
                                            ),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip: 'Editar vacuna',
                                                    onPressed:
                                                        () => _editVaccine(
                                                          vaccine,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip: 'Eliminar vacuna',
                                                    onPressed:
                                                        () => _deleteVaccine(
                                                          vaccine.id ?? 0,
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
