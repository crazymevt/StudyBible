import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Inserts dictated [text] into [controller] at the current cursor (replacing
/// any selection). Adds a leading space when the character before the cursor is
/// a word character so speech phrases don't run together. Goes through
/// [QuillController.replaceText] so the editor's change listeners (autosave,
/// autolink) fire.
void insertDictatedText(QuillController controller, String text) {
  if (text.isEmpty) return;
  final docLength = controller.document.length; // includes the trailing '\n'
  final sel = controller.selection;
  var index = sel.isValid ? sel.baseOffset : docLength - 1;
  var length = sel.isValid && !sel.isCollapsed
      ? (sel.extentOffset - sel.baseOffset).abs()
      : 0;
  if (sel.isValid && !sel.isCollapsed) {
    index = sel.start;
  }
  index = index.clamp(0, docLength - 1);
  if (index + length > docLength - 1) {
    length = (docLength - 1 - index).clamp(0, docLength - 1);
  }

  final plain = controller.document.toPlainText();
  final needsLeadingSpace =
      index > 0 && index <= plain.length && _isWordChar(plain[index - 1]);
  final insert = needsLeadingSpace ? ' $text' : text;

  controller.replaceText(
    index,
    length,
    insert,
    TextSelection.collapsed(offset: index + insert.length),
  );
}

bool _isWordChar(String c) => RegExp(r'[A-Za-z0-9]').hasMatch(c);
