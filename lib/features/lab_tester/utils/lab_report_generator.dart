import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/models/lab_report_export.dart';

/// Renders a date-bounded lab-test export to a printable A4 sheet.
///
/// The branding, type scale and table construction are the house style the
/// dispatch challan established -- the same greens, the same Inter faces, the
/// same hairline grid -- so a lab report and a challan read as one family of
/// documents. The sheet is landscape because the report's twelve columns
/// cannot sit on one uninterrupted row in portrait without either splitting
/// or shrinking the type past legibility.
class LabReportGenerator {
  LabReportGenerator._();

  static const PdfColor _primary = PdfColor.fromInt(0xFF1E7A34);
  static const PdfColor _primaryDark = PdfColor.fromInt(0xFF145523);
  static const PdfColor _tintStrong = PdfColor.fromInt(0xFFE8F3EA);
  static const PdfColor _tintSoft = PdfColor.fromInt(0xFFF4F9F5);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111111);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF555555);
  static const PdfColor _textMuted = PdfColor.fromInt(0xFF999999);
  static const PdfColor _divider = PdfColor.fromInt(0xFFDCE0DC);
  static const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);

  /// Result semantics are the one place colour carries meaning rather than
  /// structure, which Rule Set B permits.
  static const PdfColor _fail = PdfColor.fromInt(0xFFC62828);

  static const double _hairline = 0.5;

  /// ASCII on purpose: the Helvetica fallback carries no em-dash glyph, so a
  /// nicer character would silently drop out when the font download fails.
  static const String _blank = '-';

  static Future<Uint8List> generate(LabReportExport report) async {
    final pw.Font base = await PdfGoogleFonts.interRegular();
    final pw.Font bold = await PdfGoogleFonts.interBold();
    final pw.Font italic = await PdfGoogleFonts.interItalic();

    final pw.Document doc = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold, italic: italic),
    );

    final pw.MemoryImage? logo = await _loadLogo();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _continuationHeader(report),
              ),
        footer: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            if (context.pageNumber == context.pagesCount) ...[
              _aboutReport(),
              pw.SizedBox(height: 10),
            ],
            _footer(context),
          ],
        ),
        build: (context) => [
          _header(report, logo),
          pw.SizedBox(height: 10),
          _periodStrip(report),
          pw.SizedBox(height: 10),
          _reportTable(report),
        ],
      ),
    );

    return doc.save();
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load(AppAssets.LOGO);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // ══════════════ HEADER ══════════════

  static pw.Widget _header(LabReportExport report, pw.MemoryImage? logo) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              // The logo and the company name share one line, centred
              // against each other so the mark and the wordmark read as a
              // single lockup rather than two stacked pieces.
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null) ...[
                    pw.Image(logo, width: 48, height: 48),
                    pw.SizedBox(width: 10),
                  ],
                  pw.Expanded(
                    child: pw.Text(
                      AppStrings.LAB_EXPORT_COMPANY_NAME,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'LAB TEST REPORT',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryDark,
                    letterSpacing: 1.4,
                  ),
                ),
                pw.SizedBox(height: 5),
                _kv('Period:', _period(report)),
                _kv('Records:', '${report.count}'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: _primary),
      ],
    );
  }

  static pw.Widget _continuationHeader(LabReportExport report) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'LAB TEST REPORT  ${_period(report)}',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _primaryDark,
              ),
            ),
            pw.Text(
              '${report.count} records',
              style: const pw.TextStyle(fontSize: 7.5, color: _textSecondary),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 1, color: _primary),
      ],
    );
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: _textSecondary,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            value.isEmpty ? _blank : value,
            style: pw.TextStyle(
              fontSize: 7.5,
              color: _textPrimary,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════ PERIOD STRIP ══════════════

  /// The report's cover facts in one tinted band, built the way the challan
  /// builds its journey strip: equal cells split by hairline verticals.
  static pw.Widget _periodStrip(LabReportExport report) {
    final int pass = report.results.where((item) => item.isPass).length;
    final int fail = report.results.where((item) => item.isFail).length;

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _tintSoft,
        border: pw.Border.all(color: _divider, width: _hairline),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Row(
        children: [
          _stripCell('FROM', _formatDate(report.startDate)),
          pw.Container(width: 1, height: 18, color: _divider),
          _stripCell('TO', _formatDate(report.endDate)),
          pw.Container(width: 1, height: 18, color: _divider),
          _stripCell('RECORDS', '${report.count}'),
          pw.Container(width: 1, height: 18, color: _divider),
          _stripCell('PASS', '$pass'),
          pw.Container(width: 1, height: 18, color: _divider),
          _stripCell('FAIL', '$fail'),
        ],
      ),
    );
  }

  static pw.Widget _stripCell(String label, String value) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: _textMuted,
                letterSpacing: 0.6,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              value.isEmpty ? _blank : value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════ TABLE ══════════════

  static pw.Widget _reportTable(LabReportExport report) {
    if (report.results.isEmpty) {
      return pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _divider, width: _hairline),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        padding: const pw.EdgeInsets.fromLTRB(10, 18, 10, 18),
        child: pw.Text(
          'No lab tests were recorded in this period.',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7.5, color: _textSecondary),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: _hairline),
      columnWidths: const {
        0: pw.FixedColumnWidth(58), // TESTED
        1: pw.FlexColumnWidth(), // PRODUCT
        2: pw.FixedColumnWidth(68), // LOT NO.
        3: pw.FixedColumnWidth(52), // QTY KG
        4: pw.FlexColumnWidth(), // PARTY
        5: pw.FixedColumnWidth(38), // PLANTS
        6: pw.FixedColumnWidth(40), // FEMALE
        7: pw.FixedColumnWidth(36), // OT
        8: pw.FixedColumnWidth(46), // IMPURITY
        9: pw.FixedColumnWidth(46), // GROW OUT
        10: pw.FixedColumnWidth(44), // RESULT
        11: pw.FixedColumnWidth(64), // TESTED BY
        12: pw.FixedColumnWidth(48), // STATUS
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: [
            _th('TESTED', pw.TextAlign.center),
            _th('PRODUCT', pw.TextAlign.left),
            _th('LOT NO.', pw.TextAlign.left),
            _th('QTY KG', pw.TextAlign.right),
            _th('PARTY', pw.TextAlign.left),
            _th('PLANTS', pw.TextAlign.right),
            _th('FEMALE', pw.TextAlign.right),
            _th('OT', pw.TextAlign.right),
            _th('IMPURITY', pw.TextAlign.right),
            _th('GROW OUT', pw.TextAlign.right),
            _th('RESULT', pw.TextAlign.center),
            _th('TESTED BY', pw.TextAlign.left),
            _th('STATUS', pw.TextAlign.left),
          ],
        ),
        ...report.results.asMap().entries.map((entry) {
          final int index = entry.key;
          final LabReportExportItem item = entry.value;
          final PdfColor bg = index.isEven ? _white : _tintSoft;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _td(_testedAt(item), pw.TextAlign.center),
              _tdStrong(item.productName, pw.TextAlign.left),
              _td(item.lotNo, pw.TextAlign.left),
              _td(item.quantityKg, pw.TextAlign.right),
              _td(item.partyName, pw.TextAlign.left),
              _td('${item.numberOfPlants}', pw.TextAlign.right),
              _td('${item.femaleCount}', pw.TextAlign.right),
              _td('${item.otCount}', pw.TextAlign.right),
              _td(item.geneticalImpurity, pw.TextAlign.right),
              _td(item.growOutTest, pw.TextAlign.right),
              _resultCell(item),
              _td(item.testedByName, pw.TextAlign.left),
              _td(item.status, pw.TextAlign.left),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _th(String text, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
          color: _white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static pw.Widget _td(String text, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text.trim().isEmpty ? _blank : text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 7, color: _textPrimary),
      ),
    );
  }

  static pw.Widget _tdStrong(String text, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text.trim().isEmpty ? _blank : text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _textPrimary,
        ),
      ),
    );
  }

  /// The only cell that carries colour: Pass reads brand green, Fail red, and
  /// an awaiting-re-test blank falls back to the muted placeholder.
  static pw.Widget _resultCell(LabReportExportItem item) {
    final bool isBlank = item.result.trim().isEmpty;
    final PdfColor color = item.isPass
        ? _primary
        : item.isFail
        ? _fail
        : _textPrimary;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        isBlank ? _blank : item.result,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: isBlank ? pw.FontWeight.normal : pw.FontWeight.bold,
          color: isBlank ? _textMuted : color,
        ),
      ),
    );
  }

  // ══════════════ ABOUT ══════════════

  /// The last page explains the two computed columns, so a reader who has
  /// never opened the app can still audit the numbers.
  static pw.Widget _aboutReport() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider, width: _hairline),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            color: _tintStrong,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: pw.Text(
              'ABOUT THIS REPORT',
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: _primaryDark,
                letterSpacing: 0.8,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 7),
            child: pw.Text(
              'Genetical Impurity = (Female count + OT count) / Number of '
              'plants x 100. Grow Out Test = 100 - Genetical Impurity. Both '
              'values are computed on the server and rounded to two decimal '
              'places. This report lists every lab test recorded within the '
              'period shown above.',
              style: const pw.TextStyle(
                fontSize: 6.5,
                color: _textSecondary,
                lineSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════ FOOTER ══════════════

  static pw.Widget _footer(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'This is a computer generated document.',
            style: pw.TextStyle(
              fontSize: 6.5,
              fontStyle: pw.FontStyle.italic,
              color: _textMuted,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 6.5, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ══════════════ FORMATTERS ══════════════

  static String _period(LabReportExport report) {
    final String from = _formatDate(report.startDate);
    final String to = _formatDate(report.endDate);
    if (from == _blank || to == _blank) return _blank;
    return '$from - $to';
  }

  /// A plain calendar day off the wire, printed as sent: applying the IST
  /// offset the timestamp formatter uses would be wrong for a day that has
  /// no instant behind it.
  static String _formatDate(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw.trim());
    return parsed == null ? _blank : DateFormatter.calendarDay(parsed);
  }

  /// A timestamp, shifted into IST the way every other screen prints one.
  static String _testedAt(LabReportExportItem item) =>
      item.testedAt == null ? _blank : DateFormatter.day(item.testedAt);
}
