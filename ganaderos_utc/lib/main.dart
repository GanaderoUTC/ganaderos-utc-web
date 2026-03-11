import 'package:flutter/material.dart';
import 'package:ganaderos_utc/views/cattle_view/cattle_view.dart';
import 'package:ganaderos_utc/views/maps_view/companies_map_view.dart';
import 'package:ganaderos_utc/views/stats_view/stats_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

// ✅ NUEVO IMPORT
import 'guards/auth_guard.dart';

// vistas...
import 'views/inicio_view/inicio_view.dart';
import 'views/breeds_view/breeds_view.dart';
import 'views/categories_view/categories_view.dart';
import 'views/checkup_view/checkup_view.dart';
import 'views/collection_view/collection_view.dart';
import 'views/companies_view/companies_view.dart';
import 'views/diagnosis_view/diagnosis_view.dart';
import 'views/origin_view/origin_view.dart';
import 'views/user_view/user_view.dart';
import 'views/vaccines_view/vaccines_view.dart';
import 'views/weight_view/weight_view.dart';

// widgets Login & Register
import 'widgets/login_widget.dart';
import 'widgets/register_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicialización de locale con fallback (evita fallos raros en web)
  try {
    await initializeDateFormatting('es_EC', null);
  } catch (_) {
    await initializeDateFormatting('es_ES', null);
  }

  // ✅ Leer estado de login de forma segura
  final prefs = await SharedPreferences.getInstance();
  final bool isLogged = prefs.getBool('isLoggedIn') ?? false;
  final String token = prefs.getString('token') ?? '';

  runApp(
    GanaderosUTCApp(
      initialRoute: (isLogged && token.isNotEmpty) ? '/inicio' : '/login',
    ),
  );
}

class GanaderosUTCApp extends StatelessWidget {
  final String initialRoute;

  const GanaderosUTCApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ganaderos UTC',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const Scaffold(body: LoginWidget()),
        '/register': (_) => const RegisterWidget(),

        // ✅ Rutas protegidas
        '/inicio': (context) => const AuthGuard(child: InicioView()),
        '/breeds': (context) => const AuthGuard(child: BreedsView()),
        '/categories': (context) => const AuthGuard(child: CategoriesView()),
        '/cattle': (context) => const AuthGuard(child: CattleView()),
        '/checkup': (context) => const AuthGuard(child: CheckupView()),
        '/collection': (context) => const AuthGuard(child: CollectionView()),
        '/companies': (context) => const AuthGuard(child: CompaniesView()),
        '/diagnosis': (context) => const AuthGuard(child: DiagnosisView()),
        '/origin': (context) => const AuthGuard(child: OriginView()),
        '/user': (context) => const AuthGuard(child: UserView()),
        '/vaccines': (context) => const AuthGuard(child: VaccineView()),
        '/weight': (context) => const AuthGuard(child: WeightView()),
        '/stats': (_) => const AuthGuard(child: StatsView()),
        '/companies-map':
            (context) => const AuthGuard(child: CompaniesMapView()),
      },

      // ✅ Si alguna ruta no existe, evita crasheos y vuelve a login
      onUnknownRoute:
          (_) => MaterialPageRoute(
            builder: (_) => const Scaffold(body: LoginWidget()),
          ),
    );
  }
}
