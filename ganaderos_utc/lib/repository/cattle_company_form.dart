import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repository/cattle_company_repository.dart';
import '../../models/cattle_models.dart';
import '../../models/categories_models.dart';
import '../../models/origin_models.dart';
import '../../models/breed_models.dart';
import '../../models/company_models.dart';
import '../../repositories/categories_repository.dart';
import '../../repositories/origin_repository.dart';
import '../../repositories/breeds_repository.dart';
import '../../repositories/company_repository.dart';
import '../../utils/validators.dart';

class CattleCompanyForm extends StatefulWidget {
  final Cattle? cattle;
  final int? initialCompanyId;
  final Function onSave;

  const CattleCompanyForm({
    super.key,
    this.cattle,
    this.initialCompanyId,
    required this.onSave,
  });

  @override
  State<CattleCompanyForm> createState() => _CattleCompanyFormState();
}

class _CattleCompanyFormState extends State<CattleCompanyForm> {
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

  bool get isEditing => widget.cattle != null;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (isEditing) {
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
    final categories = await CategoriesRepository.getAll();
    final origins = await OriginRepository.getAll();
    final breeds = await BreedsRepository.getAll();
    final companies = await CompanyRepository().getAll();

    Company? selectedCompany;

    if (companies.isNotEmpty) {
      if (isEditing && widget.cattle != null) {
        selectedCompany = companies.firstWhere(
          (x) => x.id == widget.cattle!.companyId,
          orElse: () => companies.first,
        );
      } else if (widget.initialCompanyId != null) {
        selectedCompany = companies.firstWhere(
          (x) => x.id == widget.initialCompanyId,
          orElse: () => companies.first,
        );
      } else {
        selectedCompany = companies.first;
      }
    } else {
      selectedCompany = null;
    }

    setState(() {
      _categories = categories;
      _origins = origins;
      _breeds = breeds;
      _companies = companies;

      _selectedCategory =
          isEditing
              ? categories.firstWhere(
                (x) => x.id == widget.cattle!.categoryId,
                orElse: () => categories.first,
              )
              : null;

      _selectedOrigin =
          isEditing
              ? origins.firstWhere(
                (x) => x.id == widget.cattle!.originId,
                orElse: () => origins.first,
              )
              : null;

      _selectedBreed =
          isEditing
              ? breeds.firstWhere(
                (x) => x.id == widget.cattle!.breedId,
                orElse: () => breeds.first,
              )
              : null;

      _selectedCompany = selectedCompany;
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ seguridad extra: empresa obligatoria al crear
    if (!isEditing &&
        (_selectedCompany?.id == null || _selectedCompany!.id == 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Seleccione una empresa")));
      return;
    }

    // ✅ peso válido (por si intentan "0" o algo raro)
    final weightStr = _weightController.text.trim();
    final weight = double.tryParse(weightStr);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese un peso válido mayor a 0")),
      );
      return;
    }

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
      weight: weight,
      urlImage: null,
      companyId: _selectedCompany?.id ?? (widget.cattle?.companyId ?? 0),
      sync: _sync,
    );

    try {
      if (isEditing) {
        await CattleCompanyRepository.updateForCompany(newCattle);
      } else {
        await CattleCompanyRepository.createForCompany(newCattle);
      }
      if (!mounted) return;
      widget.onSave();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al guardar")));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _field(
                  "Código",
                  _codeController,
                  validator: (v) {
                    final req = Validators.requiredField(v);
                    if (req != null) return req;
                    final s = v!.trim();
                    // código ganado: letras/números/guion, 2-25
                    if (!RegExp(r'^[A-Za-z0-9_-]{2,25}$').hasMatch(s)) {
                      return "Código inválido (solo letras/números/-/_)";
                    }
                    return null;
                  },
                ),
                _field(
                  "Nombre",
                  _nameController,
                  validator: (v) => Validators.name(v, msg: "Nombre inválido"),
                ),
                _field(
                  "Registro",
                  _registerController,
                  validator: (v) {
                    final req = Validators.requiredField(v);
                    if (req != null) return req;
                    final s = v!.trim();
                    // registro: letras/números/guiones/espacios, 2-40
                    if (!RegExp(
                      r'^[A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ _-]{2,40}$',
                    ).hasMatch(s)) {
                      return "Registro inválido";
                    }
                    return null;
                  },
                ),
                _field(
                  "Peso (kg)",
                  _weightController,
                  numeric: true,
                  validator: (v) {
                    final req = Validators.requiredField(v);
                    if (req != null) return req;
                    final value = double.tryParse(v!.trim());
                    if (value == null) return "Ingrese un número válido";
                    if (value <= 0) return "El peso debe ser mayor a 0";
                    if (value > 2000) return "Peso fuera de rango";
                    return null;
                  },
                ),
                _genderField(),
                _dropdown<Category>(
                  "Categoría",
                  _categories,
                  _selectedCategory,
                  (v) => setState(() => _selectedCategory = v),
                ),
                _dropdown<Origin>(
                  "Origen",
                  _origins,
                  _selectedOrigin,
                  (v) => setState(() => _selectedOrigin = v),
                ),
                _dropdown<Breed>(
                  "Raza",
                  _breeds,
                  _selectedBreed,
                  (v) => setState(() => _selectedBreed = v),
                ),
                if (!isEditing) _companySelector(),
                _datePicker(),
                SwitchListTile(
                  title: const Text("Sincronizado"),
                  value: _sync == 1,
                  onChanged: (v) => setState(() => _sync = v ? 1 : 0),
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

  // --------- UI HELPERS ---------

  Widget _field(
    String label,
    TextEditingController controller, {
    bool numeric = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType:
            numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator ?? (v) => Validators.requiredField(v),
      ),
    );
  }

  Widget _genderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<int>(
        value: _selectedGender,
        decoration: const InputDecoration(
          labelText: "Género",
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 1, child: Text("Macho")),
          DropdownMenuItem(value: 2, child: Text("Hembra")),
        ],
        onChanged: (v) => setState(() => _selectedGender = v),
        validator: (v) => v == null ? "Seleccione un género" : null,
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    List<T> list,
    T? selected,
    Function(T?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items:
            list.map((e) {
              final text = (e as dynamic).name ?? e.toString();
              return DropdownMenuItem(value: e, child: Text(text));
            }).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "Seleccione $label" : null,
      ),
    );
  }

  Widget _companySelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<Company>(
        value: _selectedCompany,
        decoration: const InputDecoration(
          labelText: "Empresa",
          border: OutlineInputBorder(),
        ),
        items:
            _companies
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text("${c.companyName} (ID: ${c.id})"),
                  ),
                )
                .toList(),
        onChanged: (value) => setState(() => _selectedCompany = value),
        validator: (v) => v == null ? "Seleccione una empresa" : null,
      ),
    );
  }

  Widget _datePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
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
                DateTime.tryParse(_dateController.text) ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _dateController.text = picked.toIso8601String().split("T").first;
            });
          }
        },
        validator:
            (v) => v == null || v.isEmpty ? "Seleccione una fecha" : null,
      ),
    );
  }
}
