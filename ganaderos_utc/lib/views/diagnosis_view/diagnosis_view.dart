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
  final GlobalKey<DiagnosisTableState> _tableKey =
      GlobalKey<DiagnosisTableState>();

  Future<void> _openDiagnosisForm({dynamic diagnosis}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => DiagnosisForm(
            diagnosis: diagnosis,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true) {
      _tableKey.currentState?.loadDiagnosis();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      backgroundColor: const Color.fromARGB(155, 161, 207, 131),

      // ✅ Botón flotante para crear (perfecto en móvil web)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDiagnosisForm(diagnosis: null),
        icon: const Icon(Icons.add),
        label: Text(isMobile ? 'Nuevo' : 'Agregar Diagnóstico'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = isMobile ? 10.0 : 16.0;

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Header responsive (título + botón opcional en desktop)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Gestión de Diagnósticos',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      if (!isMobile)
                        ElevatedButton.icon(
                          onPressed: () => _openDiagnosisForm(diagnosis: null),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: isMobile ? 10 : 16),

                  Expanded(
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 10 : 16),
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
            );
          },
        ),
      ),
    );
  }
}
