import 'package:flutter/material.dart';
import '../../models/checkup_models.dart';
import '../../models/cattle_models.dart';
import '../../models/company_models.dart';
import '../../repositories/checkup_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/company_repository.dart';

class CheckupForm extends StatefulWidget {
  final Checkup? checkup; // Si es nulo, se crea uno nuevo
  final Function onSave;

  const CheckupForm({super.key, this.checkup, required this.onSave});

  @override
  State<CheckupForm> createState() => _CheckupFormState();
}

class _CheckupFormState extends State<CheckupForm> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CheckupRepository();

  // Controladores
  final _dateController = TextEditingController();
  final _symptomController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _observationController = TextEditingController();

  // Listas de selects
  List<Cattle> _cattleList = [];
  List<Company> _companies = [];

  // Selecciones actuales
  Cattle? _selectedCattle;
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();

    if (widget.checkup != null) {
      _dateController.text = widget.checkup!.date;
      _symptomController.text = widget.checkup!.symptom;
      _diagnosisController.text = widget.checkup!.diagnosis;
      _treatmentController.text = widget.checkup!.treatment;
      _observationController.text = widget.checkup!.observation;

      _selectedCattle = widget.checkup!.cattle;
      _selectedCompany = widget.checkup!.company;
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
    _symptomController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newCheckup = Checkup(
        id: widget.checkup?.id,
        date: _dateController.text.trim(),
        symptom: _symptomController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        treatment: _treatmentController.text.trim(),
        observation: _observationController.text.trim(),
        cattleId: _selectedCattle!.id!,
        cattle: _selectedCattle!,
        companyId: _selectedCompany!.id!,
        company: _selectedCompany!,
        sync: _selectedCattle != null ? 1 : 0,
      );

      if (widget.checkup == null) {
        await _repository.create(newCheckup);
      } else {
        await _repository.update(newCheckup);
      }

      widget.onSave();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.checkup != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(isEditing ? 'Editar Chequeo' : 'Agregar Nuevo Chequeo'),
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
                    labelText: 'Fecha del Chequeo',
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

                // Síntoma
                TextFormField(
                  controller: _symptomController,
                  decoration: const InputDecoration(
                    labelText: 'Síntoma',
                    prefixIcon: Icon(Icons.sick),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Campo requerido'
                              : null,
                ),
                const SizedBox(height: 15),

                // Diagnóstico
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico',
                    prefixIcon: Icon(Icons.medical_services),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Campo requerido'
                              : null,
                ),
                const SizedBox(height: 15),

                // Tratamiento
                TextFormField(
                  controller: _treatmentController,
                  decoration: const InputDecoration(
                    labelText: 'Tratamiento',
                    prefixIcon: Icon(Icons.healing),
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
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                    prefixIcon: Icon(Icons.note_alt),
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
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text("${cat.code} - ${cat.name}"),
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
                              child: Text("Empresa #${comp.id}"),
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
