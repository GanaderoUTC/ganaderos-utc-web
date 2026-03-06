import 'dart:convert';
import '../utils/storage.dart';
import '../models/user_models.dart';

class Session {
  static Future<User?> currentUser() async {
    final raw = await storageRead("user");
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return User.fromMap(Map<String, dynamic>.from(decoded));
  }

  static Future<bool> isAdmin() async {
    final u = await currentUser();
    return (u?.role ?? 'user') == 'admin';
  }

  static Future<int?> companyId() async {
    final u = await currentUser();
    return u?.companyId ?? u?.company?.id;
  }
}
