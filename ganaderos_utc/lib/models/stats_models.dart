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
      totalCattle: (json['totalCattle'] ?? 0) as int,
      totalCompanies: (json['totalCompanies'] ?? 0) as int,
      totalUsers: (json['totalUsers'] ?? 0) as int,
      totalCheckups: (json['totalCheckups'] ?? 0) as int,
      totalVaccines: (json['totalVaccines'] ?? 0) as int,
      milkTodayLitres: (json['milkTodayLitres'] as num?)?.toDouble() ?? 0,
      milkMonthLitres: (json['milkMonthLitres'] as num?)?.toDouble() ?? 0,
      avgWeight: (json['avgWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AvgWeightByCattleItem {
  final String cattleName;
  final double avgWeight;

  AvgWeightByCattleItem({required this.cattleName, required this.avgWeight});

  factory AvgWeightByCattleItem.fromJson(Map<String, dynamic> json) {
    return AvgWeightByCattleItem(
      cattleName: (json['cattleName'] ?? '').toString(),
      avgWeight: (json['avgWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MilkDayItem {
  final DateTime date;
  final double litres;

  MilkDayItem({required this.date, required this.litres});

  factory MilkDayItem.fromJson(Map<String, dynamic> json) {
    return MilkDayItem(
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      litres: (json['litres'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CattleByCategoryItem {
  final String category;
  final int count;

  CattleByCategoryItem({required this.category, required this.count});

  factory CattleByCategoryItem.fromJson(Map<String, dynamic> json) {
    return CattleByCategoryItem(
      category: (json['category'] ?? '').toString(),
      count: (json['count'] ?? 0) as int,
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
    final milk =
        (json['milkByDay'] as List? ?? [])
            .map((e) => MilkDayItem.fromJson(e as Map<String, dynamic>))
            .toList();

    final cattleCat =
        (json['cattleByCategory'] as List? ?? [])
            .map(
              (e) => CattleByCategoryItem.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    final w =
        (json['avgWeightByCattle'] as List? ?? [])
            .map(
              (e) => AvgWeightByCattleItem.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    return DashboardStatsResponse(
      summary: DashboardSummary.fromJson(json['summary'] ?? {}),
      milkByDay: milk,
      cattleByCategory: cattleCat,
      avgWeightByCattle: w,
    );
  }
}
