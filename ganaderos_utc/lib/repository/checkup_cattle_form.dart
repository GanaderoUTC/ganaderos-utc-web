import 'package:flutter/material.dart';
import '../../../models/checkup_models.dart';
import '../../../models/cattle_models.dart';
import '../../../repository/checkup_cattle_repository.dart';
import '../../../repositories/cattle_repository.dart';

class CheckupCattleForm extends StatefulWidget {
  final Checkup? checkup;
  final int cattleId; // cattle fijo
  final VoidCallback onSave;

  const CheckupCattleForm({
    super.key,
    this.checkup,
    required this.cattleId,
    required this.onSave,
  });

  @override
  State<CheckupCattleForm> createState() => _CheckupCattleFormState();
}

class _CheckupCattleFormState extends State<CheckupCattleForm> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _symptomController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _observationController = TextEditingController();

  Cattle? _selectedCattle;
  List<Cattle> _cattleList = [];

  bool _isLoading = false;
  bool get _isEditing => widget.checkup != null;

  @override
  void initState() {
    super.initState();
    _loadCattle();
    if (_isEditing) _fillForm(widget.checkup!);
  }

  void _fillForm(Checkup checkup) {
    _dateController.text = checkup.date;
    _symptomController.text = checkup.symptom;
    _diagnosisController.text = checkup.diagnosis;
    _treatmentController.text = checkup.treatment;
    _observationController.text = checkup.observation;
  }

  Future<void> _loadCattle() async {
    try {
      final cattle = await CattleRepository.getAll();

      if (!mounted) return;

      final match = cattle.firstWhere(
        (c) => c.id == widget.cattleId,
        // ignore: null_check_always_fails
        orElse: () => null!,
      );

      setState(() {
        _cattleList = cattle;
        _selectedCattle = match;
      });
    } catch (e) {
      debugPrint("❌ Error al cargar cattle: $e");
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

    if (_selectedCattle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo determinar el ganado")),
      );
      return;
    }

    final int companyId =
        _selectedCattle!.companyId != 0
            ? _selectedCattle!.companyId
            : widget.checkup?.companyId ?? 3; //id company

    setState(() => _isLoading = true);

    try {
      final checkup = Checkup(
        id: widget.checkup?.id,
        date: _dateController.text.trim(),
        symptom: _symptomController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        treatment: _treatmentController.text.trim(),
        observation: _observationController.text.trim(),
        cattleId: widget.cattleId, // FIJO
        companyId: companyId, // AUTOMÁTICO
        sync: 1,
      );

      bool ok;
      if (_isEditing) {
        ok = await CheckupCattleRepository.updateForCattle(checkup);
      } else {
        ok = await CheckupCattleRepository.createForCattle(checkup) != null;
      }

      if (!mounted) return;

      if (ok) {
        widget.onSave();
        ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(content: Text("Chequeo guardado correctamente")),
            )
            .closed
            .then((_) {
              if (mounted) Navigator.pop(context);
            });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo guardar el chequeo")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error al guardar chequeo: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(_isEditing ? 'Editar Chequeo' : 'Agregar Chequeo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              children: [
                _buildField(
                  _dateController,
                  'Fecha',
                  Icons.calendar_today,
                  readOnly: true,
                  onTap: _pickDate,
                ),
                _buildField(_symptomController, 'Síntoma', Icons.sick),
                _buildField(
                  _diagnosisController,
                  'Diagnóstico',
                  Icons.medical_services,
                ),
                _buildField(_treatmentController, 'Tratamiento', Icons.healing),
                _buildField(
                  _observationController,
                  'Observación',
                  Icons.note_alt,
                  required: false,
                ),
                const SizedBox(height: 12),

                // Ganado fijo
                DropdownButtonFormField<Cattle>(
                  value: _selectedCattle,
                  items:
                      _cattleList
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text("${c.code} - ${c.name}"),
                            ),
                          )
                          .toList(),
                  onChanged: null,
                  decoration: const InputDecoration(
                    labelText: 'Ganado',
                    prefixIcon: Icon(Icons.pets),
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveForm,
          icon:
              _isLoading
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator:
            required
                ? (v) => v == null || v.isEmpty ? 'Campo requerido' : null
                : null,
      ),
    );
  }
}
