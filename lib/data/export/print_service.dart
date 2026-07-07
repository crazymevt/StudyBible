import 'dart:typed_data';
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
  static Future<void> printPdf(
    Future<Uint8List> Function(PdfPageFormat format) build, {
    String documentName = 'StudyBible',
  }) {
    return Printing.layoutPdf(
      onLayout: build,
      name: documentName,
    );
  }
}
