import '../models/diagnosis_models.dart';
import '../settings/api_connections.dart';

class DiagnosisRepository {
  static const String endpoint = "/diagnosis";

  // Obtener todos los diagnósticos
  static Future<List<Diagnosis>> getAll() async {
    try {
      final dataList = await ApiConnection.get(endpoint);

      // ✅ protección extra por si llega algo raro
      if (dataList.isEmpty) return [];

      return dataList
          .map((data) => Diagnosis.fromMap(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print("Error al obtener diagnósticos: $e");
      return [];
    }
  }

  // Crear un nuevo diagnóstico
  static Future<Diagnosis?> insertDiagnosis(Diagnosis diagnosis) async {
    try {
      final response = await ApiConnection.post(endpoint, diagnosis.toMap());
      if (response != null) return Diagnosis.fromMap(response);
    } catch (e) {
      // ignore: avoid_print
      print("Error al crear diagnóstico: $e");
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // ✅ helpers internos (sin tocar ApiConnection)
  // ---------------------------------------------------------------------------
  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  // Actualizar un diagnóstico existente
  static Future<bool> updateDiagnosis(Diagnosis diagnosis) async {
    if (diagnosis.id == null) return false;
    try {
      final result = await ApiConnection.patch(
        '$endpoint/${diagnosis.id}',
        diagnosis.toMap(),
      );

      // ✅ tolerante: si llega int, num o string
      return _asInt(result) > 0;
    } catch (e) {
      // ignore: avoid_print
      print("Error al actualizar diagnóstico: $e");
      return false;
    }
  }

  // Eliminar un diagnóstico por ID
  static Future<bool> deleteDiagnosis(int id) async {
    try {
      final result = await ApiConnection.delete('$endpoint/$id');

      // ✅ tolerante: si llega int, num o string
      return _asInt(result) > 0;
    } catch (e) {
      // ignore: avoid_print
      print("Error al eliminar diagnóstico: $e");
      return false;
    }
  }
}
