class Category {
  int? id;
  String name;
  String description;
  int sync;

  Category({
    this.id,
    required this.name,
    required this.description,
    required this.sync,
  });

  // Transforma de clase a mapa
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description, 'sync': sync};
  }

  // Transforma de mapa a clase
  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      id: data['id'],
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sync: data['sync'] is bool ? (data['sync'] ? 1 : 0) : (data['sync'] ?? 0),
    );
  }

  // Default "Desconocido" para dropdowns
  factory Category.empty() {
    return Category(id: 0, name: "Desconocido", description: '', sync: 0);
  }
}
