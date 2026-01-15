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
  final TextEditingController _illnessController = TextEditingController();
  final TextEditingController _densityController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  Cattle? _selectedCattle;
  List<Cattle> _cattleList = [];

  bool _isLoading = false;

  bool get _isEditing => widget.collection != null;

  @override
  void initState() {
    super.initState();
    _loadSelectData();
    if (widget.collection != null) {
      _fillForm(widget.collection!);
    }
  }

  void _fillForm(Collection collection) {
    _dateController.text = collection.date;
    _litresController.text = collection.litres.toString();
    _illnessController.text = (collection.illness).toString();
    _densityController.text = collection.density.toString();
    _observationController.text = collection.observation ?? '';
  }

  Future<void> _loadSelectData() async {
    try {
      final cattle = await CattleRepository.getAll();

      if (!mounted) return;
      setState(() {
        _cattleList = cattle;

        // Cattle fijo (por cattleId)
        final match =
            _cattleList.where((c) => c.id == widget.cattleId).toList();
        _selectedCattle = match.isNotEmpty ? match.first : null;
      });
    } catch (e) {
      print("❌ Error al cargar ganado: $e");
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

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    // cattle obligatorio y fijo
    if (_selectedCattle == null || _selectedCattle!.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar el ganado (cattleId)'),
        ),
      );
      return;
    }

    // companyId sale del cattle (evita null)
    final int companyId = _selectedCattle!.companyId;

    if (mounted) setState(() => _isLoading = true);

    try {
      final newCollection = Collection(
        id: widget.collection?.id,
        date: _dateController.text.trim(),
        litres: double.tryParse(_litresController.text.trim()) ?? 0.0,
        illness: int.tryParse(_illnessController.text.trim()) ?? 0,
        density: double.tryParse(_densityController.text.trim()) ?? 0.0,
        observation:
            _observationController.text.trim().isNotEmpty
                ? _observationController.text.trim()
                : null,
        cattleId: _selectedCattle!.id!, // fijo
        cattle: _selectedCattle,
        companyId: companyId, // YA NO ES NULL
        sync: 1,
      );

      bool success = false;

      if (_isEditing) {
        success = await CollectionCattleRepository.updateForCattle(
          newCollection,
        );
      } else {
        final created = await CollectionCattleRepository.createForCattle(
          newCollection,
        );
        success = created != null;
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
          const SnackBar(content: Text('Error al guardar la recolección')),
        );
      }
    } catch (e) {
      print(" Error al guardar: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _litresController.dispose();
    _illnessController.dispose();
    _densityController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isEditing ? 'Editar Recolección' : 'Agregar Recolección',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Ingrese la fecha'
                            : null,
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
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Ingrese los litros'
                            : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _illnessController,
                decoration: const InputDecoration(
                  labelText: 'Nivel de enfermedad (número)',
                  prefixIcon: Icon(Icons.healing),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
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
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _observationController,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                  prefixIcon: Icon(Icons.comment),
                  border: OutlineInputBorder(),
                ),
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
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                onChanged: null,
                validator:
                    (value) => value == null ? 'Seleccione un ganado' : null,
              ),
            ],
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
