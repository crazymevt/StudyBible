import 'scripture_reference.dart';

class ScriptureParser {
  /// Basic parsing of strings like "John 3:16"
  static ScriptureReference? parse(String reference) {
    final regex = RegExp(r'^(\d?\s*[A-Za-z]+)\s+(\d+):(\d+)$');
    final match = regex.firstMatch(reference.trim());
    if (match != null) {
      return ScriptureReference(
        book: match.group(1)!,
        chapter: int.parse(match.group(2)!),
        verse: int.parse(match.group(3)!),
      );
    }
    return null;
  }
}
