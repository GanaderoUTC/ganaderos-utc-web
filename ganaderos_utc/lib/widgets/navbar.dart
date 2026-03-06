import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Navbar extends StatefulWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> with RouteAware {
  bool _isLogged = false;

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
  }

  /// 🔹 Verifica sesión
  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final logged = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      setState(() => _isLogged = logged);
    }
  }

  /// 🔹 Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('user');

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    return AppBar(
      elevation: 4,
      centerTitle: true,

      /// ☰ Drawer siempre visible
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),

      title: const Text(
        'UTC GEN APP',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),

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
        IconButton(
          tooltip: _isLogged ? 'Cerrar sesión' : 'Iniciar sesión',
          icon: Icon(
            _isLogged ? Icons.logout : Icons.login,
            color: Colors.white,
          ),
          onPressed:
              _isLogged
                  ? _logout
                  : () => Navigator.pushReplacementNamed(context, '/login'),
        ),

        /// 🔹 Mostrar texto SOLO en pantallas grandes
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed:
                  _isLogged
                      ? _logout
                      : () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                _isLogged ? 'Cerrar sesión' : 'Iniciar sesión',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
