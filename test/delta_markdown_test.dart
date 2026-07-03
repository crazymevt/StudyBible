import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/export/delta_markdown.dart';

void main() {
  group('deltaToMarkdown', () {
    test('renders headings, lists, blockquotes and inline emphasis', () {
      // Block attributes ride on the trailing newline op; inline attributes on
      // the text op — the Quill Delta convention.
      final ops = [
        {'insert': 'Title'},
        {
          'insert': '\n',
          'attributes': {'header': 1}
        },
        {'insert': 'A '},
        {
          'insert': 'bold',
          'attributes': {'bold': true}
        },
        {'insert': ' and '},
        {
          'insert': 'italic',
          'attributes': {'italic': true}
        },
        {'insert': ' word.\n'},
        {'insert': 'First'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'}
        },
        {'insert': 'Second'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'}
        },
        {'insert': 'Step one'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'}
        },
        {'insert': 'Step two'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'}
        },
        {'insert': 'A quote'},
        {
          'insert': '\n',
          'attributes': {'blockquote': true}
        },
      ];

      final md = deltaToMarkdown(ops);

      expect(md, contains('# Title'));
      expect(md, contains('A **bold** and _italic_ word.'));
      expect(md, contains('- First'));
      expect(md, contains('- Second'));
      expect(md, contains('1. Step one'));
      expect(md, contains('2. Step two'));
      expect(md, contains('> A quote'));
    });

    test('keeps emphasis markers tight around trimmed text', () {
      final ops = [
        {
          'insert': 'hello ',
          'attributes': {'bold': true}
        },
        {'insert': 'world\n'},
      ];
      // The trailing space stays outside the ** markers.
      expect(deltaToMarkdown(ops), 'hello world'.replaceFirst('hello ', '**hello** '));
    });

    test('plain paragraphs pass through unchanged', () {
      final ops = [
        {'insert': 'Just a line.\n'},
      ];
      expect(deltaToMarkdown(ops), 'Just a line.');
    });
  });
}
