import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/breeds_table.dart';
import 'breed_form.dart';

class BreedsView extends StatefulWidget {
  const BreedsView({super.key});

  @override
  State<BreedsView> createState() => _BreedsViewState();
}

class _BreedsViewState extends State<BreedsView> {
  // Clave global para refrescar la tabla después de CRUD
  final GlobalKey<BreedsTableState> _tableKey = GlobalKey<BreedsTableState>();

  // Abre el formulario modal para editar una raza existente
  void _openBreedForm({dynamic breed}) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => BreedForm(
            breed: breed,
            onSave: () {
              Navigator.pop(context, true);
            },
          ),
    );

    if (result == true) {
      // Recarga la tabla al cerrar el formulario
      _tableKey.currentState?.loadBreeds();
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
              // Título principal sin botón de agregar
              const Text(
                'Gestión de Razas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(height: 16),

              // Contenedor principal con la tabla
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BreedsTable(
                      key: _tableKey,
                      onEdit: (breed) async => _openBreedForm(breed: breed),
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
