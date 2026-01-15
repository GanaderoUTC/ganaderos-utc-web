import 'cattle_models.dart';
import 'company_models.dart';

class Collection {
  final int? id;
  final String date;
  final double litres;
  final int? illness;
  final double density;
  final String? observation;
  final int cattleId;
  final int companyId;
  final int sync;

  // Relaciones
  final Cattle? cattle;
  final Company? company;

  Collection({
    this.id,
    required this.date,
    required this.litres,
    this.illness,
    required this.density,
    this.observation,
    required this.cattleId,
    required this.companyId,
    required this.sync,
    this.cattle,
    this.company,
  });

  // Convertir desde JSON / Map
  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'],
      date: map['date']?.toString() ?? '',

      litres:
          (map['litres'] is int)
              ? (map['litres'] as int).toDouble()
              : (map['litres'] ?? 0.0).toDouble(),

      illness:
          map['illness'] == null
              ? null
              : (map['illness'] is int
                  ? map['illness']
                  : int.tryParse(map['illness'].toString())),

      density:
          (map['density'] is int)
              ? (map['density'] as int).toDouble()
              : (map['density'] ?? 0.0).toDouble(),

      observation: map['observation']?.toString(),

      // corrección del nombre de claves para IDs
      cattleId: map['cattle_id'] ?? 0,
      companyId: map['company_id'] ?? 0,

      // sync normalizado
      sync: map['sync'] is bool ? (map['sync'] ? 1 : 0) : (map['sync'] ?? 0),

      // Relaciones anidadas
      cattle: map['cattle'] != null ? Cattle.fromMap(map['cattle']) : null,
      company: map['company'] != null ? Company.fromMap(map['company']) : null,
    );
  }

  // Convertir a Map para BD/API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'litres': litres,
      'illness': illness,
      'density': density,
      'observation': observation,
      'cattle_id': cattleId,
      'company_id': companyId,
      'sync': sync,
    };
  }
}
