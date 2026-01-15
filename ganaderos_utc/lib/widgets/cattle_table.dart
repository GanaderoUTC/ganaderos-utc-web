import 'package:flutter/material.dart';
import '../models/cattle_models.dart';
import '../repositories/cattle_repository.dart';
import '../views/cattle_view/cattle_form.dart';
import '../widgets/footer.dart';

class CattleTable extends StatefulWidget {
  final List<Cattle> initialData;
  final Future<void> Function(Cattle cattle) onEdit;

  const CattleTable({
    super.key,
    required this.initialData,
    required this.onEdit,
  });

  @override
  State<CattleTable> createState() => _CattleTableState();
}

class _CattleTableState extends State<CattleTable> {
  final CattleRepository repository = CattleRepository();
  late List<Cattle> cattleList;
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 10;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    cattleList = widget.initialData;
    isLoading = false;
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _addCattle() async {
    final newCattle = Cattle(
      companyId: 0,
      code: '',
      name: '',
      register: '',
      categoryId: 0,
      gender: 0,
      originId: 0,
      breedId: 0,
      date: '',
      weight: 0,
      sync: 0,
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CattleForm(
            cattle: newCattle,
            onSave: () {
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            initialCompanyId: 0,
          ),
    );

    if (!mounted) return;
    if (result == true) {
      await _reloadData();
    }
  }

  Future<void> _reloadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await CattleRepository.getAll();
      if (!mounted) return;
      setState(() {
        cattleList = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar ganado: $e')));
    }
  }

  Future<void> _deleteCattle(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar Ganado'),
            content: const Text('¿Seguro que deseas eliminar este ganado?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await CattleRepository.delete(id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ganado eliminado correctamente')),
        );
        await _reloadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el registro')),
        );
      }
    }
  }

  List<Cattle> get paginatedData {
    if (cattleList.isEmpty) return [];
    final start = (currentPage - 1) * rowsPerPage;
    final end =
        (start + rowsPerPage) > cattleList.length
            ? cattleList.length
            : (start + rowsPerPage);
    return cattleList.sublist(start, end);
  }

  int get totalPages =>
      cattleList.isEmpty ? 1 : (cattleList.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;
    setState(() => currentPage = page);
  }

  String _genderLabel(int? gender) {
    switch (gender) {
      case 1:
        return 'Macho';
      case 2:
        return 'Hembra';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganado General'),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addCattle,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Ganado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 2, 129, 21),
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _reloadData,
                    icon: const Icon(Icons.update),
                    label: const Text('Actualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(156, 14, 246, 2),
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Regresar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 18, 228, 158),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : cattleList.isEmpty
                      ? const Center(child: Text('No hay registros de ganado'))
                      : SingleChildScrollView(
                        controller: _verticalController,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
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
                              dataRowColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.grey.withOpacity(0.2);
                                    }
                                    return Colors.white.withOpacity(0.9);
                                  }),
                              columns: const [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Código')),
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Registro')),
                                DataColumn(label: Text('Categoría')),
                                DataColumn(label: Text('Género')),
                                DataColumn(label: Text('Origen')),
                                DataColumn(label: Text('Raza')),
                                DataColumn(label: Text('Fecha')),
                                DataColumn(label: Text('Peso')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows:
                                  paginatedData.map((cattle) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text('${cattle.id ?? '-'}')),
                                        DataCell(Text(cattle.code)),
                                        DataCell(Text(cattle.name)),
                                        DataCell(Text(cattle.register)),
                                        DataCell(
                                          Text(cattle.category?.name ?? '-'),
                                        ),
                                        DataCell(
                                          Text(_genderLabel(cattle.gender)),
                                        ),
                                        DataCell(
                                          Text(cattle.origin?.name ?? '-'),
                                        ),
                                        DataCell(
                                          Text(cattle.breed?.name ?? '-'),
                                        ),
                                        DataCell(Text(cattle.date)),
                                        DataCell(
                                          Text(
                                            cattle.weight.toStringAsFixed(2),
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
                                                onPressed: () async {
                                                  if (!mounted) return;
                                                  await widget.onEdit(cattle);
                                                  await _reloadData();
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    () => _deleteCattle(
                                                      cattle.id ?? 0,
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
            if (totalPages > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalPages, (index) {
                    final page = index + 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => goToPage(page),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              page == currentPage
                                  ? Colors.black87
                                  : Colors.white70,
                          foregroundColor:
                              page == currentPage ? Colors.white : Colors.black,
                        ),
                        child: Text('$page'),
                      ),
                    );
                  }),
                ),
              ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
