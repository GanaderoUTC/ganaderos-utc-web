import 'package:flutter/material.dart';
import '../../models/diagnosis_models.dart';
import '../../repositories/diagnosis_repository.dart';

class DiagnosisForm extends StatefulWidget {
  final Diagnosis? diagnosis; // null = nuevo
  final VoidCallback onSave;

  const DiagnosisForm({super.key, this.diagnosis, required this.onSave});

  @override
  State<DiagnosisForm> createState() => _DiagnosisFormState();
}

class _DiagnosisFormState extends State<DiagnosisForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _sync = false;
  bool _saving = false;

  bool get isEditing => widget.diagnosis != null;

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

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
    final s = v.trim();
    if (s.length < 3) return 'Mínimo 3 caracteres';
    if (s.length > 60) return 'Máximo 60 caracteres';
    return null;
  }

  String? _validateDescription(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    if (v.trim().length > 250) return 'Descripción muy larga (máx. 250)';
    return null;
  }

  Future<void> _saveForm() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

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

      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? 'Editar Diagnóstico' : 'Agregar Nuevo Diagnóstico',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),

      // ✅ RESPONSIVE: limita ancho/alto y permite scroll en móvil web
      content: LayoutBuilder(
        builder: (context, constraints) {
          final dialogWidth = isMobile ? w * 0.92 : 480.0;
          final maxH = MediaQuery.of(context).size.height * 0.65;

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: maxH),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del diagnóstico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 15),

                    // Descripción
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
                    const SizedBox(height: 12),

                    // Sync
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sincronizado'),
                      value: _sync,
                      onChanged:
                          _saving
                              ? null
                              : (value) =>
                                  setState(() => _sync = value ?? false),
                      activeColor: Colors.green.shade700,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
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
