import 'package:flutter/material.dart';

import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/user_table.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final GlobalKey<UserTableState> _tableKey = GlobalKey<UserTableState>();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 700;

    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      backgroundColor: const Color.fromARGB(155, 161, 207, 131),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 12 : 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.70),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Color(0xFF2C3E50)),
                    const SizedBox(width: 10),
                    Text(
                      'Gestión de Usuarios',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// TABLA
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: UserTable(key: _tableKey),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// FOOTER SIMPLE
              const Center(
                child: Text(
                  "© 2025 UTC GEN APP - Todos los derechos reservados",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
