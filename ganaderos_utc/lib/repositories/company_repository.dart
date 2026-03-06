import '../models/company_models.dart';
import '../settings/api_connections.dart';

class CompanyRepository {
  static const String endpoint = "/companies";

  // ---------------------------------------------------------------------------
  // GET ALL
  // ---------------------------------------------------------------------------
  Future<List<Company>> getAll() async {
    final dynamic res = await ApiConnection.get(endpoint);
    if (res == null) return [];

    List<dynamic> rawList = [];

    if (res is List) {
      rawList = res;
    } else if (res is Map && res['data'] is List) {
      rawList = res['data'];
    } else if (res is Map && res['companies'] is List) {
      rawList = res['companies'];
    } else {
      return [];
    }

    return rawList
        .map((e) => Company.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // SOLO EMPRESAS CON COORDENADAS
  // ---------------------------------------------------------------------------
  Future<List<Company>> getAllWithCoords() async {
    final all = await getAll();
    return all.where((c) => c.lat != null && c.lng != null).toList();
  }

  // ---------------------------------------------------------------------------
  // PARA LA APP
  // ---------------------------------------------------------------------------
  Future<List<Company>> getAllForApp() async {
    return await getAll();
  }

  // ---------------------------------------------------------------------------
  // GET ONE
  // ---------------------------------------------------------------------------
  Future<Company?> getById(int id) async {
    try {
      final dynamic res = await ApiConnection.get('$endpoint/$id');
      if (res == null) return null;

      if (res is Map<String, dynamic>) {
        if (res['data'] is Map) {
          return Company.fromMap(Map<String, dynamic>.from(res['data']));
        }
        return Company.fromMap(res);
      }

      if (res is Map && res['data'] is Map) {
        return Company.fromMap(Map<String, dynamic>.from(res['data']));
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------
  Future<bool> create(Company company) async {
    final payload = _normalizePayload(company);

    final dynamic response = await ApiConnection.post(endpoint, payload);

    if (response == null) return false;
    if (response is bool) return response;
    if (response is int) return response > 0;
    if (response is Map) return true;

    return false;
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------
  Future<bool> update(Company company) async {
    if (company.id == null) return false;

    final payload = _normalizePayload(company);

    final dynamic result = await ApiConnection.patch(
      '$endpoint/${company.id}',
      payload,
    );

    if (result is bool) return result;
    if (result is int) return result > 0;
    if (result is Map) return true;

    return result != null;
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------
  Future<bool> delete(int id) async {
    final dynamic result = await ApiConnection.delete('$endpoint/$id');

    if (result is bool) return result;
    if (result is int) return result > 0;
    if (result is Map) return true;

    return result != null;
  }

  // ---------------------------------------------------------------------------
  // NORMALIZAR PAYLOAD
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _normalizePayload(Company c) {
    final map = <String, dynamic>{
      'id': c.id,
      'company_code': c.companyCode.trim(),
      'company_name': c.companyName.trim(),
      'responsible': c.responsible.trim(),
      'dni': c.dni.trim(),
      'contact': c.contact.trim(),
      'email': c.email.trim(),

      // ✅ solo parish se mantiene
      'parish': _cleanNullable(c.parish),
      'city': _cleanNullable(c.city),
      'quarter': _cleanNullable(c.quarter),
      'neighborhood': _cleanNullable(c.neighborhood),

      'address': c.address.trim(),
      'code_address': _cleanNullable(c.codeAddress),

      // ✅ SOLO coordinates se envía al backend
      'coordinates': c.coordinatesString,

      'surface': c.surface,
      'fertility_percentage': c.fertilityPercentage,
      'birth_rate': c.birthRate,
      'mortality_rate': c.mortalityRate,
      'weaning_percentage': c.weaningPercentage,
      'liters_of_milk': c.litersOfMilk,

      'observation': _cleanNullable(c.observation),
    };

    // limpia nulls
    map.removeWhere((key, value) => value == null);

    return map;
  }

  String? _cleanNullable(String? value) {
    if (value == null) return null;
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }
}
