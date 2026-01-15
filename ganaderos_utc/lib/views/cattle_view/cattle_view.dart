import 'package:flutter/material.dart';
import '../../models/cattle_models.dart';
import '../../repositories/cattle_repository.dart';
import '../../widgets/cattle_table.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import 'cattle_form.dart';

class CattleView extends StatefulWidget {
  const CattleView({super.key});

  @override
  State<CattleView> createState() => _CattleViewState();
}

class _CattleViewState extends State<CattleView> {
  List<Cattle> _cattleList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCattle();
  }

  Future<void> _fetchCattle() async {
    try {
      final data = await CattleRepository.getAll();
      if (!mounted) return;

      setState(() {
        _cattleList = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar ganado: $e")));
    }
  }

  Future<void> _goToCattleForm({Cattle? cattle}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CattleForm(
            cattle: cattle,
            onSave: () {
              if (!mounted) return;
              Navigator.of(context).pop(true);
            },
          ),
    );

    if (!mounted) return;
    if (result == true) {
      _fetchCattle();
    }
  }

  void _goToCattleTable() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CattleTable(
              onEdit: (item) async {
                await _goToCattleForm(cattle: item);
              },
              initialData: _cattleList,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: Navbar(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 25, 210, 155),
        icon: const Icon(Icons.add, color: Color.fromARGB(255, 51, 51, 51)),
        label: const Text(
          "Nuevo Ganado",
          style: TextStyle(color: Color.fromARGB(255, 83, 82, 82)),
        ),
        onPressed: () => _goToCattleForm(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo1.jpg'),
            fit: BoxFit.cover,
            opacity: 0.85,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child:
            _loading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Ganado Registrado",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 1, 97, 34),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _fetchCattle,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Actualizar"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  25,
                                  210,
                                  155,
                                ).withOpacity(0.9),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _goToCattleTable,
                              icon: const Icon(Icons.table_chart_outlined),
                              label: const Text("Ver Tabla"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  25,
                                  210,
                                  155,
                                ).withOpacity(0.9),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // GRID GANADO
                    Expanded(
                      child:
                          _cattleList.isEmpty
                              ? const Center(
                                child: Text(
                                  "No hay ganado registrado.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                              : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                itemCount: _cattleList.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 18,
                                      crossAxisSpacing: 18,
                                      childAspectRatio: 4 / 2.3,
                                    ),
                                itemBuilder: (context, index) {
                                  final cattle = _cattleList[index];
                                  return GestureDetector(
                                    onTap:
                                        () => _goToCattleForm(cattle: cattle),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          157,
                                          159,
                                          217,
                                          171,
                                        ).withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.15,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(3, 5),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.agriculture_rounded,
                                              size: 46,
                                              color: Colors.green.shade700,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              cattle.name,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Raza: ${cattle.breed?.name ?? cattle.breedId}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Código: ${cattle.code}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "© 2025 UTC GEN APP - Todos los derechos reservados",
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
