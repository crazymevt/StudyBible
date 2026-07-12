import 'measure.dart';
import 'measures_data.dart';
import 'number_words.dart';

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

/// Metals the text weighs shekels of when it means the weight standard, not
/// the coin — "shekels of silver" is the money sense (kept as the ambiguous
/// default above), but silver was the only metal ever used as shekel
/// currency, so any other named metal, noun or adjective form alike
/// ("shekels of brass"/"golden spoon", never "shekels of golden"), is
/// unambiguously the weight standard and should never be reported as money.
const Set<String> _weightShekelMaterials = {'gold', 'golden', 'brass', 'brazen', 'iron'};

/// Spice/incense ingredients scripture weighs out by the shekel as part of a
/// recipe list, never as currency — e.g. Exodus 30:23's anointing-oil recipe
/// ("of pure myrrh five hundred shekels ... of sweet cinnamon half so much,
/// even two hundred and fifty shekels ... of sweet calamus two hundred and
/// fifty shekels ... of cassia five hundred shekels").
const Set<String> _weightShekelIngredients = {'myrrh', 'cinnamon', 'calamus', 'cassia'};

/// The suffix of [words] (oldest-to-newest) after the nearest preceding
/// "and a"/"and an", or the whole list if there isn't one. KJV enumerates
/// parts of the *same* thing with a bare comma or "and of" ("...shekels,
/// one silver bowl...", Numbers 7:19; "...shekels, and of sweet
/// cinnamon...", Exodus 30:23) but introduces a genuinely separate item
/// with "and a"/"and an" ("...shekels of silver, AND A wedge of gold...",
/// Joshua 7:21) — so this is the cutoff a backward scan for weight-standard
/// markers must respect to avoid crediting one item's material to another.
List<String> _sinceLastNewItem(List<String> words) {
  for (var i = words.length - 2; i >= 0; i--) {
    if (words[i].toLowerCase() == 'and' && _isArticle(words[i + 1])) {
      return words.sublist(i + 2);
    }
  }
  return words;
}

/// The prefix of [words] before the nearest following "and a"/"and an", or
/// the whole list if there isn't one — the forward-scanning counterpart to
/// [_sinceLastNewItem].
List<String> _untilNextNewItem(List<String> words) {
  for (var i = 0; i < words.length - 1; i++) {
    if (words[i].toLowerCase() == 'and' && _isArticle(words[i + 1])) {
      return words.sublist(0, i);
    }
  }
  return words;
}

bool _isArticle(String word) => word.toLowerCase() == 'a' || word.toLowerCase() == 'an';

/// Corrects a bare "shekel(s)" match to the weight sense when a word tied to
/// this same item (see [_sinceLastNewItem]/[_untilNextNewItem]) marks it as
/// the weight standard rather than a coin, since the marker's position
/// relative to the shekel figure varies too much across the KJV's phrasing
/// to check by strict adjacency:
///  - a metal from [_weightShekelMaterials], whether it names what the
///    shekels themselves weigh ("shekels of brass", 1 Samuel 17:5) or
///    describes an object whose weight they give ("one golden spoon of ten
///    shekels", Numbers 7:32);
///  - the literal word "weight" — on the shekel word itself ("ten shekels
///    weight of gold"), well before it ("the weight of the coat was five
///    thousand shekels of brass"), or established for an earlier shekel
///    figure that a later bare one for the same item then inherits (Numbers
///    7:19: "the weight whereof was an hundred and thirty shekels, one
///    silver bowl of seventy shekels" — the bowl's bare "seventy shekels"
///    carries no marker of its own, but the verse already does);
///  - an ingredient from [_weightShekelIngredients].
Measure _disambiguateShekel(Measure measure, List<String> precedingWords, List<String> wordsAfterUnit) {
  if (measure.id != 'shekel-money') return measure;

  final itemContext = _sinceLastNewItem(precedingWords)
      .followedBy(_untilNextNewItem(wordsAfterUnit))
      .map((w) => w.toLowerCase());
  final isWeight = itemContext.any(
    (w) => w == 'weight' || _weightShekelMaterials.contains(w) || _weightShekelIngredients.contains(w),
  );
  return isWeight ? _measuresById['shekel-weight']! : measure;
}

/// A [Measure] resolved from a tapped word, the quantity that applies to it,
/// and the literal word that names the unit (e.g. "cubits") — which may
/// differ from the tapped word itself, see [resolveMeasureNearWord].
typedef ResolvedMeasure = ({Measure measure, num? quantity, String unitWord});

/// Resolves the unit of measure a tapped [word] implies, whether the tap
/// landed on the unit word itself ("cubits" in "six cubits") or on a word in
/// the quantity phrase that precedes it ("six"). In the latter case, scans
/// forward through [followingWords] past any remaining number/connector
/// words to find the unit they modify; returns null if none is found.
ResolvedMeasure? resolveMeasureNearWord(
  String word,
  List<String> precedingWords,
  List<String> followingWords,
) {
  final direct = matchMeasureWord(word);
  if (direct != null) {
    final measure = _disambiguateShekel(direct, precedingWords, followingWords);
    return (measure: measure, quantity: parseQuantityBeforeMeasure(precedingWords), unitWord: word);
  }

  if (!isNumberWord(word)) return null;

  var i = 0;
  while (i < followingWords.length && isNumberWord(followingWords[i])) {
    i++;
  }
  if (i >= followingWords.length) return null;

  final unitWord = followingWords[i];
  final rawMeasure = matchMeasureWord(unitWord);
  if (rawMeasure == null) return null;
  final wordsBeforeUnit = [...precedingWords, word, ...followingWords.sublist(0, i)];
  final measure = _disambiguateShekel(rawMeasure, wordsBeforeUnit, followingWords.sublist(i + 1));

  final quantity = parseQuantityBeforeMeasure(wordsBeforeUnit);
  return (measure: measure, quantity: quantity, unitWord: unitWord);
}
