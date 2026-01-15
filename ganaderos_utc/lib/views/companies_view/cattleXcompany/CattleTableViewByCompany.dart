import 'package:flutter/material.dart';
import 'package:ganaderos_utc/repository/cattle_company_form.dart';
import 'package:ganaderos_utc/repository/cattle_company_repository.dart';
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
  List<Cattle> cattleList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCattle();
  }

  Future<void> _loadCattle() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final data = await CattleCompanyRepository.getAllByCompany(
        widget.companyId,
      );
      if (!mounted) return;

      setState(() {
        cattleList = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar ganado: $e')));
    }
  }

  Future<void> _onEdit(Cattle cattle) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CattleCompanyForm(
            cattle: cattle,
            initialCompanyId: cattle.companyId, // ⚠️ Mantiene empresa al editar
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) {
      await _loadCattle();
    }
  }

  Future<void> _onAdd() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CattleCompanyForm(
            initialCompanyId: widget.companyId, // 🔒 Empresa fija al crear
            onSave: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) {
      await _loadCattle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : CattleTableByCompany(
                companyId: widget.companyId,
                onEdit: _onEdit,
                onAdd: _onAdd,
              ),
    );
  }
}
