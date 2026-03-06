import '../models/vaccine_models.dart';
import '../settings/api_connections.dart';

class VaccineCompanyRepository {
  // Mantengo el mismo para evitar que no traiga datos.
  static const String _basePath = "/Vaccines";

  // Obtener vacunas por CATTLE ID (filtrado seguro)
  static Future<List<Vaccine>> getAllByCattle(int cattleId) async {
    try {
      // ✅ coherente con ApiConnection: getList siempre devuelve lista
      final List<Map<String, dynamic>> rawList = await ApiConnection.getList(
        "$_basePath?cattleId=$cattleId",
      );

      final parsed =
          rawList
              .map((item) => Vaccine.fromMap(Map<String, dynamic>.from(item)))
              .toList();

      // ✅ FILTRO FINAL por si la API no filtra
      return parsed.where((v) {
        // campo directo
        if (v.cattleId == cattleId) return true;

        // respaldo: objeto anidado cattle
        final nestedId = v.cattle?.id;
        if (nestedId != null) return nestedId == cattleId;

        return false;
      }).toList();
    } catch (e) {
      print("❌ Error al obtener vacunas por cattleId=$cattleId: $e");
      return [];
    }
  }

  // Crear vacuna (requiere cattleId)
  static Future<Vaccine?> createForCattle(Vaccine vaccine) async {
    try {
      if (vaccine.cattleId == 0) {
        throw Exception("cattleId es requerido para crear una vacuna.");
      }

      final response = await ApiConnection.post(_basePath, vaccine.toMap());

      if (response != null) {
        return Vaccine.fromMap(Map<String, dynamic>.from(response));
      }

      print("⚠️ Respuesta inesperada al crear vacuna: $response");
      return null;
    } catch (e) {
      print("❌ Error al crear vacuna: $e");
      return null;
    }
  }

  // Actualizar vacuna
  static Future<bool> updateForCattle(Vaccine vaccine) async {
    try {
      if (vaccine.id == null) return false;

      final dynamic response = await ApiConnection.patch(
        "$_basePath/${vaccine.id}",
        vaccine.toMap(),
      );

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;
      if (response is Map && response['id'] != null) return true;

      print("⚠️ Respuesta inesperada al actualizar vacuna: $response");
      return false;
    } catch (e) {
      print("❌ Error al actualizar vacuna: $e");
      return false;
    }
  }

  // Eliminar vacuna
  static Future<bool> deleteForCattle(int id) async {
    try {
      final dynamic response = await ApiConnection.delete("$_basePath/$id");

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      return false;
    } catch (e) {
      print("❌ Error al eliminar vacuna: $e");
      return false;
    }
  }
}
