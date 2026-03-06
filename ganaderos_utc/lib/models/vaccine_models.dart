import 'package:ganaderos_utc/models/cattle_models.dart';
import 'package:ganaderos_utc/models/company_models.dart';

class Vaccine {
  final int? id;
  final String date;
  final String name;

  // ✅ opcional
  final String? observation;

  final int cattleId;
  final int companyId;

  // ✅ consistente con el resto del proyecto (0/1)
  final int sync;

  final Cattle? cattle;
  final Company? company;

  Vaccine({
    this.id,
    required this.date,
    required this.name,
    this.observation,
    required this.cattleId,
    required this.companyId,
    required this.sync,
    this.cattle,
    this.company,
  });

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return Vaccine(
      id: map['id'] is int ? map['id'] : int.tryParse('${map['id']}'),
      date: map['date']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      observation: map['observation']?.toString(),
      cattleId: parseInt(map['cattle_id'] ?? map['cattleId']),
      companyId: parseInt(map['company_id'] ?? map['companyId']),
      cattle: map['cattle'] != null ? Cattle.fromMap(map['cattle']) : null,
      company: map['company'] != null ? Company.fromMap(map['company']) : null,
      sync: map['sync'] is bool ? (map['sync'] ? 1 : 0) : parseInt(map['sync']),
    );
  }

  Map<String, dynamic> toMap() {
    final data = {
      'id': id,
      'date': date,
      'name': name,
      'observation': observation,
      'cattle_id': cattleId,
      'company_id': companyId,
      'sync': sync,
    };

    // opcional: no mandar nulls
    data.removeWhere((k, v) => v == null);
    return data;
  }
}
