import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/user_repository.dart';
import '../models/user_models.dart'; // ✅ User model

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Primera letra en mayúscula y el resto en minúsculas
  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String? _validateUsername(String? value) {
    if (value == null) return 'El usuario es obligatorio';

    final s = value.trim();

    if (s.isEmpty) return 'El usuario es obligatorio';
    if (s.length < 3) return 'Usuario muy corto';
    if (s.length > 50) return 'Usuario muy largo (máx. 50)';

    final ok = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9._\-\s]{3,50}$").hasMatch(s);
    if (!ok) return 'Usuario inválido';

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null) return 'La contraseña es obligatoria';

    final s = value.trim();

    if (s.isEmpty) return 'La contraseña es obligatoria';
    if (s.length < 4) return 'La contraseña es muy corta';
    if (s.length > 100) return 'La contraseña es muy larga';

    return null;
  }

  Future<void> _handleLogin() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final formattedUsername = _capitalizeFirst(usernameController.text);
      final formattedPassword = passwordController.text.trim();

      // 🔵 LOGIN AL API
      final User? user = await UserRepository.login(
        formattedUsername,
        formattedPassword,
      );

      if (!mounted) return;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();

        // ✅ Guardar sesión activa
        await prefs.setBool("isLoggedIn", true);

        // ✅ Guardar token para AuthGuard
        // Si luego tu API devuelve token real, aquí reemplazas "sesion_activa"
        await prefs.setString("token", "sesion_activa");

        // ✅ Guardar usuario completo en sesión
        try {
          final userJson = jsonEncode(user.toDbMap());
          await prefs.setString("user", userJson);
        } catch (_) {}

        // ✅ Rol opcional si lo necesitas después
        // await prefs.setString("role", "superadmin");

        // 🔵 REDIRECCIONAR A INICIO
        Navigator.pushNamedAndRemoveUntil(context, "/inicio", (_) => false);
      } else {
        setState(() => errorMessage = "Usuario o contraseña incorrectos");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = "Error al iniciar sesión: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    final double cardPadding = isMobile ? 16.0 : 22.0;
    final double outerPadding = isMobile ? 14.0 : 24.0;
    final double titleSize = isMobile ? 22.0 : 26.0;
    final double radius = isMobile ? 14.0 : 18.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/fondo_login.jpg",
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
                constraints: const BoxConstraints(maxWidth: 450),
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
                              "Iniciar Sesión",
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Bienvenido a UTC GEN APP",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 22),

                            TextFormField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                labelText: "Administrador",
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              autofillHints: const [AutofillHints.username],
                              textInputAction: TextInputAction.next,
                              validator: _validateUsername,
                            ),

                            const SizedBox(height: 14),

                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              validator: _validatePassword,
                            ),

                            const SizedBox(height: 16),

                            if (errorMessage != null) ...[
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
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
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text(
                                          "Ingresar",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ✅ REGISTER DESACTIVADO PARA PREDEFENSA
                            // TextButton(
                            //   onPressed: () {
                            //     Navigator.pushReplacementNamed(
                            //       context,
                            //       "/register",
                            //     );
                            //   },
                            //   child: const Text(
                            //     "¿No tienes cuenta? Regístrate",
                            //   ),
                            // ),
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
}
