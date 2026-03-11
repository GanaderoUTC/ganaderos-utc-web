import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StatsReportPdf {
  static Future<Uint8List> build({
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
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final generatedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final baseFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        ),
        build: (context) {
          return [
            _buildHeader(
              companyName: companyName,
              title: title,
              from: from,
              to: to,
              dateFormat: dateFormat,
              generatedAt: generatedAt,
            ),
            pw.SizedBox(height: 14),
            _buildSummarySection(summary),
            pw.SizedBox(height: 18),
            _buildSectionTitle('Producción de leche registrada'),
            _buildMilkTable(milkRows),
            pw.SizedBox(height: 16),
            _buildSectionTitle('Ganado por categoría'),
            _buildCategoryTable(categoryRows),
            pw.SizedBox(height: 16),
            _buildSectionTitle('Peso promedio por ganado'),
            _buildWeightTable(weightRows),
            pw.SizedBox(height: 16),
            _buildSectionTitle('Distribución de razas'),
            _buildBreedTable(breedRows),
          ];
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'UTC GEN APP - Reporte de estadísticas',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required String companyName,
    required String title,
    required DateTime from,
    required DateTime to,
    required DateFormat dateFormat,
    required String generatedAt,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.green300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'REPORTE DE ESTADÍSTICAS',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(title, style: const pw.TextStyle(fontSize: 13)),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              pw.Text('Empresa: $companyName'),
              pw.Text('Desde: ${dateFormat.format(from)}'),
              pw.Text('Hasta: ${dateFormat.format(to)}'),
              pw.Text('Generado: $generatedAt'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(Map<String, String> summary) {
    if (summary.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text('No existen datos de resumen para mostrar.'),
      );
    }

    final entries = summary.entries.toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Resumen general'),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              entries.map((e) {
                return pw.Container(
                  width: 160,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        e.key,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        e.value,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  static pw.Widget _buildMilkTable(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return _emptyBox('No existen registros de recolección de leche.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: const ['Fecha', 'Litros'],
      data:
          rows.map((e) {
            return ['${e['date'] ?? ''}', '${e['litres'] ?? ''}'];
          }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  static pw.Widget _buildCategoryTable(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return _emptyBox('No existen datos de ganado por categoría.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: const ['Categoría', 'Cantidad'],
      data:
          rows.map((e) {
            return ['${e['category'] ?? ''}', '${e['count'] ?? ''}'];
          }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  static pw.Widget _buildWeightTable(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return _emptyBox('No existen datos de peso promedio por ganado.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: const ['Ganado', 'Peso Promedio (kg)'],
      data:
          rows.map((e) {
            return ['${e['cattleName'] ?? ''}', '${e['avgWeight'] ?? ''}'];
          }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  static pw.Widget _buildBreedTable(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return _emptyBox('No existen datos de razas.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: const ['Raza', 'Cantidad'],
      data:
          rows.map((e) {
            return ['${e['breed'] ?? ''}', '${e['count'] ?? ''}'];
          }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  static pw.Widget _emptyBox(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(message, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
