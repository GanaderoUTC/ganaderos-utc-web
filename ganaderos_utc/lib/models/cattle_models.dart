import 'breed_models.dart';
import 'categories_models.dart';
import 'origin_models.dart';
import 'company_models.dart';

class Cattle {
  final int? id;

  final String code;
  final String name;
  final String register;

  final int categoryId;
  final int gender;
  final int originId;
  final int breedId;

  final String? otherBreed;

  /// Idealmente en formato YYYY-MM-DD
  final String date;

  final double weight;
  final String? urlImage;

  final int companyId;

  /// sync: 1 = sincronizado, 0 = no sincronizado
  final int sync;

  // Relaciones anidadas
  final Category? category;
  final Origin? origin;
  final Breed? breed;
  final Company? company;

  const Cattle({
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

  factory Cattle.fromMap(Map<String, dynamic> data) {
    final cat = data['category'];
    final org = data['origin'];
    final brd = data['breed'];
    final cmp = data['company'];

    return Cattle(
      id: _asInt(data['id']),
      code: (data['code'] ?? '').toString().trim(),
      name: (data['name'] ?? '').toString().trim(),
      register: (data['register'] ?? '').toString().trim(),

      categoryId: _asInt(data['category_id']) ?? 0,
      gender: _asInt(data['gender']) ?? 0,
      originId: _asInt(data['origin_id']) ?? 0,
      breedId: _asInt(data['breed_id']) ?? 0,

      otherBreed: data['other_breed']?.toString(),

      date: (data['date'] ?? '').toString().trim(),
      weight: _asDouble(data['weight']) ?? 0.0,

      urlImage: data['url_image']?.toString(),
      companyId: _asInt(data['company_id']) ?? 0,

      sync: _asIntBool(data['sync']),

      category:
          cat is Map ? Category.fromMap(Map<String, dynamic>.from(cat)) : null,
      origin:
          org is Map ? Origin.fromMap(Map<String, dynamic>.from(org)) : null,
      breed: brd is Map ? Breed.fromMap(Map<String, dynamic>.from(brd)) : null,
      company:
          cmp is Map ? Company.fromMap(Map<String, dynamic>.from(cmp)) : null,
    );
  }

  factory Cattle.empty() {
    return const Cattle(
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

  // ---------------- HELPERS ----------------

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    return int.tryParse(s);
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    return double.tryParse(s);
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
