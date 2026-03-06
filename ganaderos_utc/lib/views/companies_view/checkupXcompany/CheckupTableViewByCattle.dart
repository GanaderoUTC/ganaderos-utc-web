// ignore_for_file: file_names
import 'package:flutter/material.dart';
import '../../../models/checkup_models.dart';
import '../../../repository/checkup_cattle_repository.dart';
import '../../../repository/checkup_cattle_form.dart';
import '../../../widgets/footer.dart';

class CheckupTableViewByCattle extends StatefulWidget {
  final int cattleId;
  final String cattleName;

  const CheckupTableViewByCattle({
    super.key,
    required this.cattleId,
    required this.cattleName,
  });

  @override
  State<CheckupTableViewByCattle> createState() =>
      _CheckupTableViewByCattleState();
}

class _CheckupTableViewByCattleState extends State<CheckupTableViewByCattle> {
  bool isLoading = true;
  List<Checkup> list = [];

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  int currentPage = 1;
  final int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await CheckupCattleRepository.getAllByCattle(
        widget.cattleId,
      );
      if (!mounted) return;

      setState(() {
        list = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar chequeos: $e")));
    }
  }

  Future<void> _onAdd() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CheckupCattleForm(
            cattleId: widget.cattleId,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) await _load();
  }

  Future<void> _onEdit(Checkup checkup) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CheckupCattleForm(
            checkup: checkup,
            cattleId: widget.cattleId,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) await _load();
  }

  Future<void> _onDelete(int id) async {
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID inválido para eliminar.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text("Eliminar"),
            content: const Text("¿Deseas eliminar este chequeo?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Eliminar"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final ok = await CheckupCattleRepository.deleteForCattle(id);
      if (!mounted) return;

      if (ok) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Eliminado correctamente")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No se pudo eliminar")));
      }
    }
  }

  List<Checkup> get paginatedData {
    if (list.isEmpty) return [];
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= list.length) return [];
    final end = start + rowsPerPage;
    return list.sublist(start, end > list.length ? list.length : end);
    // (si quieres paginar también en móvil, se reutiliza)
  }

  int get totalPages => list.isEmpty ? 1 : (list.length / rowsPerPage).ceil();
  void goToPage(int page) => setState(() => currentPage = page);

  ButtonStyle _topButtonStyle(Color bg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
    );
  }

  Widget _tableCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  String _safeObs(Checkup it) {
    final s = (it.observation).trim();
    return s.isEmpty ? '-' : s;
  }

  // ✅ Card para móvil
  Widget _checkupCard(Checkup it) {
    final id = it.id ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Chequeo #${id > 0 ? id : '-'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Editar",
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _onEdit(it),
                ),
                IconButton(
                  tooltip: "Eliminar",
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _onDelete(id),
                ),
              ],
            ),
            const SizedBox(height: 6),

            _kv("Fecha", it.date),
            _kv("Síntoma", it.symptom),
            _kv("Diagnóstico", it.diagnosis),
            _kv("Tratamiento", it.treatment),
            _kv("Observación", _safeObs(it)),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: "$k: ",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // ✅ si quieres, cambia el umbral
    final bool isMobile = width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chequeos - ${widget.cattleName}"),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_general_2.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.06),
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: [
                            SizedBox(
                              width: isMobile ? double.infinity : null,
                              child: ElevatedButton.icon(
                                onPressed: _onAdd,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar Chequeo'),
                                style: _topButtonStyle(Colors.green.shade700),
                              ),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : null,
                              child: ElevatedButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualizar'),
                                style: _topButtonStyle(Colors.green.shade500),
                              ),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : null,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Regresar'),
                                style: _topButtonStyle(Colors.teal.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child:
                              list.isEmpty
                                  ? _tableCard(
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          "No hay chequeos registrados",
                                        ),
                                      ),
                                    ),
                                  )
                                  : isMobile
                                  // ✅ MÓVIL: cards
                                  ? ListView.builder(
                                    itemCount: paginatedData.length,
                                    itemBuilder:
                                        (_, i) =>
                                            _checkupCard(paginatedData[i]),
                                  )
                                  // ✅ DESKTOP/TABLET: tabla original
                                  : SingleChildScrollView(
                                    controller: _verticalController,
                                    child: SingleChildScrollView(
                                      controller: _horizontalController,
                                      scrollDirection: Axis.horizontal,
                                      child: _tableCard(
                                        DataTable(
                                          columnSpacing: 30,
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                Colors.black.withOpacity(0.85),
                                              ),
                                          headingTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          dataRowColor:
                                              WidgetStateProperty.resolveWith(
                                                (states) =>
                                                    states.contains(
                                                          WidgetState.hovered,
                                                        )
                                                        ? Colors.grey
                                                            .withOpacity(0.15)
                                                        : Colors.white
                                                            .withOpacity(0.92),
                                              ),
                                          columns: const [
                                            DataColumn(label: Text('ID')),
                                            DataColumn(label: Text('Fecha')),
                                            DataColumn(label: Text('Síntoma')),
                                            DataColumn(
                                              label: Text('Diagnóstico'),
                                            ),
                                            DataColumn(
                                              label: Text('Tratamiento'),
                                            ),
                                            DataColumn(
                                              label: Text('Observación'),
                                            ),
                                            DataColumn(label: Text('Acciones')),
                                          ],
                                          rows:
                                              paginatedData.map((it) {
                                                final id = it.id ?? 0;

                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        id > 0 ? '$id' : '-',
                                                      ),
                                                    ),
                                                    DataCell(Text(it.date)),
                                                    DataCell(Text(it.symptom)),
                                                    DataCell(
                                                      Text(it.diagnosis),
                                                    ),
                                                    DataCell(
                                                      Text(it.treatment),
                                                    ),
                                                    // ✅ FIX real: observation null-safe
                                                    DataCell(
                                                      Text(_safeObs(it)),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            tooltip: "Editar",
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    _onEdit(it),
                                                          ),
                                                          IconButton(
                                                            tooltip: "Eliminar",
                                                            icon: const Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                            ),
                                                            onPressed:
                                                                () => _onDelete(
                                                                  id,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                        ),
                      ),

                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(totalPages, (index) {
                                final page = index + 1;
                                final selected = page == currentPage;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () => goToPage(page),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          selected
                                              ? Colors.black.withOpacity(0.85)
                                              : Colors.white.withOpacity(0.75),
                                      foregroundColor:
                                          selected
                                              ? Colors.white
                                              : Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('$page'),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                      const Footer(),
                    ],
                  ),
        ),
      ),
    );
  }
}
