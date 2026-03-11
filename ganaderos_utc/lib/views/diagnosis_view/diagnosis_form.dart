import 'package:flutter/material.dart';
import '../../models/diagnosis_models.dart';
import '../../repositories/diagnosis_repository.dart';

class DiagnosisForm extends StatefulWidget {
  final Diagnosis? diagnosis;
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

  String _normalizeSpaces(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _capitalize(String text) {
    final clean = _normalizeSpaces(text);
    if (clean.isEmpty) return clean;
    return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "El nombre es obligatorio";
    }

    final name = _normalizeSpaces(value);

    if (name.length < 3) {
      return "Mínimo 3 caracteres";
    }

    if (name.length > 60) {
      return "Máximo 60 caracteres";
    }

    if (!RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúñÑ ]+$').hasMatch(name)) {
      return "Solo se permiten letras";
    }

    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final description = _normalizeSpaces(value);

    if (description.length < 5) {
      return "La descripción es muy corta";
    }

    if (description.length > 250) {
      return "Máximo 250 caracteres";
    }

    return null;
  }

  Future<void> _saveForm() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final formattedName = _capitalize(_nameController.text);
      final formattedDescription =
          _descriptionController.text.trim().isEmpty
              ? ''
              : _capitalize(_descriptionController.text);

      final allDiagnosis = await DiagnosisRepository.getAll();

      for (final d in allDiagnosis) {
        final sameRecord = widget.diagnosis?.id == d.id;

        if (!sameRecord) {
          final existingName = _normalizeSpaces(d.name).toLowerCase();
          final newName = _normalizeSpaces(formattedName).toLowerCase();

          if (existingName == newName) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("El nombre del diagnóstico ya existe"),
                backgroundColor: Colors.red.shade700,
              ),
            );

            setState(() => _saving = false);
            return;
          }

          final existingDescription =
              _normalizeSpaces(d.description).toLowerCase();

          final newDescription =
              _normalizeSpaces(formattedDescription).toLowerCase();

          if (formattedDescription.isNotEmpty &&
              existingDescription == newDescription) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("La descripción ya existe"),
                backgroundColor: Colors.red.shade700,
              ),
            );

            setState(() => _saving = false);
            return;
          }
        }
      }

      final diagnosis = Diagnosis(
        id: widget.diagnosis?.id,
        name: formattedName,
        description: formattedDescription,
        sync: _sync,
      );

      if (widget.diagnosis == null) {
        await DiagnosisRepository.insertDiagnosis(diagnosis);
      } else {
        await DiagnosisRepository.updateDiagnosis(diagnosis);
      }

      if (!mounted) return;

      Navigator.pop(context);
      widget.onSave();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.diagnosis == null
                ? "Diagnóstico registrado correctamente"
                : "Diagnóstico actualizado correctamente",
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar: $e"),
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
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    final dialogWidth = isMobile ? w * 0.92 : 480.0;
    final maxH = MediaQuery.of(context).size.height * 0.65;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? 'Editar Diagnóstico' : 'Agregar Nuevo Diagnóstico',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del diagnóstico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    validator: _validateDescription,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sincronizado'),
                    value: _sync,
                    onChanged:
                        _saving
                            ? null
                            : (value) => setState(() => _sync = value ?? false),
                    activeColor: Colors.green.shade700,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.cancel, color: Colors.white),
          label: const Text('Cancelar', style: TextStyle(color: Colors.white)),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
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
