import '../models/categories_models.dart';
import '../settings/api_connections.dart';

class CategoriesRepository {
  static const String endpoint = "/categories"; // Ajusta según tu API real

  // Obtener lista de categorías desde la API
  static Future<List<Category>> getAll() async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        endpoint,
      );
      return dataList.map((data) => Category.fromMap(data)).toList();
    } catch (e) {
      print("Error al obtener categorías: $e");
      return [];
    }
  }

  // Crear una nueva categoría
  Future<Category?> create(Category category) async {
    try {
      final response = await ApiConnection.post(endpoint, category.toMap());
      if (response != null) {
        return Category.fromMap(response);
      }
    } catch (e) {
      print("Error al crear categoría: $e");
    }
    return null;
  }

  // Actualizar una categoría existente
  Future<bool> update(Category category) async {
    if (category.id == null) return false;
    try {
      final int result = await ApiConnection.patch(
        '$endpoint/${category.id}',
        category.toMap(),
      );
      return result > 0;
    } catch (e) {
      print("Error al actualizar categoría: $e");
      return false;
    }
  }

  // Eliminar una categoría por ID
  Future<bool> delete(int id) async {
    try {
      final int result = await ApiConnection.delete('$endpoint/$id');
      return result > 0;
    } catch (e) {
      print("Error al eliminar categoría: $e");
      return false;
    }
  }
}
