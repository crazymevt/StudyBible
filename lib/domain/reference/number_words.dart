/// Best-effort parsing of an English/KJV-style cardinal number out of the
/// word tokens immediately preceding a tapped unit-of-measure word, so a tap
/// on "cubits" in "six cubits" can report a computed total rather than just
/// the fixed per-unit conversion.
library;

const Map<String, int> _numberWords = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
  'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
  'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
  'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
  'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
  'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
  // KJV-archaic absolute values — not multipliers (unlike hundred/thousand,
  // nothing precedes these to scale them: "threescore" always just means 60).
  'score': 20, 'threescore': 60, 'fourscore': 80,
};

const Map<String, int> _multiplierWords = {'hundred': 100, 'thousand': 1000};

const Set<String> _connectorWords = {'a', 'an', 'and'};

/// Scans backward through [precedingWords] (oldest-to-newest, i.e. the word
/// immediately before the tapped measure word is last) collecting a
/// contiguous run of recognized number/connector tokens, then sums it into a
/// quantity. Returns null if no number phrase is found immediately before
/// the measure word.
///
/// Handles compound numbers regardless of KJV's reversed ones-before-tens
/// order ("five and twenty" and "twenty five" both parse to 25), the
/// implied 1 in "an hundred"/"a thousand"/bare "a cubit", and scaling words
/// ("three hundred", "two thousand"). Does not handle a trailing fraction
/// that follows the unit word ("two cubits and an half") — that modifier
/// isn't visible from the word preceding the tap.
num? parseQuantityBeforeMeasure(List<String> precedingWords) {
  final run = <String>[];
  for (var i = precedingWords.length - 1; i >= 0; i--) {
    final word = precedingWords[i].toLowerCase();
    if (_numberWords.containsKey(word) ||
        _multiplierWords.containsKey(word) ||
        _connectorWords.contains(word) ||
        int.tryParse(word) != null) {
      run.insert(0, word);
    } else {
      break;
    }
  }

  if (run.isEmpty) return null;

  // A bare "a"/"an" with nothing else recognized ("an omer is...") reads as
  // a singular article, not zero — treat it as a quantity of 1.
  if (run.length == 1 && _connectorWords.contains(run.first)) {
    return run.first == 'and' ? null : 1;
  }

  num total = 0;
  num current = 0;
  for (final word in run) {
    if (_connectorWords.contains(word)) continue;

    final digit = int.tryParse(word);
    if (digit != null) {
      current += digit;
      continue;
    }

    final multiplier = _multiplierWords[word];
    if (multiplier != null) {
      if (current == 0) current = 1; // implied "a"/"an" before hundred/thousand
      current *= multiplier;
      total += current;
      current = 0;
      continue;
    }

    current += _numberWords[word]!;
  }
  total += current;

  return total == 0 ? null : total;
}
