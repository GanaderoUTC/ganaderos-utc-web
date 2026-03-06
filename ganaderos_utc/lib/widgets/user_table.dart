import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repositories/user_repository.dart';
import '../models/user_models.dart';
import '../views/user_view/user_form.dart';
import '../views/companies_view/companies_view.dart';

class UserTable extends StatefulWidget {
  const UserTable({super.key});

  @override
  UserTableState createState() => UserTableState();
}

class UserTableState extends State<UserTable> {
  final UserRepository repository = UserRepository();
  List<User> users = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  /// Cargar lista de usuarios
  Future<void> loadUsers() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await UserRepository.getAll();
      if (!mounted) return;

      setState(() {
        users = data;
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

  /// Agregar usuario
  Future<void> _addUser() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UserForm(),
    );

    if (mounted && result == true) {
      await loadUsers();
    }
  }

  /// Editar usuario
  Future<void> _editUser(User user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserForm(user: user),
    );

    if (mounted && result == true) {
      await loadUsers();
    }
  }

  /// Eliminar usuario
  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text("Eliminar usuario"),
            content: const Text("¿Seguro que deseas eliminar este usuario?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Eliminar"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await repository.delete(id);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario eliminado correctamente")),
        );
        await loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo eliminar el usuario")),
        );
      }
    }
  }

  /// Paginación segura
  List<User> get paginatedData {
    if (users.isEmpty) return [];
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= users.length) return [];
    final end = (start + rowsPerPage).clamp(0, users.length);
    return users.sublist(start, end);
  }

  int get totalPages => users.isEmpty ? 1 : (users.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;
    if (page < 1 || page > totalPages) return;
    setState(() => currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 700;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
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
              /// ✅ Barra superior responsive (móvil: botones full width)
              if (isMobile) ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar Usuario"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6EDB44),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _addUser,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Recargar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2E735),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: loadUsers,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Regresar a Empresas"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CompaniesView(),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Agregar Usuario"),
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
                          onPressed: _addUser,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Recargar"),
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
                          onPressed: loadUsers,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Regresar a Empresas"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CompaniesView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              /// ✅ Tabla responsive
              Expanded(
                child:
                    users.isEmpty
                        ? const Center(
                          child: Text(
                            "No hay registros de usuarios.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        )
                        : _buildTable(constraints, isMobile),
              ),

              const SizedBox(height: 10),
              _buildPagination(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(BoxConstraints constraints, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
              dataRowMinHeight: isMobile ? 48 : 56,
              dataRowMaxHeight: isMobile ? 76 : 86,
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Nombre")),
                DataColumn(label: Text("Apellido")),
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("DNI")),
                DataColumn(label: Text("Empresa")),
                DataColumn(label: Text("Acciones")),
              ],
              rows:
                  paginatedData.map((user) {
                    final empresaTexto =
                        user.company?.companyName ??
                        (user.companyId != null
                            ? "Empresa #${user.companyId}"
                            : "Sin empresa");

                    return DataRow(
                      cells: [
                        DataCell(Text(user.id?.toString() ?? "-")),
                        DataCell(
                          SizedBox(
                            width: isMobile ? 140 : 180,
                            child: Text(
                              user.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: isMobile ? 140 : 180,
                            child: Text(
                              user.lastName.isEmpty
                                  ? "(Sin apellido)"
                                  : user.lastName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: isMobile ? 190 : 260,
                            child: Text(
                              user.email ?? "N/A",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        DataCell(Text(user.dni ?? "N/A")),
                        DataCell(
                          SizedBox(
                            width: isMobile ? 160 : 240,
                            child: Text(
                              empresaTexto,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),

                        /// ✅ Acciones: en móvil => menú ⋮, en desktop => iconos
                        DataCell(
                          isMobile
                              ? PopupMenuButton<String>(
                                tooltip: "Acciones",
                                onSelected: (v) async {
                                  if (v == "edit") await _editUser(user);
                                  if (v == "delete" && user.id != null) {
                                    await _deleteUser(user.id!);
                                  }
                                },
                                itemBuilder:
                                    (_) => [
                                      const PopupMenuItem(
                                        value: "edit",
                                        child: Text("Editar"),
                                      ),
                                      PopupMenuItem(
                                        value: "delete",
                                        enabled: user.id != null,
                                        child: const Text("Eliminar"),
                                      ),
                                    ],
                                child: const Icon(Icons.more_vert),
                              )
                              : Row(
                                children: [
                                  IconButton(
                                    tooltip: "Editar",
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _editUser(user),
                                  ),
                                  IconButton(
                                    tooltip: "Eliminar",
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        user.id != null
                                            ? () => _deleteUser(user.id!)
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
    );
  }

  /// ✅ Paginación responsive (móvil muestra menos botones)
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
            child: const Text("Anterior"),
          ),
          const SizedBox(width: 8),
          ...pagesToShow.map((p) {
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
                child: Text("$p"),
              ),
            );
          }),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed:
                currentPage < totalPages
                    ? () => goToPage(currentPage + 1)
                    : null,
            child: const Text("Siguiente"),
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
