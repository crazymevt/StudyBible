/// Converts a Quill delta (a list of `{insert, attributes}` op maps) into
/// Markdown, preserving headings, bullet/ordered lists, blockquotes and inline
/// bold/italic. Mirrors the block/inline handling of [quillDeltaToPdfWidgets]
/// (document_pdf.dart): block attributes (header, list, blockquote) ride on the
/// newline op, inline attributes (bold, italic) on the text op. Unknown
/// attributes (colour, underline, embeds, alignment) are dropped — Markdown has
/// no portable syntax for them.
String deltaToMarkdown(List<dynamic> ops) {
  final out = StringBuffer();
  final line = <_MdSpan>[];
  var orderedCounter = 0;

  String renderInline(List<_MdSpan> spans) {
    final b = StringBuffer();
    for (final s in spans) {
      var text = s.text;
      if (text.isEmpty) continue;
      // Markdown emphasis wraps trimmed text; keep surrounding spaces outside
      // the markers so `**bold** next` doesn't become `** bold ** next`.
      final leading = RegExp(r'^\s*').firstMatch(text)!.group(0)!;
      final trailing = RegExp(r'\s*$').firstMatch(text)!.group(0)!;
      final core = text.substring(leading.length, text.length - trailing.length);
      if (core.isEmpty) {
        b.write(text);
        continue;
      }
      var wrapped = core;
      if (s.bold) wrapped = '**$wrapped**';
      if (s.italic) wrapped = '_${wrapped}_';
      b.write('$leading$wrapped$trailing');
    }
    return b.toString();
  }

  void flush(Map<String, dynamic> blockAttrs) {
    final header = blockAttrs['header'];
    final list = blockAttrs['list'];
    final isQuote = blockAttrs['blockquote'] == true;

    if (list == 'ordered') {
      orderedCounter++;
    } else {
      orderedCounter = 0;
    }

    final text = renderInline(line);

    if (line.isEmpty && header == null && list == null && !isQuote) {
      out.writeln();
      return;
    }

    if (header == 1 || header == 2 || header == 3) {
      out.writeln('${'#' * (header as int)} $text');
    } else if (list == 'bullet') {
      out.writeln('- $text');
    } else if (list == 'ordered') {
      out.writeln('$orderedCounter. $text');
    } else if (isQuote) {
      out.writeln('> $text');
    } else {
      out.writeln(text);
    }
  }

  for (final op in ops) {
    if (op is! Map) continue;
    final insert = op['insert'];
    final attrs =
        (op['attributes'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (insert is! String) continue; // skip embeds (images, etc.)

    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        line.add(
          _MdSpan(
            parts[i],
            bold: attrs['bold'] == true,
            italic: attrs['italic'] == true,
          ),
        );
      }
      if (i < parts.length - 1) {
        flush(attrs);
        line.clear();
      }
    }
  }
  if (line.isNotEmpty) flush(const {});

  return out.toString().trimRight();
}

class _MdSpan {
  final String text;
  final bool bold;
  final bool italic;
  const _MdSpan(this.text, {this.bold = false, this.italic = false});
}
