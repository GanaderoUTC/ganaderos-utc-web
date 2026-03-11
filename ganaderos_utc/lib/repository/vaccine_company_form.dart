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
      _dateController.text = widget.vaccine?.date ?? '';
      _nameController.text = _capitalizeFirst(widget.vaccine?.name ?? '');
      _observationController.text = _capitalizeFirst(
        widget.vaccine?.observation ?? '',
      );
    }
  }

  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  // ignore: unused_element
  String _normalizeForCompare(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
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
    if (v == null || v.trim().isEmpty) return null;
    final s = v.trim();

    if (s.length > 250) return 'Observación muy larga (máx. 250)';
    return null;
  }

  Future<bool> _isDuplicateDate(String date) async {
    try {
      final vaccines = await VaccineCompanyRepository.getAllByCattle(
        widget.cattleId,
      );

      final newDate = date.trim();

      for (final vaccine in vaccines) {
        final sameId =
            widget.vaccine?.id != null && vaccine.id == widget.vaccine!.id;

        if (sameId) continue;

        if ((vaccine.date).trim() == newDate) {
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
        _cattle!.id == null ||
        _company!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo determinar empresa o ganado."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final formattedName = _capitalizeFirst(_nameController.text);
      final formattedObservation = _capitalizeFirst(
        _observationController.text,
      );
      final selectedDate = _dateController.text.trim();

      final existsDate = await _isDuplicateDate(selectedDate);
      if (existsDate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ya existe una vacuna registrada en esa fecha"),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _saving = false);
        return;
      }

      final vaccine = Vaccine(
        id: widget.vaccine?.id,
        date: selectedDate,
        name: formattedName,
        observation: formattedObservation,
        cattleId: _cattle!.id!,
        companyId: _company!.id!,
        sync: 0,
      );

      bool ok = false;

      if (_isEditing) {
        ok = await VaccineCompanyRepository.updateForCattle(vaccine);
      } else {
        ok = await VaccineCompanyRepository.createForCattle(vaccine) != null;
      }

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? "Vacuna actualizada correctamente"
                  : "Vacuna guardada correctamente",
            ),
            backgroundColor: Colors.green,
          ),
        );

        widget.onSave(); // refresca automáticamente la vista padre
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo guardar la vacuna"),
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
    _nameController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        _isEditing ? 'Editar Vacuna' : 'Agregar Vacuna',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
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
