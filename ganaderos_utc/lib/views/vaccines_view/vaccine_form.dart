import 'package:flutter/material.dart';
import '../../models/vaccine_models.dart';
import '../../models/cattle_models.dart';
import '../../models/company_models.dart';
import '../../repositories/vaccine_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/company_repository.dart';

class VaccineForm extends StatefulWidget {
  final Vaccine? vaccine;
  final VoidCallback onSave;

  const VaccineForm({super.key, this.vaccine, required this.onSave});

  @override
  State<VaccineForm> createState() => _VaccineFormState();
}

class _VaccineFormState extends State<VaccineForm> {
  final _formKey = GlobalKey<FormState>();
  final _repository = VaccineRepository();

  final _dateController = TextEditingController();
  final _nameController = TextEditingController();
  final _observationController = TextEditingController();

  List<Cattle> _cattleList = [];
  List<Company> _companies = [];

  Cattle? _selectedCattle;
  Company? _selectedCompany;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.vaccine != null) {
      _dateController.text = widget.vaccine!.date;
      _nameController.text = widget.vaccine!.name;
      _observationController.text = widget.vaccine!.observation!;
      _selectedCattle = widget.vaccine!.cattle;
      _selectedCompany = widget.vaccine!.company;
    }
  }

  Future<void> _loadData() async {
    final cattle = await CattleRepository.getAll();
    final companies = await CompanyRepository().getAll();

    if (!mounted) return;

    setState(() {
      _cattleList = cattle;
      _companies = companies;
      _loading = false;
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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCattle == null || _selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione ganado y empresa")),
      );
      return;
    }

    final vaccine = Vaccine(
      id: widget.vaccine?.id,
      date: _dateController.text.trim(),
      name: _nameController.text.trim(),
      observation: _observationController.text.trim(),
      cattleId: _selectedCattle!.id!,
      cattle: _selectedCattle!,
      companyId: _selectedCompany!.id!,
      company: _selectedCompany!,
      sync: 0,
    );

    if (widget.vaccine == null) {
      await _repository.create(vaccine);
    } else {
      await _repository.update(vaccine);
    }

    widget.onSave();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.vaccine == null ? 'Agregar Vacuna' : 'Editar Vacuna'),
      content: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final double width = isMobile ? constraints.maxWidth * 0.95 : 520;

          return SizedBox(
            width: width,
            child:
                _loading
                    ? const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // FECHA
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
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Seleccione una fecha'
                                          : null,
                            ),
                            const SizedBox(height: 12),

                            // NOMBRE
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la vacuna',
                                prefixIcon: Icon(Icons.vaccines),
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Campo obligatorio'
                                          : null,
                            ),
                            const SizedBox(height: 12),

                            // OBSERVACIÓN
                            TextFormField(
                              controller: _observationController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Observación',
                                prefixIcon: Icon(Icons.note),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // GANADO
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
                              onChanged:
                                  (v) => setState(() => _selectedCattle = v),
                              validator:
                                  (v) =>
                                      v == null ? 'Seleccione un ganado' : null,
                            ),
                            const SizedBox(height: 12),

                            // EMPRESA
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
                                  (v) => setState(() => _selectedCompany = v),
                              validator:
                                  (v) =>
                                      v == null
                                          ? 'Seleccione una empresa'
                                          : null,
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
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          onPressed: _saveForm,
          icon: const Icon(Icons.save),
          label: Text(widget.vaccine == null ? "Guardar" : "Actualizar"),
        ),
      ],
    );
  }
}
