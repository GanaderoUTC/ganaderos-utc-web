import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/origin_table.dart';
import 'origin_form.dart';
import '../../models/origin_models.dart';

class OriginView extends StatefulWidget {
  const OriginView({super.key});

  @override
  State<OriginView> createState() => _OriginViewState();
}

class _OriginViewState extends State<OriginView> {
  // 🔹 Clave global para refrescar la tabla después de CRUD
  final GlobalKey<OriginTableState> _tableKey = GlobalKey<OriginTableState>();

  /// 🔹 Abre el formulario modal para crear o editar un origen
  void _openOriginForm({Origin? origin}) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => OriginForm(
            origin: origin,
            onSave: () {
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      // Recarga la tabla al cerrar el formulario
      _tableKey.currentState?.loadOrigins();
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
              // 🔹 Título principal
              const Text(
                'Gestión de Orígenes',
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
                    child: OriginTable(
                      key: _tableKey,
                      onEdit: (origin) async => _openOriginForm(origin: origin),
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
