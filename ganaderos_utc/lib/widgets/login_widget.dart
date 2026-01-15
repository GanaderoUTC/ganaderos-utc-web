import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/user_repository.dart';

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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // 🔵 LOGIN AL API
    final user = await UserRepository.login(
      usernameController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (user != null) {
      // 🔵 GUARDAR SESIÓN CORRECTAMENTE
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);

      if (!mounted) return;

      // 🔵 REDIRECCIONAR A INICIO
      Navigator.pushNamedAndRemoveUntil(context, "/inicio", (_) => false);
    } else {
      setState(() => errorMessage = "Usuario o contraseña incorrectos");
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 10,
                  color: Colors.white.withOpacity(0.90),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            "Iniciar Sesión",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Bienvenido a UTC GEN APP",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Username
                          TextFormField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: "Usuario",
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator:
                                (v) => v!.isEmpty ? "Ingrese su usuario" : null,
                          ),

                          const SizedBox(height: 15),

                          // Password
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Contraseña",
                              prefixIcon: Icon(Icons.lock),
                            ),
                            validator:
                                (v) =>
                                    v!.isEmpty ? "Ingrese su contraseña" : null,
                          ),

                          const SizedBox(height: 20),

                          if (errorMessage != null)
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 15,
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Botón de login
                          isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleLogin,
                                  child: const Text("Ingresar"),
                                ),
                              ),

                          const SizedBox(height: 15),

                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                "/register",
                              );
                            },
                            child: const Text("¿No tienes cuenta? Regístrate"),
                          ),
                        ],
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
