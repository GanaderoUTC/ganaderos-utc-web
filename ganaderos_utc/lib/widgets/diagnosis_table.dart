import 'package:flutter/material.dart';
import '../models/diagnosis_models.dart';
import '../repositories/diagnosis_repository.dart';
import '../views/diagnosis_view/diagnosis_form.dart';

class DiagnosisTable extends StatefulWidget {
  final VoidCallback? onReload;

  /// ✅ Si quieres que el padre controle la edición, usa esto.
  /// Si no lo pasas, la tabla abre DiagnosisForm internamente.
  final Future<void> Function(Diagnosis diagnosis)? onEdit;

  const DiagnosisTable({super.key, this.onReload, this.onEdit});

  @override
  DiagnosisTableState createState() => DiagnosisTableState();
}

class DiagnosisTableState extends State<DiagnosisTable> {
  final DiagnosisRepository repository = DiagnosisRepository();

  List<Diagnosis> diagnosisList = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadDiagnosis();
  }

  Future<void> loadDiagnosis() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await DiagnosisRepository.getAll();
      if (!mounted) return;
      setState(() {
        diagnosisList = data;
        isLoading = false;
        currentPage = 1;
      });

      widget.onReload?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar diagnósticos: $e')),
      );
    }
  }

  void _addDiagnosis() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DiagnosisForm(onSave: () => Navigator.pop(context, true)),
    ).then((ok) async {
      if (ok == true) await loadDiagnosis();
    });
  }

  Future<void> _editDiagnosisInternal(Diagnosis diagnosis) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => DiagnosisForm(
            diagnosis: diagnosis,
            onSave: () => Navigator.pop(context, true),
          ),
    );
    if (ok == true) await loadDiagnosis();
  }

  Future<void> _handleEdit(Diagnosis diagnosis) async {
    if (widget.onEdit != null) {
      await widget.onEdit!(diagnosis);
      await loadDiagnosis();
    } else {
      await _editDiagnosisInternal(diagnosis);
    }
  }

  Future<void> _deleteDiagnosis(int id) async {
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID inválido para eliminar.')),
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
            title: const Text('Eliminar Diagnóstico'),
            content: const Text(
              '¿Seguro que deseas eliminar este diagnóstico?',
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
      final success = await DiagnosisRepository.deleteDiagnosis(id);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diagnóstico eliminado correctamente')),
        );
        await loadDiagnosis();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el diagnóstico')),
        );
      }
    }
  }

  // ✅ Mostrar descripción completa (sin cambiar diseño de tabla)
  void _showFullDescription(String title, String description) {
    showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(title),
            content: SingleChildScrollView(
              child: Text(description.isEmpty ? '-' : description),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  List<Diagnosis> get paginatedData {
    if (diagnosisList.isEmpty) return [];
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= diagnosisList.length) return [];
    final end = start + rowsPerPage;
    return diagnosisList.sublist(
      start,
      end > diagnosisList.length ? diagnosisList.length : end,
    );
  }

  int get totalPages =>
      diagnosisList.isEmpty ? 1 : (diagnosisList.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;
    setState(() => currentPage = page);
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 700;

    if (isLoading) return const Center(child: CircularProgressIndicator());

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
              if (isMobile) ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Diagnóstico'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 96, 227, 2),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addDiagnosis,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(136, 110, 223, 5),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadDiagnosis,
                  ),
                ),
              ] else ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Diagnóstico'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 96, 227, 2),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: _addDiagnosis,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recargar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(136, 110, 223, 5),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: loadDiagnosis,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              Expanded(
                child:
                    diagnosisList.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay diagnósticos registrados.',
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

                                  // ✅ AUMENTA la altura máxima para que quepan descripciones largas
                                  dataRowMinHeight: isMobile ? 56 : 64,
                                  dataRowMaxHeight: isMobile ? 120 : 220,

                                  columns: [
                                    const DataColumn(label: Text('ID')),
                                    const DataColumn(label: Text('Nombre')),
                                    if (!isMobile)
                                      const DataColumn(
                                        label: Text('Descripción'),
                                      ),
                                    const DataColumn(label: Text('Sync')),
                                    const DataColumn(label: Text('Acciones')),
                                  ],
                                  rows:
                                      paginatedData.map((diagnosis) {
                                        final id = diagnosis.id ?? 0;

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(id > 0 ? '$id' : '-'),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: isMobile ? 200 : 220,
                                                child: Text(
                                                  diagnosis.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),

                                            // ✅ ESCRITORIO: descripción completa (sin ellipsis)
                                            if (!isMobile)
                                              DataCell(
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 520,
                                                      ),
                                                  child: InkWell(
                                                    onTap:
                                                        () =>
                                                            _showFullDescription(
                                                              diagnosis.name,
                                                              diagnosis
                                                                  .description,
                                                            ),
                                                    child: Text(
                                                      diagnosis.description,
                                                      // ✅ sin maxLines => muestra completo
                                                      // ✅ sin overflow => no recorta
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            DataCell(
                                              Icon(
                                                diagnosis.sync
                                                    ? Icons.cloud_done
                                                    : Icons.cloud_off,
                                                color:
                                                    diagnosis.sync
                                                        ? Colors.green
                                                        : Colors.grey,
                                              ),
                                            ),
                                            DataCell(
                                              isMobile
                                                  ? PopupMenuButton<String>(
                                                    tooltip: 'Acciones',
                                                    onSelected: (v) {
                                                      if (v == 'edit') {
                                                        _handleEdit(diagnosis);
                                                      }
                                                      if (v == 'delete') {
                                                        _deleteDiagnosis(id);
                                                      }
                                                      if (v == 'desc') {
                                                        _showFullDescription(
                                                          diagnosis.name,
                                                          diagnosis.description,
                                                        );
                                                      }
                                                    },
                                                    itemBuilder:
                                                        (_) => const [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Text(
                                                              'Editar',
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Text(
                                                              'Eliminar',
                                                            ),
                                                          ),
                                                          // ✅ móvil NO tiene columna descripción:
                                                          // sin cambiar diseño, mostramos opción para verla.
                                                          PopupMenuItem(
                                                            value: 'desc',
                                                            child: Text(
                                                              'Ver descripción',
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
                                                        tooltip:
                                                            'Editar diagnóstico',
                                                        onPressed:
                                                            () => _handleEdit(
                                                              diagnosis,
                                                            ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        tooltip:
                                                            'Eliminar diagnóstico',
                                                        onPressed:
                                                            () =>
                                                                _deleteDiagnosis(
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
            child: const Text('Anterior'),
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
                  side: const BorderSide(color: Colors.black54),
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
}
