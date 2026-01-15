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

  /// Ahora sync es INT en el modelo, pero el checkbox usa BOOL.
  /// Lo manejamos internamente con bool.
  bool _syncBool = false;

  final _repository = BreedsRepository();

  @override
  void initState() {
    super.initState();

    if (widget.breed != null) {
      _nameController.text = widget.breed!.name;
      _descriptionController.text = widget.breed!.description;

      // Convertir INT → BOOL (1 = true, 0 = false)
      _syncBool = widget.breed!.sync == 1;
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
      final newBreed = Breed(
        id: widget.breed?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        // Convertimos BOOL → INT
        sync: _syncBool ? 1 : 0,
      );

      try {
        if (widget.breed == null) {
          await _repository.insertBreed(newBreed);
        } else {
          await _repository.updateBreed(newBreed);
        }

        widget.onSave();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.breed == null
                    ? 'Raza registrada correctamente'
                    : 'Raza actualizada correctamente',
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
    final isEditing = widget.breed != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? 'Editar Raza' : 'Agregar Nueva Raza',
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
                  labelText: 'Nombre de la raza',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets_outlined),
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

              /// CHECKBOX CON BOOL
              CheckboxListTile(
                title: const Text('Sincronizado'),
                value: _syncBool,
                onChanged: (value) {
                  setState(() {
                    _syncBool = value ?? false;
                  });
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.save, color: Colors.white),
          label: Text(
            isEditing ? 'Actualizar' : 'Guardar',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
