import 'package:flutter/material.dart';
import 'package:ganaderos_utc/views/inicio_view/inicio_view.dart';
import '../models/checkup_models.dart';
import '../repositories/checkup_repository.dart';
import '../views/checkup_view/checkup_form.dart';

class CheckupTable extends StatefulWidget {
  final Function()? onReload;
  final Future<void> Function(Checkup checkup)? onEdit;
  final VoidCallback? onBack;

  const CheckupTable({super.key, this.onReload, this.onEdit, this.onBack});

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

  Future<void> loadCheckups() async {
    setState(() => isLoading = true);
    try {
      final data = await CheckupRepository.getAll();
      if (!mounted) return;

      setState(() {
        checkupList = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar chequeos: $e')));
    }
  }

  void _addCheckup() {
    showDialog(
      context: context,
      builder:
          (_) => CheckupForm(
            onSave: () async {
              await loadCheckups();
              widget.onReload?.call();
            },
          ),
    );
  }

  void _editCheckup(Checkup checkup) {
    showDialog(
      context: context,
      builder:
          (_) => CheckupForm(
            checkup: checkup,
            onSave: () async {
              await loadCheckups();
              widget.onReload?.call();
            },
          ),
    );
  }

  Future<void> _deleteCheckup(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Eliminar chequeo'),
            content: const Text('¿Seguro que deseas eliminar este chequeo?'),
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
      final success = await repository.delete(id);

      if (!mounted) return;

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

  List<Checkup> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    return checkupList.sublist(
      start,
      end > checkupList.length ? checkupList.length : end,
    );
  }

  int get totalPages =>
      checkupList.isEmpty ? 1 : (checkupList.length / rowsPerPage).ceil();

  void goToPage(int page) => setState(() => currentPage = page);

  String _getCattleText(Checkup checkup) {
    final code = checkup.cattle?.code.trim() ?? '';
    final name = checkup.cattle?.name.trim() ?? '';

    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    } else if (name.isNotEmpty) {
      return name;
    } else if (code.isNotEmpty) {
      return code;
    } else if (checkup.cattleId > 0) {
      return 'Ganado #${checkup.cattleId}';
    }

    return 'Sin ganado';
  }

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
            icon: const Icon(Icons.arrow_back),
            label: const Text('Regresar al inicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed:
                widget.onBack ??
                () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const InicioView()),
                  );
                },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar chequeo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _addCheckup,
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
            onPressed: loadCheckups,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BoxConstraints constraints) {
    if (checkupList.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text(
              'No hay registros de chequeos.',
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
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Ganado')),
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
                            DataCell(Text(checkup.id?.toString() ?? '-')),
                            DataCell(Text(checkup.date)),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  _getCattleText(checkup),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 140,
                                child: Text(
                                  checkup.symptom,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  checkup.diagnosis,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  checkup.treatment,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 160,
                                child: Text(
                                  checkup.observation.trim().isNotEmpty
                                      ? checkup.observation
                                      : '-',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
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
                                      tooltip: 'Editar chequeo',
                                      onPressed: () => _editCheckup(checkup),
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
                                      tooltip: 'Eliminar chequeo',
                                      onPressed:
                                          () => _deleteCheckup(checkup.id ?? 0),
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
