import 'package:flutter/material.dart';
import '../models/origin_models.dart';
import '../repositories/origin_repository.dart';
import '../views/origin_view/origin_form.dart';

class OriginTable extends StatefulWidget {
  final VoidCallback? onReload;

  /// ✅ Opcional: si el padre quiere controlar la edición.
  final Future<void> Function(Origin origin)? onEdit;

  const OriginTable({super.key, this.onReload, this.onEdit});

  @override
  OriginTableState createState() => OriginTableState();
}

class OriginTableState extends State<OriginTable> {
  final OriginRepository repository = OriginRepository();

  List<Origin> originList = [];
  bool isLoading = true;

  int currentPage = 1;
  final int rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    loadOrigins();
  }

  /// ✅ helper: soporta sync bool o int (0/1) o string
  bool _isSynced(dynamic sync) {
    if (sync is bool) return sync;
    if (sync is int) return sync == 1;
    if (sync is String) return sync == '1' || sync.toLowerCase() == 'true';
    return false;
  }

  /// 🔹 Cargar todos los orígenes
  Future<void> loadOrigins() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await OriginRepository.getAll();
      if (!mounted) return;

      setState(() {
        originList = data;
        isLoading = false;

        // ✅ si quedó fuera de rango por eliminaciones, ajusta página
        final maxPages =
            originList.isEmpty ? 1 : (originList.length / rowsPerPage).ceil();
        if (currentPage > maxPages) currentPage = maxPages;
        if (currentPage < 1) currentPage = 1;
      });

      widget.onReload?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar orígenes: $e')));
    }
  }

  /// 🔹 Crear nuevo origen
  void _addOrigin() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OriginForm(onSave: () => Navigator.pop(context, true)),
    ).then((ok) async {
      if (ok == true) await loadOrigins();
    });
  }

  /// 🔹 Editar origen (interno)
  Future<void> _editOriginInternal(Origin origin) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => OriginForm(
            origin: origin,
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (ok == true) await loadOrigins();
  }

  /// ✅ Si hay onEdit externo, úsalo
  Future<void> _handleEdit(Origin origin) async {
    if (widget.onEdit != null) {
      await widget.onEdit!(origin);
      await loadOrigins();
    } else {
      await _editOriginInternal(origin);
    }
  }

  /// 🔹 Eliminar origen con confirmación
  Future<void> _deleteOrigin(int id) async {
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID inválido para eliminar')),
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
            title: const Text('Eliminar Origen'),
            content: const Text('¿Seguro que deseas eliminar este origen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await repository.deleteOrigin(id);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Origen eliminado correctamente')),
        );
        await loadOrigins();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el origen')),
        );
      }
    }
  }

  /// 🔹 Datos paginados (✅ protegido para evitar RangeError)
  List<Origin> get paginatedData {
    if (originList.isEmpty) return [];

    final start = (currentPage - 1) * rowsPerPage;
    if (start >= originList.length) return [];

    final end = start + rowsPerPage;
    return originList.sublist(
      start,
      end > originList.length ? originList.length : end,
    );
  }

  int get totalPages =>
      originList.isEmpty ? 1 : (originList.length / rowsPerPage).ceil();

  void goToPage(int page) {
    if (!mounted) return;
    if (page < 1 || page > totalPages) return;
    setState(() => currentPage = page);
  }

  List<int> _pagesWindow({
    required int current,
    required int total,
    required int maxButtons,
  }) {
    if (total <= maxButtons) return List.generate(total, (i) => i + 1);

    final half = maxButtons ~/ 2;
    int start = current - half;
    int end = current + half;

    if (start < 1) {
      start = 1;
      end = maxButtons;
    }
    if (end > total) {
      end = total;
      start = total - maxButtons + 1;
    }
    return [for (int i = start; i <= end; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 700;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
          width: constraints.maxWidth,
          // ✅ NO height fijo: mejor para web móvil
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondo1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// ✅ Barra de acciones responsive
              if (isMobile) ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Origen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 96, 227, 2),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _addOrigin,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(136, 110, 223, 5),
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: loadOrigins,
                  ),
                ),
              ] else ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Origen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 96, 227, 2),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: _addOrigin,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recargar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(136, 110, 223, 5),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: loadOrigins,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              /// 🔹 Tabla principal
              Expanded(
                child:
                    originList.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay orígenes registrados.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.88),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: DataTable(
                                  columnSpacing: isMobile ? 18 : 40,
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.black.withOpacity(0.85),
                                  ),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  dataRowMinHeight: isMobile ? 48 : 56,
                                  dataRowMaxHeight: isMobile ? 72 : 86,
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Descripción')),
                                    DataColumn(label: Text('Sync')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows:
                                      paginatedData.map((origin) {
                                        final id = origin.id ?? 0;
                                        final synced = _isSynced(origin.sync);

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(id > 0 ? '$id' : '-'),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: isMobile ? 180 : 220,
                                                child: Text(
                                                  origin.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: isMobile ? 220 : 420,
                                                child: Text(
                                                  origin.description,
                                                  maxLines: isMobile ? 2 : 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Icon(
                                                synced
                                                    ? Icons.cloud_done
                                                    : Icons.cloud_off,
                                                color:
                                                    synced
                                                        ? Colors.green
                                                        : Colors.grey,
                                              ),
                                            ),
                                            DataCell(
                                              isMobile
                                                  ? PopupMenuButton<String>(
                                                    tooltip: 'Acciones',
                                                    onSelected: (v) {
                                                      if (v == 'edit') {
                                                        _handleEdit(origin);
                                                      }
                                                      if (v == 'delete') {
                                                        _deleteOrigin(id);
                                                      }
                                                    },
                                                    itemBuilder:
                                                        (_) => const [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Text(
                                                              'Editar',
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Text(
                                                              'Eliminar',
                                                            ),
                                                          ),
                                                        ],
                                                    child: const Icon(
                                                      Icons.more_vert,
                                                    ),
                                                  )
                                                  : Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.blue,
                                                        ),
                                                        tooltip:
                                                            'Editar origen',
                                                        onPressed:
                                                            () => _handleEdit(
                                                              origin,
                                                            ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        tooltip:
                                                            'Eliminar origen',
                                                        onPressed:
                                                            () => _deleteOrigin(
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

              const SizedBox(height: 10),
              _buildPagination(isMobile),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Paginación con ventana (mejor en móvil web)
  Widget _buildPagination(bool isMobile) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pagesToShow = _pagesWindow(
      current: currentPage,
      total: totalPages,
      maxButtons: isMobile ? 5 : 10,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: currentPage > 1 ? () => goToPage(currentPage - 1) : null,
            child: const Text('Anterior'),
          ),
          const SizedBox(width: 8),
          ...pagesToShow.map((p) {
            final selected = p == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selected ? Colors.black87 : Colors.white.withOpacity(0.7),
                  foregroundColor: selected ? Colors.white : Colors.black,
                  side: const BorderSide(color: Colors.black54),
                ),
                onPressed: () => goToPage(p),
                child: Text('$p'),
              ),
            );
          }),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed:
                currentPage < totalPages
                    ? () => goToPage(currentPage + 1)
                    : null,
            child: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}
