import 'package:flutter/material.dart';
import '../../models/categories_models.dart';
import '../../repositories/categories_repository.dart';

class CategoryForm extends StatefulWidget {
  final Category? category;
  final VoidCallback onSave;

  const CategoryForm({super.key, this.category, required this.onSave});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _syncBool = false;
  bool _saving = false;

  final _repository = CategoriesRepository();

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    if (c != null) {
      _nameController.text = c.name;
      _descriptionController.text = c.description;
      _syncBool = c.sync == 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre es obligatorio';
    if (v.length < 2) return 'Nombre muy corto';
    if (v.length > 50) return 'Nombre muy largo (máx. 50)';

    final ok = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 _-]{2,50}$").hasMatch(v);
    if (!ok) return 'Nombre inválido';
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 250) return 'Descripción muy larga (máx. 250)';
    return null;
  }

  Future<void> _saveForm() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);

    final category = Category(
      id: widget.category?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      sync: _syncBool ? 1 : 0,
    );

    try {
      if (widget.category == null) {
        await _repository.create(category);
      } else {
        await _repository.update(category);
      }

      if (!mounted) return;

      // ✅ IMPORTANTE: NO hacer Navigator.pop() aquí (evita doble pop)
      // Tu view ya cierra el dialog dentro de onSave (Navigator.pop(context, true))
      widget.onSave();

      // ✅ Snackbar luego del pop: programado al siguiente frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.category == null
                  ? 'Categoría registrada correctamente'
                  : 'Categoría actualizada correctamente',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final bool isMobile = w < 600;
        final bool isShortHeight = h < 650; // landscape / teclado

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 40,
            vertical: isMobile ? 12 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            isEditing ? 'Editar Categoría' : 'Agregar Nueva Categoría',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              // ✅ En móvil web: usa casi todo el alto disponible
              maxHeight: isMobile ? (isShortHeight ? h * 0.75 : h * 0.65) : 420,
              maxWidth: isMobile ? double.infinity : 440,
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
                        labelText: 'Nombre de la categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: _validateName,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                      validator: _validateDescription,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Sincronizado'),
                      value: _syncBool,
                      onChanged:
                          (value) => setState(() => _syncBool = value ?? false),
                      activeColor: Colors.green.shade700,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions:
              isMobile
                  ? [
                    // ✅ Botones full width en móvil web
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveForm,
                        icon:
                            _saving
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.save, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        label: Text(
                          isEditing ? 'Actualizar' : 'Guardar',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ]
                  : [
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
                                ),
                              )
                              : const Icon(Icons.save, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: Text(
                        isEditing ? 'Actualizar' : 'Guardar',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
        );
      },
    );
  }
}
