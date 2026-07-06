import '../../domain/feasts/feast_data.dart';

/// One scripture reference for a [CuratedTopic] entry — same shape as the
/// bundled Nave's Topical Bible's `topic_references` rows: a whole-chapter
/// reference leaves [verse] null, and a single verse leaves [verseEnd] null.
class CuratedTopicRef {
  final String bookName;
  final int chapter;
  final int? verse;
  final int? verseEnd;

  const CuratedTopicRef(this.bookName, this.chapter, [this.verse, this.verseEnd]);
}

/// A hand-curated topic layered into the same `topics` table Nave's Topical
/// Bible import populates — see `CuratedTopicsImporter`. [category]
/// distinguishes these from Nave's own entries (whose `category` column is
/// left null) so the Explorer can browse them as a group: 'feast' for the
/// appointed times (Passover, Pentecost, ...), 'story' for well-known
/// narrative passages that Nave's subject-heading index doesn't surface as a
/// single browsable entry.
class CuratedTopic {
  final String name;
  final String category;
  final String description;
  final List<CuratedTopicRef> refs;

  const CuratedTopic({
    required this.name,
    required this.category,
    required this.description,
    required this.refs,
  });
}

/// Parses "Book C:V-V", "Book C:V", or "Book C" (whole chapter) into a
/// [CuratedTopicRef]. The book-name group is lazy so multi-word names ("1
/// Samuel", "Song of Solomon") aren't swallowed by a greedy match.
CuratedTopicRef _ref(String passage) {
  final m = RegExp(
    r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$',
  ).firstMatch(passage.trim());
  if (m == null) {
    throw ArgumentError('CuratedTopic: cannot parse passage "$passage"');
  }
  return CuratedTopicRef(
    m.group(1)!,
    int.parse(m.group(2)!),
    m.group(3) == null ? null : int.parse(m.group(3)!),
    m.group(4) == null ? null : int.parse(m.group(4)!),
  );
}

/// The nine appointed feasts (Leviticus 23, plus Purim and Dedication),
/// reusing the same names/descriptions/passages as the Feasts & Calendar
/// reader tool (`domain/feasts/feast_data.dart`) so the two never drift.
final _feastTopics = [
  for (final f in feasts)
    CuratedTopic(
      name: f.name.toUpperCase(),
      category: 'feast',
      description: f.description,
      refs: [for (final p in f.passages) _ref(p)],
    ),
];

