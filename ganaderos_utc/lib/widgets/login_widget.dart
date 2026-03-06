import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/user_repository.dart';
// Si tu User model está en otro archivo, importa aquí:
// import '../models/user_models.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 🔵 LOGIN AL API
      final user = await UserRepository.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        // 🔵 GUARDAR SESIÓN
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);

        // ✅ MUY RECOMENDADO: guardar el user para usar role/company después
        // Requiere que tu modelo tenga toMap()
        try {
          final userJson = jsonEncode(user.toDbMap());
          await prefs.setString("user", userJson);
        } catch (_) {
          // Si tu modelo no tiene toMap(), no rompe el login.
        }

        // 🔵 REDIRECCIONAR A INICIO
        Navigator.pushNamedAndRemoveUntil(context, "/inicio", (_) => false);
      } else {
        setState(() => errorMessage = "Usuario o contraseña incorrectos");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = "Error al iniciar sesión: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    final cardPadding = isMobile ? 16.0 : 22.0;
    final outerPadding = isMobile ? 14.0 : 24.0;
    final titleSize = isMobile ? 22.0 : 26.0;
    final radius = isMobile ? 14.0 : 18.0;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              "assets/images/fondo_login.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Overlay para legibilidad (muy importante en móvil)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),

          // Card responsive
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

                            // Username
                            TextFormField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                labelText: "Usuario",
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              autofillHints: const [AutofillHints.username],
                              textInputAction: TextInputAction.next,
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? "Ingrese su usuario"
                                          : null,
                            ),

                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "Contraseña",
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                              ),
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? "Ingrese su contraseña"
                                          : null,
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

                            // Botón login
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

                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  "/register",
                                );
                              },
                              child: const Text(
                                "¿No tienes cuenta? Regístrate",
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
}
