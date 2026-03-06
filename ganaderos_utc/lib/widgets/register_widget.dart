import 'package:flutter/material.dart';

import '../models/user_models.dart';
import '../models/company_models.dart';
import '../repositories/user_repository.dart';
import '../repositories/company_repository.dart';
import '../repository/user_company_repository.dart';
import '../utils/validators.dart';

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final dniController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Repositories
  final CompanyRepository _companyRepository = CompanyRepository();
  // ignore: unused_field
  final UserRepository _usersRepository = UserRepository();

  // Dropdowns / state
  String selectedRole = 'user'; // 'admin' o 'user'
  int? selectedCompanyId;

  String? errorMessage;
  bool isLoading = false;

  // Companies
  List<Company> companies = [];
  bool isLoadingCompanies = true;

  // rule check
  bool _checkingAdminRule = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final data = await _companyRepository.getAll();
      if (!mounted) return;

      setState(() {
        companies = data;
        if (companies.isNotEmpty) {
          selectedCompanyId = companies.first.id; // default
        }
        isLoadingCompanies = false;
      });

      // aplica regla si por default está admin (normalmente no)
      await _applyOneAdminRuleIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingCompanies = false;
        errorMessage = "Error cargando empresas: $e";
      });
    }
  }

  Company? _getSelectedCompany() {
    if (selectedCompanyId == null) return null;
    try {
      return companies.firstWhere((c) => c.id == selectedCompanyId);
    } catch (_) {
      return null;
    }
  }

  /// ✅ Regla: solo 1 admin por empresa
  /// Si selecciona "admin" y esa empresa ya tiene admin -> forzar a "user".
  Future<void> _applyOneAdminRuleIfNeeded() async {
    if (selectedCompanyId == null) return;
    if (selectedRole.toLowerCase() != 'admin') return;

    setState(() {
      _checkingAdminRule = true;
      errorMessage = null;
    });

    try {
      final users = await UserCompanyRepository.getAllByCompany(
        selectedCompanyId!,
      );

      final hasAdmin = users.any(
        (u) => (u.role ?? 'user').toLowerCase() == 'admin',
      );

      if (!mounted) return;

      setState(() {
        _checkingAdminRule = false;
        if (hasAdmin) {
          selectedRole = 'user';
          errorMessage =
              "Esta empresa ya tiene un Administrador. Solo puedes registrarte como Usuario.";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingAdminRule = false;
        // No bloqueamos el registro por fallo de verificación, solo avisamos.
        errorMessage = "No se pudo verificar admins de la empresa: $e";
      });
    }
  }

  Future<void> _handleRegister() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (selectedCompanyId == null) {
      setState(() => errorMessage = "Seleccione una empresa");
      return;
    }

    // ✅ regla final (por si cambió rápido)
    if (selectedRole.toLowerCase() == 'admin') {
      setState(() {
        _checkingAdminRule = true;
        errorMessage = null;
      });

      try {
        final users = await UserCompanyRepository.getAllByCompany(
          selectedCompanyId!,
        );
        final hasAdmin = users.any(
          (u) => (u.role ?? 'user').toLowerCase() == 'admin',
        );

        if (!mounted) return;

        setState(() => _checkingAdminRule = false);

        if (hasAdmin) {
          setState(() {
            selectedRole = 'user';
            errorMessage =
                "Esta empresa ya tiene un Administrador. Regístrate como Usuario.";
          });
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _checkingAdminRule = false);
        // No bloqueamos por fallo de verificación, pero puedes hacerlo si quieres.
        setState(() {
          errorMessage = "No se pudo validar el rol admin: $e";
        });
        return;
      }
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = User(
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        dni: dniController.text.trim(),
        role: selectedRole,
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
        companyId: selectedCompanyId,
      );

      final result = await UserRepository.register(user);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (result["success"] == true) {
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        setState(() => errorMessage = result["message"]?.toString());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Error en registro: $e";
      });
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    final outerPadding = isMobile ? 14.0 : 24.0;
    final cardPadding = isMobile ? 16.0 : 22.0;
    final titleSize = isMobile ? 22.0 : 26.0;
    final radius = isMobile ? 14.0 : 18.0;

    final companySelected = _getSelectedCompany();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/fondo_register.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(outerPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 10,
                  color: Colors.white.withOpacity(0.92),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Registro de Usuario",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _input(
                              controller: nameController,
                              label: "Nombre",
                              icon: Icons.person,
                              validator: Validators.name,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.givenName],
                            ),
                            _input(
                              controller: lastNameController,
                              label: "Apellido",
                              icon: Icons.person_outline,
                              validator: Validators.name,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.familyName],
                            ),
                            _input(
                              controller: emailController,
                              label: "Correo",
                              icon: Icons.email,
                              validator: Validators.email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                            ),
                            _input(
                              controller: dniController,
                              label: "Cédula",
                              icon: Icons.badge,
                              validator: Validators.cedulaEC,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 6),

                            // ✅ ROL (admin/user) + regla 1 admin por empresa
                            DropdownButtonFormField<String>(
                              value: selectedRole,
                              items: const [
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Text('Usuario'),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Administrador'),
                                ),
                              ],
                              onChanged: (v) async {
                                if (v == null) return;
                                setState(() {
                                  selectedRole = v;
                                  errorMessage = null;
                                });
                                await _applyOneAdminRuleIfNeeded();
                              },
                              decoration: const InputDecoration(
                                labelText: 'Rol',
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ✅ EMPRESA
                            isLoadingCompanies
                                ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: CircularProgressIndicator(),
                                )
                                : DropdownButtonFormField<int>(
                                  value: selectedCompanyId,
                                  items:
                                      companies
                                          .map(
                                            (c) => DropdownMenuItem<int>(
                                              value: c.id,
                                              child: Text(
                                                c.companyName,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) async {
                                    setState(() {
                                      selectedCompanyId = v;
                                      errorMessage = null;
                                    });
                                    await _applyOneAdminRuleIfNeeded();
                                  },
                                  validator:
                                      (v) =>
                                          v == null
                                              ? "Seleccione empresa"
                                              : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Empresa (Hacienda)',
                                  ),
                                ),

                            if (companySelected != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Seleccionada: ${companySelected.companyName}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                            if (_checkingAdminRule)
                              const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: LinearProgressIndicator(),
                              ),

                            const SizedBox(height: 10),

                            _input(
                              controller: usernameController,
                              label: "Usuario",
                              icon: Icons.account_circle,
                              validator: Validators.username,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                            ),
                            _input(
                              controller: passwordController,
                              label: "Contraseña",
                              icon: Icons.lock,
                              obscure: true,
                              validator: Validators.passwordStrong,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onSubmitted: (_) => _handleRegister(),
                            ),

                            const SizedBox(height: 12),

                            if (errorMessage != null) ...[
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          "Registrar",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  "/login",
                                );
                              },
                              child: const Text(
                                "¿Ya tienes cuenta? Inicia sesión",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<String>? autofillHints,
    void Function(String)? onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator:
            validator ??
            (v) => (v == null || v.trim().isEmpty) ? "Campo requerido" : null,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
