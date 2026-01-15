import 'package:flutter/material.dart';
import '../../models/user_models.dart';
import '../../models/company_models.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/company_repository.dart';

class UserForm extends StatefulWidget {
  final User? user;

  /// Nota: ya no pedimos onSave aquí. El diálogo devolverá `true` si guardó OK.
  const UserForm({super.key, this.user, required void Function() onSave});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _repository = UserRepository();

  // Controllers
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dniController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Company> _companies = [];
  Company? _selectedCompany;
  String _selectedRole = "user";
  bool _isLoading = true;
  bool _isSaving = false; // para deshabilitar botón mientras guarda

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  Future<void> _initForm() async {
    // si vienen datos para editar, precargar
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _lastNameController.text = widget.user!.lastName;
      _emailController.text = widget.user!.email ?? '';
      _dniController.text = widget.user!.dni ?? '';
      _usernameController.text = widget.user!.username ?? '';
      _selectedRole = widget.user!.role ?? 'user';
      _selectedCompany = widget.user!.company;
    }

    // cargar empresas (puede tardar)
    try {
      final repo = CompanyRepository();
      final list = await repo.getAll();

      if (!mounted) return;

      _companies =
          list.isNotEmpty
              ? list
              : [
                Company(
                  id: 0,
                  companyCode: '',
                  companyName: 'Sin empresa',
                  responsible: '',
                  dni: '',
                  contact: '',
                  email: '',
                  address: '',
                  surface: 0,
                  fertilityPercentage: 0,
                  birthRate: 0,
                  mortalityRate: 0,
                  weaningPercentage: 0,
                  litersOfMilk: 0,
                ),
              ];

      // si tenemos company del user, buscarla en la lista; si no existe seleccionar la primera
      if (_selectedCompany != null) {
        _selectedCompany = _companies.firstWhere(
          (c) => c.id == _selectedCompany!.id,
          orElse: () => _companies.first,
        );
      } else {
        _selectedCompany = _companies.first;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando empresas: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione una empresa')));
      return;
    }

    setState(() => _isSaving = true);

    final user = User(
      id: widget.user?.id,
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      dni: _dniController.text.trim(),
      role: _selectedRole,
      username: _usernameController.text.trim(),
      password:
          _passwordController.text.isNotEmpty
              ? _passwordController.text.trim()
              : null,
      companyId: _selectedCompany!.id,
      company: _selectedCompany,
    );

    try {
      bool ok;
      if (widget.user == null) {
        final created = await _repository.create(user);
        ok = created != null;
      } else {
        ok = await _repository.update(
          user,
          updatePassword: _passwordController.text.isNotEmpty,
        );
      }

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (ok) {
        // cerramos el diálogo devolviendo true (padre detectará y refrescará)
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el usuario')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(isEditing ? 'Editar Usuario' : 'Agregar Usuario'),
      content:
          _isLoading
              ? const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
              : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          _nameController,
                          'Nombre',
                          Icons.person,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _lastNameController,
                          'Apellido',
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _emailController,
                          'Email',
                          Icons.email,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingrese email';
                            if (!v.contains('@')) return 'Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(_dniController, 'DNI', Icons.badge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            prefixIcon: Icon(Icons.admin_panel_settings),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Administrador'),
                            ),
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('Usuario'),
                            ),
                          ],
                          onChanged:
                              (v) =>
                                  setState(() => _selectedRole = v ?? 'user'),
                          validator: (v) => v == null ? 'Seleccione rol' : null,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _usernameController,
                          'Username',
                          Icons.account_circle,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _passwordController,
                          isEditing ? 'Nueva contraseña' : 'Contraseña',
                          Icons.lock,
                          obscureText: true,
                          validator: (v) {
                            if (!isEditing && (v == null || v.isEmpty)) {
                              return 'Ingrese contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Company>(
                          value: _selectedCompany,
                          decoration: const InputDecoration(
                            labelText: 'Empresa',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _companies
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.companyName),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _selectedCompany = v),
                          validator:
                              (v) => v == null ? 'Seleccione empresa' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save),
          label: Text(isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
    );
  }
}
