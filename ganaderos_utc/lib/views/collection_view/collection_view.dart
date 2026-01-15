import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/collection_table.dart';

class CollectionView extends StatefulWidget {
  const CollectionView({super.key});

  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {
  // 🔹 Clave global para refrescar la tabla después de CRUD
  final GlobalKey<CollectionTableState> _tableKey =
      GlobalKey<CollectionTableState>();

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
                'Gestión de Recolección de Leche',
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
                    child: CollectionTable(
                      key: _tableKey,
                      onReload: () => _tableKey.currentState?.loadCollections(),
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
