import 'package:flutter/material.dart';
import '../../models/diagnosis_models.dart';
import '../../repositories/diagnosis_repository.dart';

class DiagnosisForm extends StatefulWidget {
  final Diagnosis? diagnosis; // Si viene nulo, es para crear nuevo
  final VoidCallback onSave;

  const DiagnosisForm({super.key, this.diagnosis, required this.onSave});

  @override
  State<DiagnosisForm> createState() => _DiagnosisFormState();
}

class _DiagnosisFormState extends State<DiagnosisForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _sync = false; // Indicador de sincronización

  @override
  void initState() {
    super.initState();
    if (widget.diagnosis != null) {
      _nameController.text = widget.diagnosis!.name;
      _descriptionController.text = widget.diagnosis!.description;
      _sync = widget.diagnosis!.sync;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 🔹 Guardar o actualizar diagnóstico
  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newDiagnosis = Diagnosis(
        id: widget.diagnosis?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        sync: _sync,
      );

      try {
        if (widget.diagnosis == null) {
          await DiagnosisRepository.insertDiagnosis(newDiagnosis);
        } else {
          await DiagnosisRepository.updateDiagnosis(newDiagnosis);
        }

        widget.onSave();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.diagnosis == null
                    ? 'Diagnóstico registrado correctamente'
                    : 'Diagnóstico actualizado correctamente',
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
    final isEditing = widget.diagnosis != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? 'Editar Diagnóstico' : 'Agregar Nuevo Diagnóstico',
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
                  labelText: 'Nombre del diagnóstico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services_outlined),
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

              // Checkbox: sincronización
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
