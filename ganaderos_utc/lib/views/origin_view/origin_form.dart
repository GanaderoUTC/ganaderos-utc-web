import 'package:flutter/material.dart';
import '../../models/origin_models.dart';
import '../../repositories/origin_repository.dart';

class OriginForm extends StatefulWidget {
  final Origin? origin; // Si viene nulo, es para crear uno nuevo
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

  final _repository = OriginRepository();

  @override
  void initState() {
    super.initState();
    if (widget.origin != null) {
      _nameController.text = widget.origin!.name;
      _descriptionController.text = widget.origin!.description;
      _sync = widget.origin!.sync;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 🔹 Guardar o actualizar origen
  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newOrigin = Origin(
        id: widget.origin?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        sync: _sync,
      );

      try {
        if (widget.origin == null) {
          await _repository.insertOrigin(newOrigin);
        } else {
          await _repository.updateOrigin(newOrigin);
        }

        widget.onSave();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.origin == null
                    ? 'Origen registrado correctamente'
                    : 'Origen actualizado correctamente',
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
    final isEditing = widget.origin != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? 'Editar Origen' : 'Agregar Nuevo Origen',
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
              // Campo: Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del origen',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.public),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo: Descripción
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

              // Checkbox: Sincronización
              CheckboxListTile(
                title: const Text('Sincronizado'),
                value: _sync,
                onChanged: (value) {
                  setState(() {
                    _sync = value ?? false;
                  });
                },
                activeColor: Colors.green.shade700,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),

      // 🔹 Botones inferiores
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
