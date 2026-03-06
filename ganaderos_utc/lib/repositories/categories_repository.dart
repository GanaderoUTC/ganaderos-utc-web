import '../models/categories_models.dart';
import '../settings/api_connections.dart';

class CategoriesRepository {
  static const String endpoint = "/categories";

  // Obtener lista de categorías desde la API (robusto)
  static Future<List<Category>> getAll() async {
    try {
      // ✅ usa método robusto (List o {data:[]})
      final List<Map<String, dynamic>> dataList = await ApiConnection.getList(
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
        // ✅ si viene {data:{...}} también funciona
        if (response['data'] is Map) {
          return Category.fromMap(Map<String, dynamic>.from(response['data']));
        }
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
      // ✅ patch ahora es bool (no int)
      final bool ok =
          (await ApiConnection.patch(
                '$endpoint/${category.id}',
                category.toMap(),
              ))
              as bool;
      return ok;
    } catch (e) {
      print("Error al actualizar categoría: $e");
      return false;
    }
  }

  // Eliminar una categoría por ID
  Future<bool> delete(int id) async {
    try {
      // ✅ delete ahora es bool (no int)
      final bool ok = (await ApiConnection.delete('$endpoint/$id')) as bool;
      return ok;
    } catch (e) {
      print("Error al eliminar categoría: $e");
      return false;
    }
  }
}
