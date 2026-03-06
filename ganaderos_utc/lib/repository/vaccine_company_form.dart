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

      // ✅ Cambio mínimo: no uses toString aquí
      _observationController.text = widget.vaccine!.observation!;

      // Por si algo raro llega como 'null' (defensa extra)
      if (_observationController.text.trim() == 'null') {
        _observationController.text = '';
      }
    }
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // ✅ Empresa fija (evitar crash)
      final companies = await CompanyRepository().getAll();
      Company? company;
      for (final c in companies) {
        if (c.id == widget.companyId) {
          company = c;
          break;
        }
      }

      // ✅ Ganado fijo solo de esa empresa (evitar crash)
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

      // ✅ Mensajes si algo no existe
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

  String? _validateVaccineName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo requerido';
    final s = v.trim();
    if (s.length < 2) return 'Nombre muy corto';
    if (s.length > 80) return 'Nombre muy largo';
    if (!RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,'-]{2,80}$").hasMatch(s)) {
      return 'Nombre inválido';
    }
    return null;
  }

  String? _validateObservation(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    final s = v.trim();
    if (s.length > 250) return 'Observación muy larga (máx. 250)';
    return null;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_company == null ||
        _cattle == null ||
        _cattle!.id == null ||
        _company!.id == null) {
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

        // ✅ limpia observación: si está vacía, manda ''
        observation: _observationController.text.trim(),

        cattleId: _cattle!.id!,
        companyId: _company!.id!,

        // ✅ recomendado: consistencia con el resto de forms
        sync: 0, // o false si tu API lo usa al revés
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
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Seleccione una fecha'
                                      : null,
                        ),
                        _buildField(
                          _nameController,
                          'Nombre de la vacuna',
                          Icons.vaccines,
                          validator: _validateVaccineName,
                        ),
                        _buildField(
                          _observationController,
                          'Observaciones',
                          Icons.note_alt,
                          required: false,
                          maxLines: 2,
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
    String? Function(String?)? validator,
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
            validator ??
            (required
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
                : null),
      ),
    );
  }
}
