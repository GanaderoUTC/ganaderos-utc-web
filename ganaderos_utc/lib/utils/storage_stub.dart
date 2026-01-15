// mobile/desktop implementation (SharedPreferences)
import 'package:shared_preferences/shared_preferences.dart';

Future<void> storageSave(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<String?> storageRead(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> storageRemove(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
