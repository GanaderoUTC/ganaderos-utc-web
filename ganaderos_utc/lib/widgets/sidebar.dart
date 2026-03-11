import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late final Future<_SessionState> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _loadSession();
  }

  Future<_SessionState> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool('isLoggedIn') ?? false;

    String? name;
    String? role;

    final rawUser = prefs.getString('user');

    if (rawUser != null) {
      try {
        final map = jsonDecode(rawUser);
        name = map['name'];
        role = map['role'];
      } catch (_) {}
    }

    return _SessionState(isLogged: isLogged, name: name, role: role);
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('isLoggedIn');
    await prefs.remove('user');

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _goTo(BuildContext context, String route) async {
    Navigator.pop(context);

    await Future.delayed(const Duration(milliseconds: 120));

    if (!context.mounted) return;

    final current = ModalRoute.of(context)?.settings.name;

    if (current != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 10,
      child: FutureBuilder<_SessionState>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = snapshot.data!;
          final isLogged = session.isLogged;

          return Container(
            color: const Color(0xFFF4F6F7),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(session),

                if (isLogged) ...[
                  _item(context, "Inicio", '/inicio', Icons.home),
                  _item(context, "Haciendas", '/companies', Icons.house_siding),
                  _item(context, "Razas", '/breeds', Icons.pets),
                  _item(context, "Orígenes", '/origin', Icons.location_on),
                  _item(context, "Categorías", '/categories', Icons.category),
                  _item(context, "Estadísticas", '/stats', Icons.bar_chart),
                  _item(context, "Mapa Haciendas", '/companies-map', Icons.map),

                  const SizedBox(height: 10),

                  const Divider(),

                  const SizedBox(height: 10),

                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
                    title: const Text(
                      "Cerrar sesión",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () => _logout(context),
                  ),
                ],

                if (!isLogged) ...[
                  _item(context, "Iniciar Sesión", '/login', Icons.login),
                  //_item(context, "Registrarse", '/register', Icons.person_add),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(_SessionState session) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "UTC GEN APP",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (session.isLogged)
                      Text(
                        session.name ?? "Usuario",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                    if (session.role != null)
                      Text(
                        "Rol: ${session.role}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String title,
    String route,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E7D32)),

      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),

      hoverColor: const Color(0xFFE8F5E9),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

      onTap: () => _goTo(context, route),
    );
  }
}

class _SessionState {
  final bool isLogged;
  final String? name;
  final String? role;

  _SessionState({required this.isLogged, this.name, this.role});
}
