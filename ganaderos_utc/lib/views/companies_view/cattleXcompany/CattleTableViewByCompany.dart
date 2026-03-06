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
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CattleCompanyForm(
            cattle: cattle,
            initialCompanyId: cattle.companyId, // mantiene empresa al editar
            onSave: () => Navigator.pop(context, true),
          ),
    );

    // ✅ refrescar tabla (la tabla se recarga internamente con su propio _loadCattle)
    if (result == true && mounted) {
      // forzar rebuild para que el widget hijo pueda recargar con botón actualizar o al volver
      setState(() {});
    }
  }

  Future<void> _onAdd() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CattleCompanyForm(
            initialCompanyId: widget.companyId, // empresa fija al crear
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ OJO: aquí NO usamos Scaffold, porque CattleTableByCompany ya tiene Scaffold/AppBar
    return CattleTableByCompany(
      companyId: widget.companyId,
      onEdit: _onEdit,
      onAdd: _onAdd,
    );
  }
}
