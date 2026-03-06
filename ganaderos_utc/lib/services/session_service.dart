import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  final int userId;
  final int companyId;
  final String role; // 'admin' o 'user'
  final String companyName;

  const SessionData({
    required this.userId,
    required this.companyId,
    required this.role,
    required this.companyName,
  });
}

class SessionService {
  static const _kUserId = 'session_user_id';
  static const _kCompanyId = 'session_company_id';
  static const _kRole = 'session_role';
  static const _kCompanyName = 'session_company_name';

  static Future<void> save({
    required int userId,
    required int companyId,
    required String role,
    required String companyName,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kUserId, userId);
    await sp.setInt(_kCompanyId, companyId);
    await sp.setString(_kRole, role);
    await sp.setString(_kCompanyName, companyName);
  }

  static Future<SessionData?> get() async {
    final sp = await SharedPreferences.getInstance();
    final userId = sp.getInt(_kUserId);
    final companyId = sp.getInt(_kCompanyId);
    final role = sp.getString(_kRole);
    final companyName = sp.getString(_kCompanyName) ?? '';

    if (userId == null || companyId == null || role == null) return null;

    return SessionData(
      userId: userId,
      companyId: companyId,
      role: role,
      companyName: companyName,
    );
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUserId);
    await sp.remove(_kCompanyId);
    await sp.remove(_kRole);
    await sp.remove(_kCompanyName);
  }
}
