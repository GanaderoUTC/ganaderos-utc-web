import '../models/vaccine_models.dart';
import '../settings/api_connections.dart';

class VaccineCompanyRepository {
  // Mantengo el mismo para evitar que no traiga datos.
  static const String _basePath = "/Vaccines";

  // Obtener vacunas por CATTLE ID (filtrado seguro)
  static Future<List<Vaccine>> getAllByCattle(int cattleId) async {
    try {
      final dynamic response = await ApiConnection.get(
        "$_basePath?cattleId=$cattleId",
      );

      if (response == null) return [];

      //  Parseo flexible (List o {data: []})
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] is List) {
        rawList = response['data'] as List;
      } else {
        print(" Formato inesperado en $_basePath: $response");
        return [];
      }

      final parsed =
          rawList
              .map((item) => Vaccine.fromMap(Map<String, dynamic>.from(item)))
              .toList();

      //  FILTRO FINAL por si la API no filtra
      final filtered =
          parsed.where((v) {
            // Prioridad 1: campo directo cattleId
            // ignore: unnecessary_null_comparison
            if (v.cattleId != null) return v.cattleId == cattleId;

            // Prioridad 2: objeto cattle anidado
            final nestedId = v.cattle?.id;
            if (nestedId != null) return nestedId == cattleId;

            return false;
          }).toList();

      return filtered;
    } catch (e) {
      print(" Error al obtener vacunas por cattleId=$cattleId: $e");
      return [];
    }
  }

  // Crear vacuna (requiere cattleId)
  static Future<Vaccine?> createForCattle(Vaccine vaccine) async {
    try {
      // ignore: unnecessary_null_comparison
      if (vaccine.cattleId == null || vaccine.cattleId == 0) {
        throw Exception("cattleId es requerido para crear una vacuna.");
      }

      final dynamic response = await ApiConnection.post(
        _basePath,
        vaccine.toMap(),
      );

      if (response != null && response is Map) {
        return Vaccine.fromMap(Map<String, dynamic>.from(response));
      }

      print(" Respuesta inesperada al crear vacuna: $response");
      return null;
    } catch (e) {
      print(" Error al crear vacuna: $e");
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

      print(" Respuesta inesperada al actualizar vacuna: $response");
      return false;
    } catch (e) {
      print(" Error al actualizar vacuna: $e");
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
      print(" Error al eliminar vacuna: $e");
      return false;
    }
  }
}