/// Well-known narrative passages that Nave's subject-heading index doesn't
/// surface as a single browsable entry (its headings are subjects like
/// "FAITH" or "AARON", not story titles) — seeded with commonly looked-up
/// accounts spanning both Testaments. More can be appended here without any
/// code changes; each becomes its own Explorer topic page via
/// `CuratedTopicsImporter`.
const _storyTopics = <CuratedTopic>[
  CuratedTopic(
    name: 'CREATION',
    category: 'story',
    description: 'God creates the heavens, the earth, and all living things '
        'in six days, then rests on the seventh.',
    refs: [CuratedTopicRef('Genesis', 1), CuratedTopicRef('Genesis', 2, 1, 3)],
  ),
  CuratedTopic(
    name: 'THE FALL OF MAN',
    category: 'story',
    description: 'The serpent tempts Eve, Adam and Eve eat the forbidden '
        'fruit, and sin and death enter the world.',
    refs: [CuratedTopicRef('Genesis', 3)],
  ),
  CuratedTopic(
    name: 'NOAH AND THE FLOOD',
    category: 'story',
    description: 'God floods the earth to judge its wickedness, sparing '
        'Noah, his family, and the animals aboard the ark.',
    refs: [
      CuratedTopicRef('Genesis', 6, 9, 22),
      CuratedTopicRef('Genesis', 7, 17, 24),
      CuratedTopicRef('Genesis', 8, 1, 19),
      CuratedTopicRef('Genesis', 9, 8, 17),
    ],
  ),
  CuratedTopic(
    name: 'THE TOWER OF BABEL',
    category: 'story',
    description: 'Humanity builds a tower to make a name for itself; God '
        'confuses their language and scatters them across the earth.',
    refs: [CuratedTopicRef('Genesis', 11, 1, 9)],
  ),
  CuratedTopic(
    name: "ABRAHAM'S CALL AND COVENANT",
    category: 'story',
    description: 'God calls Abram out of Haran and repeatedly covenants to '
        'make him a great nation and give his offspring the land of Canaan.',
    refs: [
      CuratedTopicRef('Genesis', 12, 1, 9),
      CuratedTopicRef('Genesis', 15, 1, 6),
      CuratedTopicRef('Genesis', 17, 1, 8),
    ],
  ),
  CuratedTopic(
    name: 'THE BINDING OF ISAAC',
    category: 'story',
    description: 'God tests Abraham by commanding him to sacrifice Isaac, '
        'then provides a ram in his place at the last moment.',
    refs: [CuratedTopicRef('Genesis', 22, 1, 19)],
  ),
  CuratedTopic(
    name: 'JOSEPH SOLD INTO SLAVERY',
    category: 'story',
    description: "Joseph's jealous brothers throw him into a pit and sell "
        'him to traders bound for Egypt.',
    refs: [CuratedTopicRef('Genesis', 37, 12, 36)],
  ),
  CuratedTopic(
    name: 'MOSES AND THE BURNING BUSH',
    category: 'story',
    description: 'God appears to Moses in a bush that burns without being '
        'consumed and commissions him to deliver Israel from Egypt.',
    refs: [CuratedTopicRef('Exodus', 3, 1, 15)],
  ),
  CuratedTopic(
    name: 'THE EXODUS FROM EGYPT',
    category: 'story',
    description: 'After the tenth plague, Pharaoh releases Israel, who '
        'cross the Red Sea on dry ground as the pursuing Egyptian army '
        'drowns.',
    refs: [
      CuratedTopicRef('Exodus', 12, 29, 42),
      CuratedTopicRef('Exodus', 14, 21, 31),
    ],
  ),
  CuratedTopic(
    name: 'THE TEN COMMANDMENTS',
    category: 'story',
    description: 'God gives Israel the ten commandments at Mount Sinai.',
    refs: [CuratedTopicRef('Exodus', 20, 1, 17)],
  ),
  CuratedTopic(
    name: 'DAVID AND GOLIATH',
    category: 'story',
    description: 'The shepherd boy David kills the Philistine champion '
        'Goliath with a sling and a stone.',
    refs: [CuratedTopicRef('1 Samuel', 17)],
  ),
  CuratedTopic(
    name: "DANIEL IN THE LIONS' DEN",
    category: 'story',
    description: 'Daniel is thrown into a den of lions for praying to God '
        'in defiance of a royal decree, and God shuts the lions\' mouths.',
    refs: [CuratedTopicRef('Daniel', 6)],
  ),
  CuratedTopic(
    name: 'THE BIRTH OF JESUS',
    category: 'story',
    description: 'Jesus is born to Mary in Bethlehem and laid in a manger; '
        'angels announce the news to shepherds keeping watch nearby.',
    refs: [
      CuratedTopicRef('Luke', 2, 1, 20),
      CuratedTopicRef('Matthew', 1, 18, 25),
    ],
  ),
  CuratedTopic(
    name: 'THE VISIT OF THE MAGI',
    category: 'story',
    description: 'Magi from the east follow a star to Bethlehem and worship '
        'the infant Jesus with gifts of gold, frankincense, and myrrh.',
    refs: [CuratedTopicRef('Matthew', 2, 1, 12)],
  ),
  CuratedTopic(
    name: "JESUS' BAPTISM",
    category: 'story',
    description: 'John the Baptist baptizes Jesus in the Jordan; the Spirit '
        'descends like a dove and a voice from heaven declares him God\'s '
        'Son.',
    refs: [CuratedTopicRef('Matthew', 3, 13, 17)],
  ),
  CuratedTopic(
    name: 'THE SERMON ON THE MOUNT',
    category: 'story',
    description: "Jesus teaches the Beatitudes and the core of his ethical "
        'teaching to a crowd gathered on a mountainside.',
    refs: [
      CuratedTopicRef('Matthew', 5, 1, 12),
      CuratedTopicRef('Matthew', 7, 24, 29),
    ],
  ),
  CuratedTopic(
    name: 'THE FEEDING OF THE FIVE THOUSAND',
    category: 'story',
    description: 'Jesus multiplies five loaves and two fish to feed a crowd '
        'of five thousand, with twelve baskets of food left over.',
    refs: [CuratedTopicRef('John', 6, 1, 14)],
  ),
  CuratedTopic(
    name: 'THE TRANSFIGURATION',
    category: 'story',
    description: "Jesus is transfigured before Peter, James, and John; his "
        'face and clothes shine, and Moses and Elijah appear with him.',
    refs: [CuratedTopicRef('Matthew', 17, 1, 8)],
  ),
  CuratedTopic(
    name: 'THE LAST SUPPER',
    category: 'story',
    description: 'Jesus shares a final Passover meal with his disciples '
        'and institutes the bread and cup in remembrance of him.',
    refs: [CuratedTopicRef('Luke', 22, 14, 20)],
  ),
  CuratedTopic(
    name: 'THE CRUCIFIXION',
    category: 'story',
    description: 'Jesus is crucified at Golgotha between two criminals and '
        'dies, committing his spirit into the Father\'s hands.',
    refs: [CuratedTopicRef('Luke', 23, 33, 46)],
  ),
  CuratedTopic(
    name: 'THE RESURRECTION',
    category: 'story',
    description: 'Women find the tomb empty on the third day; angels '
        'announce that Jesus has risen.',
    refs: [CuratedTopicRef('Luke', 24, 1, 12)],
  ),
  CuratedTopic(
    name: 'THE ASCENSION',
    category: 'story',
    description: 'Jesus commissions his disciples and is taken up into '
        'heaven before their eyes.',
    refs: [CuratedTopicRef('Acts', 1, 6, 11)],
  ),
  CuratedTopic(
    name: 'THE DAY OF PENTECOST',
    category: 'story',
    description: 'The Holy Spirit descends on the gathered believers with '
        'the sound of wind and tongues of fire, and they speak in other '
        'tongues.',
    refs: [CuratedTopicRef('Acts', 2, 1, 13)],
  ),
  CuratedTopic(
    name: 'PETER HEALS THE LAME MAN AT THE TEMPLE',
    category: 'story',
    description: 'Peter heals a man lame from birth at the Beautiful Gate '
        'of the temple, "in the name of Jesus Christ of Nazareth."',
    refs: [CuratedTopicRef('Acts', 3, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE CONVERSION OF SAUL',
    category: 'story',
    description: 'A blinding light and the voice of Jesus confront Saul on '
        'the road to Damascus; Ananias restores his sight and he is '
        'baptized.',
    refs: [CuratedTopicRef('Acts', 9, 1, 19)],
  ),
];

final curatedTopics = <CuratedTopic>[..._feastTopics, ..._storyTopics];
