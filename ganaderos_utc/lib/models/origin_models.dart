class Origin {
  final int? id;
  final String name;
  final String description;
  final bool sync;

  const Origin({
    this.id,
    required this.name,
    required this.description,
    required this.sync,
  });

  // ---------------- MAP ----------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sync': sync ? 1 : 0,
    };
  }

  factory Origin.fromMap(Map<String, dynamic> map) {
    return Origin(
      id: _asInt(map['id']),
      name: _asString(map['name']),
      description: _asString(map['description']),
      sync: _asBool(map['sync']),
    );
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

  // ---------------- UTILS ----------------

  Origin copyWith({int? id, String? name, String? description, bool? sync}) {
    return Origin(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sync: sync ?? this.sync,
    );
  }

  factory Origin.empty() {
    return const Origin(
      id: 0,
      name: 'Desconocido',
      description: '',
      sync: false,
    );
  }

  @override
  String toString() {
    return 'Origin(id: $id, name: $name, description: $description, sync: $sync)';
  }
}
