import 'measure.dart';

/// A rough modern daily wage (USD) used only to give currency conversions a
/// ballpark dollar figure alongside the labor-value equivalent. Ancient
/// purchasing power doesn't map cleanly onto modern prices, so this is a
/// deliberately soft, debatable placeholder, not a rate the app claims is
/// authoritative — the UI always shows it captioned as a rough estimate.
const double kAssumedDailyWageUsd = 150.0;

/// Computes and formats [quantity] units of [measure] into US customary
/// units (or, for [MeasureCategory.money], laborer day-wages plus a rough
/// USD estimate).
String formatMeasureConversion(Measure measure, num quantity) {
  final total = measure.usUnitFactor * quantity;
  switch (measure.category) {
    case MeasureCategory.length:
      return _formatFeet(total.toDouble());
    case MeasureCategory.weight:
      return _formatOunces(total.toDouble());
    case MeasureCategory.volume:
      return _formatQuarts(total.toDouble());
    case MeasureCategory.money:
      return _formatDayWages(total.toDouble());
  }
}

String _formatFeet(double feet) {
  if (feet < 1) {
    final inches = feet * 12;
    return '${_trim(inches)} inch${inches == 1 ? '' : 'es'}';
  }
  if (feet >= 5280) {
    final miles = feet / 5280;
    return '${_trim(miles)} mile${miles == 1 ? '' : 's'}';
  }
  final wholeFeet = feet.floor();
  final inches = ((feet - wholeFeet) * 12).round();
  if (inches == 0) return '$wholeFeet ft';
  if (inches >= 12) return '${wholeFeet + 1} ft';
  return '$wholeFeet ft $inches in';
}

String _formatOunces(double ounces) {
  if (ounces < 16) return '${_trim(ounces)} oz';
  final wholeLb = (ounces / 16).floor();
  final remOz = ounces - wholeLb * 16;
  if (remOz < 0.05) return '$wholeLb lb';
  return '$wholeLb lb ${_trim(remOz)} oz';
}

String _formatQuarts(double quarts) {
  if (quarts < 4) return '${_trim(quarts)} qt';
  final wholeGal = (quarts / 4).floor();
  final remQt = quarts - wholeGal * 4;
  if (remQt < 0.05) return '$wholeGal gal';
  return '$wholeGal gal ${_trim(remQt)} qt';
}

String _formatDayWages(double dayWages) {
  final wagesLabel = dayWages < 1 ? dayWages.toStringAsFixed(3) : _withCommas(_trim(dayWages));
  final wageUnit = dayWages == 1 ? "day's wage" : "days' wages";
  final usd = _formatUsd(dayWages * kAssumedDailyWageUsd);
  return "$wagesLabel $wageUnit (~$usd)";
}

String _formatUsd(double amount) {
  final rounded = amount < 10 ? amount.toStringAsFixed(2) : amount.round().toString();
  return '\$${_withCommas(rounded)}';
}

/// Inserts thousands separators into a formatted number string's integer part.
String _withCommas(String formatted) {
  final parts = formatted.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  return parts.length > 1 ? '${buffer.toString()}.${parts[1]}' : buffer.toString();
}

/// Trims a computed value to at most 1-2 decimals without trailing zeros.
String _trim(double value) {
  final decimals = value < 10 ? 2 : 1;
  var s = value.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}
