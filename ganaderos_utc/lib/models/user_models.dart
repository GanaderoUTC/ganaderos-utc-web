import 'company_models.dart';

class User {
  final int? id;

  final String name;
  final String lastName;

  final String? email;
  final String? dni;
  final String? role;

  final String? username;

  /// Solo usar para login/register (NO persistir en DB ni mandar en update normal)
  final String? password;

  /// companyId es clave para multi-tenant
  final int? companyId;

  /// Objeto anidado si la API lo manda
  final Company? company;

  const User({
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

  /// ✅ FromMap ultra flexible (API / SQLite / JSON mixto)
  factory User.fromMap(Map<String, dynamic> map) {
    final Company? parsedCompany =
        (map['company'] is Map)
            ? Company.fromMap(Map<String, dynamic>.from(map['company']))
            : null;

    final int? parsedCompanyId =
        _toInt(map['companyId']) ??
        _toInt(map['company_id']) ??
        _toInt(map['companyID']) ??
        parsedCompany?.id;

    return User(
      id: _toInt(map['id']),
      name: (map['name'] ?? map['first_name'] ?? '').toString(),
      lastName:
          (map['lastName'] ??
                  map['lastname'] ??
                  map['last_name'] ??
                  map['surname'] ??
                  '')
              .toString(),
      email: map['email']?.toString(),
      dni: map['dni']?.toString(),
      role: map['role']?.toString().toLowerCase(), // ✅ evita bugs
      username: map['username']?.toString(),
      password: map['password']?.toString(),
      companyId: parsedCompanyId,
      company: parsedCompany,
    );
  }

  /// ✅ Para UI / updates: crea una copia con cambios
  User copyWith({
    int? id,
    String? name,
    String? lastName,
    String? email,
    String? dni,
    String? role,
    String? username,
    String? password,
    int? companyId,
    Company? company,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      dni: dni ?? this.dni,
      role: (role ?? this.role)?.toLowerCase(),
      username: username ?? this.username,
      password: password ?? this.password,
      companyId: companyId ?? this.companyId,
      company: company ?? this.company,
    );
  }

  // ---------------------------------------------------------------------------
  // MAPS SEPARADOS: API vs SQLITE
  // ---------------------------------------------------------------------------

  /// ✅ Map para API (register / update) usando snake_case típico backend
  Map<String, dynamic> toApiMap({bool includePassword = false}) {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'last_name': lastName,
      'email': email,
      'dni': dni,
      'role': role,
      'username': username,
      'company_id': companyId,
    };

    data.removeWhere((k, v) => v == null);

    if (includePassword) {
      if (password != null && password!.trim().isNotEmpty) {
        data['password'] = password;
      }
    }

    return data;
  }

  /// ✅ Map para SQLite (igual snake_case)
  /// - Nunca guardes password en SQLite
  Map<String, dynamic> toDbMap() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'last_name': lastName,
      'email': email,
      'dni': dni,
      'role': role,
      'username': username,
      'company_id': companyId,
    };
    data.removeWhere((k, v) => v == null);
    return data;
  }

  /// ✅ Para guardar en Storage / SharedPreferences (JSON)
  /// (incluye company para UI)
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'last_name': lastName,
      'email': email,
      'dni': dni,
      'role': role,
      'username': username,
      'company_id': companyId,
      'company': company?.toMap(),
    };
    data.removeWhere((k, v) => v == null);
    return data;
  }

  bool get isValidBasic => name.trim().isNotEmpty && lastName.trim().isNotEmpty;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }
}
