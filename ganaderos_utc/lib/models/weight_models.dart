import 'package:ganaderos_utc/models/cattle_models.dart';
import 'package:ganaderos_utc/models/company_models.dart';

class Weight {
  final int? id;
  final String date;
  final double weight;
  final String observation;
  final int cattleId;
  final int companyId;
  final bool sync;

  final Cattle? cattle;
  final Company? company;

  Weight({
    this.id,
    required this.date,
    required this.weight,
    required this.observation,
    required this.cattleId,
    required this.companyId,
    this.cattle,
    this.company,
    required this.sync,
  });

  // FROM MAP
  factory Weight.fromMap(Map<String, dynamic> map) {
    return Weight(
      id: map['id'],
      date: map['date'] ?? '',
      weight:
          map['weight'] is int
              ? (map['weight'] as int).toDouble()
              : double.tryParse(map['weight']?.toString() ?? '0') ?? 0.0,
      observation: map['observation'] ?? '',
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

  // TO MAP
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'weight': weight,
      'observation': observation,
      'cattle_id': cattleId,
      'company_id': companyId,
      'sync': sync ? 1 : 0,
    };
  }

  // COPY WITH (para EDITAR)
  Weight copyWith({
    int? id,
    String? date,
    double? weight,
    String? observation,
    int? cattleId,
    int? companyId,
    bool? sync,
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
