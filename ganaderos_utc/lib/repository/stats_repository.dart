import 'package:ganaderos_utc/models/stats_models.dart';
import 'package:ganaderos_utc/settings/api_connections.dart';

class StatsRepository {
  Future<DashboardStatsResponse> getDashboard({
    int? companyId,
    int days = 30,
  }) async {
    final collections = await _safeGetList(
      _withCompany('/collection', companyId),
    );

    final weights = await _safeGetList(_withCompany('/Weight', companyId));

    final cattle = await _safeGetList(_withCompany('/cattle', companyId));

    final checkups = await _safeGetList(_withCompany('/checkup', companyId));

    final vaccines = await _safeGetList(_withCompany('/vaccines', companyId));

    final companies = await _safeGetList('/companies');
    final users = await _safeGetList('/users');

    final collectionsF = _filterByCompany(collections, companyId);
    final weightsF = _filterByCompany(weights, companyId);
    final cattleF = _filterByCompany(cattle, companyId);
    final checkupsF = _filterByCompany(checkups, companyId);
    final vaccinesF = _filterByCompany(vaccines, companyId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final from = today.subtract(Duration(days: days - 1));

    final collectionsRange =
        collectionsF.where((e) {
          final d = _extractCollectionDate(e);
          return d != null && !d.isBefore(from);
        }).toList();

    /// SUMMARY
    final totalCattle = cattleF.length;
    final totalCompanies = companyId == null ? companies.length : 1;

    final totalUsers =
        companyId == null
            ? users.length
            : _countUsersByCompany(users, companyId);

    final totalCheckups = checkupsF.length;
    final totalVaccines = vaccinesF.length;

    final milkToday = collectionsF
        .where((e) {
          final d = _extractCollectionDate(e);
          return d != null && _isSameDay(d, today);
        })
        .fold<double>(0, (sum, e) => sum + _extractLitres(e));

    final milkRange = collectionsRange.fold<double>(
      0,
      (sum, e) => sum + _extractLitres(e),
    );

    final avgWeight = _avg(
      weightsF.map((e) => _extractWeight(e)).where((e) => e > 0).toList(),
    );

    final summary = DashboardSummary(
      totalCattle: totalCattle,
      totalCompanies: totalCompanies,
      totalUsers: totalUsers,
      totalCheckups: totalCheckups,
      totalVaccines: totalVaccines,
      milkTodayLitres: milkToday,
      milkMonthLitres: milkRange,
      avgWeight: avgWeight,
    );

    /// GRAFICAS
    final milkByDay = _groupMilkByDay(collectionsRange);
    final cattleByCategory = _groupCattleByCategory(cattleF);
    final avgWeightByCattle = _avgWeightByCattle(weightsF, cattleF);
    final cattleByBreed = _groupCattleByBreed(cattleF);

    return DashboardStatsResponse(
      summary: summary,
      milkByDay: milkByDay,
      cattleByCategory: cattleByCategory,
      avgWeightByCattle: avgWeightByCattle,
      cattleByBreed: cattleByBreed,
    );
  }

  /// AGREGA companyId A QUERY
  String _withCompany(String endpoint, int? companyId) {
    if (companyId == null) return endpoint;

    return endpoint.contains('?')
        ? '$endpoint&companyId=$companyId'
        : '$endpoint?companyId=$companyId';
  }

  /// SAFE GET
  Future<List<Map<String, dynamic>>> _safeGetList(String endpoint) async {
    try {
      return await ApiConnection.getList(endpoint);
    } catch (e) {
      // ignore: avoid_print
      print('Error al consultar $endpoint: $e');
      return [];
    }
  }

  /// FILTRO POR EMPRESA
  List<Map<String, dynamic>> _filterByCompany(
    List<Map<String, dynamic>> list,
    int? companyId,
  ) {
    if (companyId == null) return list;

    return list.where((e) {
      final cid =
          e['company_id'] ??
          e['companyId'] ??
          e['company']?['id'] ??
          e['cattle']?['company_id'] ??
          e['cattle']?['companyId'] ??
          e['cattle']?['company']?['id'];

      return _asInt(cid) == companyId;
    }).toList();
  }

  /// USUARIOS POR EMPRESA
  int _countUsersByCompany(List<Map<String, dynamic>> users, int? companyId) {
    if (companyId == null) return users.length;

    return users.where((u) {
      final cid = u['company_id'] ?? u['companyId'] ?? u['company']?['id'];
      return _asInt(cid) == companyId;
    }).length;
  }

  /// PESO PROMEDIO POR GANADO
  List<AvgWeightByCattleItem> _avgWeightByCattle(
    List<Map<String, dynamic>> weightsF,
    List<Map<String, dynamic>> cattleF,
  ) {
    final cattleNameById = <int, String>{};

    for (final c in cattleF) {
      final id = _asInt(c['id']);
      if (id == null) continue;

      final name = _extractCattleName(c, id);
      cattleNameById[id] = name;
    }

    final sumByCattle = <int, double>{};
    final countByCattle = <int, int>{};

    for (final w in weightsF) {
      final cidRaw = w['cattle_id'] ?? w['cattleId'] ?? w['cattle']?['id'];

      final cattleId = _asInt(cidRaw);
      if (cattleId == null) continue;

      final weight = _extractWeight(w);
      if (weight <= 0) continue;

      sumByCattle[cattleId] = (sumByCattle[cattleId] ?? 0) + weight;
      countByCattle[cattleId] = (countByCattle[cattleId] ?? 0) + 1;
    }

    final list = <AvgWeightByCattleItem>[];

    for (final entry in sumByCattle.entries) {
      final id = entry.key;
      final cnt = countByCattle[id] ?? 1;
      final avg = cnt == 0 ? 0.0 : entry.value / cnt;

      list.add(
        AvgWeightByCattleItem(
          cattleName: cattleNameById[id] ?? 'Ganado $id',
          avgWeight: avg,
        ),
      );
    }

    list.sort((a, b) => b.avgWeight.compareTo(a.avgWeight));
    return list;
  }

  /// PRODUCCION DE LECHE POR DIA
  List<MilkDayItem> _groupMilkByDay(List<Map<String, dynamic>> collections) {
    final map = <String, double>{};
    final sample = <String, Map<String, dynamic>>{};

    for (final e in collections) {
      final d = _extractCollectionDate(e);
      if (d == null) continue;

      final key =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      map[key] = (map[key] ?? 0) + _extractLitres(e);
      sample[key] = e;
    }

    final items =
        map.entries.map((kv) {
          final data = sample[kv.key] ?? {};

          final collectionId =
              _asInt(
                data['id'] ?? data['collection_id'] ?? data['collectionId'],
              ) ??
              0;

          final cattleId =
              _asInt(
                data['cattle_id'] ?? data['cattleId'] ?? data['cattle']?['id'],
              ) ??
              0;

          final companyId =
              _asInt(
                data['company_id'] ??
                    data['companyId'] ??
                    data['company']?['id'] ??
                    data['cattle']?['company_id'] ??
                    data['cattle']?['companyId'] ??
                    data['cattle']?['company']?['id'],
              ) ??
              0;

          return MilkDayItem(
            collectionId: collectionId,
            cattleId: cattleId,
            companyId: companyId,
            date: DateTime.tryParse(kv.key) ?? DateTime.now(),
            litres: kv.value,
          );
        }).toList();

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  /// GANADO POR CATEGORIA
  List<CattleByCategoryItem> _groupCattleByCategory(
    List<Map<String, dynamic>> cattle,
  ) {
    final map = <String, int>{};

    for (final c in cattle) {
      final key = _extractCategoryName(c);
      map[key] = (map[key] ?? 0) + 1;
    }

    final items =
        map.entries
            .map((e) => CattleByCategoryItem(category: e.key, count: e.value))
            .toList();

    items.sort((a, b) => b.count.compareTo(a.count));
    return items;
  }

  /// GANADO POR RAZA
  List<CattleByBreedItem> _groupCattleByBreed(
    List<Map<String, dynamic>> cattle,
  ) {
    final map = <String, int>{};

    for (final c in cattle) {
      final key = _extractBreedName(c);
      map[key] = (map[key] ?? 0) + 1;
    }

    final items =
        map.entries
            .map((e) => CattleByBreedItem(breed: e.key, count: e.value))
            .toList();

    items.sort((a, b) => b.count.compareTo(a.count));
    return items;
  }

  String _extractCattleName(Map<String, dynamic> c, int id) {
    final name = c['name']?.toString().trim();
    final code = c['code']?.toString().trim();
    final register = c['register']?.toString().trim();

    if (name != null && name.isNotEmpty) return name;
    if (code != null && code.isNotEmpty) return code;
    if (register != null && register.isNotEmpty) return register;

    return 'Ganado $id';
  }

  String _extractCategoryName(Map<String, dynamic> c) {
    final catObj = c['category'];

    if (catObj is Map && catObj['name'] != null) {
      final name = catObj['name'].toString().trim();
      if (name.isNotEmpty) return name;
    }

    final alt = c['category_name']?.toString().trim();
    if (alt != null && alt.isNotEmpty) return alt;

    final cid = _asInt(c['category_id'] ?? c['categoryId']);
    if (cid != null) return 'Categoría $cid';

    return 'Sin categoría';
  }

  String _extractBreedName(Map<String, dynamic> c) {
    final breedObj = c['breed'];

    if (breedObj is Map && breedObj['name'] != null) {
      final name = breedObj['name'].toString().trim();
      if (name.isNotEmpty) return name;
    }

    final alt = c['breed_name']?.toString().trim();
    if (alt != null && alt.isNotEmpty) return alt;

    final bid = _asInt(c['breed_id'] ?? c['breedId']);
    if (bid != null) return 'Raza $bid';

    return 'Sin raza';
  }

  DateTime? _extractCollectionDate(Map<String, dynamic> e) {
    return _parseDate(
      e['date'] ??
          e['day'] ??
          e['collection_date'] ??
          e['created_at'] ??
          e['updated_at'],
    );
  }

  double _extractLitres(Map<String, dynamic> e) {
    return _asDouble(
      e['litres'] ??
          e['liters'] ??
          e['milk'] ??
          e['milk_litres'] ??
          e['milk_liters'] ??
          e['value'] ??
          e['total'],
    );
  }

  double _extractWeight(Map<String, dynamic> e) {
    return _asDouble(
      e['weight'] ?? e['avgWeight'] ?? e['avg_weight'] ?? e['value'],
    );
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;

    final s = v.toString().trim();
    if (s.isEmpty) return null;

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    final partsSlash = s.split('/');
    if (partsSlash.length == 3) {
      final d = int.tryParse(partsSlash[0]);
      final m = int.tryParse(partsSlash[1]);
      final y = int.tryParse(partsSlash[2]);

      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }

    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _avg(List<double> values) {
    if (values.isEmpty) return 0;

    final sum = values.fold<double>(0, (p, e) => p + e);
    return sum / values.length;
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0;

    if (v is num) return v.toDouble();

    final value = v.toString().trim().replaceAll(',', '.');
    return double.tryParse(value) ?? 0;
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;

    if (v is int) return v;
    if (v is num) return v.toInt();

    return int.tryParse(v.toString().trim());
  }
}
