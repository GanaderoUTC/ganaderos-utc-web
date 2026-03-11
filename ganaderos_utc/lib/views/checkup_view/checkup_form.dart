import 'package:flutter/material.dart';
import '../../models/checkup_models.dart';
import '../../models/cattle_models.dart';
import '../../models/company_models.dart';
import '../../repositories/checkup_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/company_repository.dart';

class CheckupForm extends StatefulWidget {
  final Checkup? checkup;
  final VoidCallback onSave;

  const CheckupForm({super.key, this.checkup, required this.onSave});

  @override
  State<CheckupForm> createState() => _CheckupFormState();
}

class _CheckupFormState extends State<CheckupForm> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CheckupRepository();

  final _dateController = TextEditingController();
  final _symptomController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _observationController = TextEditingController();

  List<Cattle> _cattleList = [];
  List<Company> _companies = [];

  Cattle? _selectedCattle;
  Company? _selectedCompany;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _normalizeForCompare(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String? _validateRequiredText(String? value, String field, {int max = 250}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio';
    }

    final s = value.trim();
    if (s.length < 2) return '$field muy corto';
    if (s.length > max) return '$field muy largo (máx. $max)';
    return null;
  }

  String? _validateObservation(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 300) {
      return 'Observación muy larga (máx. 300)';
    }
    return null;
  }

  Future<void> _loadDropdownData() async {
    try {
      final companiesRepo = CompanyRepository();

      final cattleList = await CattleRepository.getAll();
      final companies = await companiesRepo.getAll();

      if (!mounted) return;

      Cattle? cattleSelected;
      Company? companySelected;

      if (widget.checkup != null) {
        _dateController.text = widget.checkup!.date;
        _symptomController.text = _capitalizeFirst(widget.checkup!.symptom);
        _diagnosisController.text = _capitalizeFirst(widget.checkup!.diagnosis);
        _treatmentController.text = _capitalizeFirst(widget.checkup!.treatment);
        _observationController.text =
            widget.checkup!.observation.trim().isEmpty
                ? ''
                : _capitalizeFirst(widget.checkup!.observation);

        final cattleId = widget.checkup!.cattleId;
        final companyId = widget.checkup!.companyId;

        for (final c in cattleList) {
          if (c.id == cattleId) {
            cattleSelected = c;
            break;
          }
        }

        for (final c in companies) {
          if (c.id == companyId) {
            companySelected = c;
            break;
          }
        }
      }

      setState(() {
        _cattleList = cattleList;
        _companies = companies;
        _selectedCattle = cattleSelected;
        _selectedCompany = companySelected;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _isDuplicateCheckup({
    required String date,
    required String symptom,
    required String diagnosis,
    required String treatment,
    required int cattleId,
    required int companyId,
  }) async {
    try {
      final List<Checkup> checkups = await CheckupRepository.getAll();

      final newDate = date.trim();
      final newSymptom = _normalizeForCompare(symptom);
      final newDiagnosis = _normalizeForCompare(diagnosis);
      final newTreatment = _normalizeForCompare(treatment);

      for (final item in checkups) {
        final bool sameId =
            widget.checkup?.id != null && item.id == widget.checkup!.id;

        if (sameId) continue;

        final sameDate = item.date.trim() == newDate;
        final sameSymptom = _normalizeForCompare(item.symptom) == newSymptom;
        final sameDiagnosis =
            _normalizeForCompare(item.diagnosis) == newDiagnosis;
        final sameTreatment =
            _normalizeForCompare(item.treatment) == newTreatment;
        final sameCattle = item.cattleId == cattleId;
        final sameCompany = item.companyId == companyId;

        if (sameDate &&
            sameSymptom &&
            sameDiagnosis &&
            sameTreatment &&
            sameCattle &&
            sameCompany) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error validando duplicados de chequeo: $e');
      return false;
    }
  }

  Future<void> _saveForm() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCattle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un ganado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una empresa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCattle!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El ganado seleccionado no tiene un ID válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCompany!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La empresa seleccionada no tiene un ID válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final formattedSymptom = _capitalizeFirst(_symptomController.text);
      final formattedDiagnosis = _capitalizeFirst(_diagnosisController.text);
      final formattedTreatment = _capitalizeFirst(_treatmentController.text);
      final formattedObservation =
          _observationController.text.trim().isEmpty
              ? ''
              : _capitalizeFirst(_observationController.text);

      final isDuplicate = await _isDuplicateCheckup(
        date: _dateController.text.trim(),
        symptom: formattedSymptom,
        diagnosis: formattedDiagnosis,
        treatment: formattedTreatment,
        cattleId: _selectedCattle!.id!,
        companyId: _selectedCompany!.id!,
      );

      if (isDuplicate) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ya existe un chequeo con la misma fecha, síntoma, diagnóstico y tratamiento para este ganado en esta empresa',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        setState(() => _saving = false);
        return;
      }

      final newCheckup = Checkup(
        id: widget.checkup?.id,
        date: _dateController.text.trim(),
        symptom: formattedSymptom,
        diagnosis: formattedDiagnosis,
        treatment: formattedTreatment,
        observation: formattedObservation,
        cattleId: _selectedCattle!.id!,
        companyId: _selectedCompany!.id!,
        cattle: _selectedCattle,
        company: _selectedCompany,
        sync: 1,
      );

      bool success = false;

      if (widget.checkup == null) {
        final result = await _repository.create(newCheckup);
        success = result != null;
      } else {
        success = await _repository.update(newCheckup);
      }

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el chequeo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.checkup == null
                ? 'Chequeo registrado correctamente'
                : 'Chequeo actualizado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSave();
      Navigator.pop(context);
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
  void dispose() {
    _dateController.dispose();
    _symptomController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.checkup != null;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? 'Editar Chequeo' : 'Agregar Nuevo Chequeo',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content:
          _loading
              ? const SizedBox(
                width: 120,
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
              : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: SizedBox(
                    width: isMobile ? size.width * 0.90 : 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Fecha del chequeo',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          onTap:
                              _saving
                                  ? null
                                  : () async {
                                    final initialDate =
                                        _dateController.text.isNotEmpty
                                            ? DateTime.tryParse(
                                                  _dateController.text,
                                                ) ??
                                                DateTime.now()
                                            : DateTime.now();

                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: initialDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );

                                    if (picked != null) {
                                      _dateController.text =
                                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                    }
                                  },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Seleccione una fecha';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _symptomController,
                          decoration: const InputDecoration(
                            labelText: 'Síntoma',
                            prefixIcon: Icon(Icons.sick),
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) => _validateRequiredText(
                                value,
                                'Síntoma',
                                max: 200,
                              ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _diagnosisController,
                          decoration: const InputDecoration(
                            labelText: 'Diagnóstico',
                            prefixIcon: Icon(Icons.medical_services),
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) => _validateRequiredText(
                                value,
                                'Diagnóstico',
                                max: 200,
                              ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _treatmentController,
                          decoration: const InputDecoration(
                            labelText: 'Tratamiento',
                            prefixIcon: Icon(Icons.healing),
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) => _validateRequiredText(
                                value,
                                'Tratamiento',
                                max: 250,
                              ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _observationController,
                          decoration: const InputDecoration(
                            labelText: 'Observación',
                            prefixIcon: Icon(Icons.note_alt),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          validator: _validateObservation,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<Cattle>(
                          value: _selectedCattle,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Ganado',
                            prefixIcon: Icon(Icons.pets),
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _cattleList.map((cat) {
                                final code = (cat.code).trim();
                                final name = (cat.name).trim();

                                String label = 'Ganado';
                                if (code.isNotEmpty && name.isNotEmpty) {
                                  label = '$code - $name';
                                } else if (name.isNotEmpty) {
                                  label = name;
                                } else if (code.isNotEmpty) {
                                  label = code;
                                } else if (cat.id != null) {
                                  label = 'Ganado #${cat.id}';
                                }

                                return DropdownMenuItem<Cattle>(
                                  value: cat,
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              _saving
                                  ? null
                                  : (value) {
                                    setState(() => _selectedCattle = value);
                                  },
                          validator:
                              (value) =>
                                  value == null ? 'Seleccione un ganado' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<Company>(
                          value: _selectedCompany,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Hacienda / Empresa',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _companies.map((comp) {
                                final companyName = comp.companyName.trim();
                                final label =
                                    companyName.isNotEmpty
                                        ? companyName
                                        : (comp.id != null
                                            ? 'Empresa #${comp.id}'
                                            : 'Empresa');

                                return DropdownMenuItem<Company>(
                                  value: comp,
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              _saving
                                  ? null
                                  : (value) {
                                    setState(() => _selectedCompany = value);
                                  },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Seleccione una empresa'
                                      : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton.icon(
          onPressed: (_saving || _loading) ? null : _saveForm,
          icon:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save),
          label: Text(isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}
