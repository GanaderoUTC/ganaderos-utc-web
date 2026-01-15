import '../models/checkup_models.dart';
import '../settings/api_connections.dart';

class CheckupCattleRepository {
  static const String _basePath = "/checkup";

  // Obtener chequeos por CATTLE ID (filtrado seguro)
  static Future<List<Checkup>> getAllByCattle(int cattleId) async {
    try {
      final dynamic response = await ApiConnection.get(
        "$_basePath?cattleId=$cattleId",
      );

      if (response == null) return [];

      // ✅ Parseo flexible (List o {data: []})
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] is List) {
        rawList = response['data'] as List;
      } else {
        print(" Formato inesperado en /checkup: $response");
        return [];
      }

      final parsed =
          rawList
              .map((item) => Checkup.fromMap(Map<String, dynamic>.from(item)))
              .toList();

      //  FILTRO FINAL (por si la API no filtra)
      final filtered =
          parsed.where((c) {
            // Prioridad 1: campo directo cattleId
            // ignore: unnecessary_null_comparison
            if (c.cattleId != null) return c.cattleId == cattleId;

            // Prioridad 2: objeto cattle anidado
            final nestedId = c.cattle?.id;
            if (nestedId != null) return nestedId == cattleId;

            return false;
          }).toList();

      return filtered;
    } catch (e) {
      print(" Error al obtener chequeos por cattleId=$cattleId: $e");
      return [];
    }
  }

  // Crear chequeo (requiere cattleId)
  static Future<Checkup?> createForCattle(Checkup checkup) async {
    try {
      // ignore: unnecessary_null_comparison
      if (checkup.cattleId == null || checkup.cattleId == 0) {
        throw Exception("cattleId es requerido para crear un chequeo.");
      }

      final Map<String, dynamic> payload = checkup.toMap();

      // PROTECCIÓN CLAVE
      if (payload['company_id'] == null || payload['company_id'] == 0) {
        payload.remove('company_id');
      }

      final dynamic response = await ApiConnection.post(_basePath, payload);

      if (response != null && response is Map) {
        return Checkup.fromMap(Map<String, dynamic>.from(response));
      }

      print(" Respuesta inesperada al crear chequeo: $response");
      return null;
    } catch (e) {
      print(" Error al crear chequeo: $e");
      return null;
    }
  }

  // Actualizar chequeo
  static Future<bool> updateForCattle(Checkup checkup) async {
    try {
      if (checkup.id == null) return false;

      final Map<String, dynamic> payload = checkup.toMap();

      if (payload['company_id'] == null || payload['company_id'] == 0) {
        payload.remove('company_id');
      }

      final dynamic response = await ApiConnection.patch(
        "$_basePath/${checkup.id}",
        payload,
      );

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;
      if (response is Map && response['id'] != null) return true;

      print(" Respuesta inesperada al actualizar: $response");
      return false;
    } catch (e) {
      print(" Error al actualizar chequeo: $e");
      return false;
    }
  }

  // Eliminar chequeo
  static Future<bool> deleteForCattle(int id) async {
    try {
      final dynamic response = await ApiConnection.delete("$_basePath/$id");

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      return false;
    } catch (e) {
      print(" Error al eliminar chequeo: $e");
      return false;
    }
  }
}
