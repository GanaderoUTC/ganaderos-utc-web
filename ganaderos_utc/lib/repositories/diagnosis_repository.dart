import '../models/diagnosis_models.dart';
import '../settings/api_connections.dart';

class DiagnosisRepository {
  static const String endpoint = "/diagnosis";

  // Obtener todos los diagnósticos
  static Future<List<Diagnosis>> getAll() async {
    try {
      final List<dynamic> dataList = await ApiConnection.get(endpoint);
      return dataList.map((data) => Diagnosis.fromMap(data)).toList();
    } catch (e) {
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
      print("Error al crear diagnóstico: $e");
    }
    return null;
  }

  // Actualizar un diagnóstico existente
  static Future<bool> updateDiagnosis(Diagnosis diagnosis) async {
    if (diagnosis.id == null) return false;
    try {
      final response = await ApiConnection.patch(
        '$endpoint/${diagnosis.id}',
        diagnosis.toMap(),
      );
      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      print("Error al actualizar diagnóstico: $e");
      return false;
    }
  }

  // Eliminar un diagnóstico por ID
  static Future<bool> deleteDiagnosis(int id) async {
    try {
      final response = await ApiConnection.delete('$endpoint/$id');
      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      print("Error al eliminar diagnóstico: $e");
      return false;
    }
  }
}
