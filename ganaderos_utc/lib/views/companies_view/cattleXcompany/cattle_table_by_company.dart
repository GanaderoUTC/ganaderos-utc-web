// ignore_for_file: file_names
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repository/cattle_company_repository.dart';
import '../../../models/cattle_models.dart';
import '../../../widgets/footer.dart';

// sesión
import '../../../utils/storage.dart';
import '../../../models/user_models.dart';

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

  bool _roleLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadCattle();
  }

  Future<void> _loadRole() async {
    try {
      final raw = await storageRead("user");

      if (raw == null) {
        setState(() {
          _isAdmin = false;
          _roleLoading = false;
        });
        return;
      }

      final map = jsonDecode(raw);
      final u = User.fromMap(Map<String, dynamic>.from(map));
      final role = (u.role ?? 'user').toLowerCase();

      setState(() {
        _isAdmin = role == 'admin';
        _roleLoading = false;
      });
    } catch (_) {
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

  Future<void> _loadCattle() async {
    setState(() => isLoading = true);

    try {
      final data = await CattleCompanyRepository.getAllByCompany(
        widget.companyId,
      );

      setState(() {
        cattleList = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar ganado: $e')));
    }
  }

  Future<void> _handleAdd() async {
    if (widget.onAdd == null) return;

    await widget.onAdd!();
    await _loadCattle();
  }

  Future<void> _handleEdit(Cattle cattle) async {
    await widget.onEdit(cattle);
    await _loadCattle();
  }

  Future<void> _deleteCattle(int id) async {
    if (_roleLoading || !_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No tiene permisos para eliminar.")),
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
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await CattleCompanyRepository.deleteForCompany(id);
      await _loadCattle();
    }
  }

  List<Cattle> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
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
    );
  }

  Widget _tableCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = !_roleLoading && _isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ganado por Empresa"),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_general_2.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.28)),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),

                /// BOTONES CENTRADOS (SIN BACKGROUND)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onAdd == null ? null : _handleAdd,
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

                const SizedBox(height: 16),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _tableCard(
                              SingleChildScrollView(
                                controller: _verticalController,
                                child: SingleChildScrollView(
                                  controller: _horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 30,
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.black.withOpacity(0.9),
                                    ),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                          final id = cattle.id ?? 0;

                                          return DataRow(
                                            cells: [
                                              DataCell(Text('$id')),
                                              DataCell(Text(cattle.code)),
                                              DataCell(Text(cattle.name)),
                                              DataCell(Text(cattle.register)),
                                              DataCell(
                                                Text(
                                                  cattle.category?.name ?? '-',
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _genderLabel(cattle.gender),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  cattle.origin?.name ?? '-',
                                                ),
                                              ),
                                              DataCell(
                                                Text(cattle.breed?.name ?? '-'),
                                              ),
                                              DataCell(Text(cattle.date)),
                                              DataCell(
                                                Text(
                                                  cattle.weight.toStringAsFixed(
                                                    2,
                                                  ),
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
                                                      onPressed:
                                                          () => _handleEdit(
                                                            cattle,
                                                          ),
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
                ),

                const Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
