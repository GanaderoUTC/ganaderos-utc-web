import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CompanyReportPdf {
  static Future<Uint8List> build({
    required String companyName,
    required String title,
    required DateTime from,
    required DateTime to,
    required List<Map<String, dynamic>> rows,
    required Map<String, String> summary,
  }) async {
    final pdf = pw.Document();

    final df = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build:
            (ctx) => [
              _header(companyName, title, df.format(from), df.format(to)),
              pw.SizedBox(height: 14),
              _summaryCards(summary),
              pw.SizedBox(height: 16),
              _table(rows),
              pw.SizedBox(height: 14),
              pw.Divider(),
              pw.Text(
                'Generado: ${df.format(now)}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
        footer:
            (ctx) => pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Página ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _header(
    String companyName,
    String title,
    String from,
    String to,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'UTC GEN APP',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Empresa: $companyName',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Rango: $from - $to',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              'REPORTE',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryCards(Map<String, String> summary) {
    final items = summary.entries.toList();

    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          items.map((e) {
            return pw.Container(
              width: 170,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    e.key,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    e.value,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  static pw.Widget _table(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return pw.Text('Sin registros en el rango seleccionado.');
    }

    final headers = rows.first.keys.toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data:
          rows
              .map((r) => headers.map((h) => '${r[h] ?? ''}').toList())
              .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(),
      },
    );
  }
}
