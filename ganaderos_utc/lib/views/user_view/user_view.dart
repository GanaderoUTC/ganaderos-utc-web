import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/user_table.dart';
import '../../models/user_models.dart';
import '../user_view/user_form.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  // 🔹 Clave global para refrescar la tabla después de CRUD
  final GlobalKey<UserTableState> _tableKey = GlobalKey<UserTableState>();

  /// 🔹 Abre el formulario modal para crear o editar un usuario
  Future<void> _openUserForm({User? user}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => UserForm(
            user: user,
            onSave: () {
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      // Recarga la tabla al cerrar el formulario
      _tableKey.currentState?.loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      backgroundColor: const Color.fromARGB(155, 161, 207, 131),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Encabezado principal
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Contenedor principal con la tabla
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: UserTable(
                      key: _tableKey,
                      onEdit: (user) => _openUserForm(user: user),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Footer(),
            ],
          ),
        ),
      ),
    );
  }
}
