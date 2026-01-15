// Import correcto del modelo Company
import 'company_models.dart';

class User {
  int? id;
  String name;
  String lastName;
  String? email;
  String? dni;
  String? role;
  String? username;
  String? password;
  int? companyId;
  Company? company;

  User({
    this.id,
    required this.name,
    required this.lastName,
    this.email,
    this.dni,
    this.role,
    this.username,
    this.password,
    this.companyId,
    this.company,
  });

  /// FACTORY FROM MAP — Acepta API, Base de datos y JSON mixto
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: _toInt(map['id']),
      name: map['name']?.toString() ?? '',
      lastName:
          map['lastName']?.toString() ??
          map['lastname']?.toString() ??
          map['last_name']?.toString() ??
          '',
      email: map['email']?.toString(),
      dni: map['dni']?.toString(),
      role: map['role']?.toString(),
      username: map['username']?.toString(),
      password: map['password']?.toString(),
      companyId: _toInt(map['companyId']) ?? _toInt(map['company_id']),
      company: map['company'] is Map ? Company.fromMap(map['company']) : null,
    );
  }

  // TO MAP — para SQLite / API
  Map<String, dynamic> toMap({bool includePassword = false}) {
    final map = {
      'id': id,
      'name': name,
      'last_name': lastName,
      'email': email,
      'dni': dni,
      'role': role,
      'username': username,
      'company_id': companyId,
    };

    if (includePassword && password != null) {
      map['password'] = password;
    }

    return map;
  }

  // Utilidad interna para convertir cualquier cosa a int sin errores
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
