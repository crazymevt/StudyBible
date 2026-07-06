// Plain-text extraction for the full-text search index.
//
// Commentary and devotional content is stored as HTML. Indexing it verbatim
// pollutes the FTS5 vocabulary (and therefore search autocomplete) with markup
// and embedded junk tokens (tag names, attribute values, ids). Strip it to
// plain words before indexing.

import 'dart:convert';

final RegExp _tagPattern = RegExp(r'<[^>]*>');
final RegExp _whitespacePattern = RegExp(r'\s+');

/// Removes HTML/XML markup and decodes the most common entities, producing
/// plain text suitable for the full-text search index. This is a fast, lenient
/// strip rather than a full HTML parse — it only needs to yield word tokens.
String stripMarkupForIndex(String input) {
  if (input.isEmpty || (!input.contains('<') && !input.contains('&'))) {
    return input;
  }

  var text = input.replaceAll(_tagPattern, ' ');

  if (text.contains('&')) {
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&'); // decode '&amp;' last to avoid re-decoding
  }

  return text.replaceAll(_whitespacePattern, ' ').trim();
}

/// Extracts plain text from a Quill Delta JSON string (a list of ops, each with
/// an `insert`). Used to index rich-text content (e.g. sermons) as words rather
/// than raw JSON. Falls back to returning the input unchanged if it doesn't
/// decode into a recognized Delta shape at all — legacy content from before
/// this app's editors used Quill is plain text or HTML, not JSON, and should
/// pass through unchanged rather than being blanked.
String deltaToPlainText(String deltaJson) {
  if (deltaJson.isEmpty) return deltaJson;
  final ops = _decodeDeltaOps(deltaJson);
  if (ops == null) return deltaJson;
  final buffer = StringBuffer();
  for (final op in ops) {
    if (op is Map && op['insert'] is String) {
      buffer.write(op['insert']);
    }
  }
  return buffer.toString().replaceAll(_whitespacePattern, ' ').trim();
}

/// Returns the op list for [deltaJson], accepting both the bare-array shape
/// this app writes (`[{"insert": ...}, ...]`) and the `{"ops": [...]}` wrapper
/// some JS Quill clients produce when they JSON.stringify a Delta object
/// directly (its `ops` field is the only enumerable property). Also unwraps
/// one extra level of encoding, so content that was accidentally
/// double-JSON-encoded by an import/export round trip resolves to its real
/// ops instead of leaving raw JSON text to display. Returns null if
/// [deltaJson] doesn't decode into a recognized shape.
List<dynamic>? _decodeDeltaOps(String deltaJson) {
  dynamic decoded;
  try {
    decoded = jsonDecode(deltaJson);
  } catch (_) {
    return null;
  }
  if (decoded is String) {
    try {
      decoded = jsonDecode(decoded);
    } catch (_) {
      return null;
    }
  }
  if (decoded is List) return decoded;
  if (decoded is Map && decoded['ops'] is List) {
    return decoded['ops'] as List;
  }
  return null;
}
