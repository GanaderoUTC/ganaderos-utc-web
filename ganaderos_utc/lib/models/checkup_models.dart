import 'package:ganaderos_utc/models/cattle_models.dart';
import 'package:ganaderos_utc/models/company_models.dart';

class Checkup {
  final int? id;
  final String date;
  final String symptom;
  final String diagnosis;
  final String treatment;
  final String observation;
  final int cattleId;
  final int companyId;
  final int sync;

  // Relaciones anidadas
  final Cattle? cattle;
  final Company? company;

  Checkup({
    this.id,
    required this.date,
    required this.symptom,
    required this.diagnosis,
    required this.treatment,
    required this.observation,
    required this.cattleId,
    required this.companyId,
    this.cattle,
    this.company,
    required this.sync,
  });

  // Convertir desde JSON / Map
  factory Checkup.fromMap(Map<String, dynamic> map) {
    return Checkup(
      id: map['id'],
      date: map['date'] ?? '',
      symptom: map['symptom'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      treatment: map['treatment'] ?? '',
      observation: map['observation'] ?? '',
      cattleId: map['cattle_id'] ?? 0,
      companyId: map['company_id'] ?? 0,

      // Relaciones anidadas seguras
      cattle: map['cattle'] != null ? Cattle.fromMap(map['cattle']) : null,
      company: map['company'] != null ? Company.fromMap(map['company']) : null,

      // Normalizar sync
      sync: map['sync'] is bool ? (map['sync'] ? 1 : 0) : (map['sync'] ?? 0),
    );
  }

  // Convertir a Map para BD/API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'symptom': symptom,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'observation': observation,
      'cattle_id': cattleId,
      'company_id': companyId,
      'sync': sync,
    };
  }
}
