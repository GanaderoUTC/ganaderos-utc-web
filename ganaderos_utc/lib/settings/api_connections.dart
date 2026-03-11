import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiConnection {
  // CAMBIA AQUÍ TU IP LOCAL O DEL SERVIDOR
  static String url = "http://192.168.56.101:3000/api";
  //static String url = "http://172.16.32.110:3000/api"; // para pre-prod
  //static String url = "https://api.allorigins.win/raw?url=https://utcgen.utc.edu.ec/api";

  // ---------------------------------------------------------------------------
  // 🔵 LOGIN - POST /api/users/auth
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    try {
      if (!await _isConnected()) {
        return {"error": "Sin conexión a internet"};
      }

      final uri = Uri.parse("$url/users/auth");
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
      };

      final body = json.encode({
        "username": username.trim(),
        "password": password.trim(),
      });

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        return {"error": "Respuesta inválida del servidor"};
      }

      return {
        "error": "Login falló (${response.statusCode})",
        "detail": response.body,
      };
    } on TimeoutException {
      return {"error": "Tiempo de espera agotado (servidor lento o caído)"};
    } catch (e) {
      return {"error": "Error en login: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // 🔵 REGISTER - prueba varias rutas típicas porque NO tienes backend
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> register(
    Map<String, dynamic> payload,
  ) async {
    try {
      if (!await _isConnected()) {
        return {"error": "Sin conexión a internet"};
      }

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
      };

      // NO borres company_id/role/etc
      final bodyMap = Map<String, dynamic>.from(payload);
      bodyMap.removeWhere((k, v) => v == null);

      // ✅ rutas comunes (prueba todas)
      final endpointsToTry = <String>[
        "/users/register",
        "/users", // POST /users (muy común)
        "/auth/register",
        "/register",
        "/user/register",
        "/user",
      ];

      Map<String, dynamic>? lastError;

      for (final ep in endpointsToTry) {
        final uri = Uri.parse(url + ep);

        try {
          final response = await http
              .post(uri, headers: headers, body: json.encode(bodyMap))
              .timeout(const Duration(seconds: 20));

          if (response.statusCode == 200 || response.statusCode == 201) {
            final decoded = json.decode(response.body);
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
            return {"success": true, "message": "Registrado correctamente"};
          }

          // 404 => endpoint no existe, prueba siguiente
          if (response.statusCode == 404) {
            lastError = {
              "error": "Endpoint no existe: $ep",
              "detail": response.body,
            };
            continue;
          }

          // Otros errores => devolvemos ya (porque el endpoint sí existe)
          return {
            "error": "Registro falló (${response.statusCode}) en $ep",
            "detail": response.body,
          };
        } on TimeoutException {
          lastError = {"error": "Timeout en $ep"};
          continue;
        } catch (e) {
          // En web, CORS o bloqueo del navegador suele caer aquí
          lastError = {"error": "Error llamando $ep: $e"};
          continue;
        }
      }

      return lastError ??
          {
            "error":
                "No se encontró endpoint de registro. El backend no expone ruta pública.",
          };
    } catch (e) {
      return {"error": "Error general en register: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 GET que devuelve LISTA:  [ {...}, {...} ]
  // ---------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getList(String endpoint) async {
    try {
      if (!await _isConnected()) return [];

      final uri = Uri.parse(url + endpoint);

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        // ignore: avoid_print
        print(
          "GET LIST ERROR: Se esperaba List pero llegó ${decoded.runtimeType}",
        );
        return [];
      }
      // ignore: avoid_print
      print("GET LIST ERROR: ${response.statusCode} - ${response.body}");
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("GET LIST EXCEPTION: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 GET MAP con query params:  { ... }
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> getMapQuery(
    String endpoint, {
    Map<String, String>? query,
  }) async {
    try {
      if (!await _isConnected()) return null;

      final uri = Uri.parse(url + endpoint).replace(queryParameters: query);

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        // ignore: avoid_print
        print(
          "GET MAP QUERY ERROR: Se esperaba Map pero llegó ${decoded.runtimeType}",
        );
        return null;
      }
      // ignore: avoid_print
      print("GET MAP QUERY ERROR: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("GET MAP QUERY EXCEPTION: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔵 GET GENERAL /api/*
  // ---------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> get(String endpoint) async {
    try {
      if (!await _isConnected()) return [];

      final uri = Uri.parse(url + endpoint);

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      // ignore: avoid_print
      print("GET ERROR: ${response.statusCode} - ${response.body}");
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("GET EXCEPTION: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 🔵 POST GENERAL /api/*
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      if (!await _isConnected()) return null;

      final uri = Uri.parse(url + endpoint);

      // Limpieza automática de campos
      body.remove('id');
      body.remove('sync');
      body.remove('external_id');
      body.remove('path');

      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }

      // ignore: avoid_print
      print("POST ERROR: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("POST EXCEPTION: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔵 PATCH GENERAL /api/*
  // ---------------------------------------------------------------------------
  static Future<int> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      if (!await _isConnected()) return 0;

      final uri = Uri.parse(url + endpoint);

      body.remove('id');
      body.remove('sync');
      body.remove('external_id');
      body.remove('company_id');
      body.remove('uuid');

      final response = await http
          .patch(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return int.parse(response.body);
      }
      // ignore: avoid_print
      print("PATCH ERROR: ${response.statusCode}");
      return 0;
    } catch (e) {
      // ignore: avoid_print
      print("PATCH EXCEPTION: $e");
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔵 DELETE GENERAL /api/*
  // ---------------------------------------------------------------------------
  static Future<int> delete(String endpoint) async {
    try {
      if (!await _isConnected()) return 0;

      final uri = Uri.parse(url + endpoint);

      final response = await http
          .delete(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return int.parse(response.body);
      }
      // ignore: avoid_print
      print("DELETE ERROR: ${response.statusCode}");
      return 0;
    } catch (e) {
      // ignore: avoid_print
      print("DELETE EXCEPTION: $e");
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔵 Check Conexión
  // ---------------------------------------------------------------------------
  static Future<bool> _isConnected() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }
}
