// ignore_for_file: file_names
import 'package:flutter/material.dart';
import '../../../models/user_models.dart';
import '../../../repository/user_company_repository.dart';
import '../../../repository/user_company_form.dart';
import '../../../widgets/footer.dart';

class UserTableViewByCompany extends StatefulWidget {
  final int companyId;
  final String companyName;

  const UserTableViewByCompany({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<UserTableViewByCompany> createState() => _UserTableViewByCompanyState();
}

class _UserTableViewByCompanyState extends State<UserTableViewByCompany> {
  bool isLoading = true;
  List<User> list = [];

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  // ✅ rows por página responsive
  int _rowsPerPage(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w < 600) ? 5 : 10;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await UserCompanyRepository.getAllByCompany(
        widget.companyId,
      );
      if (!mounted) return;

      setState(() {
        list = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar usuarios: $e")));
    }
  }

  Future<void> _onAdd() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => UserCompanyForm(
            companyId: widget.companyId,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) await _load();
  }

  Future<void> _onEdit(User user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => UserCompanyForm(
            user: user,
            companyId: widget.companyId,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) await _load();
  }

  Future<void> _onDelete(int id) async {
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
            title: const Text("Eliminar"),
            content: const Text("¿Deseas eliminar este usuario?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
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
                child: const Text("Eliminar"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final ok = await UserCompanyRepository.deleteForCompany(id);
      if (!mounted) return;

      if (ok) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Eliminado correctamente")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No se pudo eliminar")));
      }
    }
  }

  List<User> _paginatedData(BuildContext context) {
    final rowsPerPage = _rowsPerPage(context);

    if (list.isEmpty) return [];
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= list.length) return [];
    final end = start + rowsPerPage;
    return list.sublist(start, end > list.length ? list.length : end);
  }

  int _totalPages(BuildContext context) {
    final rowsPerPage = _rowsPerPage(context);
    return list.isEmpty ? 1 : (list.length / rowsPerPage).ceil();
  }

  void goToPage(int page) => setState(() => currentPage = page);

  ButtonStyle _topButtonStyle(Color bg, {bool fullWidth = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      minimumSize: fullWidth ? const Size.fromHeight(44) : null,
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final rows = _paginatedData(context);
    final totalPages = _totalPages(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Usuarios - ${widget.companyName}"),
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
                        child:
                            isMobile
                                ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _onAdd,
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Agregar Usuario'),
                                      style: _topButtonStyle(
                                        Colors.green.shade700,
                                        fullWidth: true,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: _load,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Actualizar'),
                                      style: _topButtonStyle(
                                        Colors.green.shade500,
                                        fullWidth: true,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text('Regresar'),
                                      style: _topButtonStyle(
                                        Colors.teal.shade600,
                                        fullWidth: true,
                                      ),
                                    ),
                                  ],
                                )
                                : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _onAdd,
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Agregar Usuario'),
                                      style: _topButtonStyle(
                                        Colors.green.shade700,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _load,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Actualizar'),
                                      style: _topButtonStyle(
                                        Colors.green.shade500,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text('Regresar'),
                                      style: _topButtonStyle(
                                        Colors.teal.shade600,
                                      ),
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
                              list.isEmpty
                                  ? _tableCard(
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          "No hay usuarios registrados",
                                        ),
                                      ),
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    controller: _verticalController,
                                    child: SingleChildScrollView(
                                      controller: _horizontalController,
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        // ✅ minWidth ayuda en web móvil
                                        constraints: BoxConstraints(
                                          minWidth: isMobile ? 760 : 980,
                                        ),
                                        child: _tableCard(
                                          DataTable(
                                            columnSpacing: isMobile ? 18 : 30,
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                  Colors.black.withOpacity(
                                                    0.85,
                                                  ),
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
                                                              .withOpacity(
                                                                0.92,
                                                              ),
                                                ),
                                            columns: const [
                                              DataColumn(label: Text('ID')),
                                              DataColumn(label: Text('Nombre')),
                                              DataColumn(
                                                label: Text('Apellido'),
                                              ),
                                              DataColumn(label: Text('Email')),
                                              DataColumn(label: Text('DNI')),
                                              DataColumn(
                                                label: Text('Acciones'),
                                              ),
                                            ],
                                            rows:
                                                rows.map((u) {
                                                  final id = u.id ?? 0;

                                                  return DataRow(
                                                    cells: [
                                                      DataCell(
                                                        Text(
                                                          id > 0 ? '$id' : '-',
                                                        ),
                                                      ),
                                                      DataCell(Text(u.name)),
                                                      DataCell(
                                                        Text(u.lastName),
                                                      ),
                                                      DataCell(
                                                        SizedBox(
                                                          width:
                                                              isMobile
                                                                  ? 180
                                                                  : 260,
                                                          child: Text(
                                                            u.email ?? '-',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(u.dni ?? '-'),
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
                                                                  () => _onEdit(
                                                                    u,
                                                                  ),
                                                            ),
                                                            IconButton(
                                                              tooltip:
                                                                  "Eliminar",
                                                              icon: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      _onDelete(
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
