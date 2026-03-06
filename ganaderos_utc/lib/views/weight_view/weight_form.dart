import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/weight_models.dart';
import '../../models/cattle_models.dart';
import '../../models/company_models.dart';
import '../../repositories/weight_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/company_repository.dart';

class WeightForm extends StatefulWidget {
  final Weight? weight;
  final VoidCallback onSave;

  const WeightForm({super.key, this.weight, required this.onSave});

  @override
  State<WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends State<WeightForm> {
  final _formKey = GlobalKey<FormState>();
  final _repository = WeightRepository();

  final _dateController = TextEditingController();
  final _weightController = TextEditingController();
  final _observationController = TextEditingController();

  List<Cattle> _cattleList = [];
  List<Company> _companies = [];
  Cattle? _selectedCattle;
  Company? _selectedCompany;

  bool _loadingDropdowns = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() => _loadingDropdowns = true);

    try {
      final cattle = await CattleRepository.getAll();
      final companies = await CompanyRepository().getAll();

      // Prefill si estamos editando
      if (widget.weight != null) {
        final w = widget.weight!;

        // buscar ganado por ID (sin crash)
        _selectedCattle =
            cattle.where((c) => c.id == w.cattleId).isNotEmpty
                ? cattle.firstWhere((c) => c.id == w.cattleId)
                : null;

        // buscar empresa por ID (sin crash)
        _selectedCompany =
            companies.where((c) => c.id == w.companyId).isNotEmpty
                ? companies.firstWhere((c) => c.id == w.companyId)
                : null;

        _dateController.text = w.date;
        _weightController.text = w.weight.toString();
        _observationController.text = w.observation ?? ''; // ✅ FIX null
      } else {
        // defaults útiles cuando es nuevo (opcional)
        _selectedCattle = null;
        _selectedCompany = null;
      }

      _cattleList = cattle;
      _companies = companies;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando listas: $e')));
    } finally {
      if (mounted) setState(() => _loadingDropdowns = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _saveForm() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCattle == null || _selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione ganado y empresa')),
      );
      return;
    }

    setState(() => _saving = true);

    final weight = Weight(
      id: widget.weight?.id,
      date: _dateController.text.trim(),
      weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      observation: _observationController.text.trim(),
      cattleId: _selectedCattle!.id!,
      companyId: _selectedCompany!.id!,
      cattle: _selectedCattle,
      company: _selectedCompany,
      sync: widget.weight?.sync ?? 0,
    );

    try {
      bool success;

      if (widget.weight == null) {
        final created = await _repository.create(weight);
        success = created != null;
      } else {
        success = await _repository.update(weight);
      }

      if (!mounted) return;

      if (success) {
        widget.onSave();
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar registro')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.weight != null;

    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 700;

    // ✅ ancho responsivo del diálogo
    final dialogW = min(520.0, screenW * 0.95);

    // ✅ paddings responsivos
    final double gap = isMobile ? 12 : 15;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(isEditing ? 'Editar Peso' : 'Agregar Nuevo Peso'),
      content: SizedBox(
        width: dialogW,
        child:
            _loadingDropdowns
                ? const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
                : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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

                        SizedBox(height: gap),

                        // Peso
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            final val = double.tryParse(value.trim());
                            if (val == null || val <= 0) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: gap),

                        // Observación
                        TextFormField(
                          controller: _observationController,
                          maxLines: isMobile ? 2 : 3,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones',
                            prefixIcon: Icon(Icons.note_alt),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        SizedBox(height: gap),

                        // Ganado
                        DropdownButtonFormField<Cattle>(
                          value: _selectedCattle,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Ganado',
                            prefixIcon: Icon(Icons.pets),
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _cattleList
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        "${c.name} (${c.code})",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _selectedCattle = v),
                          validator:
                              (v) => v == null ? 'Seleccione un ganado' : null,
                        ),

                        SizedBox(height: gap),

                        // Empresa
                        DropdownButtonFormField<Company>(
                          value: _selectedCompany,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Empresa',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _companies
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c.companyName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _selectedCompany = v),
                          validator:
                              (v) =>
                                  v == null ? 'Seleccione una empresa' : null,
                        ),
                      ],
                    ),
                  ),
                ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
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
          label: Text(isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}
