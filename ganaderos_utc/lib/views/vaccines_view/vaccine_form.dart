import 'package:flutter/material.dart';
import '../../models/vaccine_models.dart';
import '../../models/cattle_models.dart';
import '../../models/company_models.dart';
import '../../repositories/vaccine_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/company_repository.dart';

class VaccineForm extends StatefulWidget {
  final Vaccine? vaccine; // Si es nulo, es nuevo registro
  final Function onSave;

  const VaccineForm({super.key, this.vaccine, required this.onSave});

  @override
  State<VaccineForm> createState() => _VaccineFormState();
}

class _VaccineFormState extends State<VaccineForm> {
  final _formKey = GlobalKey<FormState>();
  final _repository = VaccineRepository();

  // Controladores de texto
  final _dateController = TextEditingController();
  final _nameController = TextEditingController();
  final _observationController = TextEditingController();

  // Listas para selects
  List<Cattle> _cattleList = [];
  List<Company> _companies = [];

  // Seleccionados
  Cattle? _selectedCattle;
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();

    if (widget.vaccine != null) {
      _dateController.text = widget.vaccine!.date;
      _nameController.text = widget.vaccine!.name;
      _observationController.text = widget.vaccine!.observation;
      _selectedCattle = widget.vaccine!.cattle;
      _selectedCompany = widget.vaccine!.company;
    }
  }

  Future<void> _loadDropdownData() async {
    final companiesRepo = CompanyRepository();

    final cattleList = await CattleRepository.getAll();
    final companies = await companiesRepo.getAll();

    setState(() {
      _cattleList = cattleList;
      _companies = companies;
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newVaccine = Vaccine(
        id: widget.vaccine?.id,
        date: _dateController.text.trim(),
        name: _nameController.text.trim(),
        observation: _observationController.text.trim(),
        cattleId: _selectedCattle!.id!,
        cattle: _selectedCattle!,
        companyId: _selectedCompany!.id!,
        company: _selectedCompany!,
        sync: true,
      );

      if (widget.vaccine == null) {
        await _repository.create(newVaccine);
      } else {
        await _repository.update(newVaccine);
      }

      widget.onSave();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vaccine != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(isEditing ? 'Editar Vacuna' : 'Agregar Nueva Vacuna'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fecha
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de aplicación',
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

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la vacuna',
                    prefixIcon: Icon(Icons.vaccines),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Campo requerido'
                              : null,
                ),
                const SizedBox(height: 15),

                // Observación
                TextFormField(
                  controller: _observationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // Ganado
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
                            (cattle) => DropdownMenuItem(
                              value: cattle,
                              child: Text("${cattle.name} (${cattle.code})"),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedCattle = value),
                  validator:
                      (value) => value == null ? 'Seleccione un ganado' : null,
                ),
                const SizedBox(height: 15),

                // Empresa
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
                            (comp) => DropdownMenuItem(
                              value: comp,
                              child: Text(comp.companyName),
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
