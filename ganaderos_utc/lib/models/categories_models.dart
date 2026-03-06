class Category {
  final int? id;
  final String name;
  final String description;

  /// sync: 1 = sincronizado, 0 = no sincronizado
  final int sync;

  const Category({
    this.id,
    required this.name,
    required this.description,
    required this.sync,
  });

  Category copyWith({int? id, String? name, String? description, int? sync}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sync: sync ?? this.sync,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description, 'sync': sync};
  }

  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      id: _asInt(data['id']),
      name: (data['name'] ?? '').toString().trim(),
      description: (data['description'] ?? '').toString().trim(),
      sync: _asIntBool(data['sync']),
    );
  }

  factory Category.empty() {
    return const Category(id: 0, name: "Desconocido", description: '', sync: 0);
  }

  // ---------------- HELPERS ----------------

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    return int.tryParse(s);
  }

  /// Convierte true/false, 1/0, "1"/"0", "true"/"false" a int 1/0
  static int _asIntBool(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v == 1 ? 1 : 0;
    if (v is num) return v.toInt() == 1 ? 1 : 0;
    if (v is bool) return v ? 1 : 0;

    final s = v.toString().trim().toLowerCase();
    if (s == '1' || s == 'true' || s == 'yes' || s == 'si') return 1;
    return 0;
  }
}
