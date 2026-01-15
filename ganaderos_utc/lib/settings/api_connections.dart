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
      if (!await _isConnected()) return null;

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
          .timeout(const Duration(seconds: 10));

      // Éxito esperado de tu API
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      print("LOGIN ERROR: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
      print("LOGIN EXCEPTION: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔵 REGISTER - POST /api/users/register
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> register(
    String username,
    String password,
  ) async {
    try {
      if (!await _isConnected()) return null;

      final uri = Uri.parse("$url/users/register");
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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      }

      print("REGISTER ERROR: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
      print("REGISTER EXCEPTION: $e");
      return null;
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
        print(
          "GET LIST ERROR: Se esperaba List pero llegó ${decoded.runtimeType}",
        );
        return [];
      }

      print("GET LIST ERROR: ${response.statusCode} - ${response.body}");
      return [];
    } catch (e) {
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

        print(
          "GET MAP QUERY ERROR: Se esperaba Map pero llegó ${decoded.runtimeType}",
        );
        return null;
      }

      print("GET MAP QUERY ERROR: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
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

      print("GET ERROR: ${response.statusCode} - ${response.body}");
      return [];
    } catch (e) {
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

      print("POST ERROR: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
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

      print("PATCH ERROR: ${response.statusCode}");
      return 0;
    } catch (e) {
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

      print("DELETE ERROR: ${response.statusCode}");
      return 0;
    } catch (e) {
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
