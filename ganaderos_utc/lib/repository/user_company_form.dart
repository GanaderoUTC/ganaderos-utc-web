import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repositories/user_repository.dart';
import '../../models/user_models.dart';
import '../../repository/user_company_repository.dart';

class UserCompanyForm extends StatefulWidget {
  final User? user;
  final int companyId;
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

  final String _fixedRole = "user";
  bool _isSaving = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _nameController.text = _toTitleCase(widget.user!.name);
      _lastNameController.text = _toTitleCase(widget.user!.lastName);
      _emailController.text = (widget.user!.email ?? '').trim().toLowerCase();
      _dniController.text = (widget.user!.dni ?? '').trim();
      _usernameController.text = (widget.user!.username ?? '').trim();
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

  String? _validateName(String? v, {String label = "Campo"}) {
    if (v == null || v.trim().isEmpty) return '$label obligatorio';

    final s = v.trim();

    if (s.length < 2) return '$label muy corto';
    if (s.length > 40) return '$label muy largo';

    final ok = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ\s]+$").hasMatch(s);
    if (!ok) return '$label inválido';

    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese email';

    final s = v.trim().toLowerCase();

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(s)) return 'Email inválido';
    if (s.length > 80) return 'Email muy largo';

    return null;
  }

  String? _validateDni(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';

    final s = v.trim();

    if (!RegExp(r'^\d{10}$').hasMatch(s)) {
      return 'La cédula debe tener 10 dígitos';
    }

    if (!_isValidEcuadorianDni(s)) {
      return 'Cédula ecuatoriana inválida';
    }

    return null;
  }

  bool _isValidEcuadorianDni(String dni) {
    if (!RegExp(r'^\d{10}$').hasMatch(dni)) return false;

    final province = int.tryParse(dni.substring(0, 2)) ?? 0;
    if (province < 1 || province > 24) return false;

    final thirdDigit = int.tryParse(dni[2]) ?? -1;
    if (thirdDigit < 0 || thirdDigit > 5) return false;

    final digits = dni.split('').map(int.parse).toList();

    int total = 0;
    for (int i = 0; i < 9; i++) {
      int value = digits[i];
      if (i % 2 == 0) {
        value *= 2;
        if (value > 9) value -= 9;
      }
      total += value;
    }

    final verifier = total % 10 == 0 ? 0 : 10 - (total % 10);
    return verifier == digits[9];
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

    if (s.isEmpty) return null;
    if (s.length < 6) return 'Mínimo 6 caracteres';
    if (s.length > 50) return 'Contraseña muy larga';

    return null;
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
    final newValue = value.trim().toLowerCase();

    for (final user in users) {
      final sameId = widget.user?.id != null && user.id == widget.user!.id;
      if (sameId) continue;

      final currentEmail = (user.email ?? '').trim().toLowerCase();
      if (currentEmail == newValue) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateDni(String value) async {
    final users = await UserRepository.getAll();
    final newValue = value.trim();

    for (final user in users) {
      final sameId = widget.user?.id != null && user.id == widget.user!.id;
      if (sameId) continue;

      final currentDni = (user.dni ?? '').trim();
      if (currentDni == newValue) return true;
    }
    return false;
  }

  Future<bool> _isDuplicateUsername(String value) async {
    final users = await UserRepository.getAll();
    final newValue = value.trim().toLowerCase();

    for (final user in users) {
      final sameId = widget.user?.id != null && user.id == widget.user!.id;
      if (sameId) continue;

      final currentUsername = (user.username ?? '').trim().toLowerCase();
      if (currentUsername == newValue) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _toTitleCase(_nameController.text);
      final lastName = _toTitleCase(_lastNameController.text);
      final email = _emailController.text.trim().toLowerCase();
      final dni = _dniController.text.trim();
      final username = _usernameController.text.trim();
      final passText = _passwordController.text.trim();

      final existsName = await _isDuplicateName(name);
      if (existsName) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya existe un usuario con ese nombre")),
        );
        return;
      }

      final existsLastName = await _isDuplicateLastName(lastName);
      if (existsLastName) {
        if (!mounted) return;
        setState(() => _isSaving = false);
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
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya existe un usuario con ese correo")),
        );
        return;
      }

      final existsDni = await _isDuplicateDni(dni);
      if (existsDni) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya existe un usuario con esa cédula")),
        );
        return;
      }

      final existsUsername = await _isDuplicateUsername(username);
      if (existsUsername) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ya existe un usuario con ese username"),
          ),
        );
        return;
      }

      final user = User(
        id: widget.user?.id,
        name: name,
        lastName: lastName,
        email: email,
        dni: dni,
        role: _fixedRole,
        username: username,
        companyId: widget.companyId,
      );

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
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 8),
                _tf(
                  _dniController,
                  'Cédula',
                  Icons.badge,
                  keyboardType: TextInputType.number,
                  validator: _validateDni,
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
                  obscureText: _obscurePassword,
                  isPassword: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tipo de usuario fijo: Usuario",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
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
        ElevatedButton.icon(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.cancel, color: Colors.white),
          label: const Text('Cancelar', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.save, color: Colors.white),
          label: Text(
            _isEditing ? 'Actualizar' : 'Guardar',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _tf(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscureText = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
                : null,
      ),
      validator:
          validator ??
          (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
    );
  }
}
