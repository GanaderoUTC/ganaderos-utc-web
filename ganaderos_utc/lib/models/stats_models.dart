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
      totalCattle: _asInt(_pick(json, ['totalCattle', 'total_cattle'])),
      totalCompanies: _asInt(
        _pick(json, ['totalCompanies', 'total_companies']),
      ),
      totalUsers: _asInt(_pick(json, ['totalUsers', 'total_users'])),
      totalCheckups: _asInt(_pick(json, ['totalCheckups', 'total_checkups'])),
      totalVaccines: _asInt(_pick(json, ['totalVaccines', 'total_vaccines'])),
      milkTodayLitres: _asDouble(
        _pick(json, ['milkTodayLitres', 'milk_today_litres']),
      ),
      milkMonthLitres: _asDouble(
        _pick(json, ['milkMonthLitres', 'milk_month_litres']),
      ),
      avgWeight: _asDouble(_pick(json, ['avgWeight', 'avg_weight'])),
    );
  }
}

class AvgWeightByCattleItem {
  final String cattleName;
  final double avgWeight;

  AvgWeightByCattleItem({required this.cattleName, required this.avgWeight});

  factory AvgWeightByCattleItem.fromJson(Map<String, dynamic> json) {
    return AvgWeightByCattleItem(
      cattleName: _asString(_pick(json, ['cattleName', 'cattle_name', 'name'])),
      avgWeight: _asDouble(_pick(json, ['avgWeight', 'avg_weight', 'weight'])),
    );
  }
}

/// PRODUCCIÓN DE LECHE (COLLECTIONS)
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
    final rawDate = _pick(json, ['date', 'day', 'created_at']);

    return MilkDayItem(
      collectionId: _asInt(_pick(json, ['id', 'collection_id'])),
      cattleId: _asInt(_pick(json, ['cattleId', 'cattle_id'])),
      companyId: _asInt(_pick(json, ['companyId', 'company_id'])),
      date: _asDate(rawDate),
      litres: _asDouble(_pick(json, ['litres', 'liters', 'milk', 'value'])),
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
      count: _asInt(_pick(json, ['count', 'total'])),
    );
  }
}

class DashboardStatsResponse {
  final DashboardSummary summary;
  final List<MilkDayItem> milkByDay;
  final List<CattleByCategoryItem> cattleByCategory;
  final List<AvgWeightByCattleItem> avgWeightByCattle;

  DashboardStatsResponse({
    required this.summary,
    required this.milkByDay,
    required this.cattleByCategory,
    required this.avgWeightByCattle,
  });

  factory DashboardStatsResponse.fromJson(Map<String, dynamic> json) {
    final root =
        (json['data'] is Map<String, dynamic>)
            ? (json['data'] as Map<String, dynamic>)
            : json;

    final milkRaw = _pick(root, ['milkByDay', 'milk_by_day']) as List? ?? [];

    final catRaw =
        _pick(root, ['cattleByCategory', 'cattle_by_category']) as List? ?? [];

    final wRaw =
        _pick(root, ['avgWeightByCattle', 'avg_weight_by_cattle']) as List? ??
        [];

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
    );
  }
}

/// HELPERS

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
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
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim().replaceAll(',', '.')) ?? 0.0;
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
