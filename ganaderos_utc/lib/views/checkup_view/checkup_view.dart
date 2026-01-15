import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/checkup_table.dart';
import 'checkup_form.dart';
import '../../models/checkup_models.dart';

class CheckupView extends StatefulWidget {
  const CheckupView({super.key});

  @override
  State<CheckupView> createState() => _CheckupViewState();
}

class _CheckupViewState extends State<CheckupView> {
  // 🔹 Clave global para refrescar la tabla después de CRUD
  final GlobalKey<CheckupTableState> _tableKey = GlobalKey<CheckupTableState>();

  /// 🔹 Abre el formulario modal para crear o editar un chequeo
  Future<void> _openCheckupForm({Checkup? checkup}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CheckupForm(
            checkup: checkup,
            onSave: () {
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      // Recarga la tabla al cerrar el formulario
      _tableKey.currentState?.loadCheckups();
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
                'Gestión de Chequeos',
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
                    child: CheckupTable(
                      key: _tableKey,
                      onEdit: (checkup) => _openCheckupForm(checkup: checkup),
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
