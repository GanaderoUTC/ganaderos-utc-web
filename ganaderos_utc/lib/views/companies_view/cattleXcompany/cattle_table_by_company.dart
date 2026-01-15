// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repository/cattle_company_repository.dart';
import '../../../models/cattle_models.dart';
import '../../../widgets/footer.dart';

class CattleTableByCompany extends StatefulWidget {
  final int companyId;
  final Future<void> Function(Cattle cattle) onEdit;
  final Future<void> Function()? onAdd;

  const CattleTableByCompany({
    super.key,
    required this.companyId,
    required this.onEdit,
    this.onAdd,
  });

  @override
  State<CattleTableByCompany> createState() => _CattleTableByCompanyState();
}

class _CattleTableByCompanyState extends State<CattleTableByCompany> {
  List<Cattle> cattleList = [];
  bool isLoading = true;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  int currentPage = 1;
  final int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadCattle();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _loadCattle() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await CattleCompanyRepository.getAllByCompany(
        widget.companyId,
      );
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
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID inválido para eliminar.")),
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
            title: const Text('Eliminar Ganado'),
            content: const Text('¿Seguro que deseas eliminar este ganado?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await CattleCompanyRepository.deleteForCompany(id);
      if (!mounted) return;

      if (success) {
        await _loadCattle();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ganado eliminado correctamente')),
        );
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
    if (start >= cattleList.length) return [];
    final end = start + rowsPerPage;
    return cattleList.sublist(
      start,
      end > cattleList.length ? cattleList.length : end,
    );
  }

  int get totalPages =>
      cattleList.isEmpty ? 1 : (cattleList.length / rowsPerPage).ceil();

  void goToPage(int page) => setState(() => currentPage = page);

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

  ButtonStyle _topButtonStyle(Color bg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
    );
  }

  Widget _tableCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ganado por Empresa"),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_general_2.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.06),
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: widget.onAdd ?? () {},
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Ganado'),
                              style: _topButtonStyle(Colors.green.shade700),
                            ),
                            ElevatedButton.icon(
                              onPressed: _loadCattle,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar'),
                              style: _topButtonStyle(Colors.green.shade500),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Regresar'),
                              style: _topButtonStyle(Colors.teal.shade600),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child:
                              cattleList.isEmpty
                                  ? _tableCard(
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          "No hay registros de ganado",
                                        ),
                                      ),
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    controller: _verticalController,
                                    child: SingleChildScrollView(
                                      controller: _horizontalController,
                                      scrollDirection: Axis.horizontal,
                                      child: _tableCard(
                                        DataTable(
                                          columnSpacing: 30,
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                Colors.black.withOpacity(0.85),
                                              ),
                                          headingTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          dataRowColor:
                                              WidgetStateProperty.resolveWith(
                                                (states) =>
                                                    states.contains(
                                                          WidgetState.hovered,
                                                        )
                                                        ? Colors.grey
                                                            .withOpacity(0.15)
                                                        : Colors.white
                                                            .withOpacity(0.92),
                                              ),
                                          columns: const [
                                            DataColumn(label: Text('ID')),
                                            DataColumn(label: Text('Código')),
                                            DataColumn(label: Text('Nombre')),
                                            DataColumn(label: Text('Registro')),
                                            DataColumn(
                                              label: Text('Categoría'),
                                            ),
                                            DataColumn(label: Text('Género')),
                                            DataColumn(label: Text('Origen')),
                                            DataColumn(label: Text('Raza')),
                                            DataColumn(label: Text('Fecha')),
                                            DataColumn(label: Text('Peso')),
                                            DataColumn(label: Text('Acciones')),
                                          ],
                                          rows:
                                              paginatedData.map((cattle) {
                                                final id = cattle.id ?? 0;
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        id > 0 ? '$id' : '-',
                                                      ),
                                                    ),
                                                    DataCell(Text(cattle.code)),
                                                    DataCell(Text(cattle.name)),
                                                    DataCell(
                                                      Text(cattle.register),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        cattle.category?.name ??
                                                            '-',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _genderLabel(
                                                          cattle.gender,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        cattle.origin?.name ??
                                                            '-',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        cattle.breed?.name ??
                                                            '-',
                                                      ),
                                                    ),
                                                    DataCell(Text(cattle.date)),
                                                    DataCell(
                                                      Text(
                                                        cattle.weight
                                                            .toStringAsFixed(2),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            tooltip: "Editar",
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            onPressed:
                                                                () => widget
                                                                    .onEdit(
                                                                      cattle,
                                                                    ),
                                                          ),
                                                          IconButton(
                                                            tooltip: "Eliminar",
                                                            icon: const Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    _deleteCattle(
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

                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(totalPages, (index) {
                                final page = index + 1;
                                final selected = page == currentPage;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () => goToPage(page),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          selected
                                              ? Colors.black.withOpacity(0.85)
                                              : Colors.white.withOpacity(0.75),
                                      foregroundColor:
                                          selected
                                              ? Colors.white
                                              : Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('$page'),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                      const Footer(),
                    ],
                  ),
        ),
      ),
    );
  }
}
