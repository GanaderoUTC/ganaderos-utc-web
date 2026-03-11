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

  /// sync: 1 = sincronizado, 0 = no sincronizado
  final int sync;

  /// Relaciones anidadas
  final Cattle? cattle;
  final Company? company;

  const Checkup({
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

  factory Checkup.fromMap(Map<String, dynamic> map) {
    final dynamic cattleMap = map['cattle'];
    final dynamic companyMap = map['company'];

    final int parsedCattleId =
        _asInt(map['cattle_id']) ??
        _asInt(map['cattleId']) ??
        (cattleMap is Map ? (_asInt(cattleMap['id']) ?? 0) : 0);

    final int parsedCompanyId =
        _asInt(map['company_id']) ??
        _asInt(map['companyId']) ??
        (companyMap is Map ? (_asInt(companyMap['id']) ?? 0) : 0);

    Cattle? parsedCattle;
    Company? parsedCompany;

    try {
      if (cattleMap is Map) {
        parsedCattle = Cattle.fromMap(Map<String, dynamic>.from(cattleMap));
      }
    } catch (_) {
      parsedCattle = null;
    }

    try {
      if (companyMap is Map) {
        parsedCompany = Company.fromMap(Map<String, dynamic>.from(companyMap));
      }
    } catch (_) {
      parsedCompany = null;
    }

    return Checkup(
      id: _asInt(map['id']),
      date: (map['date'] ?? '').toString().trim(),
      symptom: (map['symptom'] ?? '').toString().trim(),
      diagnosis: (map['diagnosis'] ?? '').toString().trim(),
      treatment: (map['treatment'] ?? '').toString().trim(),
      observation: (map['observation'] ?? '').toString().trim(),
      cattleId: parsedCattleId,
      companyId: parsedCompanyId,
      cattle: parsedCattle,
      company: parsedCompany,
      sync: _asIntBool(map['sync']),
    );
  }

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

  Checkup copyWith({
    int? id,
    String? date,
    String? symptom,
    String? diagnosis,
    String? treatment,
    String? observation,
    int? cattleId,
    int? companyId,
    int? sync,
    Cattle? cattle,
    Company? company,
  }) {
    return Checkup(
      id: id ?? this.id,
      date: date ?? this.date,
      symptom: symptom ?? this.symptom,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      observation: observation ?? this.observation,
      cattleId: cattleId ?? this.cattleId,
      companyId: companyId ?? this.companyId,
      sync: sync ?? this.sync,
      cattle: cattle ?? this.cattle,
      company: company ?? this.company,
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

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
