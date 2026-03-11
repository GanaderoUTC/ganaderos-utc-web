import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repository/cattle_company_form.dart';
import '../../../models/cattle_models.dart';
import 'cattle_table_by_company.dart';

class CattleTableViewByCompany extends StatefulWidget {
  final int companyId;

  const CattleTableViewByCompany({super.key, required this.companyId});

  @override
  State<CattleTableViewByCompany> createState() =>
      _CattleTableViewByCompanyState();
}

class _CattleTableViewByCompanyState extends State<CattleTableViewByCompany> {
  Future<void> _onEdit(Cattle cattle) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CattleCompanyForm(
            cattle: cattle,
            initialCompanyId: cattle.companyId,
            onSave: () {},
          ),
    );
  }

  Future<void> _onAdd() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CattleCompanyForm(
            initialCompanyId: widget.companyId,
            onSave: () {},
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CattleTableByCompany(
      companyId: widget.companyId,
      onEdit: _onEdit,
      onAdd: _onAdd,
    );
  }
}
