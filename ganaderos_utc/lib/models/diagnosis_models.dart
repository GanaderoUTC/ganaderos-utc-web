class Diagnosis {
  final int? id;
  final String name;
  final String description;
  final bool sync;

  const Diagnosis({
    this.id,
    required this.name,
    required this.description,
    required this.sync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sync': sync ? 1 : 0,
    };
  }

  factory Diagnosis.fromMap(Map<String, dynamic> map) {
    return Diagnosis(
      id: _asInt(map['id']),
      name: _asString(map['name']),
      description: _asString(map['description']),
      sync: _asBool(map['sync']),
    );
  }

  Diagnosis copyWith({int? id, String? name, String? description, bool? sync}) {
    return Diagnosis(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sync: sync ?? this.sync,
    );
  }

  factory Diagnosis.empty() {
    return const Diagnosis(
      id: 0,
      name: 'Desconocido',
      description: '',
      sync: false,
    );
  }

  @override
  String toString() {
    return 'Diagnosis(id: $id, name: $name, description: $description, sync: $sync)';
  }

  // ---------------- HELPERS ----------------

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static String _asString(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

  static bool _asBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'si';
  }
}
