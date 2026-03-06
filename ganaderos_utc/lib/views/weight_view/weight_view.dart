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
  final GlobalKey<WeightTableState> _tableKey = GlobalKey<WeightTableState>();

  Future<void> _openWeightForm({Weight? weight}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => WeightForm(
            weight: weight,
            onSave: () {
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      _tableKey.currentState?.loadWeights();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    // ✅ padding adaptativo
    final double pagePadding = isMobile ? 10 : 16;

    // ✅ altura appbar (si tu Navbar ya controla esto, ok)
    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      backgroundColor: const Color.fromARGB(155, 161, 207, 131),

      // ✅ En móvil es mejor tener botón flotante para “Agregar”
      floatingActionButton:
          isMobile
              ? FloatingActionButton.extended(
                onPressed: () => _openWeightForm(),
                icon: const Icon(Icons.add),
                label: const Text("Agregar"),
              )
              : null,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header responsive
              isMobile
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestión de Pesos del Ganado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // En móvil evitamos demasiados botones; queda el FAB
                      Text(
                        'Registra y controla el peso por fechas.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.65),
                        ),
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gestión de Pesos del Ganado',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openWeightForm(),
                        icon: const Icon(Icons.add),
                        label: const Text("Agregar"),
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

              const SizedBox(height: 12),

              // ✅ Card responsiva + tabla
              Expanded(
                child: Card(
                  elevation: isMobile ? 2 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 10 : 16),

                    // ✅ Esto ayuda si tu tabla NO tiene scroll horizontal interno
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                // En escritorio se expande al ancho disponible
                                minWidth: constraints.maxWidth,
                              ),
                              child: WeightTable(
                                key: _tableKey,
                                onEdit:
                                    (weight) => _openWeightForm(weight: weight),
                              ),
                            ),
                          ),
                        );
                      },
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
