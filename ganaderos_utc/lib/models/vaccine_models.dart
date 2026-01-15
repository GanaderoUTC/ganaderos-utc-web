import 'package:ganaderos_utc/models/cattle_models.dart';
import 'package:ganaderos_utc/models/company_models.dart';

class Vaccine {
  final int? id;
  final String date;
  final String name;
  final String observation;
  final int cattleId;
  final int companyId;
  final bool sync;

  // Relaciones foráneas
  final Cattle? cattle;
  final Company? company;

  Vaccine({
    this.id,
    required this.date,
    required this.name,
    required this.observation,
    required this.cattleId,
    required this.companyId,
    this.cattle,
    this.company,
    required this.sync,
  });

  /// Convertir desde Mapa (DB / API)
  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'],
      date: map['date']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      observation: map['observation']?.toString() ?? '',
      cattleId:
          map['cattle_id'] is int
              ? map['cattle_id']
              : int.tryParse(map['cattle_id']?.toString() ?? '0') ?? 0,
      companyId:
          map['company_id'] is int
              ? map['company_id']
              : int.tryParse(map['company_id']?.toString() ?? '0') ?? 0,
      cattle: map['cattle'] != null ? Cattle.fromMap(map['cattle']) : null,
      company: map['company'] != null ? Company.fromMap(map['company']) : null,
      sync: map['sync'] == 1 || map['sync'] == true,
    );
  }

  /// Convertir a Mapa (DB / API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'name': name,
      'observation': observation,
      'cattle_id': cattleId,
      'company_id': companyId,
      'sync': sync ? 1 : 0,
    };
  }
}
