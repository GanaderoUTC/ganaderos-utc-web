import 'dart:convert';
import 'package:flutter/services.dart';

class LocationEcService {
  static Map<String, dynamic>? _data;

  static Future<Map<String, dynamic>> _loadData() async {
    if (_data != null) return _data!;

    final jsonString = await rootBundle.loadString(
      'assets/data/ecuador_divisiones.json',
    );

    _data = json.decode(jsonString);

    return _data!;
  }

  static Future<List<String>> getProvinces() async {
    final data = await _loadData();
    return data.keys.toList()..sort();
  }

  static Future<List<String>> getCantons(String province) async {
    final data = await _loadData();

    if (!data.containsKey(province)) return [];

    final cantons = data[province] as Map<String, dynamic>;

    return cantons.keys.toList()..sort();
  }

  static Future<List<String>> getParishes(
    String province,
    String canton,
  ) async {
    final data = await _loadData();

    if (!data.containsKey(province)) return [];

    final cantons = data[province] as Map<String, dynamic>;

    if (!cantons.containsKey(canton)) return [];

    final parishes = cantons[canton] as List;

    return List<String>.from(parishes)..sort();
  }
}
