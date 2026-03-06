import 'package:ganaderos_utc/repositories/user_repository.dart';
import '../models/user_models.dart';

class CompanyAdminRuleService {
  final UserRepository repo;

  CompanyAdminRuleService(this.repo);

  Future<bool> companyHasAdmin(int companyId) async {
    final List<User> users =
        await UserRepository.getAll(); // si tienes endpoint por empresa, mejor
    return users.any(
      (u) =>
          (u.companyId ?? 0) == companyId &&
          (u.role ?? '').toLowerCase() == 'admin',
    );
  }
}
