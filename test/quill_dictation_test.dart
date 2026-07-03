import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/ui/common/quill_dictation.dart';

void main() {
  group('insertDictatedText', () {
    test('appends with a leading space after a word character', () {
      final c = QuillController.basic();
      c.document.insert(0, 'Hello');
      // Cursor at end of "Hello".
      c.updateSelection(
        const TextSelection.collapsed(offset: 5),
        ChangeSource.local,
      );

      insertDictatedText(c, 'world');

      expect(c.document.toPlainText().trim(), 'Hello world');
    });

    test('does not add a leading space at the start of an empty document', () {
      final c = QuillController.basic();
      insertDictatedText(c, 'first');
      expect(c.document.toPlainText().trim(), 'first');
    });

    test('does not add a space after existing whitespace', () {
      final c = QuillController.basic();
      c.document.insert(0, 'Hello ');
      c.updateSelection(
        const TextSelection.collapsed(offset: 6),
        ChangeSource.local,
      );

      insertDictatedText(c, 'there');
      expect(c.document.toPlainText().trim(), 'Hello there');
    });

    test('ignores empty recognized text', () {
      final c = QuillController.basic();
      c.document.insert(0, 'Keep');
      insertDictatedText(c, '');
      expect(c.document.toPlainText().trim(), 'Keep');
    });
  });
}
