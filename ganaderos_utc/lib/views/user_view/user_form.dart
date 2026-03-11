// ignore_for_file: file_names
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:ganaderos_utc/repository/user_company_repository.dart';

import '../../models/user_models.dart';
import '../../models/company_models.dart';

import '../../repositories/user_repository.dart';
import '../../repositories/company_repository.dart';
import '../../utils/validators.dart';

class UserForm extends StatefulWidget {
  final User? user;

  const UserForm({super.key, this.user});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();

  final UserRepository _repository = UserRepository();

  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final dniController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  List<Company> companies = [];
  Company? selectedCompany;

  final String selectedRole = "user";

  bool isLoading = true;
  bool isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  String _toTitleCase(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;

    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _normalize(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Future<void> _init() async {
    if (widget.user != null) {
      nameController.text = _toTitleCase(widget.user!.name);
      lastNameController.text = _toTitleCase(widget.user!.lastName);
      emailController.text = (widget.user!.email ?? "").trim().toLowerCase();
      dniController.text = widget.user!.dni ?? "";
      usernameController.text = widget.user!.username ?? "";
    }

    try {
      final repo = CompanyRepository();
      final data = await repo.getAll();

      companies = data;

      if (widget.user?.companyId != null) {
        selectedCompany = companies.firstWhere(
          (c) => c.id == widget.user!.companyId,
          orElse: () => companies.first,
        );
      } else if (companies.isNotEmpty) {
        selectedCompany = companies.first;
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cargando empresas: $e")));
    }
  }

  Future<bool> _isDuplicateName(String value) async {
    final users = await UserRepository.getAll();
    final newValue = _normalize(value);

    for (final user in users) {
      final sameId = widget.user?.id != null && user.id == widget.user!.id;
      if (sameId) continue;

      if (_normalize(user.name) == newValue) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateLastName(String value) async {
    final users = await UserRepository.getAll();
    final newValue = _normalize(value);

    for (final user in users) {
      final sameId = widget.user?.id != null && user.id == widget.user!.id;
      if (sameId) continue;

      if (_normalize(user.lastName) == newValue) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateEmail(String value) async {
    final users = await UserRepository.getAll();
    final newValue = _normalize(value);

    for (final user in users) {
      final sameId = widget.user?.id != null && user.id == widget.user!.id;
      if (sameId) continue;

      if (_normalize(user.email ?? '') == newValue) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateDni(String value) async {
    final users = await UserRepository.getAll();
    final newValue = value.trim();

    for (final user in users) {
      final sameId = widget.user?.id != null && user.id == widget.user!.id;
      if (sameId) continue;

      if ((user.dni ?? '').trim() == newValue) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCompany == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Seleccione empresa")));
      return;
    }

    setState(() => isSaving = true);

    try {
      final name = _toTitleCase(nameController.text);
      final lastName = _toTitleCase(lastNameController.text);
      final email = emailController.text.trim().toLowerCase();
      final dni = dniController.text.trim();
      final username = usernameController.text.trim();

      final existsName = await _isDuplicateName(name);
      if (existsName) {
        if (!mounted) return;
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya existe un usuario con ese nombre")),
        );
        return;
      }

      final existsLastName = await _isDuplicateLastName(lastName);
      if (existsLastName) {
        if (!mounted) return;
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ya existe un usuario con ese apellido"),
          ),
        );
        return;
      }

      final existsEmail = await _isDuplicateEmail(email);
      if (existsEmail) {
        if (!mounted) return;
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya existe un usuario con ese correo")),
        );
        return;
      }

      final existsDni = await _isDuplicateDni(dni);
      if (existsDni) {
        if (!mounted) return;
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya existe un usuario con esa cédula")),
        );
        return;
      }

      final user = User(
        id: widget.user?.id,
        name: name,
        lastName: lastName,
        email: email,
        dni: dni,
        role: selectedRole,
        username: username,
        password:
            passwordController.text.isEmpty
                ? null
                : passwordController.text.trim(),
        companyId: selectedCompany!.id,
      );

      bool ok;

      if (widget.user == null) {
        final created = await _repository.create(user);
        ok = created != null;
      } else {
        ok = await _repository.update(
          user,
          updatePassword: passwordController.text.isNotEmpty,
        );
      }

      setState(() => isSaving = false);

      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No se pudo guardar")));
      }
    } catch (e) {
      setState(() => isSaving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    dniController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? "Editar Usuario" : "Registrar Usuario",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                _input(
                  nameController,
                  "Nombre",
                  Icons.person,
                  validator: Validators.name,
                ),

                _input(
                  lastNameController,
                  "Apellido",
                  Icons.person_outline,
                  validator: Validators.name,
                ),

                _input(
                  emailController,
                  "Correo",
                  Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),

                _input(
                  dniController,
                  "Cédula",
                  Icons.badge,
                  keyboardType: TextInputType.number,
                  validator: Validators.cedulaEC,
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<Company>(
                  value: selectedCompany,
                  decoration: const InputDecoration(
                    labelText: "Empresa",
                    border: OutlineInputBorder(),
                  ),
                  items:
                      companies.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c.companyName),
                        );
                      }).toList(),
                  onChanged: (v) {
                    setState(() => selectedCompany = v);
                  },
                ),

                const SizedBox(height: 10),

                _input(
                  usernameController,
                  "Usuario",
                  Icons.account_circle,
                  validator: Validators.username,
                ),

                _input(
                  passwordController,
                  isEditing ? "Nueva contraseña (opcional)" : "Contraseña",
                  Icons.lock,
                  obscure: _obscurePassword,
                  isPassword: true,
                  validator: (v) {
                    if (!isEditing) {
                      return Validators.passwordStrong(v);
                    }
                    if (v == null || v.isEmpty) return null;
                    return Validators.passwordStrong(v);
                  },
                ),

                const SizedBox(height: 8),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tipo de usuario fijo: Usuario",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text("Cancelar"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                        ),
                        child:
                            isSaving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(isEditing ? "Actualizar" : "Guardar"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                  : null,
        ),
      ),
    );
  }
}
