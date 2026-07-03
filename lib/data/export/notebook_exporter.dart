import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:file_selector/file_selector.dart';
import '../user_store.dart';
import '../logging.dart';
import 'delta_markdown.dart';
import 'document_pdf.dart';
import 'print_service.dart';
import 'sermon_exporter.dart' show ExportFormat, ExportAction;

/// Exports a notebook (its title + ordered pages) to a single file. Reuses the
/// rich-text rendering engines shared with the sermon exporter
/// (`quillDeltaToPdfWidgets`, `QuillDeltaToHtmlConverter`, Quill's plain-text
/// projection) plus the new [deltaToMarkdown]. Each page becomes a section.
class NotebookExporter {
  static Future<void> exportNotebook(
    BuildContext context,
    Notebook notebook,
    List<NotebookPage> pages,
    ExportFormat format,
    ExportAction action,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final safeTitle = _safeName(notebook.title);

    try {
      if (action == ExportAction.print) {
        final bytes = await _generatePdf(notebook, pages);
        await PrintService.printPdf(
          bytes,
          documentName: notebook.title.isEmpty ? 'Notebook' : notebook.title,
        );
        return;
      }

      Uint8List bytes;
      String filename;
      String mimeType;
      switch (format) {
        case ExportFormat.pdf:
          bytes = await _generatePdf(notebook, pages);
          filename = '$safeTitle.pdf';
          mimeType = 'application/pdf';
          break;
        case ExportFormat.html:
          bytes = await _generateHtml(notebook, pages);
          filename = '$safeTitle.html';
          mimeType = 'text/html';
          break;
        case ExportFormat.text:
          bytes = await _generateText(notebook, pages);
          filename = '$safeTitle.txt';
          mimeType = 'text/plain';
          break;
        case ExportFormat.markdown:
          bytes = await _generateMarkdown(notebook, pages);
          filename = '$safeTitle.md';
          mimeType = 'text/markdown';
          break;
      }

      if (action == ExportAction.save) {
        final saveLocation = await getSaveLocation(suggestedName: filename);
        final path = saveLocation?.path;
        if (path != null) {
          await File(path).writeAsBytes(bytes);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Saved to $path')),
          );
        }
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(bytes, name: filename, mimeType: mimeType)],
            text: 'Exported Notebook',
          ),
        );
      }
    } catch (e, stack) {
      logError(e, stack, context: 'NotebookExporter.export');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to export: $e')),
      );
    }
  }

  static String _safeName(String title) {
    final t = title.trim().isEmpty ? 'Notebook' : title.trim();
    return t.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Future<Uint8List> _generatePdf(
    Notebook notebook,
    List<NotebookPage> pages,
  ) async {
    final pdf = pw.Document(theme: await loadPdfTheme());
    for (final page in pages) {
      List<pw.Widget> body;
      try {
        body = quillDeltaToPdfWidgets(jsonDecode(page.content) as List<dynamic>);
      } catch (e, stack) {
        logError(e, stack, context: 'NotebookExporter._generatePdf parse');
        body = [
          pw.Text(
            page.content,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
          ),
        ];
      }
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          build: (context) => [
            pw.Text(
              page.title.isEmpty ? 'Untitled Page' : page.title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            ...body,
          ],
        ),
      );
    }
    // A notebook with no pages still produces a valid (title-only) document.
    if (pages.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Text(
              notebook.title.isEmpty ? 'Notebook' : notebook.title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      );
    }
    return pdf.save();
  }

  static Future<Uint8List> _generateHtml(
    Notebook notebook,
    List<NotebookPage> pages,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln(
      '<html><head><meta charset="utf-8"><title>${_escapeHtml(notebook.title)}</title>',
    );
    buffer.writeln(
      '<style>body { font-family: sans-serif; max-width: 800px; margin: 0 auto; '
      'padding: 20px; } .page { margin-bottom: 40px; } h1 { color: #333; }</style>',
    );
    buffer.writeln('</head><body>');
    buffer.writeln('<h1>${_escapeHtml(notebook.title)}</h1>');
    for (final page in pages) {
      buffer.writeln('<div class="page">');
      buffer.writeln('<h2>${_escapeHtml(page.title)}</h2>');
      try {
        final ops = jsonDecode(page.content) as List<dynamic>;
        final converter = QuillDeltaToHtmlConverter(
          ops.map((e) => e as Map<String, dynamic>).toList(),
        );
        buffer.writeln(converter.convert());
      } catch (e, stack) {
        logError(e, stack, context: 'NotebookExporter._generateHtml parse');
        buffer.writeln('<p>${_escapeHtml(page.content)}</p>');
      }
      buffer.writeln('</div>');
      if (page != pages.last) buffer.writeln('<hr>');
    }
    buffer.writeln('</body></html>');
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static Future<Uint8List> _generateText(
    Notebook notebook,
    List<NotebookPage> pages,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(notebook.title);
    buffer.writeln('========================================');
    for (final page in pages) {
      buffer.writeln();
      buffer.writeln(page.title.isEmpty ? 'Untitled Page' : page.title);
      buffer.writeln('---');
      try {
        buffer.writeln(Document.fromJson(jsonDecode(page.content)).toPlainText());
      } catch (e, stack) {
        logError(e, stack, context: 'NotebookExporter._generateText parse');
        buffer.writeln(page.content);
      }
    }
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static Future<Uint8List> _generateMarkdown(
    Notebook notebook,
    List<NotebookPage> pages,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('# ${notebook.title}');
    for (final page in pages) {
      buffer.writeln();
      buffer.writeln('## ${page.title.isEmpty ? 'Untitled Page' : page.title}');
      buffer.writeln();
      try {
        buffer.writeln(deltaToMarkdown(jsonDecode(page.content) as List));
      } catch (e, stack) {
        logError(e, stack, context: 'NotebookExporter._generateMarkdown parse');
        buffer.writeln(page.content);
      }
    }
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
