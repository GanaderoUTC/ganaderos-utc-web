class Origin {
  final int? id;
  final String name;
  final String description;
  final bool sync;

  Origin({
    this.id,
    required this.name,
    required this.description,
    required this.sync,
  });

  // Convertir objeto a mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sync': sync ? 1 : 0,
    };
  }

  // Crear instancia desde SQLite o JSON
  factory Origin.fromMap(Map<String, dynamic> map) {
    return Origin(
      id: map['id'] is int ? map['id'] : int.tryParse('${map['id']}'),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      sync: map['sync'] == 1 || map['sync'] == true,
    );
  }

  // copyWith útil para formularios
  Origin copyWith({int? id, String? name, String? description, bool? sync}) {
    return Origin(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sync: sync ?? this.sync,
    );
  }

  @override
  String toString() {
    return 'Origin(id: $id, name: $name, description: $description, sync: $sync)';
  }
}
