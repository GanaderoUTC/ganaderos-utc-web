import '../models/checkup_models.dart';
import '../settings/api_connections.dart';

class CheckupCattleRepository {
  static const String _basePath = "/checkup";

  // Obtener chequeos por CATTLE ID
  static Future<List<Checkup>> getAllByCattle(int cattleId) async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        "$_basePath?cattleId=$cattleId",
      );

      final parsed = dataList.map((e) => Checkup.fromMap(e)).toList();

      // FILTRO FINAL (por si la API no filtra)
      final filtered =
          parsed.where((c) {
            if (c.cattleId == cattleId) return true;
            final nestedId = c.cattle?.id;
            return nestedId == cattleId;
          }).toList();

      return filtered;
    } catch (e) {
      print("❌ Error al obtener chequeos por cattleId=$cattleId: $e");
      return [];
    }
  }

  // Crear chequeo
  static Future<Checkup?> createForCattle(Checkup checkup) async {
    try {
      if (checkup.cattleId == 0) {
        throw Exception("cattleId es requerido para crear un chequeo.");
      }

      final payload = checkup.toMap();

      if (payload['company_id'] == null || payload['company_id'] == 0) {
        payload.remove('company_id');
      }

      final response = await ApiConnection.post(_basePath, payload);

      if (response != null) {
        return Checkup.fromMap(Map<String, dynamic>.from(response));
      }

      return null;
    } catch (e) {
      print("❌ Error al crear chequeo: $e");
      return null;
    }
  }

  // Actualizar chequeo
  static Future<bool> updateForCattle(Checkup checkup) async {
    try {
      if (checkup.id == null) return false;

      final payload = checkup.toMap();
      if (payload['company_id'] == null || payload['company_id'] == 0) {
        payload.remove('company_id');
      }

      final int result = await ApiConnection.patch(
        "$_basePath/${checkup.id}",
        payload,
      );

      return result > 0;
    } catch (e) {
      print("❌ Error al actualizar chequeo: $e");
      return false;
    }
  }

  // Eliminar chequeo
  static Future<bool> deleteForCattle(int id) async {
    try {
      final int result = await ApiConnection.delete("$_basePath/$id");
      return result > 0;
    } catch (e) {
      print("❌ Error al eliminar chequeo: $e");
      return false;
    }
  }
}
