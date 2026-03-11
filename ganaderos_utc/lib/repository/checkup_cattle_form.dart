import 'package:flutter/material.dart';
import '../../../models/checkup_models.dart';
import '../../../models/cattle_models.dart';
import '../../../repository/checkup_cattle_repository.dart';
import '../../../repositories/cattle_repository.dart';

class CheckupCattleForm extends StatefulWidget {
  final Checkup? checkup;
  final int cattleId;
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

  void _fillForm(Checkup c) {
    _dateController.text = c.date;
    _symptomController.text = _capitalizeFirst(c.symptom);
    _diagnosisController.text = _capitalizeFirst(c.diagnosis);
    _treatmentController.text = _capitalizeFirst(c.treatment);
    _observationController.text = _capitalizeFirst(c.observation);
  }

  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _normalizeForCompare(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

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

  Future<List<Checkup>> _getExistingCheckups() async {
    try {
      final data = await CheckupCattleRepository.getAllByCattle(
        widget.cattleId,
      );
      return data;
    } catch (e) {
      debugPrint("❌ Error al consultar chequeos existentes: $e");
      return [];
    }
  }

  Future<bool> _isDuplicateCheckup({
    required String date,
    required String symptom,
    required String diagnosis,
    required String treatment,
  }) async {
    final checkups = await _getExistingCheckups();

    final newDate = date.trim();
    final newSymptom = _normalizeForCompare(symptom);
    final newDiagnosis = _normalizeForCompare(diagnosis);
    final newTreatment = _normalizeForCompare(treatment);

    for (final item in checkups) {
      final sameId =
          widget.checkup?.id != null && item.id == widget.checkup!.id;
      if (sameId) continue;

      final itemDate = item.date.trim();
      final itemSymptom = _normalizeForCompare(item.symptom);
      final itemDiagnosis = _normalizeForCompare(item.diagnosis);
      final itemTreatment = _normalizeForCompare(item.treatment);

      final sameDate = itemDate == newDate;
      final sameSymptom = itemSymptom == newSymptom;
      final sameDiagnosis = itemDiagnosis == newDiagnosis;
      final sameTreatment = itemTreatment == newTreatment;

      if (sameDate || sameSymptom || sameDiagnosis || sameTreatment) {
        return true;
      }
    }

    return false;
  }

  Future<void> _saveForm() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

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
      final formattedSymptom = _capitalizeFirst(_symptomController.text);
      final formattedDiagnosis = _capitalizeFirst(_diagnosisController.text);
      final formattedTreatment = _capitalizeFirst(_treatmentController.text);
      final formattedObservation =
          _observationController.text.trim().isEmpty
              ? ''
              : _capitalizeFirst(_observationController.text);

      final existsDuplicate = await _isDuplicateCheckup(
        date: _dateController.text.trim(),
        symptom: formattedSymptom,
        diagnosis: formattedDiagnosis,
        treatment: formattedTreatment,
      );

      if (existsDuplicate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Ya existe un chequeo con la misma fecha, síntoma, diagnóstico o tratamiento",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final checkup = Checkup(
        id: widget.checkup?.id,
        date: _dateController.text.trim(),
        symptom: formattedSymptom,
        diagnosis: formattedDiagnosis,
        treatment: formattedTreatment,
        observation: formattedObservation,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? "Chequeo actualizado correctamente"
                  : "Chequeo guardado correctamente",
            ),
            backgroundColor: Colors.green,
          ),
        );

        widget.onSave();
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo guardar el chequeo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error al guardar chequeo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final dialogWidth = isMobile ? size.width * 0.92 : 500.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        _isEditing ? 'Editar Chequeo' : 'Agregar Chequeo',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(
                  _dateController,
                  'Fecha',
                  Icons.calendar_today,
                  readOnly: true,
                  onTap: _pickDate,
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
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
                  'Observación (Opcional)',
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
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
          onPressed: _isLoading ? null : _saveForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon:
              _isLoading
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
                ? (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null
                : null),
      ),
    );
  }
}
