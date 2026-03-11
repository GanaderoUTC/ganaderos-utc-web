import '../models/categories_models.dart';
import '../settings/api_connections.dart';

class CategoriesRepository {
  static const String endpoint = "/categories";

  // Obtener lista de categorías desde la API
  static Future<List<Category>> getAll() async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.getList(
        endpoint,
      );

      return dataList.map((data) => Category.fromMap(data)).toList();
    } catch (e) {
      // ignore: avoid_print
      print("Error al obtener categorías: $e");
      return [];
    }
  }

  // Crear una nueva categoría
  Future<Category?> create(Category category) async {
    try {
      final response = await ApiConnection.post(endpoint, category.toMap());
      if (response != null) {
        // ignore: unnecessary_type_check
        if (response is Map && response['data'] is Map) {
          return Category.fromMap(Map<String, dynamic>.from(response['data']));
        }
        // ignore: unnecessary_type_check
        if (response is Map<String, dynamic>) {
          return Category.fromMap(response);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error al crear categoría: $e");
    }
    return null;
  }

  // Actualizar una categoría existente
  Future<bool> update(Category category) async {
    if (category.id == null) return false;
    try {
      final response = await ApiConnection.patch(
        '$endpoint/${category.id}',
        category.toMap(),
      );
      return _asBool(response);
    } catch (e) {
      // ignore: avoid_print
      print("Error al actualizar categoría: $e");
      return false;
    }
  }

  // Eliminar una categoría por ID
  Future<bool> delete(int id) async {
    try {
      final response = await ApiConnection.delete('$endpoint/$id');
      return _asBool(response);
    } catch (e) {
      // ignore: avoid_print
      print("Error al eliminar categoría: $e");
      return false;
    }
  }

  // ---------------- HELPERS ----------------

  bool _asBool(dynamic value) {
    if (value == null) return false;

    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;

    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'ok' || v == 'success';
    }

    if (value is Map) {
      if (value.containsKey('success')) return _asBool(value['success']);
      if (value.containsKey('ok')) return _asBool(value['ok']);
      if (value.containsKey('status')) return _asBool(value['status']);
      if (value.containsKey('data')) return true;
      return true;
    }

    return false;
  }
}
