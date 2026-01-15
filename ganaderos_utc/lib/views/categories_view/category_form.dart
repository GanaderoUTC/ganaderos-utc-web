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

  /// sync ahora es INT en el modelo, pero BOOL en el checkbox
  bool _syncBool = false;

  final _repository = CategoriesRepository();

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description;

      // Convertir int → bool
      _syncBool = widget.category!.sync == 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newCategory = Category(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),

        /// Convertir bool → int al guardar
        sync: _syncBool ? 1 : 0,
      );

      try {
        if (widget.category == null) {
          await _repository.create(newCategory);
        } else {
          await _repository.update(newCategory);
        }

        widget.onSave();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.category == null
                    ? 'Categoría registrada correctamente'
                    : 'Categoría actualizada correctamente',
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? 'Editar Categoría' : 'Agregar Nueva Categoría',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
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
              ),
              const SizedBox(height: 15),

              CheckboxListTile(
                title: const Text('Sincronizado'),
                value: _syncBool,
                onChanged: (value) {
                  setState(() => _syncBool = value ?? false);
                },
                activeColor: Colors.green.shade700,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton.icon(
          onPressed: _saveForm,
          icon: const Icon(Icons.save, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
  }
}
