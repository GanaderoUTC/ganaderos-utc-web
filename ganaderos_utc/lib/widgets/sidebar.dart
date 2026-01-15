import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('user');

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool isLogged = snapshot.data!;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF00EFFF),
                      Color(0xFF1E90FF),
                      Color(0xFFE22B59),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'UTC GEN APP',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),

              // MENÚ PARA USUARIOS LOGUEADOS
              if (isLogged) ...[
                _item(context, 'Inicio', '/inicio', Icons.home),
                _item(context, 'Empresas', '/companies', Icons.business),
                _item(context, 'Razas', '/breeds', Icons.pets),
                _item(context, 'Orígenes', '/origin', Icons.location_on),
                _item(context, 'Categorías', '/categories', Icons.category),
                _item(context, 'Estadísticas', '/stats', Icons.bar_chart),
                //_item(context, 'Ganado', '/cattle', Icons.agriculture),
                //_item(context,'Chequeo Médico','/checkup',Icons.health_and_safety,),
                //_item(context,'Recolección de Leche','/collection',Icons.local_drink,),
                //_item(context, 'Diagnósticos', '/diagnosis', Icons.healing),
                //_item(context, 'Usuarios', '/user', Icons.person),
                //_item(context, 'Vacunas', '/vaccines', Icons.vaccines),
                //_item(context, 'Peso', '/weight', Icons.monitor_weight),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión'),
                  onTap: () => _logout(context),
                ),
              ],

              // MENÚ PARA USUARIOS NO LOGUEADOS
              if (!isLogged) ...[
                ListTile(
                  leading: const Icon(Icons.login, color: Colors.green),
                  title: const Text('Iniciar Sesión'),
                  onTap:
                      () => Navigator.pushReplacementNamed(context, '/login'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.blue),
                  title: const Text('Registrarse'),
                  onTap:
                      () =>
                          Navigator.pushReplacementNamed(context, '/register'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _item(BuildContext context, String title, String ruta, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != ruta) {
          Navigator.pushReplacementNamed(context, ruta);
        }
      },
    );
  }
}
