import 'package:flutter/material.dart';
import '../../models/origin_models.dart';
import '../../repositories/origin_repository.dart';

class OriginForm extends StatefulWidget {
  final Origin? origin;
  final VoidCallback onSave;

  const OriginForm({super.key, this.origin, required this.onSave});

  @override
  State<OriginForm> createState() => _OriginFormState();
}

class _OriginFormState extends State<OriginForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _sync = false;
  bool _saving = false;

  final _repository = OriginRepository();

  @override
  void initState() {
    super.initState();
    if (widget.origin != null) {
      _nameController.text = _capitalizeFirst(widget.origin!.name);
      _descriptionController.text = _capitalizeFirst(
        widget.origin!.description,
      );
      _sync = widget.origin!.sync;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _normalizeForCompare(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String? _validateName(String? value) {
    if (value == null) return 'El nombre es obligatorio';
    final s = value.trim();

    if (s.isEmpty) return 'El nombre es obligatorio';
    if (s.length < 2) return 'Nombre muy corto';
    if (s.length > 60) return 'Nombre muy largo (máx. 60)';

    final ok = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 '._-]{2,60}$").hasMatch(s);
    if (!ok) return 'Nombre inválido';

    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null) return null;
    final s = value.trim();

    if (s.isEmpty) return null;
    if (s.length > 250) return 'Descripción muy larga (máx. 250)';

    return null;
  }

  Future<bool> _isDuplicateName(String name) async {
    final origins = await OriginRepository.getAll();
    final newName = _normalizeForCompare(name);

    for (final origin in origins) {
      final sameId =
          widget.origin?.id != null && origin.id == widget.origin!.id;
      if (sameId) continue;

      if (_normalizeForCompare(origin.name) == newName) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isDuplicateDescription(String description) async {
    if (description.trim().isEmpty) return false;

    final origins = await OriginRepository.getAll();
    final newDescription = _normalizeForCompare(description);

    for (final origin in origins) {
      final sameId =
          widget.origin?.id != null && origin.id == widget.origin!.id;
      if (sameId) continue;

      if (_normalizeForCompare(origin.description) == newDescription) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveForm() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final formattedName = _capitalizeFirst(_nameController.text);
      final formattedDescription = _capitalizeFirst(
        _descriptionController.text,
      );

      final existsName = await _isDuplicateName(formattedName);
      if (existsName) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe un origen con ese nombre'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _saving = false);
        return;
      }

      final existsDescription = await _isDuplicateDescription(
        formattedDescription,
      );
      if (existsDescription) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe un origen con esa descripción'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _saving = false);
        return;
      }

      final newOrigin = Origin(
        id: widget.origin?.id,
        name: formattedName,
        description: formattedDescription,
        sync: _sync,
      );

      bool ok = false;

      if (widget.origin == null) {
        final response = await _repository.insertOrigin(newOrigin);
        ok = response != null;
      } else {
        ok = await _repository.updateOrigin(newOrigin);
      }

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.origin == null
                  ? 'No se pudo registrar el origen'
                  : 'No se pudo actualizar el origen',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        setState(() => _saving = false);
        return;
      }

      /// Cerramos el diálogo devolviendo true
      Navigator.of(context).pop(true);

      /// Refrescamos la tabla/lista en la vista padre
      widget.onSave();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.origin != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(16),
          title: Text(
            isEditing ? 'Editar Origen' : 'Agregar Nuevo Origen',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 420,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del origen',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                      validator: _validateDescription,
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sincronizado'),
                      value: _sync,
                      onChanged:
                          _saving
                              ? null
                              : (value) {
                                setState(() => _sync = value ?? false);
                              },
                      activeColor: Colors.green.shade700,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveForm,
              icon:
                  _saving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _saving
                    ? 'Guardando...'
                    : (isEditing ? 'Actualizar' : 'Guardar'),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
