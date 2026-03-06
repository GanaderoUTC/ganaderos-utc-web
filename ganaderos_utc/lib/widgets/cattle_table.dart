import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/cattle_models.dart';
import '../repositories/cattle_repository.dart';
import '../views/cattle_view/cattle_form.dart';
import '../widgets/footer.dart';

// ✅ sesión
import '../utils/storage.dart';
import '../models/user_models.dart';

class CattleTable extends StatefulWidget {
  final List<Cattle> initialData;
  final Future<void> Function(Cattle cattle) onEdit; // ✅ se mantiene

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

  // ✅ rol
  bool _roleLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    cattleList = widget.initialData;
    isLoading = false;
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final raw = await storageRead("user");
      if (raw == null) {
        if (!mounted) return;
        setState(() {
          _isAdmin = false;
          _roleLoading = false;
        });
        return;
      }

      final map = jsonDecode(raw);
      final u = User.fromMap(Map<String, dynamic>.from(map));
      final role = (u.role ?? 'user').toLowerCase();

      if (!mounted) return;
      setState(() {
        _isAdmin = role == 'admin';
        _roleLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _roleLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _addCattle() async {
    // ✅ ambos (admin/user) pueden agregar
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
    // ✅ solo admin elimina
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tiene permisos para eliminar.')),
      );
      return;
    }

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
    if (start >= cattleList.length) return [];
    final end = (start + rowsPerPage);
    return cattleList.sublist(
      start,
      end > cattleList.length ? cattleList.length : end,
    );
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

    final canDelete = !_roleLoading && _isAdmin;

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
            // ✅ acciones responsive
            Padding(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              child:
                  isMobile
                      ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _addCattle,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Ganado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  2,
                                  129,
                                  21,
                                ),
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _reloadData,
                              icon: const Icon(Icons.update),
                              label: const Text('Actualizar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  156,
                                  14,
                                  246,
                                  2,
                                ),
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Regresar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  18,
                                  228,
                                  158,
                                ),
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addCattle,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Ganado'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                2,
                                129,
                                21,
                              ),
                              foregroundColor: Colors.black,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _reloadData,
                            icon: const Icon(Icons.update),
                            label: const Text('Actualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                156,
                                14,
                                246,
                                2,
                              ),
                              foregroundColor: Colors.black,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Regresar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                18,
                                228,
                                158,
                              ),
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
                              columnSpacing: isMobile ? 18 : 40,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.black.withOpacity(0.85),
                              ),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              dataRowMinHeight: isMobile ? 48 : 56,
                              dataRowMaxHeight: isMobile ? 72 : 86,
                              columns: [
                                const DataColumn(label: Text('ID')),
                                const DataColumn(label: Text('Código')),
                                const DataColumn(label: Text('Nombre')),
                                if (!isMobile)
                                  const DataColumn(label: Text('Registro')),
                                if (!isMobile)
                                  const DataColumn(label: Text('Categoría')),
                                const DataColumn(label: Text('Género')),
                                if (!isMobile)
                                  const DataColumn(label: Text('Origen')),
                                if (!isMobile)
                                  const DataColumn(label: Text('Raza')),
                                if (!isMobile)
                                  const DataColumn(label: Text('Fecha')),
                                const DataColumn(label: Text('Peso')),
                                const DataColumn(label: Text('Acciones')),
                              ],
                              rows:
                                  paginatedData.map((cattle) {
                                    final id = cattle.id ?? 0;

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(id > 0 ? '$id' : '-')),
                                        DataCell(Text(cattle.code)),
                                        DataCell(
                                          SizedBox(
                                            width: isMobile ? 180 : 220,
                                            child: Text(
                                              cattle.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (!isMobile)
                                          DataCell(Text(cattle.register)),
                                        if (!isMobile)
                                          DataCell(
                                            Text(cattle.category?.name ?? '-'),
                                          ),
                                        DataCell(
                                          Text(_genderLabel(cattle.gender)),
                                        ),
                                        if (!isMobile)
                                          DataCell(
                                            Text(cattle.origin?.name ?? '-'),
                                          ),
                                        if (!isMobile)
                                          DataCell(
                                            Text(cattle.breed?.name ?? '-'),
                                          ),
                                        if (!isMobile)
                                          DataCell(Text(cattle.date)),
                                        DataCell(
                                          Text(
                                            cattle.weight.toStringAsFixed(2),
                                          ),
                                        ),
                                        DataCell(
                                          isMobile
                                              ? PopupMenuButton<String>(
                                                tooltip: 'Acciones',
                                                onSelected: (v) async {
                                                  if (v == 'edit') {
                                                    await widget.onEdit(cattle);
                                                    await _reloadData();
                                                  }
                                                  if (v == 'delete') {
                                                    if (canDelete) {
                                                      await _deleteCattle(id);
                                                    }
                                                  }
                                                },
                                                itemBuilder:
                                                    (_) => [
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Text('Editar'),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        enabled: canDelete,
                                                        child: const Text(
                                                          'Eliminar',
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
                                                    onPressed: () async {
                                                      await widget.onEdit(
                                                        cattle,
                                                      );
                                                      await _reloadData();
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed:
                                                        canDelete
                                                            ? () =>
                                                                _deleteCattle(
                                                                  id,
                                                                )
                                                            : null,
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
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: _buildPagination(isMobile),
              ),

            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(bool isMobile) {
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
                onPressed: () => goToPage(p),
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected ? Colors.black87 : Colors.white70,
                  foregroundColor: selected ? Colors.white : Colors.black,
                ),
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
