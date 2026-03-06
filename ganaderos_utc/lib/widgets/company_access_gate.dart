import 'package:flutter/material.dart';
import '../services/session_service.dart';

class CompanyAccessGate extends StatelessWidget {
  final int companyId;
  final Widget child;

  const CompanyAccessGate({
    super.key,
    required this.companyId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionData?>(
      future: SessionService.get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Center(child: Text('Inicia sesión'));
        }

        final s = snap.data!;
        final ok = s.companyId == companyId;

        if (!ok) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 48),
                  SizedBox(height: 10),
                  Text(
                    'Acceso restringido.\nNo perteneces a esta hacienda.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
