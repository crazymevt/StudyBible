import 'measure.dart';
import 'measures_data.dart';

/// Maps a lowercased word as it might appear in verse text to the
/// [Measure.id] it names — the app's default KJV text spells several of
/// these differently from the [Measure.name] used for browsing (e.g. a
/// denarius is rendered "penny", a lepton is rendered "mite"), so this is a
/// curated word list rather than a derivation of [Measure.name].
///
/// "Shekel" and "talent" are each used in scripture as both a weight
/// standard and a currency; bare occurrences of those words default to the
/// far more commonly recognized money sense (see [ambiguityNoteFor]).
/// Words with no distinct literal form in the text (e.g. "letek", which
/// KJV renders as the two-word "half homer") aren't matchable by design.
const Map<String, String> _wordToMeasureId = {
  // Length
  'cubit': 'cubit', 'cubits': 'cubit',
  'span': 'span', 'spans': 'span',
  'handbreadth': 'handbreadth', 'handbreadths': 'handbreadth',
  'reed': 'reed', 'reeds': 'reed',
  'fathom': 'fathom', 'fathoms': 'fathom',
  'furlong': 'furlong', 'furlongs': 'furlong',
  'mile': 'mile', 'miles': 'mile',

  // Weight
  'gerah': 'gerah', 'gerahs': 'gerah',
  'bekah': 'bekah', 'bekahs': 'bekah',
  'pim': 'pim',
  'mina': 'mina', 'minas': 'mina',

  // Volume
  'cab': 'cab', 'cabs': 'cab',
  'omer': 'omer', 'omers': 'omer',
  'seah': 'seah', 'seahs': 'seah',
  'ephah': 'ephah', 'ephahs': 'ephah',
  'homer': 'homer', 'homers': 'homer',
  'log': 'log', 'logs': 'log',
  'hin': 'hin', 'hins': 'hin',
  'bath': 'bath', 'baths': 'bath',

  // Money — includes the KJV's translated forms, not just transliterations.
  'shekel': 'shekel-money', 'shekels': 'shekel-money',
  'talent': 'talent-money', 'talents': 'talent-money',
  'didrachma': 'didrachma',
  'stater': 'stater',
  'denarius': 'denarius', 'denarii': 'denarius',
  'penny': 'denarius', 'pennyworth': 'denarius', 'pence': 'denarius',
  'drachma': 'drachma', 'drachmas': 'drachma', 'drachmae': 'drachma',
  'mite': 'lepton', 'mites': 'lepton', 'lepton': 'lepton', 'lepta': 'lepton',
};

/// A one-line caveat for words that name more than one biblical unit, shown
/// alongside the (more common) sense [matchMeasureWord] resolves to.
const Map<String, String> _ambiguityNotes = {
  'shekel-money':
      "This word also names a weight standard, ≈ 11.4 grams (0.4 oz).",
  'talent-money':
      "This word also names a weight standard, ≈ 34 kg (75 lb).",
};

final Map<String, Measure> _measuresById = {for (final m in measures) m.id: m};

/// Looks up the [Measure] a literal verse-text word names, if any.
Measure? matchMeasureWord(String word) {
  final id = _wordToMeasureId[word.toLowerCase()];
  if (id == null) return null;
  return _measuresById[id];
}

/// A caveat for words that ambiguously name more than one biblical unit
/// (e.g. "shekel", "talent"), or null if [measure] isn't ambiguous.
String? ambiguityNoteFor(Measure measure) => _ambiguityNotes[measure.id];
