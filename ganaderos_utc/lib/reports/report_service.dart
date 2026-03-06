import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'templates/company_report_pdf.dart';

class ReportService {
  static Future<void> printCompanyReport({
    required String companyName,
    required String title,
    required DateTime from,
    required DateTime to,
    required List<Map<String, dynamic>> rows, // tabla genérica
    required Map<String, String> summary, // cards
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

  static Future<void> shareBytes(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'reporte.pdf');
  }
}
