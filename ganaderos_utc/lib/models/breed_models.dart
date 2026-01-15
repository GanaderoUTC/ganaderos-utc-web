class Breed {
  int? id;
  String name;
  String description;
  int sync;

  Breed({
    this.id,
    required this.name,
    required this.description,
    required this.sync,
  });

  // TRANSFORMA DE CLASE A MAPA
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description, 'sync': sync};
  }

  // TRANSFORMA DE MAPA A CLASE
  factory Breed.fromMap(Map<String, dynamic> data) {
    return Breed(
      id: data['id'],
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sync: data['sync'] is bool ? (data['sync'] ? 1 : 0) : (data['sync'] ?? 0),
    );
  }

  // Para valores default como “Desconocido”
  factory Breed.empty() {
    return Breed(id: 0, name: "Desconocido", description: '', sync: 0);
  }
}
