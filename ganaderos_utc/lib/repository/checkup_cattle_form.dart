import 'package:flutter/material.dart';
import '../../../models/checkup_models.dart';
import '../../../models/cattle_models.dart';
import '../../../repository/checkup_cattle_repository.dart';
import '../../../repositories/cattle_repository.dart';

class CheckupCattleForm extends StatefulWidget {
  final Checkup? checkup;
  final int cattleId; // ganado FIJO
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

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadCattle();
    if (_isEditing) _fillForm(widget.checkup!);
  }

  void _fillForm(Checkup c) {
    _dateController.text = c.date;
    _symptomController.text = c.symptom;
    _diagnosisController.text = c.diagnosis;
    _treatmentController.text = c.treatment;
    _observationController.text = c.observation;
  }

  // ------------------------------------------------------------
  // SOLO CARGA EL GANADO ACTUAL (no todo el sistema)
  // ------------------------------------------------------------
  Future<void> _loadCattle() async {
    try {
      final cattle = await CattleRepository.getAll();
      if (!mounted) return;

      final onlyThis = cattle.where((c) => c.id == widget.cattleId).toList();

      setState(() {
        _cattleList = onlyThis;
        _selectedCattle = onlyThis.isNotEmpty ? onlyThis.first : null;
      });

      if (_selectedCattle == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se encontró el ganado seleccionado"),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error al cargar ganado: $e");
    }
  }

  // ------------------------------------------------------------
  // DATE PICKER
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // VALIDADOR TEXTO
  // ------------------------------------------------------------
  String? _textMin(
    String? v, {
    int min = 3,
    int max = 200,
    String label = "Campo",
  }) {
    if (v == null || v.trim().isEmpty) return "Campo requerido";
    final s = v.trim();
    if (s.length < min) return "$label muy corto";
    if (s.length > max) return "$label muy largo";
    return null;
  }

  // ------------------------------------------------------------
  // GUARDAR
  // ------------------------------------------------------------
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCattle == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ganado no válido")));
      return;
    }

    final int companyId =
        _selectedCattle!.companyId != 0
            ? _selectedCattle!.companyId
            : (widget.checkup?.companyId ?? 1);

    setState(() => _isLoading = true);

    try {
      final checkup = Checkup(
        id: widget.checkup?.id,
        date: _dateController.text.trim(),
        symptom: _symptomController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        treatment: _treatmentController.text.trim(),
        observation: _observationController.text.trim(),
        cattleId: widget.cattleId,
        companyId: companyId,
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

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------
  @override
  void dispose() {
    _dateController.dispose();
    _symptomController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
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
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? "Seleccione una fecha"
                              : null,
                ),
                _buildField(
                  _symptomController,
                  'Síntoma',
                  Icons.sick,
                  validator:
                      (v) => _textMin(v, label: "Síntoma", min: 3, max: 120),
                ),
                _buildField(
                  _diagnosisController,
                  'Diagnóstico',
                  Icons.medical_services,
                  validator:
                      (v) =>
                          _textMin(v, label: "Diagnóstico", min: 3, max: 180),
                ),
                _buildField(
                  _treatmentController,
                  'Tratamiento',
                  Icons.healing,
                  validator:
                      (v) =>
                          _textMin(v, label: "Tratamiento", min: 3, max: 220),
                ),
                _buildField(
                  _observationController,
                  'Observación',
                  Icons.note_alt,
                  required: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (v.trim().length > 250) {
                      return "Observación muy larga";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Ganado fijo
                DropdownButtonFormField<Cattle>(
                  value: _selectedCattle,
                  hint: const Text("Ganado no encontrado"),
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
                  validator:
                      (_) =>
                          _selectedCattle == null
                              ? "Ganado no encontrado"
                              : null,
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
    String? Function(String?)? validator,
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
            validator ??
            (required
                ? (v) => v == null || v.isEmpty ? 'Campo requerido' : null
                : null),
      ),
    );
  }
}
