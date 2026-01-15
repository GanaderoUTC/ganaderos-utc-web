import '../models/breed_models.dart';
import '../settings/api_connections.dart';

class BreedsRepository {
  static const String endpoint = "/breeds"; // Ruta del endpoint en tu API

  // Obtener todas las razas
  static Future<List<Breed>> getAll() async {
    try {
      final List<dynamic> dataList = await ApiConnection.get(endpoint);
      return dataList.map((data) => Breed.fromMap(data)).toList();
    } catch (e) {
      print("Error al obtener razas: $e");
      return [];
    }
  }

  // Crear una nueva raza
  Future<Breed?> insertBreed(Breed breed) async {
    try {
      final response = await ApiConnection.post(endpoint, breed.toMap());
      if (response != null) {
        return Breed.fromMap(response);
      }
    } catch (e) {
      print("Error al crear raza: $e");
    }
    return null;
  }

  // Actualizar una raza existente
  Future<bool> updateBreed(Breed breed) async {
    if (breed.id == null) return false;
    try {
      final response = await ApiConnection.patch(
        '$endpoint/${breed.id}',
        breed.toMap(),
      );
      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      print("Error al actualizar raza: $e");
      return false;
    }
  }

  // Eliminar una raza por ID
  Future<bool> deleteBreed(int id) async {
    try {
      final response = await ApiConnection.delete('$endpoint/$id');
      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      print("Error al eliminar raza: $e");
      return false;
    }
  }
}
