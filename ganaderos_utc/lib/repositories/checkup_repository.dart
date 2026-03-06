import '../models/checkup_models.dart';
import '../settings/api_connections.dart';

class CheckupRepository {
  static const String _basePath = "/checkup";

  static Future<List<Checkup>> getAll({int? companyId}) async {
    try {
      final path =
          companyId != null ? "$_basePath?companyId=$companyId" : _basePath;

      // ✅ ApiConnection.get puede devolver List o {data: []} o null
      final dynamic res = await ApiConnection.get(path);
      if (res == null) return [];

      List<dynamic> rawList = [];

      if (res is List) {
        rawList = res;
      } else if (res is Map && res['data'] is List) {
        rawList = res['data'] as List;
      } else {
        // Formato inesperado => devuelve vacío sin crashear
        return [];
      }

      return rawList
          .map((e) => Checkup.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print("Error al obtener chequeos: $e");
      return [];
    }
  }

  Future<Checkup?> create(Checkup checkup) async {
    try {
      final response = await ApiConnection.post(_basePath, checkup.toMap());
      if (response == null) return null;

      // ✅ puede venir directo o {data:{...}}
      // ignore: unnecessary_type_check
      if (response is Map<String, dynamic>) {
        return Checkup.fromMap(response);
      }
      // ignore: unnecessary_type_check
      if (response is Map && response['data'] is Map) {
        return Checkup.fromMap(Map<String, dynamic>.from(response['data']));
      }
    } catch (e) {
      print("Error al crear chequeo: $e");
    }
    return null;
  }

  Future<bool> update(Checkup checkup) async {
    if (checkup.id == null) return false;
    try {
      // ✅ patch puede devolver bool/int/json según tu ApiConnection
      final dynamic result = await ApiConnection.patch(
        "$_basePath/${checkup.id}",
        checkup.toMap(),
      );

      if (result is bool) return result;
      if (result is int) return result > 0;
      return result != null;
    } catch (e) {
      print("Error al actualizar chequeo: $e");
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final dynamic result = await ApiConnection.delete("$_basePath/$id");

      if (result is bool) return result;
      if (result is int) return result > 0;
      return result != null;
    } catch (e) {
      print("Error al eliminar chequeo: $e");
      return false;
    }
  }
}
