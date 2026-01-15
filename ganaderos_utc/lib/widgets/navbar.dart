import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Navbar extends StatefulWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  bool _isLogged = false;

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
  }

  /// ✔ Cargar estado de sesión desde SharedPreferences
  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final logged = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      setState(() => _isLogged = logged);
    }
  }

  /// ✔ Logout eliminando datos de sesión
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('user');

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('GANADEROS UTC'),
      centerTitle: true,
      elevation: 4,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF18F059), Color(0xFF0BA603), Color(0xFF01EC73)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed:
              _isLogged
                  ? _logout
                  : () => Navigator.pushReplacementNamed(context, '/login'),
          icon: Icon(
            _isLogged ? Icons.logout : Icons.login,
            color: Colors.white,
          ),
          label: Text(
            _isLogged ? 'Cerrar Sesión' : 'Iniciar Sesión',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
