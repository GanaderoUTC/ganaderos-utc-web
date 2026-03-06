// ignore_for_file: file_names
import 'package:flutter/material.dart';
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

  String selectedRole = "user";

  bool isLoading = true;
  bool isSaving = false;

  bool checkingAdmin = false;
  bool companyHasAdmin = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.user != null) {
      nameController.text = widget.user!.name;
      lastNameController.text = widget.user!.lastName;
      emailController.text = widget.user!.email ?? "";
      dniController.text = widget.user!.dni ?? "";
      usernameController.text = widget.user!.username ?? "";
      selectedRole = widget.user!.role ?? "user";
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

      await _checkAdmin();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cargando empresas: $e")));
    }
  }

  Future<void> _checkAdmin() async {
    if (selectedCompany == null) return;

    setState(() => checkingAdmin = true);

    try {
      final users = await UserCompanyRepository.getAllByCompany(
        selectedCompany!.id!,
      );

      final admins = users.where((u) => (u.role ?? "user") == "admin");

      bool hasAdmin = admins.isNotEmpty;

      if (widget.user != null &&
          widget.user!.role == "admin" &&
          admins.length == 1 &&
          admins.first.id == widget.user!.id) {
        hasAdmin = false;
      }

      companyHasAdmin = hasAdmin;

      if (companyHasAdmin && selectedRole == "admin") {
        selectedRole = "user";
      }
    } catch (_) {}

    setState(() => checkingAdmin = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCompany == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Seleccione empresa")));
      return;
    }

    if (selectedRole == "admin" && companyHasAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Esta empresa ya tiene administrador")),
      );
      return;
    }

    setState(() => isSaving = true);

    final user = User(
      id: widget.user?.id,
      name: nameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      dni: dniController.text.trim(),
      role: selectedRole,
      username: usernameController.text.trim(),
      password:
          passwordController.text.isEmpty
              ? null
              : passwordController.text.trim(),
      companyId: selectedCompany!.id,
    );

    try {
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
                  validator: Validators.email,
                ),

                _input(
                  dniController,
                  "Cédula",
                  Icons.badge,
                  validator: Validators.cedulaEC,
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: "Rol",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: "admin",
                      enabled: !companyHasAdmin,
                      child: Text(
                        companyHasAdmin
                            ? "Administrador (ocupado)"
                            : "Administrador",
                      ),
                    ),

                    const DropdownMenuItem(
                      value: "user",
                      child: Text("Usuario"),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == "admin" && companyHasAdmin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Esta empresa ya tiene administrador"),
                        ),
                      );
                      return;
                    }

                    setState(() => selectedRole = v!);
                  },
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
                  onChanged: (v) async {
                    selectedCompany = v;

                    await _checkAdmin();

                    setState(() {});
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
                  obscure: true,
                  validator: (v) {
                    if (!isEditing) {
                      return Validators.passwordStrong(v);
                    }
                    if (v == null || v.isEmpty) return null;
                    return Validators.passwordStrong(v);
                  },
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
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
