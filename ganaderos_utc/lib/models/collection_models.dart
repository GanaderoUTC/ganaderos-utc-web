import 'cattle_models.dart';
import 'company_models.dart';

class Collection {
  final int? id;

  /// Recomendado: "YYYY-MM-DD" o ISO string
  final String date;

  final double litres;

  /// 1 o 2
  final int illness;

  final double density;
  final String? observation;

  final int cattleId;
  final int companyId;

  /// sync: 1 = sincronizado, 0 = no sincronizado
  final int sync;

  // Relaciones
  final Cattle? cattle;
  final Company? company;

  const Collection({
    this.id,
    required this.date,
    required this.litres,
    required this.illness,
    required this.density,
    this.observation,
    required this.cattleId,
    required this.companyId,
    required this.sync,
    this.cattle,
    this.company,
  });

  Collection copyWith({
    int? id,
    String? date,
    double? litres,
    int? illness,
    double? density,
    String? observation,
    int? cattleId,
    int? companyId,
    int? sync,
    Cattle? cattle,
    Company? company,
  }) {
    final newIllness = illness ?? this.illness;

    return Collection(
      id: id ?? this.id,
      date: date ?? this.date,
      litres: litres ?? this.litres,
      illness: _normalizeIllness(newIllness),
      density: density ?? this.density,
      observation: observation ?? this.observation,
      cattleId: cattleId ?? this.cattleId,
      companyId: companyId ?? this.companyId,
      sync: sync ?? this.sync,
      cattle: cattle ?? this.cattle,
      company: company ?? this.company,
    );
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    final c = map['cattle'];
    final co = map['company'];

    final parsedIllness = _asInt(map['illness']) ?? 1;
    final illnessNorm = _normalizeIllness(parsedIllness);

    return Collection(
      id: _asInt(map['id']),
      date: (map['date'] ?? '').toString().trim(),
      litres: _asDouble(map['litres']),
      density: _asDouble(map['density']),
      illness: illnessNorm,
      observation:
          (map['observation'] == null)
              ? null
              : map['observation'].toString().trim(),
      cattleId: _asInt(map['cattle_id']) ?? 0,
      companyId: _asInt(map['company_id']) ?? 0,
      sync: _asIntBool(map['sync']),
      cattle: c is Map ? Cattle.fromMap(Map<String, dynamic>.from(c)) : null,
      company:
          co is Map ? Company.fromMap(Map<String, dynamic>.from(co)) : null,
    );
  }

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

  // ---------------- HELPERS ----------------

  static int _normalizeIllness(int v) {
    if (v == 2) return 2;
    return 1;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0.0;
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
