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

    // Si guardas "user" como JSON, intentamos leerlo
    final rawUser = prefs.getString('user');
    if (rawUser != null) {
      try {
        final map = jsonDecode(rawUser);
        // Ajusta claves según tu JSON real
        name = (map['name'] ?? map['username'] ?? '').toString().trim();
        role = (map['role'] ?? '').toString().trim();
        if (name.isEmpty) name = null;
        if (role.isEmpty) role = null;
      } catch (_) {
        // ignorar si no es JSON válido
      }
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
    // Cierra drawer primero
    Navigator.pop(context);

    // Pequeño delay para evitar glitches en web/móvil
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
      child: ConstrainedBox(
        // ✅ ancho controlado (mejor en web)
        constraints: const BoxConstraints(maxWidth: 340),
        child: FutureBuilder<_SessionState>(
          future: _sessionFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final session = snapshot.data!;
            final isLogged = session.isLogged;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(session),

                if (isLogged) ...[
                  _item(context, 'Inicio', '/inicio', Icons.home),
                  _item(context, 'Haciendas', '/companies', Icons.house_siding),
                  _item(context, 'Razas', '/breeds', Icons.pets),
                  _item(context, 'Orígenes', '/origin', Icons.location_on),
                  _item(context, 'Categorías', '/categories', Icons.category),
                  _item(context, 'Estadísticas', '/stats', Icons.bar_chart),
                  _item(context, 'Mapa Haciendas', '/companies-map', Icons.map),

                  const SizedBox(height: 6),
                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Cerrar Sesión'),
                    onTap: () => _logout(context),
                  ),
                ],

                if (!isLogged) ...[
                  ListTile(
                    leading: const Icon(Icons.login, color: Colors.green),
                    title: const Text('Iniciar Sesión'),
                    onTap: () => _goTo(context, '/login'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add, color: Colors.blue),
                    title: const Text('Registrarse'),
                    onTap: () => _goTo(context, '/register'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(_SessionState session) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00EFFF), Color(0xFF1E90FF), Color(0xFFE22B59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UTC GEN APP',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 6),

            // ✅ extra: info de usuario (si existe)
            if (session.isLogged) ...[
              Text(
                session.name != null
                    ? 'Hola, ${session.name!}'
                    : 'Sesión iniciada',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (session.role != null)
                Text(
                  'Rol: ${session.role!}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ] else ...[
              const Text(
                'Accede para ver el menú',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
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
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
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
