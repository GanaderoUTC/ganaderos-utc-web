import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'templates/company_report_pdf.dart';
import 'templates/stats_report_pdf.dart';

class ReportService {
  static Future<void> printCompanyReport({
    required String companyName,
    required String title,
    required DateTime from,
    required DateTime to,
    required List<Map<String, dynamic>> rows,
    required Map<String, String> summary,
  }) async {
    final bytes = await CompanyReportPdf.build(
      companyName: companyName,
      title: title,
      from: from,
      to: to,
      rows: rows,
      summary: summary,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Reporte_$companyName.pdf',
    );
  }

  /// NUEVO: REPORTE DE ESTADÍSTICAS
  static Future<void> printStatsReport({
    required String companyName,
    required String title,
    required DateTime from,
    required DateTime to,
    required Map<String, String> summary,
    required List<Map<String, dynamic>> milkRows,
    required List<Map<String, dynamic>> categoryRows,
    required List<Map<String, dynamic>> weightRows,
    required List<Map<String, dynamic>> breedRows,
  }) async {
    final bytes = await StatsReportPdf.build(
      companyName: companyName,
      title: title,
      from: from,
      to: to,
      summary: summary,
      milkRows: milkRows,
      categoryRows: categoryRows,
      weightRows: weightRows,
      breedRows: breedRows,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Reporte_Estadisticas_$companyName.pdf',
    );
  }

  static Future<void> shareBytes(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'reporte.pdf');
  }
}
