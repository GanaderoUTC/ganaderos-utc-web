import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/vaccines_table.dart';
import 'vaccine_form.dart';
import '../../models/vaccine_models.dart';

class VaccineView extends StatefulWidget {
  const VaccineView({super.key});

  @override
  State<VaccineView> createState() => _VaccineViewState();
}

class _VaccineViewState extends State<VaccineView> {
  // 🔹 Clave global para refrescar la tabla después de CRUD
  final GlobalKey<VaccineTableState> _tableKey = GlobalKey<VaccineTableState>();

  /// 🔹 Abre el formulario modal para crear o editar una vacuna
  Future<void> _openVaccineForm({Vaccine? vaccine}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => VaccineForm(
            vaccine: vaccine,
            onSave: () {
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      // Recarga la tabla al cerrar el formulario
      _tableKey.currentState?.loadVaccines();
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
                'Gestión de Vacunas',
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
                    child: VaccineTable(
                      key: _tableKey,
                      onEdit: (vaccine) => _openVaccineForm(vaccine: vaccine),
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
