/// Case-insensitive string comparison that orders embedded numbers by value,
/// so "Part 2" sorts before "Part 10" (plain lexicographic order would put
/// "Part 10" first). Non-digit runs compare by code unit; numerically equal
/// digit runs ("07" vs "7") and case-only differences fall back to an exact
/// compare so the order stays deterministic.
int naturalCompare(String a, String b) {
  final la = a.toLowerCase();
  final lb = b.toLowerCase();
  var i = 0;
  var j = 0;
  while (i < la.length && j < lb.length) {
    final ca = la.codeUnitAt(i);
    final cb = lb.codeUnitAt(j);
    if (_isDigit(ca) && _isDigit(cb)) {
      final startA = i;
      while (i < la.length && _isDigit(la.codeUnitAt(i))) {
        i++;
      }
      final startB = j;
      while (j < lb.length && _isDigit(lb.codeUnitAt(j))) {
        j++;
      }
      final numA = _stripLeadingZeros(la.substring(startA, i));
      final numB = _stripLeadingZeros(lb.substring(startB, j));
      // Same significant-digit count means the shorter number is smaller;
      // equal lengths compare digit-by-digit, which is numeric order.
      if (numA.length != numB.length) return numA.length - numB.length;
      final cmp = numA.compareTo(numB);
      if (cmp != 0) return cmp;
    } else if (ca != cb) {
      return ca - cb;
    } else {
      i++;
      j++;
    }
  }
  final remaining = (la.length - i) - (lb.length - j);
  if (remaining != 0) return remaining;
  return a.compareTo(b);
}

bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

String _stripLeadingZeros(String digits) {
  var k = 0;
  while (k < digits.length - 1 && digits.codeUnitAt(k) == 0x30) {
    k++;
  }
  return digits.substring(k);
}
