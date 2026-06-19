import 'package:flutter_quill/flutter_quill.dart';
void main() {
  final d = Document.fromJson([{'insert': '\n'}]);
  print(d.length);
}
