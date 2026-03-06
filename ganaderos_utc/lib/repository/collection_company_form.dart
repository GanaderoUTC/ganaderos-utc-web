import 'package:flutter/material.dart';
import '../../models/collection_models.dart';
import '../../models/cattle_models.dart';
import '../../repository/collection_company_repository.dart';
import '../../repositories/cattle_repository.dart';

class CollectionCattleForm extends StatefulWidget {
  final Collection? collection;
  final int cattleId; // Cattle fijo
  final VoidCallback onSave;

  const CollectionCattleForm({
    super.key,
    this.collection,
    required this.cattleId,
    required this.onSave,
  });

  @override
  State<CollectionCattleForm> createState() => _CollectionCattleFormState();
}

class _CollectionCattleFormState extends State<CollectionCattleForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _litresController = TextEditingController();
  final TextEditingController _densityController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  Cattle? _selectedCattle;
  List<Cattle> _cattleList = [];

  bool _isLoading = false;
  bool get _isEditing => widget.collection != null;

  // ✅ Enfermedad 1-2 en dropdown
  int _illnessLevel = 1;
  String _illnessDescription = Collection.defaultIllnessDescription(1);

  @override
  void initState() {
    super.initState();
    _loadCattle();
    if (widget.collection != null) {
      _fillForm(widget.collection!);
    }
  }

  void _fillForm(Collection collection) {
    _dateController.text = collection.date;
    _litresController.text = collection.litres.toString();
    _densityController.text = collection.density.toString();
    _observationController.text = collection.observation ?? '';

    // ✅ carga illness del registro (si viene null -> 1)
    final ill = (collection.illness == 2) ? 2 : 1;
    _illnessLevel = ill;

    // ✅ si ya tiene descripción, úsala; si no, usa default
    _illnessDescription =
        (collection.illnessDescription != null &&
                collection.illnessDescription!.trim().isNotEmpty)
            ? collection.illnessDescription!.trim()
            : Collection.defaultIllnessDescription(ill);
  }

  Future<void> _loadCattle() async {
    try {
      final cattle = await CattleRepository.getAll();
      if (!mounted) return;

      // ✅ SOLO el ganado requerido (cattle fijo)
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
      setState(() {
        _dateController.text = picked.toIso8601String().split("T").first;
      });
    }
  }

  String? _validateLitres(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese los litros';
    final value = double.tryParse(v.trim());
    if (value == null) return 'Ingrese un número válido';
    if (value <= 0) return 'Los litros deben ser mayor a 0';
    if (value > 200) return 'Litros fuera de rango';
    return null;
  }

  String? _validateDensity(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese la densidad';
    final value = double.tryParse(v.trim());
    if (value == null) return 'Densidad inválida';
    if (value < 0.9 || value > 1.2) {
      return 'Densidad fuera de rango (0.9 - 1.2)';
    }
    return null;
  }

  String? _validateObservation(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > 250) return 'Observación muy larga (máx. 250)';
    return null;
  }

  void _onIllnessChanged(int? v) {
    if (v == null) return;
    setState(() {
      _illnessLevel = (v == 2) ? 2 : 1;
      _illnessDescription = Collection.defaultIllnessDescription(_illnessLevel);
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCattle == null || _selectedCattle!.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo determinar el ganado')),
      );
      return;
    }

    final int companyId =
        (_selectedCattle!.companyId != 0)
            ? _selectedCattle!.companyId
            : (widget.collection?.companyId ?? 1);

    if (companyId == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo determinar la empresa')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final litres = double.parse(_litresController.text.trim());
      final density = double.parse(_densityController.text.trim());

      // ✅ Usa el dropdown (1-2) y guarda descripción
      final collection = Collection(
        id: widget.collection?.id,
        date: _dateController.text.trim(),
        litres: litres,
        illness: _illnessLevel,
        illnessDescription: _illnessDescription,
        density: density,
        observation:
            _observationController.text.trim().isNotEmpty
                ? _observationController.text.trim()
                : null,
        cattleId: widget.cattleId, // ✅ FIJO
        cattle: _selectedCattle,
        companyId: companyId,
        sync: 1,
      );

      bool success;

      if (_isEditing) {
        success = await CollectionCattleRepository.updateForCattle(collection);
      } else {
        success =
            await CollectionCattleRepository.createForCattle(collection) !=
            null;
      }

      if (!mounted) return;

      if (success) {
        widget.onSave();
        ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(
                content: Text('Recolección guardada exitosamente'),
              ),
            )
            .closed
            .then((_) {
              if (mounted) Navigator.pop(context);
            });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la recolección')),
        );
      }
    } catch (e) {
      debugPrint("❌ Error al guardar recolección: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _litresController.dispose();
    _densityController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEditing ? 'Editar Recolección' : 'Agregar Recolección'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              children: [
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _pickDate,
                  validator:
                      (v) =>
                          (v == null || v.isEmpty) ? 'Ingrese la fecha' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _litresController,
                  decoration: const InputDecoration(
                    labelText: 'Litros',
                    prefixIcon: Icon(Icons.water_drop),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateLitres,
                ),
                const SizedBox(height: 12),

                // ✅ Dropdown (1-2) + descripción
                DropdownButtonFormField<int>(
                  value: _illnessLevel,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                  ],
                  onChanged: _onIllnessChanged,
                  decoration: const InputDecoration(
                    labelText: 'Enfermedad (1-2)',
                    prefixIcon: Icon(Icons.healing),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Descripción: $_illnessDescription',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _densityController,
                  decoration: const InputDecoration(
                    labelText: 'Densidad',
                    prefixIcon: Icon(Icons.scale),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateDensity,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _observationController,
                  decoration: const InputDecoration(
                    labelText: 'Observación (opcional)',
                    prefixIcon: Icon(Icons.comment),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateObservation,
                ),
                const SizedBox(height: 12),

                // ✅ Ganado fijo (solo muestra 1 opción)
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
                              child: Text("${c.code} - ${c.name}"),
                            ),
                          )
                          .toList(),
                  onChanged: null, // fijo
                  validator:
                      (_) =>
                          _selectedCattle == null
                              ? 'Ganado no encontrado'
                              : null,
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
}
