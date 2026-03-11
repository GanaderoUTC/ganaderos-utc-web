import 'package:flutter/material.dart';
import '../../models/collection_models.dart';
import '../../models/cattle_models.dart';
import '../../repository/collection_company_repository.dart';
import '../../repositories/cattle_repository.dart';

class CollectionCattleForm extends StatefulWidget {
  final Collection? collection;
  final int cattleId;
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

  int _illnessLevel = 1;

  @override
  void initState() {
    super.initState();

    if (widget.collection != null) {
      _fillForm(widget.collection!);
    }

    _loadCattle();
  }

  void _fillForm(Collection collection) {
    _dateController.text = collection.date;
    _litresController.text = collection.litres.toString();
    _densityController.text = collection.density.toString();
    _observationController.text = _capitalizeFirst(
      collection.observation ?? '',
    );
    _illnessLevel = (collection.illness == 2) ? 2 : 1;
  }

  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  double? _normalizeNumber(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  Future<void> _loadCattle() async {
    try {
      final cattle = await CattleRepository.getAll();
      if (!mounted) return;

      final onlyThis = cattle.where((c) => c.id == widget.cattleId).toList();

      setState(() {
        _cattleList = onlyThis;

        if (onlyThis.isNotEmpty) {
          _selectedCattle = onlyThis.first;
        } else {
          _selectedCattle = null;
        }
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

  String? _validateDate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese la fecha';
    return null;
  }

  String? _validateLitres(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese los litros';
    final value = double.tryParse(v.trim().replaceAll(',', '.'));
    if (value == null) return 'Ingrese un número válido';
    if (value <= 0) return 'Los litros deben ser mayor a 0';
    if (value > 200) return 'Litros fuera de rango';
    return null;
  }

  String? _validateDensity(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese la densidad';
    final value = double.tryParse(v.trim().replaceAll(',', '.'));
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
    });
  }

  Future<List<Collection>> _getCollectionsForValidation() async {
    return await CollectionCattleRepository.getAllByCattle(widget.cattleId);
  }

  Future<bool> _isDuplicateDate(String date) async {
    final collections = await _getCollectionsForValidation();
    final newDate = date.trim();

    for (final item in collections) {
      final sameId =
          widget.collection?.id != null && item.id == widget.collection!.id;
      if (sameId) continue;

      if (item.date.trim() == newDate) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isDuplicateLitres(String litresText) async {
    final collections = await _getCollectionsForValidation();
    final newLitres = _normalizeNumber(litresText);
    if (newLitres == null) return false;

    for (final item in collections) {
      final sameId =
          widget.collection?.id != null && item.id == widget.collection!.id;
      if (sameId) continue;

      if (item.litres == newLitres) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isDuplicateDensity(String densityText) async {
    final collections = await _getCollectionsForValidation();
    final newDensity = _normalizeNumber(densityText);
    if (newDensity == null) return false;

    for (final item in collections) {
      final sameId =
          widget.collection?.id != null && item.id == widget.collection!.id;
      if (sameId) continue;

      if (item.density == newDensity) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveForm() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCattle == null || _selectedCattle!.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo determinar el ganado')),
      );
      return;
    }

    if (_isEditing && widget.collection?.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede editar: el registro no tiene id'),
          backgroundColor: Colors.red,
        ),
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
      final formattedObservation = _capitalizeFirst(
        _observationController.text,
      );

      final existsDate = await _isDuplicateDate(_dateController.text);
      if (existsDate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe una recolección con esa fecha'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final existsLitres = await _isDuplicateLitres(_litresController.text);
      if (existsLitres) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe una recolección con esos litros'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final existsDensity = await _isDuplicateDensity(_densityController.text);
      if (existsDensity) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe una recolección con esa densidad'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final litres = double.parse(
        _litresController.text.trim().replaceAll(',', '.'),
      );
      final density = double.parse(
        _densityController.text.trim().replaceAll(',', '.'),
      );

      final collection = Collection(
        id: widget.collection?.id,
        date: _dateController.text.trim(),
        litres: litres,
        illness: _illnessLevel,
        density: density,
        observation:
            formattedObservation.isNotEmpty ? formattedObservation : null,
        cattleId: widget.cattleId,
        cattle: _selectedCattle,
        companyId: companyId,
        sync: 1,
      );

      debugPrint("EDITANDO: $_isEditing");
      debugPrint("ID ACTUAL: ${widget.collection?.id}");
      debugPrint("OBJETO A ENVIAR: ${collection.toMap()}");

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
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Recolección actualizada exitosamente'
                  : 'Recolección guardada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la recolección'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error al guardar recolección: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final dialogMaxWidth = isMobile ? size.width * 0.92 : 520.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isEditing ? 'Editar Recolección' : 'Agregar Recolección',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: size.height * 0.78,
        ),
        child: SingleChildScrollView(
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
                    validator: _validateDate,
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
                  DropdownButtonFormField<int>(
                    value: _illnessLevel,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                    ],
                    onChanged: _isLoading ? null : _onIllnessChanged,
                    decoration: const InputDecoration(
                      labelText: 'Enfermedad (1-2)',
                      prefixIcon: Icon(Icons.healing),
                      border: OutlineInputBorder(),
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
                    onChanged: null,
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
            backgroundColor: Colors.green.shade700,
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
}
