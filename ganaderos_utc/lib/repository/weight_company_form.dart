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

  Company? _company; // fijo
  Cattle? _cattle; // fijo

  bool get _isEditing => widget.weight != null;

  @override
  void initState() {
    super.initState();
    _init();

    if (_isEditing) {
      _dateController.text = widget.weight!.date;
      _weightController.text = widget.weight!.weight.toString();
      _observationController.text = widget.weight!.observation;
    }
  }

  Future<void> _init() async {
    setState(() => _loading = true);

    try {
      //  1) Cargar empresa
      final companies = await CompanyRepository().getAll();
      final company = companies.firstWhere((c) => c.id == widget.companyId);

      //  2) Cargar ganado solo de esa empresa
      final cattleList = await CattleCompanyRepository.getAllByCompany(
        widget.companyId,
      );
      final cattle = cattleList.firstWhere((c) => c.id == widget.cattleId);

      if (!mounted) return;
      setState(() {
        _company = company;
        _cattle = cattle;
        _loading = false;
      });
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

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_company == null || _cattle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar empresa/ganado.")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final weight = Weight(
        id: widget.weight?.id,
        date: _dateController.text.trim(),
        weight: double.tryParse(_weightController.text) ?? 0.0,
        observation: _observationController.text.trim(),
        cattleId: _cattle!.id!,
        companyId: _company!.id!,
        cattle: _cattle,
        company: _company,
        sync: true,
      );

      bool ok;
      if (_isEditing) {
        ok = await WeightCompanyRepository.updateForCattle(weight);
      } else {
        ok = await WeightCompanyRepository.createForCattle(weight) != null;
      }

      if (!mounted) return;

      if (ok) {
        widget.onSave();
        ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(content: Text("Peso guardado correctamente")),
            )
            .closed
            .then((_) {
              if (mounted) Navigator.pop(context);
            });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo guardar el peso")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
      title: Text(_isEditing ? 'Editar Peso' : 'Agregar Nuevo Peso'),
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
                        //  Empresa fija (solo mostrar)
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

                        //  Ganado fijo (solo mostrar)
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

                        // Fecha
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

                        // Peso
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            prefixIcon: Icon(Icons.monitor_weight),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo requerido';
                            }
                            final val = double.tryParse(value);
                            if (val == null || val <= 0) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Observación
                        TextFormField(
                          controller: _observationController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones',
                            prefixIcon: Icon(Icons.note_alt),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _saveForm,
          icon:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save),
          label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}
