import 'package:flutter/material.dart';
import '../../models/collection_models.dart';
import '../../models/cattle_models.dart';
import '../../models/company_models.dart';
import '../../repositories/collection_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/company_repository.dart';

class CollectionForm extends StatefulWidget {
  final Collection? collection;
  final VoidCallback onSave;

  const CollectionForm({super.key, this.collection, required this.onSave});

  @override
  State<CollectionForm> createState() => _CollectionFormState();
}

class _CollectionFormState extends State<CollectionForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _litresController = TextEditingController();
  final TextEditingController _illnessController = TextEditingController();
  final TextEditingController _densityController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  Cattle? _selectedCattle;
  Company? _selectedCompany;

  List<Cattle> _cattleList = [];
  List<Company> _companyList = [];

  bool _isLoading = false;

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
    _selectedCattle = collection.cattle;
    _selectedCompany = collection.company;
  }

  Future<void> _loadSelectData() async {
    try {
      final companiesRepo = CompanyRepository();
      final cattle = await CattleRepository.getAll();
      final companies = await companiesRepo.getAll();

      if (!mounted) return;
      setState(() {
        _cattleList = cattle;
        _companyList = companies;
      });
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al cargar datos de selects: $e");
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _dateController.text.isNotEmpty
              ? DateTime.parse(_dateController.text)
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

    if (_selectedCattle == null || _selectedCompany == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione el ganado y la empresa')),
        );
      }
      return;
    }

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
        cattleId: _selectedCattle?.id ?? 0,
        cattle: _selectedCattle,
        companyId: _selectedCompany?.id ?? 0,
        company: _selectedCompany,
        sync: _selectedCattle != null ? 1 : 0,
      );

      final repo = CollectionRepository();
      bool success = false;

      if (widget.collection == null) {
        final created = await repo.create(newCollection);
        success = created != null;
      } else {
        success = await repo.update(newCollection);
      }

      if (!mounted) return;

      if (success) {
        widget.onSave();
        // Mostramos SnackBar y luego cerramos el diálogo
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
      // ignore: avoid_print
      print("❌ Error al guardar: $e");
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
        widget.collection == null
            ? 'Agregar Recolección'
            : 'Editar Recolección',
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
              // Fecha
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

              // Litros
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

              // Nivel de enfermedad
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

              // Densidad
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

              // Observación
              TextFormField(
                controller: _observationController,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                  prefixIcon: Icon(Icons.comment),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Select de Ganado
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
                          (cattle) => DropdownMenuItem(
                            value: cattle,
                            child: Text(cattle.name),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _selectedCattle = value),
                validator:
                    (value) => value == null ? 'Seleccione un ganado' : null,
              ),
              const SizedBox(height: 12),

              // Select de Empresa
              DropdownButtonFormField<Company>(
                value: _selectedCompany,
                decoration: const InputDecoration(
                  labelText: 'Empresa',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                items:
                    _companyList
                        .map(
                          (company) => DropdownMenuItem(
                            value: company,
                            child: Text(company.companyName),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _selectedCompany = value),
                validator:
                    (value) => value == null ? 'Seleccione una empresa' : null,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
