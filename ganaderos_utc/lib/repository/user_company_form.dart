import 'package:flutter/material.dart';
import '../../models/user_models.dart';
import '../../repository/user_company_repository.dart';

class UserCompanyForm extends StatefulWidget {
  final User? user;
  final int companyId; // empresa fija
  final VoidCallback onSave;

  const UserCompanyForm({
    super.key,
    this.user,
    required this.companyId,
    required this.onSave,
  });

  @override
  State<UserCompanyForm> createState() => _UserCompanyFormState();
}

class _UserCompanyFormState extends State<UserCompanyForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dniController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = "user";
  bool _isSaving = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _nameController.text = widget.user!.name;
      _lastNameController.text = widget.user!.lastName;
      _emailController.text = widget.user!.email ?? '';
      _dniController.text = widget.user!.dni ?? '';
      _usernameController.text = widget.user!.username ?? '';
      _selectedRole = widget.user!.role ?? 'user';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = User(
        id: widget.user?.id,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        dni: _dniController.text.trim(),
        role: _selectedRole,
        username: _usernameController.text.trim(),
        // password se maneja aparte para no forzar update
        companyId: widget.companyId, // fijo
      );

      bool ok = false;

      if (!_isEditing) {
        final created = await UserCompanyRepository.createForCompany(
          user,
          password: _passwordController.text.trim(),
        );
        ok = created != null;
      } else {
        final wantsPassword = _passwordController.text.trim().isNotEmpty;

        ok = await UserCompanyRepository.updateForCompany(
          user,
          updatePassword: wantsPassword,
          password: _passwordController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (ok) {
        widget.onSave();
        ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(content: Text("Usuario guardado exitosamente")),
            )
            .closed
            .then((_) {
              if (mounted) Navigator.pop(context);
            });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo guardar el usuario")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(_isEditing ? 'Editar Usuario' : 'Agregar Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(_nameController, 'Nombre', Icons.person),
                const SizedBox(height: 8),
                _tf(_lastNameController, 'Apellido', Icons.person_outline),
                const SizedBox(height: 8),
                _tf(
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
                _tf(_dniController, 'DNI', Icons.badge),
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
                    DropdownMenuItem(value: 'user', child: Text('Usuario')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v ?? 'user'),
                  validator: (v) => v == null ? 'Seleccione rol' : null,
                ),
                const SizedBox(height: 8),
                _tf(_usernameController, 'Username', Icons.account_circle),
                const SizedBox(height: 8),
                _tf(
                  _passwordController,
                  _isEditing ? 'Nueva contraseña (opcional)' : 'Contraseña',
                  Icons.lock,
                  obscureText: true,
                  validator: (v) {
                    if (!_isEditing && (v == null || v.isEmpty)) {
                      return 'Ingrese contraseña';
                    }
                    return null;
                  },
                ),

                // Empresa fija (solo informativo)
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Empresa fija: ID ${widget.companyId}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save),
          label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }

  Widget _tf(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
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
