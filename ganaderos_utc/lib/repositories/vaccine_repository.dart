import '../models/vaccine_models.dart';
import '../settings/api_connections.dart';

class VaccineRepository {
  static const String _basePath = "/vaccines";

  // Obtener lista de vacunas desde la API (por empresa)
  static Future<List<Vaccine>> getAll({int companyId = 1}) async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        "$_basePath?companyId=$companyId",
      );
      return dataList.map((data) => Vaccine.fromMap(data)).toList();
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al obtener vacunas: $e");
      return [];
    }
  }

  // Crear un nuevo registro de vacuna
  Future<Vaccine?> create(Vaccine vaccine) async {
    try {
      final response = await ApiConnection.post(_basePath, vaccine.toMap());
      if (response != null) {
        return Vaccine.fromMap(response);
      }
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al crear vacuna: $e");
    }
    return null;
  }

  // Actualizar un registro existente
  Future<bool> update(Vaccine vaccine) async {
    if (vaccine.id == null) return false;
    try {
      final int result = (await ApiConnection.patch(
        "$_basePath/${vaccine.id}",
        vaccine.toMap(),
      ));
      return result > 0;
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al actualizar vacuna: $e");
      return false;
    }
  }

  // Eliminar una vacuna por ID
  Future<bool> delete(int id) async {
    try {
      final int result = (await ApiConnection.delete("$_basePath/$id"));
      return result > 0;
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al eliminar vacuna: $e");
      return false;
    }
  }
}
