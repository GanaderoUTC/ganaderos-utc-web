import 'package:flutter/material.dart';
import '../../models/breed_models.dart';
import '../../repositories/breeds_repository.dart';

class BreedForm extends StatefulWidget {
  final Breed? breed;
  final VoidCallback onSave;

  const BreedForm({super.key, this.breed, required this.onSave});

  @override
  State<BreedForm> createState() => _BreedFormState();
}

class _BreedFormState extends State<BreedForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// sync int (1/0) en modelo, bool en UI
  bool _syncBool = false;

  bool _saving = false;

  final _repository = BreedsRepository();

  @override
  void initState() {
    super.initState();
    if (widget.breed != null) {
      _nameController.text = widget.breed!.name;
      _descriptionController.text = widget.breed!.description;
      _syncBool = widget.breed!.sync == 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _saveForm() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final newBreed = Breed(
      id: widget.breed?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      sync: _syncBool ? 1 : 0,
    );

    try {
      if (widget.breed == null) {
        await _repository.insertBreed(newBreed);
      } else {
        await _repository.updateBreed(newBreed);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.breed == null
                ? 'Raza registrada correctamente'
                : 'Raza actualizada correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.breed != null;

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    final double dialogMaxWidth = isMobile ? size.width * 0.92 : 520;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? 'Editar Raza' : 'Agregar Nueva Raza',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: size.height * 0.75,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la raza',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets_outlined),
                  ),
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sincronizado'),
                  value: _syncBool,
                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            setState(() => _syncBool = value ?? false);
                          },
                  activeColor: Colors.green,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _saveForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save, color: Colors.white),
          label: Text(
            isEditing ? 'Actualizar' : 'Guardar',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
