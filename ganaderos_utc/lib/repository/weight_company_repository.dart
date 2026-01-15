import '../models/weight_models.dart';
import '../settings/api_connections.dart';

class WeightCompanyRepository {
  // Mantengo el mismo endpoint de tu repo viejo para evitar romper la API
  static const String _basePath = "/Weight";

  // Obtener pesos por CATTLE ID (filtrado seguro)
  static Future<List<Weight>> getAllByCattle(int cattleId) async {
    try {
      final dynamic response = await ApiConnection.get(
        "$_basePath?cattleId=$cattleId",
      );

      if (response == null) return [];

      // Parseo flexible (List o {data: []})
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
              .map((item) => Weight.fromMap(Map<String, dynamic>.from(item)))
              .toList();

      // FILTRO FINAL por si la API no filtra
      final filtered =
          parsed.where((w) {
            // Prioridad 1: campo directo cattleId
            // ignore: unnecessary_null_comparison
            if (w.cattleId != null) return w.cattleId == cattleId;

            // Prioridad 2: objeto cattle anidado
            final nestedId = w.cattle?.id;
            if (nestedId != null) return nestedId == cattleId;

            return false;
          }).toList();

      return filtered;
    } catch (e) {
      print(" Error al obtener pesos por cattleId=$cattleId: $e");
      return [];
    }
  }

  // Crear peso (requiere cattleId)
  static Future<Weight?> createForCattle(Weight weight) async {
    try {
      // ignore: unnecessary_null_comparison
      if (weight.cattleId == null || weight.cattleId == 0) {
        throw Exception(
          "cattleId es requerido para crear un registro de peso.",
        );
      }

      final dynamic response = await ApiConnection.post(
        _basePath,
        weight.toMap(),
      );

      if (response != null && response is Map) {
        return Weight.fromMap(Map<String, dynamic>.from(response));
      }

      print(" Respuesta inesperada al crear peso: $response");
      return null;
    } catch (e) {
      print(" Error al crear peso: $e");
      return null;
    }
  }

  // Actualizar peso
  static Future<bool> updateForCattle(Weight weight) async {
    try {
      if (weight.id == null) return false;

      final dynamic response = await ApiConnection.patch(
        "$_basePath/${weight.id}",
        weight.toMap(),
      );

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;
      if (response is Map && response['id'] != null) return true;

      print(" Respuesta inesperada al actualizar peso: $response");
      return false;
    } catch (e) {
      print(" Error al actualizar peso: $e");
      return false;
    }
  }

  ///  Eliminar peso
  static Future<bool> deleteForCattle(int id) async {
    try {
      final dynamic response = await ApiConnection.delete("$_basePath/$id");

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      return false;
    } catch (e) {
      print(" Error al eliminar peso: $e");
      return false;
    }
  }
}
