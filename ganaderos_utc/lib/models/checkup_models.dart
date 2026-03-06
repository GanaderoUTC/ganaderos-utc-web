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

  // Relaciones anidadas
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
    final c = map['cattle'];
    final co = map['company'];

    return Checkup(
      id: _asInt(map['id']),
      date: (map['date'] ?? '').toString().trim(),
      symptom: (map['symptom'] ?? '').toString().trim(),
      diagnosis: (map['diagnosis'] ?? '').toString().trim(),
      treatment: (map['treatment'] ?? '').toString().trim(),
      observation: (map['observation'] ?? '').toString().trim(),

      cattleId: _asInt(map['cattle_id']) ?? 0,
      companyId: _asInt(map['company_id']) ?? 0,

      cattle: c is Map ? Cattle.fromMap(Map<String, dynamic>.from(c)) : null,
      company:
          co is Map ? Company.fromMap(Map<String, dynamic>.from(co)) : null,

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

  // ---------------- HELPERS ----------------

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
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
