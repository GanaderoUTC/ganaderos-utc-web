import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/diagnosis_table.dart';
import 'diagnosis_form.dart';

class DiagnosisView extends StatefulWidget {
  const DiagnosisView({super.key});

  @override
  State<DiagnosisView> createState() => _DiagnosisViewState();
}

class _DiagnosisViewState extends State<DiagnosisView> {
  // 🔹 Clave global para refrescar la tabla después de CRUD
  final GlobalKey<DiagnosisTableState> _tableKey =
      GlobalKey<DiagnosisTableState>();

  /// 🔹 Abre el formulario modal para editar o crear un diagnóstico
  void _openDiagnosisForm({dynamic diagnosis}) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => DiagnosisForm(
            diagnosis: diagnosis,
            onSave: () {
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      // Recarga la tabla al cerrar el formulario
      _tableKey.currentState?.loadDiagnosis();
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
              // 🔹 Título principal sin botón de agregar
              const Text(
                'Gestión de Diagnósticos',
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
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DiagnosisTable(
                      key: _tableKey,
                      onEdit:
                          (diagnosis) async =>
                              _openDiagnosisForm(diagnosis: diagnosis),
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
