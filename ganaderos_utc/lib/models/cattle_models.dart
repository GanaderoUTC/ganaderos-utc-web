import 'breed_models.dart';
import 'categories_models.dart';
import 'origin_models.dart';
import 'company_models.dart';

class Cattle {
  int? id;
  String code;
  String name;
  String register;
  int categoryId;
  int gender;
  int originId;
  int breedId;
  String? otherBreed;
  String date;
  double weight;
  String? urlImage;
  int companyId;
  int sync;

  // Relaciones anidadas
  Category? category;
  Origin? origin;
  Breed? breed;
  Company? company;

  Cattle({
    this.id,
    required this.code,
    required this.name,
    required this.register,
    required this.categoryId,
    required this.gender,
    required this.originId,
    required this.breedId,
    this.otherBreed,
    required this.date,
    required this.weight,
    this.urlImage,
    required this.companyId,
    required this.sync,
    this.category,
    this.origin,
    this.breed,
    this.company,
  });

  /// Igualdad basada en ID → útil para DropdownButton
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cattle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Convierte a mapa para API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'register': register,
      'category_id': categoryId,
      'gender': gender,
      'origin_id': originId,
      'breed_id': breedId,
      'other_breed': otherBreed,
      'date': date,
      'weight': weight,
      'url_image': urlImage,
      'company_id': companyId,
      'sync': sync,
    };
  }

  /// Crea objeto desde JSON / Map
  factory Cattle.fromMap(Map<String, dynamic> data) {
    return Cattle(
      id: data['id'] ?? 0,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      register: data['register'] ?? '',
      categoryId: data['category_id'] ?? 0,
      gender: data['gender'] ?? 0,
      originId: data['origin_id'] ?? 0,
      breedId: data['breed_id'] ?? 0,
      otherBreed: data['other_breed'],
      date: data['date'] ?? '',
      weight:
          (data['weight'] is int)
              ? (data['weight'] as int).toDouble()
              : (data['weight'] ?? 0.0),
      urlImage: data['url_image'],
      companyId: data['company_id'] ?? 0,
      sync: data['sync'] is bool ? (data['sync'] ? 1 : 0) : (data['sync'] ?? 0),

      // Relaciones anidadas
      category:
          data['category'] != null ? Category.fromMap(data['category']) : null,
      origin: data['origin'] != null ? Origin.fromMap(data['origin']) : null,
      breed: data['breed'] != null ? Breed.fromMap(data['breed']) : null,
      company:
          data['company'] != null ? Company.fromMap(data['company']) : null,
    );
  }

  /// Valor por defecto para dropdowns o formularios nuevos
  factory Cattle.empty() {
    return Cattle(
      id: 0,
      code: "S/C",
      name: "Desconocido",
      register: "",
      categoryId: 0,
      gender: 0,
      originId: 0,
      breedId: 0,
      date: "",
      weight: 0.0,
      companyId: 0,
      sync: 0,
    );
  }
}
