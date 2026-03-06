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
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await VaccineRepository.getAll();
      if (!mounted) return;

      setState(() {
        vaccineList = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar vacunas: $e')));
    }
  }

  /// 🔹 Agregar nueva vacuna
  Future<void> _addVaccine() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VaccineForm(onSave: () => Navigator.pop(context, true)),
    );

    if (result == true && mounted) {
      await loadVaccines();
    }
  }

  /// 🔹 Editar vacuna
  Future<void> _editVaccine(Vaccine vaccine) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => VaccineForm(
            vaccine: vaccine,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) {
      await loadVaccines();
    }
  }

  /// 🔹 Eliminar vacuna con confirmación
  Future<void> _deleteVaccine(int id) async {
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID inválido para eliminar')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
      if (!mounted) return;

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

  /// 🔹 Paginación segura
  List<Vaccine> get paginatedData {
    if (vaccineList.isEmpty) return [];
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= vaccineList.length) return [];
    final end = (start + rowsPerPage).clamp(0, vaccineList.length);
    return vaccineList.sublist(start, end);
  }

  int get totalPages =>
      vaccineList.isEmpty ? 1 : (vaccineList.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;
    setState(() => currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 700;

    if (isLoading) return const Center(child: CircularProgressIndicator());

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// ✅ Barra superior responsive
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Vacuna'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6EDB44),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _addVaccine,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2E735),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: loadVaccines,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ✅ Tabla principal
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
                                  color: Colors.white.withOpacity(0.90),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
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
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Fecha')),
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Observación')),
                                    DataColumn(label: Text('Sync')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows:
                                      paginatedData.map((vaccine) {
                                        final obs =
                                            (vaccine.observation ?? '').trim();
                                        final obsText =
                                            obs.isNotEmpty ? obs : '-';

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                vaccine.id?.toString() ?? '-',
                                              ),
                                            ),
                                            DataCell(Text(vaccine.date)),
                                            DataCell(
                                              SizedBox(
                                                width: isMobile ? 180 : 240,
                                                child: Text(
                                                  vaccine.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: isMobile ? 220 : 320,
                                                child: Text(
                                                  obsText,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                vaccine.sync == 1 ? '✔' : '✖',
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

              const SizedBox(height: 10),
              _buildPagination(isMobile),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Paginación responsive (móvil: menos botones + anterior/siguiente)
  Widget _buildPagination(bool isMobile) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = _pagesWindow(
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
            child: const Text('Anterior'),
          ),
          const SizedBox(width: 8),
          ...pages.map((p) {
            final selected = p == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selected ? Colors.black87 : Colors.white.withOpacity(0.8),
                  foregroundColor: selected ? Colors.white : Colors.black,
                ),
                onPressed: () => goToPage(p),
                child: Text('$p'),
              ),
            );
          }),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed:
                currentPage < totalPages
                    ? () => goToPage(currentPage + 1)
                    : null,
            child: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }

  List<int> _pagesWindow({
    required int current,
    required int total,
    required int maxButtons,
  }) {
    if (total <= maxButtons) return List.generate(total, (i) => i + 1);

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
}
