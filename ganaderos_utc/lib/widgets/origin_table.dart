import 'package:flutter/material.dart';
import '../models/origin_models.dart';
import '../repositories/origin_repository.dart';
import '../views/origin_view/origin_form.dart';

class OriginTable extends StatefulWidget {
  final VoidCallback? onReload;
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

  bool _isSynced(dynamic sync) {
    if (sync is bool) return sync;
    if (sync is int) return sync == 1;
    if (sync is String) return sync == '1' || sync.toLowerCase() == 'true';
    return false;
  }

  Future<void> loadOrigins() async {
    setState(() => isLoading = true);

    try {
      final data = await OriginRepository.getAll();
      if (!mounted) return;

      setState(() {
        originList = data;
        isLoading = false;
        currentPage = 1;
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

  Future<void> _addOrigin() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OriginForm(onSave: _emptyCallback),
    );

    if (ok == true) {
      await loadOrigins();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origen registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editOriginInternal(Origin origin) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OriginForm(origin: origin, onSave: _emptyCallback),
    );

    if (ok == true) {
      await loadOrigins();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origen actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  static void _emptyCallback() {}

  Future<void> _handleEdit(Origin origin) async {
    if (widget.onEdit != null) {
      await widget.onEdit!(origin);
      await loadOrigins();
    } else {
      await _editOriginInternal(origin);
    }
  }

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
            title: const Text('Eliminar origen'),
            content: const Text('¿Seguro que deseas eliminar este origen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
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

  List<Origin> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    return originList.sublist(
      start,
      end > originList.length ? originList.length : end,
    );
  }

  int get totalPages =>
      originList.isEmpty ? 1 : (originList.length / rowsPerPage).ceil();

  void goToPage(int page) => setState(() => currentPage = page);

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar origen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _addOrigin,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: loadOrigins,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BoxConstraints constraints) {
    if (originList.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text(
              'No hay registros de orígenes.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowHeight: 54,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 68,
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF1F2937),
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => Colors.white,
                  ),
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Descripción')),
                    DataColumn(label: Text('Sync')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows:
                      paginatedData.map((origin) {
                        final synced = _isSynced(origin.sync);

                        return DataRow(
                          cells: [
                            DataCell(Text(origin.id?.toString() ?? '-')),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  origin.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 250,
                                child: Text(
                                  origin.description,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  Icon(
                                    synced ? Icons.cloud_done : Icons.cloud_off,
                                    color: synced ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(synced ? 'Sí' : 'No'),
                                ],
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar origen',
                                      onPressed: () => _handleEdit(origin),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Eliminar origen',
                                      onPressed:
                                          () => _deleteOrigin(origin.id ?? 0),
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
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    final List<Widget> pageButtons = [];

    pageButtons.add(
      OutlinedButton(
        onPressed: currentPage > 1 ? () => goToPage(currentPage - 1) : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade400),
        ),
        child: const Text('Anterior'),
      ),
    );

    for (int i = 1; i <= totalPages; i++) {
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  i == currentPage ? const Color(0xFF1F2937) : Colors.white,
              foregroundColor: i == currentPage ? Colors.white : Colors.black87,
              side: BorderSide(color: Colors.grey.shade400),
            ),
            onPressed: () => goToPage(i),
            child: Text('$i'),
          ),
        ),
      );
    }

    pageButtons.add(
      OutlinedButton(
        onPressed:
            currentPage < totalPages ? () => goToPage(currentPage + 1) : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade400),
        ),
        child: const Text('Siguiente'),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pageButtons,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondo1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActionBar(),
              const SizedBox(height: 16),
              _buildTable(constraints),
              const SizedBox(height: 10),
              _buildPagination(),
            ],
          ),
        );
      },
    );
  }
}
