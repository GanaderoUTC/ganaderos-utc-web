class Company {
  final int? id;

  final String companyCode;
  final String companyName;
  final String responsible;
  final String dni;
  final String contact;
  final String email;

  /// city se mantiene por compatibilidad si lo usas para otra cosa
  final String? city;

  /// ✅ parish se mantiene para el apartado de maps
  final String? parish;

  final String? quarter;
  final String? neighborhood;

  final String address;

  /// ✅ compatibilidad: puede venir como texto "lat,lng"
  final String? coordinates;
  final String? codeAddress;

  final double? surface;
  final double? fertilityPercentage;
  final double? birthRate;
  final double? mortalityRate;
  final double? weaningPercentage;
  final double litersOfMilk;

  /// ✅ coordenadas separadas
  final double? lat;
  final double? lng;

  final String? observation;

  const Company({
    this.id,
    required this.companyCode,
    required this.companyName,
    required this.responsible,
    required this.dni,
    required this.contact,
    required this.email,
    this.city,
    this.parish,
    this.quarter,
    this.neighborhood,
    required this.address,
    this.coordinates,
    this.codeAddress,
    this.surface,
    this.fertilityPercentage,
    this.birthRate,
    this.mortalityRate,
    this.weaningPercentage,
    required this.litersOfMilk,
    this.lat,
    this.lng,
    this.observation,
  });

  // ---------------------------------------------------------------------------
  // ✅ UTILIDADES
  // ---------------------------------------------------------------------------

  bool get hasCoords => lat != null && lng != null;

  Map<String, double>? get latLng =>
      hasCoords ? {'lat': lat!, 'lng': lng!} : null;

  String? get mapsUrl =>
      hasCoords ? 'https://www.google.com/maps?q=$lat,$lng' : null;

  String get fullLocation {
    final parts = <String>[];
    if (parish != null && parish!.trim().isNotEmpty) {
      parts.add(parish!.trim());
    }
    if (address.trim().isNotEmpty) {
      parts.add(address.trim());
    }
    return parts.isEmpty ? '-' : parts.join(' - ');
  }

  /// ✅ prioridad: lat/lng separados; si no hay, usa coordinates
  String? get coordinatesString {
    if (hasCoords) {
      return '${lat!.toStringAsFixed(6)},${lng!.toStringAsFixed(6)}';
    }
    return coordinates;
  }

  // ---------------------------------------------------------------------------
  // ✅ MAP / SERIALIZACIÓN
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_code': companyCode,
      'company_name': companyName,
      'responsible': responsible,
      'dni': dni,
      'contact': contact,
      'email': email,
      'parish': parish,
      'city': city,
      'quarter': _nullIfEmpty(quarter),
      'neighborhood': _nullIfEmpty(neighborhood),
      'address': address,

      /// ✅ se manda al API como texto "lat,lng"
      'coordinates': coordinatesString,
      'code_address': codeAddress,

      'surface': surface,
      'fertility_percentage': fertilityPercentage,
      'birth_rate': birthRate,
      'mortality_rate': mortalityRate,
      'weaning_percentage': weaningPercentage,
      'liters_of_milk': litersOfMilk,
      'observation': observation,

      /// ✅ también se mandan separados si el backend los soporta
      'lat': lat,
      'lng': lng,
    };
  }

  factory Company.fromMap(Map<String, dynamic> data) {
    double? lat = _asNullableDouble(data['lat']);
    double? lng = _asNullableDouble(data['lng']);

    final coordsRaw = _asNullableString(data['coordinates']);

    if ((lat == null || lng == null) && coordsRaw != null) {
      final parsed = _parseCoordinates(coordsRaw);
      lat ??= parsed.$1;
      lng ??= parsed.$2;
    }

    return Company(
      id: _asInt(data['id']),
      companyCode: _asString(data['company_code'], fallback: ''),
      companyName: _asString(data['company_name'], fallback: ''),
      responsible: _asString(data['responsible'], fallback: ''),
      dni: _asString(data['dni'], fallback: ''),
      contact: _asString(data['contact'], fallback: ''),
      email: _asString(data['email'], fallback: ''),
      city: _asNullableString(data['city']),
      parish: _asNullableString(data['parish']),
      quarter: _asNullableString(data['quarter']),
      neighborhood: _asNullableString(data['neighborhood']),
      address: _asString(data['address'], fallback: ''),
      coordinates: coordsRaw,
      codeAddress: _asNullableString(data['code_address']),
      surface: _asNullableDouble(data['surface']),
      fertilityPercentage: _asNullableDouble(data['fertility_percentage']),
      birthRate: _asNullableDouble(data['birth_rate']),
      mortalityRate: _asNullableDouble(data['mortality_rate']),
      weaningPercentage: _asNullableDouble(data['weaning_percentage']),
      litersOfMilk: _asDouble(data['liters_of_milk']),
      observation: _asNullableString(data['observation']),
      lat: lat,
      lng: lng,
    );
  }

  Company copyWith({
    int? id,
    String? companyCode,
    String? companyName,
    String? responsible,
    String? dni,
    String? contact,
    String? email,
    String? city,
    String? parish,
    String? quarter,
    String? neighborhood,
    String? address,
    String? coordinates,
    String? codeAddress,
    double? surface,
    double? fertilityPercentage,
    double? birthRate,
    double? mortalityRate,
    double? weaningPercentage,
    double? litersOfMilk,
    double? lat,
    double? lng,
    String? observation,
  }) {
    return Company(
      id: id ?? this.id,
      companyCode: companyCode ?? this.companyCode,
      companyName: companyName ?? this.companyName,
      responsible: responsible ?? this.responsible,
      dni: dni ?? this.dni,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      city: city ?? this.city,
      parish: parish ?? this.parish,
      quarter: quarter ?? this.quarter,
      neighborhood: neighborhood ?? this.neighborhood,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      codeAddress: codeAddress ?? this.codeAddress,
      surface: surface ?? this.surface,
      fertilityPercentage: fertilityPercentage ?? this.fertilityPercentage,
      birthRate: birthRate ?? this.birthRate,
      mortalityRate: mortalityRate ?? this.mortalityRate,
      weaningPercentage: weaningPercentage ?? this.weaningPercentage,
      litersOfMilk: litersOfMilk ?? this.litersOfMilk,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      observation: observation ?? this.observation,
    );
  }

  factory Company.empty() {
    return const Company(
      id: 0,
      companyCode: "S/C",
      companyName: "Desconocido",
      responsible: "",
      dni: "",
      contact: "",
      email: "",
      address: "",
      quarter: null,
      neighborhood: null,
      surface: null,
      fertilityPercentage: null,
      birthRate: null,
      mortalityRate: null,
      weaningPercentage: null,
      litersOfMilk: 0,
    );
  }

  // ---------------- HELPERS ----------------

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0.0;
  }

  static double? _asNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    final text = v.toString().trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static String? _asNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? _nullIfEmpty(String? v) {
    if (v == null) return null;
    final text = v.trim();
    return text.isEmpty ? null : text;
  }

  /// ✅ soporta "lat,lng" o "lat lng" o "lat;lng"
  static (double?, double?) _parseCoordinates(String raw) {
    final cleaned = raw.replaceAll(';', ',').replaceAll(' ', ',');
    final parts =
        cleaned
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    if (parts.length < 2) return (null, null);

    final a = double.tryParse(parts[0]);
    final b = double.tryParse(parts[1]);
    return (a, b);
  }
}
