// ignore_for_file: file_names
import 'package:flutter/material.dart';

import '../../../models/weight_models.dart';
import '../../../models/cattle_models.dart';
import '../../../models/company_models.dart';

import '../../../repositories/company_repository.dart';
import '../../../repository/cattle_company_repository.dart';
import '../../../repository/weight_company_repository.dart';

class WeightCompanyForm extends StatefulWidget {
  final Weight? weight; // null = nuevo
  final VoidCallback onSave;

  // fijos por CompanyDashboard (cattle card)
  final int companyId;
  final int cattleId;

  const WeightCompanyForm({
    super.key,
    this.weight,
    required this.onSave,
    required this.companyId,
    required this.cattleId,
  });

  @override
  State<WeightCompanyForm> createState() => _WeightCompanyFormState();
}

class _WeightCompanyFormState extends State<WeightCompanyForm> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _weightController = TextEditingController();
  final _observationController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  Company? _company;
  Cattle? _cattle;

  bool get _isEditing => widget.weight != null;

  @override
  void initState() {
    super.initState();
    _init();

    if (_isEditing) {
      _dateController.text = widget.weight!.date;
      _weightController.text = widget.weight!.weight.toString();

      final obs = widget.weight!.observation.toString();
      _observationController.text =
          (obs == 'null' || obs.trim().isEmpty) ? '' : _capitalizeFirst(obs);
    } else {
      _dateController.text = DateTime.now().toIso8601String().split('T').first;
    }
  }

  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final companies = await CompanyRepository().getAll();
      Company? company;
      for (final c in companies) {
        if (c.id == widget.companyId) {
          company = c;
          break;
        }
      }

      final cattleList = await CattleCompanyRepository.getAllByCompany(
        widget.companyId,
      );

      Cattle? cattle;
      for (final c in cattleList) {
        if (c.id == widget.cattleId) {
          cattle = c;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _company = company;
        _cattle = cattle;
        _loading = false;
      });

      if (company == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se encontró la empresa del formulario"),
          ),
        );
      }

      if (cattle == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se encontró el ganado del formulario"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando datos del formulario: $e")),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _dateController.text.isNotEmpty
              ? DateTime.tryParse(_dateController.text) ?? DateTime.now()
              : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      _dateController.text = picked.toIso8601String().split('T').first;
      setState(() {});
    }
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido';
    final val = double.tryParse(value.trim());
    if (val == null) return 'Ingrese un número válido';
    if (val <= 0) return 'El peso debe ser mayor a 0';
    if (val > 2000) return 'Peso fuera de rango';
    return null;
  }

  String? _validateObservation(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 250) return 'Observación muy larga (máx. 250)';
    return null;
  }

  Future<bool> _isDuplicateDate(String date) async {
    try {
      // ✅ según tu indicación: usar getAllByCattle
      final weights = await WeightCompanyRepository.getAllByCattle(
        widget.cattleId,
      );

      for (final item in weights) {
        final sameId = _isEditing && item.id == widget.weight?.id;
        if (sameId) continue;

        if (item.date.trim() == date.trim()) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error validando fecha duplicada: $e");
      return false;
    }
  }

  Future<void> _saveForm() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_company == null ||
        _cattle == null ||
        _company!.id == null ||
        _cattle!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar empresa/ganado.")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final formattedObservation = _capitalizeFirst(
        _observationController.text,
      );

      final existsDate = await _isDuplicateDate(_dateController.text.trim());
      if (existsDate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ya existe un registro con esa fecha para este ganado',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _saving = false);
        return;
      }

      final weightValue = double.tryParse(_weightController.text.trim()) ?? 0.0;

      final weight = Weight(
        id: widget.weight?.id,
        date: _dateController.text.trim(),
        weight: weightValue,
        observation: formattedObservation,
        cattleId: _cattle!.id!,
        companyId: _company!.id!,
        cattle: _cattle,
        company: _company,
        sync: 1,
      );

      bool ok;
      if (_isEditing) {
        ok = await WeightCompanyRepository.updateForCattle(weight);
      } else {
        ok = await WeightCompanyRepository.createForCattle(weight) != null;
      }

      if (!mounted) return;

      if (ok) {
        widget.onSave(); // ✅ refresca la tabla/listado automáticamente

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? "Peso actualizado correctamente"
                  : "Peso guardado correctamente",
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo guardar el peso"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        _isEditing ? 'Editar Peso' : 'Agregar Nuevo Peso',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content:
          _loading
              ? const SizedBox(
                width: 500,
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
              : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          initialValue: _company?.companyName ?? '---',
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Empresa',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          initialValue:
                              "${_cattle?.name ?? '---'} (${_cattle?.code ?? '-'})",
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Ganado',
                            prefixIcon: Icon(Icons.pets),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de registro',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          onTap: _pickDate,
                          validator:
                              (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Seleccione una fecha'
                                      : null,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            prefixIcon: Icon(Icons.monitor_weight),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateWeight,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _observationController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones',
                            prefixIcon: Icon(Icons.note_alt),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateObservation,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _saveForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                  : const Icon(Icons.save),
          label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}
