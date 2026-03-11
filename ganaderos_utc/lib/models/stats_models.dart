class DashboardSummary {
  final int totalCattle;
  final int totalCompanies;
  final int totalUsers;
  final int totalCheckups;
  final int totalVaccines;
  final double milkTodayLitres;
  final double milkMonthLitres;
  final double avgWeight;

  DashboardSummary({
    required this.totalCattle,
    required this.totalCompanies,
    required this.totalUsers,
    required this.totalCheckups,
    required this.totalVaccines,
    required this.milkTodayLitres,
    required this.milkMonthLitres,
    required this.avgWeight,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalCattle: _asInt(
        _pick(json, [
          'totalCattle',
          'total_cattle',
          'cattleTotal',
          'cattle_total',
        ]),
      ),
      totalCompanies: _asInt(
        _pick(json, [
          'totalCompanies',
          'total_companies',
          'companiesTotal',
          'companies_total',
        ]),
      ),
      totalUsers: _asInt(
        _pick(json, ['totalUsers', 'total_users', 'usersTotal', 'users_total']),
      ),
      totalCheckups: _asInt(
        _pick(json, [
          'totalCheckups',
          'total_checkups',
          'checkupsTotal',
          'checkups_total',
        ]),
      ),
      totalVaccines: _asInt(
        _pick(json, [
          'totalVaccines',
          'total_vaccines',
          'vaccinesTotal',
          'vaccines_total',
        ]),
      ),
      milkTodayLitres: _asDouble(
        _pick(json, [
          'milkTodayLitres',
          'milk_today_litres',
          'milkToday',
          'milk_today',
          'todayMilk',
        ]),
      ),
      milkMonthLitres: _asDouble(
        _pick(json, [
          'milkMonthLitres',
          'milk_month_litres',
          'milkMonth',
          'milk_month',
          'monthMilk',
        ]),
      ),
      avgWeight: _asDouble(
        _pick(json, [
          'avgWeight',
          'avg_weight',
          'averageWeight',
          'average_weight',
        ]),
      ),
    );
  }
}

class AvgWeightByCattleItem {
  final String cattleName;
  final double avgWeight;

  AvgWeightByCattleItem({required this.cattleName, required this.avgWeight});

  factory AvgWeightByCattleItem.fromJson(Map<String, dynamic> json) {
    return AvgWeightByCattleItem(
      cattleName: _asString(
        _pick(json, ['cattleName', 'cattle_name', 'name', 'cattle']),
      ),
      avgWeight: _asDouble(
        _pick(json, ['avgWeight', 'avg_weight', 'weight', 'averageWeight']),
      ),
    );
  }
}

/// PRODUCCIÓN DE LECHE / RECOLECCIONES
class MilkDayItem {
  final int collectionId;
  final int cattleId;
  final int companyId;
  final DateTime date;
  final double litres;

  MilkDayItem({
    required this.collectionId,
    required this.cattleId,
    required this.companyId,
    required this.date,
    required this.litres,
  });

  factory MilkDayItem.fromJson(Map<String, dynamic> json) {
    final rawDate = _pick(json, [
      'date',
      'day',
      'collection_date',
      'created_at',
      'updated_at',
    ]);

    return MilkDayItem(
      collectionId: _asInt(
        _pick(json, ['id', 'collection_id', 'collectionId']),
      ),
      cattleId: _asInt(_pick(json, ['cattleId', 'cattle_id'])),
      companyId: _asInt(_pick(json, ['companyId', 'company_id'])),
      date: _asDate(rawDate),
      litres: _asDouble(
        _pick(json, [
          'litres',
          'liters',
          'milk',
          'milk_litres',
          'milk_liters',
          'value',
          'total',
        ]),
      ),
    );
  }
}

class CattleByCategoryItem {
  final String category;
  final int count;

  CattleByCategoryItem({required this.category, required this.count});

  factory CattleByCategoryItem.fromJson(Map<String, dynamic> json) {
    return CattleByCategoryItem(
      category: _asString(_pick(json, ['category', 'category_name', 'name'])),
      count: _asInt(_pick(json, ['count', 'total', 'value'])),
    );
  }
}

/// NUEVO: GANADO POR RAZA (PARA GRÁFICO PASTEL)
class CattleByBreedItem {
  final String breed;
  final int count;

  CattleByBreedItem({required this.breed, required this.count});

  factory CattleByBreedItem.fromJson(Map<String, dynamic> json) {
    return CattleByBreedItem(
      breed: _asString(_pick(json, ['breed', 'breed_name', 'name'])),
      count: _asInt(_pick(json, ['count', 'total', 'value'])),
    );
  }
}

class DashboardStatsResponse {
  final DashboardSummary summary;
  final List<MilkDayItem> milkByDay;
  final List<CattleByCategoryItem> cattleByCategory;
  final List<AvgWeightByCattleItem> avgWeightByCattle;
  final List<CattleByBreedItem> cattleByBreed;

  DashboardStatsResponse({
    required this.summary,
    required this.milkByDay,
    required this.cattleByCategory,
    required this.avgWeightByCattle,
    required this.cattleByBreed,
  });

  factory DashboardStatsResponse.fromJson(Map<String, dynamic> json) {
    final root =
        (json['data'] is Map<String, dynamic>)
            ? (json['data'] as Map<String, dynamic>)
            : json;

    final milkRaw = _asList(
      _pick(root, [
        'milkByDay',
        'milk_by_day',
        'milkCollections',
        'milk_collections',
        'collections',
      ]),
    );

    final catRaw = _asList(
      _pick(root, ['cattleByCategory', 'cattle_by_category', 'categories']),
    );

    final wRaw = _asList(
      _pick(root, [
        'avgWeightByCattle',
        'avg_weight_by_cattle',
        'weightByCattle',
        'weight_by_cattle',
      ]),
    );

    final breedRaw = _asList(
      _pick(root, [
        'cattleByBreed',
        'cattle_by_breed',
        'breeds',
        'breedStats',
        'breed_stats',
      ]),
    );

    return DashboardStatsResponse(
      summary: DashboardSummary.fromJson(
        (_pick(root, ['summary', 'resumen']) as Map?)
                ?.cast<String, dynamic>() ??
            {},
      ),
      milkByDay:
          milkRaw
              .whereType<Map>()
              .map((e) => MilkDayItem.fromJson(e.cast<String, dynamic>()))
              .toList(),
      cattleByCategory:
          catRaw
              .whereType<Map>()
              .map(
                (e) => CattleByCategoryItem.fromJson(e.cast<String, dynamic>()),
              )
              .toList(),
      avgWeightByCattle:
          wRaw
              .whereType<Map>()
              .map(
                (e) =>
                    AvgWeightByCattleItem.fromJson(e.cast<String, dynamic>()),
              )
              .toList(),
      cattleByBreed:
          breedRaw
              .whereType<Map>()
              .map((e) => CattleByBreedItem.fromJson(e.cast<String, dynamic>()))
              .toList(),
    );
  }
}

/// HELPERS

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) {
      return json[k];
    }
  }
  return null;
}

List<dynamic> _asList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v;
  return [];
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? 0;
}

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();

  final value = v.toString().trim().replaceAll(',', '.');
  return double.tryParse(value) ?? 0.0;
}

String _asString(dynamic v) {
  if (v == null) return '';
  return v.toString().trim();
}

DateTime _asDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;

  final s = v.toString().trim();

  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;

  final parts = s.split('/');
  if (parts.length == 3) {
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d != null && m != null && y != null) {
      return DateTime(y, m, d);
    }
  }

  return DateTime.now();
}
