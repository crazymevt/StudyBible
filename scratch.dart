import 'dart:convert';
void main() {
  var x = '[{"insert":"\\n"}]';
  print(jsonDecode(x));
}
