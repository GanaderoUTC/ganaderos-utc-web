import '../models/company_models.dart';
import '../settings/api_connections.dart';

class CompanyRepository {
  static const String endpoint = "/companies"; // ajusta según tu ruta real

  // Obtener lista de empresas
  Future<List<Company>> getAll() async {
    final List<Map<String, dynamic>> dataList = await ApiConnection.get(
      endpoint,
    );
    return dataList.map((data) => Company.fromMap(data)).toList();
  }

  // Crear una nueva empresa
  Future<Company?> create(Company company) async {
    final response = await ApiConnection.post(endpoint, company.toMap());
    if (response != null) {
      return Company.fromMap(response);
    }
    return null;
  }

  // Actualizar una empresa existente
  Future<bool> update(Company company) async {
    if (company.id == null) return false;
    final int result = await ApiConnection.patch(
      '$endpoint/${company.id}',
      company.toMap(),
    );
    return result > 0;
  }

  // Eliminar una empresa
  Future<bool> delete(int id) async {
    final int result = await ApiConnection.delete('$endpoint/$id');
    return result > 0;
  }
}
