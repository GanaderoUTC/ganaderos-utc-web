import 'package:flutter/material.dart';
import '../../models/weight_models.dart';
import '../../models/cattle_models.dart';
import '../../models/company_models.dart';
import '../../repositories/weight_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/company_repository.dart';

class WeightForm extends StatefulWidget {
  final Weight? weight;
  final Function onSave;

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

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    _cattleList = await CattleRepository.getAll();
    _companies = await CompanyRepository().getAll();

    if (widget.weight != null) {
      // Buscar Ganado — evita crash si no existe
      try {
        _selectedCattle = _cattleList.firstWhere(
          (c) => c.id == widget.weight!.cattleId,
        );
      } catch (e) {
        _selectedCattle = null;
        print("⚠ Ganado del registro no existe en la lista");
      }

      // Buscar Empresa — evita crash si no existe
      try {
        _selectedCompany = _companies.firstWhere(
          (c) => c.id == widget.weight!.companyId,
        );
      } catch (e) {
        _selectedCompany = null;
        print("⚠ Empresa del registro no existe en la lista");
      }

      // Rellenar campos
      _dateController.text = widget.weight!.date;
      _weightController.text = widget.weight!.weight.toString();
      _observationController.text = widget.weight!.observation;
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCattle == null || _selectedCompany == null) return;

    final weight = Weight(
      id: widget.weight?.id,
      date: _dateController.text,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      observation: _observationController.text,
      cattleId: _selectedCattle!.id!,
      companyId: _selectedCompany!.id!,
      cattle: _selectedCattle,
      company: _selectedCompany,
      sync: true,
    );

    bool success;

    if (widget.weight == null) {
      final created = await _repository.create(weight);
      success = created != null;
    } else {
      success = await _repository.update(weight);
    }

    if (success) {
      widget.onSave();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar registro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.weight != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(isEditing ? 'Editar Peso' : 'Agregar Nuevo Peso'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de registro',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _dateController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    }
                  },
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Seleccione una fecha'
                              : null,
                ),
                const SizedBox(height: 15),
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
                TextFormField(
                  controller: _observationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    prefixIcon: Icon(Icons.note_alt),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // 🐄 SELECT GANADO
                DropdownButtonFormField<Cattle>(
                  value: _selectedCattle,
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
                              child: Text("${c.name} (${c.code})"),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedCattle = value),
                  validator:
                      (value) => value == null ? 'Seleccione un ganado' : null,
                ),
                const SizedBox(height: 15),

                // 🏢 SELECT EMPRESA
                DropdownButtonFormField<Company>(
                  value: _selectedCompany,
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
                              child: Text(c.companyName),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => _selectedCompany = value),
                  validator:
                      (value) =>
                          value == null ? 'Seleccione una empresa' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _saveForm,
          icon: const Icon(Icons.save),
          label: Text(isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}
