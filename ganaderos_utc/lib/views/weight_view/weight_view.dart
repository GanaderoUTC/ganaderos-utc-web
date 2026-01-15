import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/weight_table.dart';
import 'weight_form.dart';
import '../../models/weight_models.dart';

class WeightView extends StatefulWidget {
  const WeightView({super.key});

  @override
  State<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
  // 🔹 Clave global para refrescar la tabla después de CRUD
  final GlobalKey<WeightTableState> _tableKey = GlobalKey<WeightTableState>();

  /// 🔹 Abre el formulario modal para crear o editar un registro de peso
  Future<void> _openWeightForm({Weight? weight}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => WeightForm(
            weight: weight,
            onSave: () {
              // Cierra el formulario indicando que hubo cambios
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      // 🔹 Recarga la tabla al cerrar el formulario
      _tableKey.currentState?.loadWeights();
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
                'Gestión de Pesos del Ganado',
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
                    child: WeightTable(
                      key: _tableKey,
                      onEdit: (weight) => _openWeightForm(weight: weight),
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
