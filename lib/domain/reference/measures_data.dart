import 'measure.dart';

/// The curated Measures & Money dataset: units of length, weight, volume,
/// and money scripture names, each with an approximate modern equivalent and
/// a real citation showing it in use.
const List<Measure> measures = [
  // --- Length ---
  Measure(
    id: 'cubit',
    name: 'Cubit',
    category: MeasureCategory.length,
    modernEquivalent: '≈ 18 inches (45 cm)',
    notes:
        'The most common biblical length unit, based on the forearm from '
        "elbow to fingertip — used for the ark's, tabernacle's, and temple's "
        'dimensions.',
    citations: ['Genesis 6:15', 'Exodus 25:10'],
    usUnitFactor: 1.5, // feet
  ),
  Measure(
    id: 'span',
    name: 'Span',
    category: MeasureCategory.length,
    modernEquivalent: '≈ 9 inches (23 cm) — half a cubit',
    notes: 'The distance from thumb to little finger of an outstretched hand.',
    citations: ['Exodus 28:16'],
    usUnitFactor: 0.75, // feet
  ),
  Measure(
    id: 'handbreadth',
    name: 'Handbreadth',
    category: MeasureCategory.length,
    modernEquivalent: '≈ 3 inches (7.5 cm)',
    notes: "The width of a hand at the base of the fingers; used for the table of showbread's border.",
    citations: ['Exodus 25:25'],
    usUnitFactor: 0.25, // feet
  ),
  Measure(
    id: 'reed',
    name: 'Reed',
    category: MeasureCategory.length,
    modernEquivalent: '≈ 10.5 feet (3.2 m) — six long cubits',
    notes: 'Used by Ezekiel\'s measuring angel to survey the visionary temple.',
    citations: ['Ezekiel 40:5'],
    usUnitFactor: 10.5, // feet
  ),
  Measure(
    id: 'fathom',
    name: 'Fathom',
    category: MeasureCategory.length,
    modernEquivalent: '≈ 6 feet (1.8 m)',
    notes: 'A nautical depth measure — the sailors\' soundings during Paul\'s shipwreck voyage.',
    citations: ['Acts 27:28'],
    usUnitFactor: 6.0, // feet
  ),
  Measure(
    id: 'furlong',
    name: 'Furlong (Stadion)',
    category: MeasureCategory.length,
    modernEquivalent: '≈ 600 feet (185 m)',
    notes: 'A Greek/Roman distance unit — Emmaus was about seven furlongs from Jerusalem.',
    citations: ['Luke 24:13', 'Revelation 21:16'],
    usUnitFactor: 600.0, // feet
  ),
  Measure(
    id: 'mile',
    name: 'Mile',
    category: MeasureCategory.length,
    modernEquivalent: '≈ 1,000 paces (1.48 km)',
    notes: 'The Roman mile, the unit behind Jesus\' "go with him twain" teaching on compelled service.',
    citations: ['Matthew 5:41'],
    usUnitFactor: 4855.0, // feet — the Roman mile is shorter than a modern US mile
  ),

  // --- Weight ---
  Measure(
    id: 'gerah',
    name: 'Gerah',
    category: MeasureCategory.weight,
    modernEquivalent: '≈ 0.6 grams — 1/20 of a shekel',
    notes: 'The smallest weight unit, used to define the sanctuary shekel\'s standard.',
    citations: ['Exodus 30:13'],
    usUnitFactor: 0.02116, // ounces
  ),
  Measure(
    id: 'bekah',
    name: 'Bekah',
    category: MeasureCategory.weight,
    modernEquivalent: '≈ 5.7 grams — half a shekel',
    notes: 'The half-shekel weight each numbered Israelite man paid toward the tabernacle census offering.',
    citations: ['Exodus 38:26'],
    usUnitFactor: 0.2011, // ounces
  ),
  Measure(
    id: 'pim',
    name: 'Pim',
    category: MeasureCategory.weight,
    modernEquivalent: '≈ 7.6 grams — roughly two-thirds of a shekel',
    notes:
        'The price the Philistines charged Israel to sharpen plow points and '
        'other iron tools; the word survived only via archaeology, since KJV '
        'renders it "a file" rather than as a currency.',
    citations: ['1 Samuel 13:21'],
    usUnitFactor: 0.2681, // ounces
  ),
  Measure(
    id: 'shekel-weight',
    name: 'Shekel',
    category: MeasureCategory.weight,
    modernEquivalent: '≈ 11.4 grams (0.4 oz)',
    notes: 'The basic weight standard — Abraham weighed out silver by shekels to buy a burial field.',
    citations: ['Genesis 23:15-16', 'Exodus 30:13'],
    usUnitFactor: 0.4021, // ounces
  ),
  Measure(
    id: 'mina',
    name: 'Mina',
    category: MeasureCategory.weight,
    modernEquivalent: '≈ 570 grams — 50 shekels',
    notes: 'Solomon\'s gold shields were made by the mina; also the "pound" of Jesus\' minas parable.',
    citations: ['1 Kings 10:17', 'Ezekiel 45:12'],
    usUnitFactor: 20.11, // ounces
  ),
  Measure(
    id: 'talent-weight',
    name: 'Talent',
    category: MeasureCategory.weight,
    modernEquivalent: '≈ 34 kilograms (75 lb) — 3,000 shekels',
    notes: 'The largest weight unit — the amount of gold and silver used to overlay the temple.',
    citations: ['Exodus 38:25-26'],
    usUnitFactor: 1199.3, // ounces
  ),

  // --- Volume ---
  Measure(
    id: 'cab',
    name: 'Cab',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 1.2 liters — 1/18 of an ephah',
    notes: 'The smallest dry measure — a quarter-cab of dove\'s dung sold for five shekels during Samaria\'s siege famine.',
    citations: ['2 Kings 6:25'],
    usUnitFactor: 1.268, // US quarts
  ),
  Measure(
    id: 'omer',
    name: 'Omer',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 2 liters (2 quarts) — 1/10 of an ephah',
    notes: 'The daily portion of manna gathered per person in the wilderness.',
    citations: ['Exodus 16:16'],
    usUnitFactor: 2.113, // US quarts
  ),
  Measure(
    id: 'seah',
    name: 'Seah',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 7.3 liters — 1/3 of an ephah',
    notes: 'The measure of flour Sarah kneaded into bread for her three unexpected guests.',
    citations: ['Genesis 18:6'],
    usUnitFactor: 7.714, // US quarts
  ),
  Measure(
    id: 'ephah',
    name: 'Ephah',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 22 liters (5 gallons)',
    notes: 'The standard dry-goods measure — Ruth gleaned about an ephah of barley in a day.',
    citations: ['Ruth 2:17', 'Leviticus 5:11'],
    usUnitFactor: 23.25, // US quarts
  ),
  Measure(
    id: 'letek',
    name: 'Letek (Half-homer)',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 110 liters — half a homer',
    notes:
        'Part of the price Hosea paid to redeem his unfaithful wife Gomer, '
        'alongside silver and an homer of barley; KJV renders it "half homer".',
    citations: ['Hosea 3:2'],
    usUnitFactor: 116.2, // US quarts
  ),
  Measure(
    id: 'homer',
    name: 'Homer (Cor)',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 220 liters — 10 ephahs',
    notes: 'The largest dry measure, also used as a liquid measure (cor) for oil and wine.',
    citations: ['Leviticus 27:16', 'Ezekiel 45:11'],
    usUnitFactor: 232.5, // US quarts
  ),
  Measure(
    id: 'log',
    name: 'Log',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 0.3 liters',
    notes: 'The smallest liquid measure — the oil used in the cleansing ritual for a healed leper.',
    citations: ['Leviticus 14:10'],
    usUnitFactor: 0.317, // US quarts
  ),
  Measure(
    id: 'hin',
    name: 'Hin',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 3.7 liters — 1/6 of a bath',
    notes: 'A liquid measure for oil and wine drink offerings prescribed with the tabernacle sacrifices.',
    citations: ['Exodus 29:40'],
    usUnitFactor: 3.910, // US quarts
  ),
  Measure(
    id: 'bath',
    name: 'Bath',
    category: MeasureCategory.volume,
    modernEquivalent: '≈ 22 liters — the liquid counterpart to the ephah',
    notes: 'The standard liquid measure for oil and wine, sized to match the dry ephah.',
    citations: ['1 Kings 7:26', 'Ezekiel 45:10-11'],
    usUnitFactor: 23.25, // US quarts
  ),

  // --- Money ---
  Measure(
    id: 'shekel-money',
    name: 'Shekel of Silver',
    category: MeasureCategory.money,
    modernEquivalent: '≈ 4 days\' wages',
    notes:
        'Joseph was sold into slavery for twenty shekels of silver; Judas '
        'was paid thirty for betraying Jesus.',
    citations: ['Genesis 37:28', 'Matthew 26:15'],
    usUnitFactor: 4.0, // laborer day-wages
  ),
  Measure(
    id: 'didrachma',
    name: 'Didrachma (Temple Tax)',
    category: MeasureCategory.money,
    modernEquivalent: '≈ 2 days\' wages — a half-shekel per person',
    notes: 'The annual temple tax the collectors asked Peter whether Jesus paid.',
    citations: ['Matthew 17:24'],
    usUnitFactor: 2.0, // laborer day-wages
  ),
  Measure(
    id: 'stater',
    name: 'Stater',
    category: MeasureCategory.money,
    modernEquivalent: '≈ 4 days\' wages — a shekel-equivalent silver coin',
    notes:
        'The coin (KJV: "a piece of money") Peter found in a fish\'s mouth, '
        'worth exactly two didrachmas — enough to cover the temple tax for '
        'both himself and Jesus.',
    citations: ['Matthew 17:27'],
    usUnitFactor: 4.0, // laborer day-wages
  ),
  Measure(
    id: 'denarius',
    name: 'Denarius',
    category: MeasureCategory.money,
    modernEquivalent: '≈ 1 day\'s wage for a laborer',
    notes: 'The standard Roman day-wage coin — paid to the vineyard workers, and stamped with Caesar\'s image.',
    citations: ['Matthew 20:2', 'Matthew 22:19'],
    usUnitFactor: 1.0, // laborer day-wages
  ),
  Measure(
    id: 'drachma',
    name: 'Drachma',
    category: MeasureCategory.money,
    modernEquivalent: '≈ 1 day\'s wage — a Greek silver coin',
    notes: 'The coin the woman in Jesus\' parable searched her house to find.',
    citations: ['Luke 15:8'],
    usUnitFactor: 1.0, // laborer day-wages
  ),
  Measure(
    id: 'lepton',
    name: 'Mite (Lepton)',
    category: MeasureCategory.money,
    modernEquivalent: '≈ a fraction of a cent — the smallest coin in circulation',
    notes: 'The two small coins the poor widow gave, which Jesus said outweighed the rich givers\' gifts.',
    citations: ['Mark 12:42'],
    usUnitFactor: 0.007813, // laborer day-wages — 1/128 of a denarius
  ),
  Measure(
    id: 'talent-money',
    name: 'Talent (Money)',
    category: MeasureCategory.money,
    modernEquivalent: '≈ 20 years\' wages — an enormous sum',
    notes:
        'The unforgiving servant owed ten thousand talents; the same unit '
        'sizes the sums entrusted in the parable of the talents.',
    citations: ['Matthew 18:24', 'Matthew 25:15'],
    usUnitFactor: 6000.0, // laborer day-wages — 6,000 drachmas
  ),
];
