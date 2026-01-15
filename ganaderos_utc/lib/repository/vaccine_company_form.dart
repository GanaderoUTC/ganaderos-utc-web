import 'package:flutter/material.dart';

import '../../../models/vaccine_models.dart';
import '../../../models/cattle_models.dart';
import '../../../models/company_models.dart';

import '../../../repository/vaccine_company_repository.dart';
import '../../../repository/cattle_company_repository.dart';
import '../../../repositories/company_repository.dart';

class VaccineCompanyForm extends StatefulWidget {
  final Vaccine? vaccine; // null = nuevo
  final int companyId; // fijo
  final int cattleId; // fijo
  final VoidCallback onSave;

  const VaccineCompanyForm({
    super.key,
    this.vaccine,
    required this.companyId,
    required this.cattleId,
    required this.onSave,
  });

  @override
  State<VaccineCompanyForm> createState() => _VaccineCompanyFormState();
}

class _VaccineCompanyFormState extends State<VaccineCompanyForm> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _nameController = TextEditingController();
  final _observationController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  Company? _company;
  Cattle? _cattle;

  bool get _isEditing => widget.vaccine != null;

  @override
  void initState() {
    super.initState();
    _init();

    if (_isEditing) {
      _dateController.text = widget.vaccine!.date;
      _nameController.text = widget.vaccine!.name;
      _observationController.text = widget.vaccine!.observation;
    }
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      //  Empresa fija
      final companies = await CompanyRepository().getAll();
      final company = companies.firstWhere((c) => c.id == widget.companyId);

      //  Ganado fijo solo de esa empresa
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
        const SnackBar(content: Text("No se pudo determinar empresa/ganado.")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final vaccine = Vaccine(
        id: widget.vaccine?.id,
        date: _dateController.text.trim(),
        name: _nameController.text.trim(),
        observation: _observationController.text.trim(),
        cattleId: _cattle!.id!,
        cattle: _cattle!,
        companyId: _company!.id!,
        company: _company!,
        sync: true,
      );

      bool ok = false;

      if (_isEditing) {
        ok = await VaccineCompanyRepository.updateForCattle(vaccine);
      } else {
        ok = await VaccineCompanyRepository.createForCattle(vaccine) != null;
      }

      if (!mounted) return;

      if (ok) {
        widget.onSave();
        ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(content: Text("Vacuna guardada correctamente")),
            )
            .closed
            .then((_) {
              if (mounted) Navigator.pop(context);
            });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo guardar la vacuna")),
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
    _nameController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(_isEditing ? 'Editar Vacuna' : 'Agregar Vacuna'),
      content:
          _loading
              ? const SizedBox(
                width: 500,
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
              : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: SizedBox(
                    width: 500,
                    child: Column(
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
                        const SizedBox(height: 12),

                        //  Ganado fijo (solo mostrar)
                        TextFormField(
                          initialValue:
                              "${_cattle?.code ?? '-'} - ${_cattle?.name ?? '---'}",
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Ganado',
                            prefixIcon: Icon(Icons.pets),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          _dateController,
                          'Fecha de aplicación',
                          Icons.calendar_today,
                          readOnly: true,
                          onTap: _pickDate,
                        ),
                        _buildField(
                          _nameController,
                          'Nombre de la vacuna',
                          Icons.vaccines,
                        ),
                        _buildField(
                          _observationController,
                          'Observaciones',
                          Icons.note_alt,
                          required: false,
                          maxLines: 2,
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

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    VoidCallback? onTap,
    bool required = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator:
            required
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
                : null,
      ),
    );
  }
}
