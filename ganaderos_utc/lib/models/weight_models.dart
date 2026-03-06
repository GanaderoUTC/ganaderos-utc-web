import 'package:ganaderos_utc/models/cattle_models.dart';
import 'package:ganaderos_utc/models/company_models.dart';

class Weight {
  final int? id;
  final String date;
  final double weight;

  // ✅ opcional
  final String? observation;

  final int cattleId;
  final int companyId;

  // ✅ consistente con el proyecto
  final int sync;

  final Cattle? cattle;
  final Company? company;

  Weight({
    this.id,
    required this.date,
    required this.weight,
    this.observation,
    required this.cattleId,
    required this.companyId,
    required this.sync,
    this.cattle,
    this.company,
  });

  factory Weight.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return Weight(
      id: map['id'] is int ? map['id'] : int.tryParse('${map['id']}'),
      date: map['date']?.toString() ?? '',
      weight: parseDouble(map['weight']),
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
      'weight': weight,
      'observation': observation,
      'cattle_id': cattleId,
      'company_id': companyId,
      'sync': sync,
    };

    data.removeWhere((k, v) => v == null);
    return data;
  }

  Weight copyWith({
    int? id,
    String? date,
    double? weight,
    String? observation,
    int? cattleId,
    int? companyId,
    int? sync,
    Cattle? cattle,
    Company? company,
  }) {
    return Weight(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      observation: observation ?? this.observation,
      cattleId: cattleId ?? this.cattleId,
      companyId: companyId ?? this.companyId,
      sync: sync ?? this.sync,
      cattle: cattle ?? this.cattle,
      company: company ?? this.company,
    );
  }
}
