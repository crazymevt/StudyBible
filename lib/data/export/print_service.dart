import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Sends a PDF to the platform's print/preview sheet.
///
/// This is the single cross-platform print entry point reused by every
/// printable content type (sermons, notes/journals, the reader). The
/// `printing` package abstracts the platform difference: AirPrint on iOS, the
/// Android print framework, the native print dialog on macOS/Windows/Linux,
/// and the browser print sheet on web. So "print" is the same code everywhere —
/// only the UI affordance that triggers it differs per screen.
class PrintService {
  /// Opens the system print sheet, calling [build] to render the PDF for
  /// whatever [PdfPageFormat] the platform actually negotiates with the
  /// printer. [documentName] becomes the suggested job / file name (no
  /// extension). Completes when the sheet is dismissed — callers don't need
  /// to know whether the user actually printed.
  ///
  /// Rebuilding per [PdfPageFormat] (rather than handing over a document
  /// pre-rendered for a fixed size) matters: Android's default paper size is
  /// often A4, not the US Letter this app's PDFs used to be hardcoded to. A
  /// size-mismatched PDF gets rescaled by the OS print pipeline before it
  /// reaches the printer, and some print services render that rescale with
  /// visible ghosting/doubling — invisible in-app because the preview shows
  /// the PDF untouched.
  ///
  /// When [buildHtml] is provided, Android and iOS print jobs are rendered
  /// from that HTML by the OS WebView (`Printing.convertHtml`) instead of
  /// dart_pdf. Some printers' built-in PDF interpreters mishandle the
  /// CID-keyed TrueType subsets dart_pdf embeds and print overlapping or
  /// mis-spaced text from a PDF that previews fine everywhere
  /// (DavBfr/dart_pdf#572); the WebView embeds fonts the same way a browser
  /// does, which those printers handle correctly. Desktop keeps the dart_pdf
  /// path (no convertHtml implementation there), and exported PDF *files*
  /// are unaffected — this only changes what is handed to the print sheet.
  static Future<void> printPdf(
    Future<Uint8List> Function(PdfPageFormat format) build, {
    String documentName = 'StudyBible',
    Future<String> Function()? buildHtml,
  }) {
    final webViewPrint = buildHtml != null &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return Printing.layoutPdf(
      onLayout: webViewPrint
          ? (format) async =>
              // Deprecated upstream (the package wants to drop its WebView
              // dependency) but still the only in-process HTML→PDF renderer,
              // and the WebView engine is the point here.
              // ignore: deprecated_member_use
              Printing.convertHtml(html: await buildHtml(), format: format)
          : build,
      name: documentName,
    );
  }
}
