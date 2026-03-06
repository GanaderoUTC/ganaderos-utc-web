import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repositories/user_repository.dart';
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

  String? _validateName(String? v, {String label = "Campo"}) {
    if (v == null || v.trim().isEmpty) return '$label obligatorio';
    final s = v.trim();
    if (s.length < 2) return '$label muy corto';
    if (s.length > 40) return '$label muy largo';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese email';
    final s = v.trim();
    // validación simple (sin meter regex pesado)
    if (!s.contains('@') || !s.contains('.')) return 'Email inválido';
    if (s.length > 80) return 'Email muy largo';
    return null;
  }

  String? _validateDni(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    final s = v.trim();
    // Ajusta según tu país/regla: aquí 8-13 y solo números
    if (!RegExp(r'^\d{8,13}$').hasMatch(s)) return 'DNI inválido';
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username obligatorio';
    final s = v.trim();
    if (s.contains(' ')) return 'No use espacios';
    if (s.length < 3) return 'Username muy corto';
    if (s.length > 20) return 'Username muy largo';
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(s)) {
      return 'Solo letras, números, . _ -';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final s = (v ?? '').trim();

    if (!_isEditing) {
      if (s.isEmpty) return 'Ingrese contraseña';
      if (s.length < 6) return 'Mínimo 6 caracteres';
      if (s.length > 50) return 'Contraseña muy larga';
      return null;
    }

    // editando: es opcional, pero si la escribió, validamos
    if (s.isEmpty) return null;
    if (s.length < 6) return 'Mínimo 6 caracteres';
    if (s.length > 50) return 'Contraseña muy larga';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final emailText = _emailController.text.trim();
      final dniText = _dniController.text.trim();
      final username = _usernameController.text.trim();
      final passText = _passwordController.text.trim();

      // ✅ si están vacíos, mejor null (evita pisar con "")
      final String? email = emailText.isEmpty ? null : emailText;
      final String? dni = dniText.isEmpty ? null : dniText;

      final user = User(
        id: widget.user?.id,
        name: name,
        lastName: lastName,
        email: email,
        dni: dni,
        role: _selectedRole,
        username: username,
        companyId: widget.companyId, // fijo
      );

      // ✅ REGLA OPCIONAL: 1 admin por empresa (si la estás usando)
      if (_selectedRole == 'admin' && !_isEditing) {
        final exists = await UserRepository.companyHasAdmin(widget.companyId);
        if (exists) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ya existe un admin en esta empresa")),
          );
          return;
        }
      }

      bool ok = false;

      if (!_isEditing) {
        final created = await UserCompanyRepository.createForCompany(
          user,
          password: passText,
        );
        ok = created != null;
      } else {
        final wantsPassword = passText.isNotEmpty;

        ok = await UserCompanyRepository.updateForCompany(
          user,
          updatePassword: wantsPassword,
          password: passText,
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
                _tf(
                  _nameController,
                  'Nombre',
                  Icons.person,
                  validator: (v) => _validateName(v, label: "Nombre"),
                ),
                const SizedBox(height: 8),
                _tf(
                  _lastNameController,
                  'Apellido',
                  Icons.person_outline,
                  validator: (v) => _validateName(v, label: "Apellido"),
                ),
                const SizedBox(height: 8),
                _tf(
                  _emailController,
                  'Email',
                  Icons.email,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 8),
                _tf(
                  _dniController,
                  'DNI',
                  Icons.badge,
                  validator: _validateDni,
                ),
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
                _tf(
                  _usernameController,
                  'Username',
                  Icons.account_circle,
                  validator: _validateUsername,
                ),
                const SizedBox(height: 8),
                _tf(
                  _passwordController,
                  _isEditing ? 'Nueva contraseña (opcional)' : 'Contraseña',
                  Icons.lock,
                  obscureText: true,
                  validator: _validatePassword,
                ),

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
