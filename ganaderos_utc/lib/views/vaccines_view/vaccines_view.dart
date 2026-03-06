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
  final GlobalKey<VaccineTableState> _tableKey = GlobalKey<VaccineTableState>();

  Future<void> _openVaccineForm({Vaccine? vaccine}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => VaccineForm(
            vaccine: vaccine,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true) {
      _tableKey.currentState?.loadVaccines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    final double padding = isMobile ? 12 : 18;
    final double titleSize = isMobile ? 18 : 22;

    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      backgroundColor: const Color.fromARGB(155, 161, 207, 131),

      // ✅ En móvil es MUY cómodo tener botón flotante
      floatingActionButton:
          isMobile
              ? FloatingActionButton.extended(
                onPressed: () => _openVaccineForm(),
                icon: const Icon(Icons.add),
                label: const Text("Agregar"),
              )
              : null,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header responsive: título + botón (solo desktop)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gestión de Vacunas',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),

                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openVaccineForm(),
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar Vacuna"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    // ✅ padding más pequeño en móvil para aprovechar espacio
                    padding: EdgeInsets.all(isMobile ? 10 : 16),
                    child: VaccineTable(
                      key: _tableKey,
                      onEdit: (v) => _openVaccineForm(vaccine: v),
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
