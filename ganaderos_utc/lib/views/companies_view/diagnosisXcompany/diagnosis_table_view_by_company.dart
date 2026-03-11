// ignore_for_file: file_names
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ganaderos_utc/models/diagnosis_models.dart';
import 'package:ganaderos_utc/repositories/diagnosis_repository.dart';
import 'package:ganaderos_utc/views/diagnosis_view/diagnosis_form.dart';
import 'package:ganaderos_utc/widgets/footer.dart';

class DiagnosisTableViewByCompany extends StatefulWidget {
  final String companyName;

  const DiagnosisTableViewByCompany({super.key, required this.companyName});

  @override
  State<DiagnosisTableViewByCompany> createState() =>
      _DiagnosisTableViewByCompanyState();
}

class _DiagnosisTableViewByCompanyState
    extends State<DiagnosisTableViewByCompany> {
  bool isLoading = true;
  List<Diagnosis> list = [];

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  int currentPage = 1;

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

  int _rowsPerPage(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w < 600) ? 5 : 10;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await DiagnosisRepository.getAll();
      if (!mounted) return;

      setState(() {
        list = data;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar diagnósticos: $e")),
      );
    }
  }

  Future<void> _onAdd() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DiagnosisForm(onSave: () => Navigator.pop(context, true)),
    );

    if (result == true && mounted) await _load();
  }

  Future<void> _onEdit(Diagnosis diagnosis) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => DiagnosisForm(
            diagnosis: diagnosis,
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
            content: const Text("¿Deseas eliminar este diagnóstico?"),
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
      final ok = await DiagnosisRepository.deleteDiagnosis(id);
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

  List<Diagnosis> _paginatedData(BuildContext context) {
    final rowsPerPage = _rowsPerPage(context);

    if (list.isEmpty) return [];
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= list.length) return [];
    final end = start + rowsPerPage;
    return list.sublist(start, end > list.length ? list.length : end);
  }

  int _totalPages(BuildContext context) {
    final rowsPerPage = _rowsPerPage(context);
    return list.isEmpty ? 1 : (list.length / rowsPerPage).ceil();
  }

  void goToPage(int page) => setState(() => currentPage = page);

  bool _isSynced(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is num) return v.toInt() == 1;
    return false;
  }

  ButtonStyle _topButtonStyle(Color bg, {bool fullWidth = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      minimumSize: fullWidth ? const Size.fromHeight(44) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
    );
  }

  Widget _tableCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final rows = _paginatedData(context);
    final totalPages = _totalPages(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Diagnósticos - ${widget.companyName}"),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_general_2.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.28)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Diagnóstico'),
                      style: _topButtonStyle(Colors.green.shade700),
                    ),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                      style: _topButtonStyle(Colors.green.shade500),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Regresar'),
                      style: _topButtonStyle(Colors.teal.shade600),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : list.isEmpty
                            ? _tableCard(
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    "No hay diagnósticos registrados",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E2A35),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            : LayoutBuilder(
                              builder: (context, constraints) {
                                final minTableWidth = isMobile ? 700.0 : 900.0;
                                final descWidth = isMobile ? 240.0 : 360.0;

                                return _tableCard(
                                  Column(
                                    children: [
                                      Expanded(
                                        child: Scrollbar(
                                          controller: _verticalController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller: _verticalController,
                                            child: Scrollbar(
                                              controller: _horizontalController,
                                              thumbVisibility: true,
                                              notificationPredicate:
                                                  (notification) =>
                                                      notification.depth == 1,
                                              child: SingleChildScrollView(
                                                controller:
                                                    _horizontalController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    minWidth: minTableWidth,
                                                  ),
                                                  child: DataTable(
                                                    columnSpacing:
                                                        isMobile ? 18 : 26,
                                                    dataRowMinHeight:
                                                        isMobile ? 52 : 58,
                                                    dataRowMaxHeight:
                                                        isMobile ? 74 : 86,
                                                    headingRowHeight: 52,
                                                    headingRowColor:
                                                        WidgetStateProperty.all(
                                                          Colors.black
                                                              .withOpacity(0.9),
                                                        ),
                                                    headingTextStyle:
                                                        const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                    dataRowColor:
                                                        WidgetStateProperty.resolveWith((
                                                          states,
                                                        ) {
                                                          return states.contains(
                                                                WidgetState
                                                                    .hovered,
                                                              )
                                                              ? const Color(
                                                                0xFFEAF2F8,
                                                              ).withOpacity(
                                                                0.92,
                                                              )
                                                              : Colors.white
                                                                  .withOpacity(
                                                                    0.92,
                                                                  );
                                                        }),
                                                    dividerThickness: 0.7,
                                                    border: TableBorder(
                                                      horizontalInside:
                                                          BorderSide(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                  0.18,
                                                                ),
                                                          ),
                                                    ),
                                                    columns: const [
                                                      DataColumn(
                                                        label: Text('ID'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Nombre'),
                                                      ),
                                                      DataColumn(
                                                        label: Text(
                                                          'Descripción',
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Sync'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Acciones'),
                                                      ),
                                                    ],
                                                    rows:
                                                        rows.map((it) {
                                                          final synced =
                                                              _isSynced(
                                                                it.sync,
                                                              );
                                                          return DataRow(
                                                            cells: [
                                                              DataCell(
                                                                Text(
                                                                  '${it.id ?? '-'}',
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width:
                                                                      isMobile
                                                                          ? 160
                                                                          : 220,
                                                                  child: Text(
                                                                    it.name,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width:
                                                                      descWidth,
                                                                  child: Tooltip(
                                                                    message:
                                                                        it.description,
                                                                    child: Text(
                                                                      it.description,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      maxLines:
                                                                          isMobile
                                                                              ? 2
                                                                              : 3,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Tooltip(
                                                                  message:
                                                                      synced
                                                                          ? "Sincronizado"
                                                                          : "No sincronizado",
                                                                  child: Icon(
                                                                    synced
                                                                        ? Icons
                                                                            .cloud_done
                                                                        : Icons
                                                                            .cloud_off,
                                                                    color:
                                                                        synced
                                                                            ? Colors.green
                                                                            : Colors.grey,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    IconButton(
                                                                      tooltip:
                                                                          "Editar",
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .edit,
                                                                        color:
                                                                            Colors.blue,
                                                                      ),
                                                                      onPressed:
                                                                          () => _onEdit(
                                                                            it,
                                                                          ),
                                                                    ),
                                                                    IconButton(
                                                                      tooltip:
                                                                          "Eliminar",
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color:
                                                                            Colors.red,
                                                                      ),
                                                                      onPressed:
                                                                          () => _onDelete(
                                                                            it.id ??
                                                                                0,
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
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ),

                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(totalPages, (index) {
                          final page = index + 1;
                          final selected = page == currentPage;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              onPressed: () => goToPage(page),
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    selected
                                        ? Colors.black.withOpacity(0.85)
                                        : Colors.white.withOpacity(0.75),
                                foregroundColor:
                                    selected ? Colors.white : Colors.black,
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
        ],
      ),
    );
  }
}
