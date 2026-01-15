import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../models/user_models.dart';

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final dniController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Dropdowns
  String? selectedRole = "user";
  int? selectedCompanyId = 1;

  bool isLoading = false;
  String? errorMessage;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

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

    setState(() => isLoading = false);

    if (result["success"] == true) {
      if (mounted) Navigator.pushReplacementNamed(context, "/login");
    } else {
      setState(() => errorMessage = result["message"]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/fondo_register.png",
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
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
                            "Registro de Usuario",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Text(
                            "Crea tu cuenta para ingresar",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: "Nombre",
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator:
                                (v) => v!.isEmpty ? "Ingrese el nombre" : null,
                          ),

                          const SizedBox(height: 10),

                          TextFormField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              labelText: "Apellido",
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator:
                                (v) =>
                                    v!.isEmpty ? "Ingrese el apellido" : null,
                          ),

                          const SizedBox(height: 10),

                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: "Correo",
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator:
                                (v) => v!.isEmpty ? "Ingrese el correo" : null,
                          ),

                          const SizedBox(height: 10),

                          TextFormField(
                            controller: dniController,
                            decoration: const InputDecoration(
                              labelText: "Cédula",
                              prefixIcon: Icon(Icons.badge),
                            ),
                            validator:
                                (v) => v!.isEmpty ? "Ingrese la cédula" : null,
                          ),

                          const SizedBox(height: 10),

                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            decoration: const InputDecoration(
                              labelText: "Rol",
                              prefixIcon: Icon(Icons.admin_panel_settings),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "user",
                                child: Text("Usuario"),
                              ),
                              DropdownMenuItem(
                                value: "admin",
                                child: Text("Administrador"),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => selectedRole = v);
                            },
                          ),

                          const SizedBox(height: 10),

                          DropdownButtonFormField<int>(
                            value: selectedCompanyId,
                            decoration: const InputDecoration(
                              labelText: "Empresa",
                              prefixIcon: Icon(Icons.business),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text("Empresa 1"),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text("Empresa 2"),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => selectedCompanyId = v);
                            },
                          ),

                          const SizedBox(height: 10),

                          TextFormField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: "Usuario",
                              prefixIcon: Icon(Icons.account_circle),
                            ),
                            validator:
                                (v) => v!.isEmpty ? "Ingrese el usuario" : null,
                          ),

                          const SizedBox(height: 10),

                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Contraseña",
                              prefixIcon: Icon(Icons.lock),
                            ),
                            validator:
                                (v) =>
                                    v!.isEmpty ? "Ingrese la contraseña" : null,
                          ),

                          const SizedBox(height: 15),

                          if (errorMessage != null)
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 15,
                              ),
                            ),

                          const SizedBox(height: 15),

                          isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleRegister,
                                  child: const Text("Registrar"),
                                ),
                              ),

                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, "/login");
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
        ],
      ),
    );
  }
}
