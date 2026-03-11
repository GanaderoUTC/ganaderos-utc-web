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
  final VoidCallback? onSave;

  const CattleCompanyForm({
    super.key,
    this.cattle,
    this.initialCompanyId,
    this.onSave,
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
  bool _saving = false;

  bool get isEditing => widget.cattle != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadDropdownData();
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

  void _loadInitialData() {
    if (isEditing) {
      final c = widget.cattle!;
      _codeController.text = _normalizeCode(c.code);
      _nameController.text = _capitalizeFirst(c.name);
      _registerController.text = _capitalizeFirst(c.register);
      _weightController.text = _formatWeight(c.weight);
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
    }

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _origins = origins;
      _breeds = breeds;
      _companies = companies;

      _selectedCategory =
          isEditing && categories.isNotEmpty
              ? categories.firstWhere(
                (x) => x.id == widget.cattle!.categoryId,
                orElse: () => categories.first,
              )
              : null;

      _selectedOrigin =
          isEditing && origins.isNotEmpty
              ? origins.firstWhere(
                (x) => x.id == widget.cattle!.originId,
                orElse: () => origins.first,
              )
              : null;

      _selectedBreed =
          isEditing && breeds.isNotEmpty
              ? breeds.firstWhere(
                (x) => x.id == widget.cattle!.breedId,
                orElse: () => breeds.first,
              )
              : null;

      _selectedCompany = selectedCompany;
    });
  }

  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _normalizeText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _normalizeCode(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  String _formatWeight(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  bool _sameWeight(double a, double b) {
    return (a - b).abs() < 0.0001;
  }

  int _currentCompanyId() {
    return _selectedCompany?.id ??
        widget.initialCompanyId ??
        widget.cattle?.companyId ??
        0;
  }

  String? _validateCode(String? value) {
    final req = Validators.requiredField(value);
    if (req != null) return req;

    final s = value!.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{2,25}$').hasMatch(s)) {
      return "Código inválido (solo letras, números, - y _)";
    }
    return null;
  }

  String? _validateName(String? value) {
    final req = Validators.requiredField(value);
    if (req != null) return req;

    final s = value!.trim();
    if (s.length < 2) return "Nombre muy corto";
    if (s.length > 60) return "Nombre muy largo (máx. 60)";
    return Validators.name(s, msg: "Nombre inválido");
  }

  String? _validateRegister(String? value) {
    final req = Validators.requiredField(value);
    if (req != null) return req;

    final s = value!.trim();
    if (!RegExp(r'^[A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ _-]{2,40}$').hasMatch(s)) {
      return "Registro inválido";
    }
    return null;
  }

  String? _validateWeight(String? value) {
    final req = Validators.requiredField(value);
    if (req != null) return req;

    final weight = double.tryParse(value!.trim());
    if (weight == null) return "Ingrese un número válido";
    if (weight <= 0) return "El peso debe ser mayor a 0";
    if (weight > 2000) return "Peso fuera de rango";
    return null;
  }

  Future<List<Cattle>> _getCattleForValidation(int companyId) async {
    try {
      return await CattleCompanyRepository.getAllByCompany(companyId);
    } catch (e) {
      debugPrint("Error al obtener ganado para validación: $e");
      return [];
    }
  }

  Future<bool> _isDuplicateCode(String code) async {
    final companyId = _currentCompanyId();
    final cattleList = await _getCattleForValidation(companyId);
    final newCode = _normalizeCode(code);

    for (final item in cattleList) {
      final sameId = widget.cattle?.id != null && item.id == widget.cattle!.id;
      if (sameId) continue;

      if (_normalizeCode(item.code) == newCode) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateName(String name) async {
    final companyId = _currentCompanyId();
    final cattleList = await _getCattleForValidation(companyId);
    final newName = _normalizeText(name);

    for (final item in cattleList) {
      final sameId = widget.cattle?.id != null && item.id == widget.cattle!.id;
      if (sameId) continue;

      if (_normalizeText(item.name) == newName) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateRegister(String register) async {
    final companyId = _currentCompanyId();
    final cattleList = await _getCattleForValidation(companyId);
    final newRegister = _normalizeText(register);

    for (final item in cattleList) {
      final sameId = widget.cattle?.id != null && item.id == widget.cattle!.id;
      if (sameId) continue;

      if (_normalizeText(item.register) == newRegister) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateWeight(double weight) async {
    final companyId = _currentCompanyId();
    final cattleList = await _getCattleForValidation(companyId);

    for (final item in cattleList) {
      final sameId = widget.cattle?.id != null && item.id == widget.cattle!.id;
      if (sameId) continue;

      if (_sameWeight(item.weight, weight)) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateDate(String date) async {
    final companyId = _currentCompanyId();
    final cattleList = await _getCattleForValidation(companyId);
    final newDate = date.trim();

    for (final item in cattleList) {
      final sameId = widget.cattle?.id != null && item.id == widget.cattle!.id;
      if (sameId) continue;

      if (item.date.trim() == newDate) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateCompleteRecord({
    required String code,
    required String name,
    required String register,
    required double weight,
    required int categoryId,
    required int originId,
    required int breedId,
    required int gender,
    required int companyId,
    required String date,
  }) async {
    final cattleList = await _getCattleForValidation(companyId);

    for (final item in cattleList) {
      final sameId = widget.cattle?.id != null && item.id == widget.cattle!.id;
      if (sameId) continue;

      final sameRecord =
          _normalizeCode(item.code) == _normalizeCode(code) &&
          _normalizeText(item.name) == _normalizeText(name) &&
          _normalizeText(item.register) == _normalizeText(register) &&
          _sameWeight(item.weight, weight) &&
          item.categoryId == categoryId &&
          item.originId == originId &&
          item.breedId == breedId &&
          item.gender == gender &&
          item.companyId == companyId &&
          item.date.trim() == date.trim();

      if (sameRecord) return true;
    }

    return false;
  }

  Future<void> _saveForm() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showError("Seleccione una categoría");
      return;
    }

    if (_selectedOrigin == null) {
      _showError("Seleccione un origen");
      return;
    }

    if (_selectedBreed == null) {
      _showError("Seleccione una raza");
      return;
    }

    if (_selectedGender == null) {
      _showError("Seleccione un género");
      return;
    }

    if (_selectedCompany == null ||
        _selectedCompany!.id == null ||
        _selectedCompany!.id == 0) {
      _showError("Seleccione una empresa");
      return;
    }

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      _showError("Ingrese un peso válido mayor a 0");
      return;
    }

    final formattedCode = _normalizeCode(_codeController.text);
    final formattedName = _capitalizeFirst(_nameController.text);
    final formattedRegister = _capitalizeFirst(_registerController.text);
    final formattedDate = _dateController.text.trim();

    setState(() => _saving = true);

    try {
      final duplicateCode = await _isDuplicateCode(formattedCode);
      if (duplicateCode) {
        _showError("Ya existe un ganado con ese código en esta empresa");
        if (mounted) setState(() => _saving = false);
        return;
      }

      final duplicateName = await _isDuplicateName(formattedName);
      if (duplicateName) {
        _showError("Ya existe un ganado con ese nombre en esta empresa");
        if (mounted) setState(() => _saving = false);
        return;
      }

      final duplicateRegister = await _isDuplicateRegister(formattedRegister);
      if (duplicateRegister) {
        _showError("Ya existe un ganado con ese registro en esta empresa");
        if (mounted) setState(() => _saving = false);
        return;
      }

      final duplicateWeight = await _isDuplicateWeight(weight);
      if (duplicateWeight) {
        _showError("Ya existe un ganado con ese peso en esta empresa");
        if (mounted) setState(() => _saving = false);
        return;
      }

      final duplicateDate = await _isDuplicateDate(formattedDate);
      if (duplicateDate) {
        _showError(
          "Ya existe un ganado registrado con esa fecha en esta empresa",
        );
        if (mounted) setState(() => _saving = false);
        return;
      }

      final duplicateFullRecord = await _isDuplicateCompleteRecord(
        code: formattedCode,
        name: formattedName,
        register: formattedRegister,
        weight: weight,
        categoryId: _selectedCategory!.id ?? 0,
        originId: _selectedOrigin!.id ?? 0,
        breedId: _selectedBreed!.id ?? 0,
        gender: _selectedGender ?? 0,
        companyId: _selectedCompany!.id ?? 0,
        date: formattedDate,
      );

      if (duplicateFullRecord) {
        _showError("Ya existe un registro de ganado con los mismos datos");
        if (mounted) setState(() => _saving = false);
        return;
      }

      final newCattle = Cattle(
        id: widget.cattle?.id,
        code: formattedCode,
        name: formattedName,
        register: formattedRegister,
        categoryId: _selectedCategory?.id ?? 0,
        gender: _selectedGender ?? 0,
        originId: _selectedOrigin?.id ?? 0,
        breedId: _selectedBreed?.id ?? 0,
        date: formattedDate,
        weight: weight,
        urlImage: null,
        companyId: _selectedCompany?.id ?? (widget.cattle?.companyId ?? 0),
        sync: _sync,
      );

      if (isEditing) {
        await CattleCompanyRepository.updateForCompany(newCattle);
      } else {
        await CattleCompanyRepository.createForCompany(newCattle);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? "Ganado actualizado correctamente"
                : "Ganado registrado correctamente",
          ),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSave?.call();
      Navigator.pop(context, true);
    } catch (e) {
      _showError("Error al guardar: $e");
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        isEditing ? "Editar Ganado" : "Agregar Ganado",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field("Código", _codeController, validator: _validateCode),
                _field("Nombre", _nameController, validator: _validateName),
                _field(
                  "Registro",
                  _registerController,
                  validator: _validateRegister,
                ),
                _field(
                  "Peso (kg)",
                  _weightController,
                  numeric: true,
                  validator: _validateWeight,
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
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Sincronizado"),
                  value: _sync == 1,
                  onChanged:
                      _saving ? null : (v) => setState(() => _sync = v ? 1 : 0),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Cancelar"),
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
          label: Text(isEditing ? "Actualizar" : "Guardar"),
        ),
      ],
    );
  }

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
        onChanged: _saving ? null : (v) => setState(() => _selectedGender = v),
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
              return DropdownMenuItem(
                value: e,
                child: Text(_capitalizeFirst(text.toString())),
              );
            }).toList(),
        onChanged: _saving ? null : onChanged,
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
                    child: Text(
                      "${_capitalizeFirst(c.companyName)} (ID: ${c.id})",
                    ),
                  ),
                )
                .toList(),
        onChanged:
            _saving
                ? null
                : (value) => setState(() => _selectedCompany = value),
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
        onTap:
            _saving
                ? null
                : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(_dateController.text) ??
                        DateTime.now(),
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
            (v) => v == null || v.isEmpty ? "Seleccione una fecha" : null,
      ),
    );
  }
}
