class Diagnosis {
  final int? id;
  final String name;
  final String description;
  final bool sync;

  Diagnosis({
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

  // Convertir datos del mapa a un objeto Diagnosis
  factory Diagnosis.fromMap(Map<String, dynamic> map) {
    return Diagnosis(
      id: map['id'] is int ? map['id'] : int.tryParse('${map['id']}'),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      sync: map['sync'] == 1 || map['sync'] == true,
    );
  }

  // Para copiar el objeto modificando solo lo necesario
  Diagnosis copyWith({int? id, String? name, String? description, bool? sync}) {
    return Diagnosis(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sync: sync ?? this.sync,
    );
  }

  @override
  String toString() {
    return 'Diagnosis(id: $id, name: $name, description: $description, sync: $sync)';
  }
}
