import 'package:flutter/material.dart';
import '../../models/cattle_models.dart';
import '../../models/categories_models.dart';
import '../../models/origin_models.dart';
import '../../models/breed_models.dart';
import '../../models/company_models.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/categories_repository.dart';
import '../../repositories/origin_repository.dart';
import '../../repositories/breeds_repository.dart';
import '../../repositories/company_repository.dart';

class CattleForm extends StatefulWidget {
  final Cattle? cattle;
  final int? initialCompanyId; // ✅ Nuevo parámetro
  final Function onSave;

  const CattleForm({
    super.key,
    this.cattle,
    this.initialCompanyId,
    required this.onSave,
  });

  @override
  State<CattleForm> createState() => _CattleFormState();
}

class _CattleFormState extends State<CattleForm> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _registerController = TextEditingController();
  final _weightController = TextEditingController();
  final _dateController = TextEditingController();

  List<Category> _categories = [];
  List<Origin> _origins = [];
  List<Breed> _breeds = [];
  List<Company> _companies = [];

  Category? _selectedCategory;
  Origin? _selectedOrigin;
  Breed? _selectedBreed;
  Company? _selectedCompany;

  int? _selectedGender;
  int _sync = 1;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.cattle != null) {
      final c = widget.cattle!;
      _codeController.text = c.code;
      _nameController.text = c.name;
      _registerController.text = c.register;
      _weightController.text = c.weight.toString();
      _dateController.text = c.date;
      _selectedGender = c.gender;
      _sync = c.sync;
    }
  }

  Future<void> _loadDropdownData() async {
    final companiesRepo = CompanyRepository();

    final categories = await CategoriesRepository.getAll();
    final origins = await OriginRepository.getAll();
    final breeds = await BreedsRepository.getAll();
    final companies = await companiesRepo.getAll();

    setState(() {
      _categories = categories;
      _origins = origins;
      _breeds = breeds;
      _companies = companies;

      // Categoría
      _selectedCategory =
          widget.cattle != null
              ? _categories.firstWhere(
                (cat) => widget.cattle!.categoryId == cat.id,
                orElse: () => _categories[0],
              )
              : null;

      // Origen
      _selectedOrigin =
          widget.cattle != null
              ? _origins.firstWhere(
                (o) => widget.cattle!.originId == o.id,
                orElse: () => _origins[0],
              )
              : null;

      // Raza
      _selectedBreed =
          widget.cattle != null
              ? _breeds.firstWhere(
                (b) => widget.cattle!.breedId == b.id,
                orElse: () => _breeds[0],
              )
              : null;

      // Empresa
      _selectedCompany =
          widget.cattle != null
              ? _companies.firstWhere(
                (c) => widget.cattle!.companyId == c.id,
                orElse: () => _companies[0],
              )
              : widget.initialCompanyId != null
              ? _companies.firstWhere(
                (c) => c.id == widget.initialCompanyId,
                orElse: () => _companies[0],
              )
              : null;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _registerController.dispose();
    _weightController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newCattle = Cattle(
        id: widget.cattle?.id,
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        register: _registerController.text.trim(),
        categoryId: _selectedCategory?.id ?? 0,
        gender: _selectedGender ?? 0,
        originId: _selectedOrigin?.id ?? 0,
        breedId: _selectedBreed?.id ?? 0,
        date: _dateController.text.trim(),
        weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
        urlImage: null,
        companyId: _selectedCompany?.id ?? 0,
        sync: _sync,
      );

      try {
        if (widget.cattle == null) {
          await CattleRepository.create(newCattle);
        } else {
          await CattleRepository.update(newCattle);
        }

        if (!mounted) return;
        widget.onSave();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cattle != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(isEditing ? "Editar Ganado" : "Agregar Ganado"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              children: [
                // Código
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: "Código",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) => v == null || v.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 10),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) => v == null || v.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 10),

                // Registro
                TextFormField(
                  controller: _registerController,
                  decoration: const InputDecoration(
                    labelText: "Registro",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) => v == null || v.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 10),

                // Peso
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Peso (kg)",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Campo requerido";
                    if (double.tryParse(v) == null) {
                      return "Ingrese un número válido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Género
                DropdownButtonFormField<int>(
                  value:
                      [1, 2].contains(_selectedGender) ? _selectedGender : null,
                  hint: const Text("Seleccione un género"),
                  decoration: const InputDecoration(
                    labelText: "Género",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("Macho")),
                    DropdownMenuItem(value: 2, child: Text("Hembra")),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator:
                      (value) => value == null ? "Seleccione un género" : null,
                ),
                const SizedBox(height: 10),

                // Categoría
                DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  hint: const Text("Seleccione una categoría"),
                  decoration: const InputDecoration(
                    labelText: "Categoría",
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.name),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => _selectedCategory = value),
                  validator:
                      (value) =>
                          value == null ? "Seleccione una categoría" : null,
                ),
                const SizedBox(height: 10),

                // Origen
                DropdownButtonFormField<Origin>(
                  value: _selectedOrigin,
                  hint: const Text("Seleccione un origen"),
                  decoration: const InputDecoration(
                    labelText: "Origen",
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _origins
                          .map(
                            (o) =>
                                DropdownMenuItem(value: o, child: Text(o.name)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedOrigin = value),
                  validator:
                      (value) => value == null ? "Seleccione un origen" : null,
                ),
                const SizedBox(height: 10),

                // Raza
                DropdownButtonFormField<Breed>(
                  value: _selectedBreed,
                  hint: const Text("Seleccione una raza"),
                  decoration: const InputDecoration(
                    labelText: "Raza",
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _breeds
                          .map(
                            (b) =>
                                DropdownMenuItem(value: b, child: Text(b.name)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedBreed = value),
                  validator:
                      (value) => value == null ? "Seleccione una raza" : null,
                ),
                const SizedBox(height: 10),

                // Empresa
                DropdownButtonFormField<Company>(
                  value: _selectedCompany,
                  hint: const Text("Seleccione una empresa"),
                  decoration: const InputDecoration(
                    labelText: "Empresa",
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _companies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                "Empresa #${c.id} - ${c.companyName}",
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => _selectedCompany = value),
                  validator:
                      (value) =>
                          value == null ? "Seleccione una empresa" : null,
                ),
                const SizedBox(height: 10),

                // Fecha
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Fecha",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _dateController.text.isNotEmpty
                              ? DateTime.tryParse(_dateController.text) ??
                                  DateTime.now()
                              : DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateController.text =
                            picked.toIso8601String().split("T").first;
                      });
                    }
                  },
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? "Seleccione una fecha"
                              : null,
                ),
                const SizedBox(height: 10),

                // Sincronizado
                SwitchListTile(
                  title: const Text("Sincronizado"),
                  value: _sync == 1,
                  onChanged: (value) => setState(() => _sync = value ? 1 : 0),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          onPressed: _saveForm,
          icon: const Icon(Icons.save),
          label: Text(isEditing ? "Actualizar" : "Guardar"),
        ),
      ],
    );
  }
}
