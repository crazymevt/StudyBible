import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
  /// Resolution for the print-time rasterization below. 300 dpi matches the
  /// effective resolution of most consumer printers; going higher multiplies
  /// memory/spool size for no visible gain on paper.
  static const _printDpi = 300.0;

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
      onLayout: (format) async {
        final bytes = await build(format);
        return await _rasterizeForPrint(bytes) ?? bytes;
      },
      name: documentName,
    );
  }

  /// Re-renders [bytes] as a PDF of full-page images, or returns null if the
  /// platform can't rasterize (then the vector PDF is printed as-is).
  ///
  /// This exists because some printers' built-in PDF/PostScript interpreters
  /// mishandle the CID-keyed TrueType subsets dart_pdf embeds: they silently
  /// substitute a font with different glyph widths, so the page previews fine
  /// everywhere on screen but prints with overlapping/letter-spaced text
  /// (DavBfr/dart_pdf#572). Sending pre-rendered pixels sidesteps every
  /// printer-side font engine. Exported PDF *files* keep real, selectable
  /// text — only the print path is rasterized.
  static Future<Uint8List?> _rasterizeForPrint(Uint8List bytes) async {
    try {
      if (!(await Printing.info()).canRaster) return null;
      final doc = pw.Document();
      await for (final page in Printing.raster(bytes, dpi: _printDpi)) {
        final png = await page.toPng();
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              page.width * PdfPageFormat.inch / _printDpi,
              page.height * PdfPageFormat.inch / _printDpi,
            ),
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.fill),
          ),
        );
      }
      // No pages rastered (empty/undecodable document) — print the original.
      if (doc.document.pdfPageList.pages.isEmpty) return null;
      return doc.save();
    } catch (_) {
      return null;
    }
  }
}
