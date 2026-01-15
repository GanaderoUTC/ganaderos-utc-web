import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repositories/user_repository.dart';
import '../models/user_models.dart';
import '../views/user_view/user_form.dart';
import '../views/companies_view/companies_view.dart';

class UserTable extends StatefulWidget {
  final Future<void> Function(User user)? onEdit;

  const UserTable({super.key, this.onEdit});

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

      for (var u in data) {
        u.lastName = (u.lastName.isEmpty) ? "(Sin apellido)" : u.lastName;
      }

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
  void _addUser() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserForm(onSave: () => Navigator.pop(context, true)),
    );

    if (mounted && result == true) loadUsers();
  }

  /// Editar usuario
  void _editUser(User user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) =>
              UserForm(user: user, onSave: () => Navigator.pop(context, true)),
    );

    if (mounted && result == true) loadUsers();
  }

  /// Eliminar usuario
  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
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
    final end = (start + rowsPerPage).clamp(0, users.length);

    if (start >= users.length) return [];

    return users.sublist(start, end);
  }

  int get totalPages => users.isEmpty ? 1 : (users.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;
    setState(() => currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
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
              /// Barra superior
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Agregar Usuario"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6EDB44),
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: _addUser,
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Recargar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD2E735),
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: loadUsers,
                      ),
                    ],
                  ),

                  // 🔙 NUEVO BOTÓN: REGRESAR A EMPRESAS
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Regresar a Empresas"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade200,
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CompaniesView(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// Tabla
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
                        : _buildTable(constraints),
              ),

              const SizedBox(height: 12),
              _buildPagination(),
            ],
          ),
        );
      },
    );
  }

  /// Tabla de usuarios
  Widget _buildTable(BoxConstraints constraints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                  offset: Offset(0, 3),
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
              dataRowColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.selected)
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.white.withOpacity(0.9),
              ),
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
                    return DataRow(
                      cells: [
                        DataCell(Text(user.id?.toString() ?? "-")),
                        DataCell(Text(user.name)),
                        DataCell(Text(user.lastName)),
                        DataCell(Text(user.email ?? "N/A")),
                        DataCell(Text(user.dni ?? "N/A")),
                        DataCell(
                          Text(user.company?.companyName ?? "Sin empresa"),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editUser(user),
                                tooltip: "Editar usuario",
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  if (user.id != null) {
                                    _deleteUser(user.id!);
                                  }
                                },
                                tooltip: "Eliminar usuario",
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

  /// Paginación
  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        final page = i + 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  page == currentPage ? Colors.black87 : Colors.white,
              foregroundColor:
                  page == currentPage ? Colors.white : Colors.black,
            ),
            onPressed: () => goToPage(page),
            child: Text("$page"),
          ),
        );
      }),
    );
  }
}
