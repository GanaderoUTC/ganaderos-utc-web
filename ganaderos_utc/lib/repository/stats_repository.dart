import 'package:ganaderos_utc/models/stats_models.dart';
import 'package:ganaderos_utc/settings/api_connections.dart';

class StatsRepository {
  Future<DashboardStatsResponse> getDashboard({
    int? companyId,
    int days = 30,
  }) async {
    final collections = await ApiConnection.getList(
      _withCompany('/collection', companyId),
    );

    final weights = await ApiConnection.getList(
      _withCompany('/Weight', companyId),
    );

    final cattle = await ApiConnection.getList(
      _withCompany('/cattle', companyId),
    );

    final checkups = await ApiConnection.getList(
      _withCompany('/checkup', companyId),
    );

    final vaccines = await ApiConnection.getList(
      _withCompany('/vaccines', companyId),
    );

    final companies = await _safeGetList('/companies');
    final users = await _safeGetList('/users');

    final collectionsF = _filterByCompany(collections, companyId);
    final weightsF = _filterByCompany(weights, companyId);
    final cattleF = _filterByCompany(cattle, companyId);
    final checkupsF = _filterByCompany(checkups, companyId);
    final vaccinesF = _filterByCompany(vaccines, companyId);

    final now = DateTime.now();
    final from = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final collectionsRange =
        collectionsF.where((e) {
          final d = _parseDate(e['date']);
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

    final today = DateTime(now.year, now.month, now.day);

    final milkToday = collectionsF
        .where((e) {
          final d = _parseDate(e['date']);
          return d != null && _isSameDay(d, today);
        })
        .fold<double>(0, (sum, e) => sum + _asDouble(e['litres']));

    final milkRange = collectionsRange.fold<double>(
      0,
      (sum, e) => sum + _asDouble(e['litres']),
    );

    final avgWeight = _avg(
      weightsF.map((e) => _asDouble(e['weight'])).toList(),
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

    return DashboardStatsResponse(
      summary: summary,
      milkByDay: milkByDay,
      cattleByCategory: cattleByCategory,
      avgWeightByCattle: avgWeightByCattle,
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
    } catch (_) {
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
      final cid = e['company_id'] ?? e['companyId'] ?? e['company']?['id'];
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

      final name = (c['name'] ?? c['code'] ?? 'Ganado $id').toString();
      cattleNameById[id] = name;
    }

    final sumByCattle = <int, double>{};
    final countByCattle = <int, int>{};

    for (final w in weightsF) {
      final cidRaw = w['cattle_id'] ?? w['cattleId'] ?? w['cattle']?['id'];
      final cattleId = _asInt(cidRaw);

      if (cattleId == null) continue;

      sumByCattle[cattleId] =
          (sumByCattle[cattleId] ?? 0) + _asDouble(w['weight']);

      countByCattle[cattleId] = (countByCattle[cattleId] ?? 0) + 1;
    }

    final list = <AvgWeightByCattleItem>[];

    for (final entry in sumByCattle.entries) {
      final id = entry.key;
      final cnt = countByCattle[id] ?? 1;

      final avg = entry.value / cnt;

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
      final d = _parseDate(e['date']);
      if (d == null) continue;

      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      map[key] = (map[key] ?? 0) + _asDouble(e['litres']);

      sample[key] = e;
    }

    final items =
        map.entries.map((kv) {
          final data = sample[kv.key]!;

          final collectionId = _asInt(data['id'] ?? data['collection_id']) ?? 0;

          final cattleId =
              _asInt(
                data['cattle_id'] ?? data['cattleId'] ?? data['cattle']?['id'],
              ) ??
              0;

          final companyId =
              _asInt(
                data['company_id'] ??
                    data['companyId'] ??
                    data['company']?['id'],
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
      String key = '';

      final catObj = c['category'];

      if (catObj is Map && catObj['name'] != null) {
        key = catObj['name'].toString();
      } else {
        final cid = c['category_id'] ?? c['categoryId'];
        key = 'Cat ${_asInt(cid) ?? 0}';
      }

      map[key] = (map[key] ?? 0) + 1;
    }

    final items =
        map.entries
            .map((e) => CattleByCategoryItem(category: e.key, count: e.value))
            .toList();

    items.sort((a, b) => b.count.compareTo(a.count));

    return items;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;

    final s = v.toString().trim();

    if (s.isEmpty) return null;

    return DateTime.tryParse(s);
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

    return double.tryParse(v.toString()) ?? 0;
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;

    if (v is int) return v;

    if (v is num) return v.toInt();

    return int.tryParse(v.toString());
  }
}
