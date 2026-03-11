import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repositories/user_repository.dart';
import '../models/user_models.dart';
import '../views/user_view/user_form.dart';
import '../views/companies_view/companies_view.dart';

class UserTable extends StatefulWidget {
  final VoidCallback? onReload;
  final VoidCallback? onBack;

  const UserTable({super.key, this.onReload, this.onBack});

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

  Future<void> loadUsers() async {
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
      ).showSnackBar(SnackBar(content: Text('Error al cargar usuarios: $e')));
    }
  }

  Future<void> _addUser() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UserForm(),
    );

    if (mounted && result == true) {
      await loadUsers();
      widget.onReload?.call();
    }
  }

  Future<void> _editUser(User user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserForm(user: user),
    );

    if (mounted && result == true) {
      await loadUsers();
      widget.onReload?.call();
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Eliminar usuario'),
            content: const Text('¿Seguro que deseas eliminar este usuario?'),
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
          const SnackBar(content: Text('Usuario eliminado correctamente')),
        );
        await loadUsers();
        widget.onReload?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el usuario')),
        );
      }
    }
  }

  List<User> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    if (users.isEmpty || start >= users.length) return [];

    return users.sublist(start, end > users.length ? users.length : end);
  }

  int get totalPages => users.isEmpty ? 1 : (users.length / rowsPerPage).ceil();

  void goToPage(int page) => setState(() => currentPage = page);

  String _getCompanyText(User user) {
    final companyName = user.company?.companyName.trim() ?? '';

    if (companyName.isNotEmpty) {
      return companyName;
    } else if (user.companyId != null && user.companyId! > 0) {
      return 'Empresa #${user.companyId}';
    }

    return 'Sin empresa';
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
            label: const Text('Regresar a empresas'),
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
                    MaterialPageRoute(builder: (_) => const CompaniesView()),
                  );
                },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _addUser,
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
            onPressed: loadUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BoxConstraints constraints) {
    if (users.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text(
              'No hay registros de usuarios.',
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
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Apellido')),
                    DataColumn(label: Text('Correo')),
                    DataColumn(label: Text('Cédula')),
                    DataColumn(label: Text('Empresa')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows:
                      paginatedData.map((user) {
                        return DataRow(
                          cells: [
                            DataCell(Text(user.id?.toString() ?? '-')),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  user.name.trim().isNotEmpty ? user.name : '-',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  user.lastName.trim().isNotEmpty
                                      ? user.lastName
                                      : '-',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  (user.email ?? '').trim().isNotEmpty
                                      ? user.email!
                                      : '-',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                (user.dni ?? '').trim().isNotEmpty
                                    ? user.dni!
                                    : '-',
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  _getCompanyText(user),
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
                                      tooltip: 'Editar usuario',
                                      onPressed: () => _editUser(user),
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
                                      tooltip: 'Eliminar usuario',
                                      onPressed:
                                          user.id != null
                                              ? () => _deleteUser(user.id!)
                                              : null,
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
