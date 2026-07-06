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

  // --- Genesis ---
  CuratedTopic(
    name: 'CAIN AND ABEL',
    category: 'story',
    description: 'Cain murders his brother Abel out of jealousy and is '
        'marked and banished by God.',
    refs: [CuratedTopicRef('Genesis', 4, 1, 16)],
  ),
  CuratedTopic(
    name: 'ABRAHAM AND MELCHIZEDEK',
    category: 'story',
    description: 'The king-priest Melchizedek blesses Abraham with bread '
        'and wine after his rescue of Lot, and Abraham gives him a tenth '
        'of everything.',
    refs: [CuratedTopicRef('Genesis', 14, 17, 20)],
  ),
  CuratedTopic(
    name: 'THE DESTRUCTION OF SODOM AND GOMORRAH',
    category: 'story',
    description: 'Angels rescue Lot and his family before God rains fire '
        'and sulfur on Sodom and Gomorrah; Lot\'s wife looks back and '
        'becomes a pillar of salt.',
    refs: [CuratedTopicRef('Genesis', 19, 1, 29)],
  ),
  CuratedTopic(
    name: 'HAGAR AND ISHMAEL SENT AWAY',
    category: 'story',
    description: 'Sarah has Hagar and Ishmael sent into the wilderness, '
        'where God provides water and promises to make Ishmael a great '
        'nation.',
    refs: [CuratedTopicRef('Genesis', 21, 8, 21)],
  ),
  CuratedTopic(
    name: 'ISAAC AND REBEKAH',
    category: 'story',
    description: 'Abraham\'s servant prays for a sign at a well and finds '
        'Rebekah, who returns with him to become Isaac\'s wife.',
    refs: [CuratedTopicRef('Genesis', 24)],
  ),
  CuratedTopic(
    name: "JACOB'S BIRTHRIGHT AND BLESSING",
    category: 'story',
    description: 'Esau sells his birthright for a bowl of stew, and Jacob '
        'later deceives their blind father Isaac to steal Esau\'s blessing.',
    refs: [
      CuratedTopicRef('Genesis', 25, 29, 34),
      CuratedTopicRef('Genesis', 27, 1, 40),
    ],
  ),
  CuratedTopic(
    name: 'JACOB WRESTLES WITH THE ANGEL',
    category: 'story',
    description: 'Jacob wrestles with a divine visitor all night at Peniel, '
        'refusing to let go until he is blessed, and is renamed Israel.',
    refs: [CuratedTopicRef('Genesis', 32, 22, 32)],
  ),
  CuratedTopic(
    name: "JOSEPH'S DREAMS",
    category: 'story',
    description: 'Joseph, favored by his father with a special coat, '
        'dreams that his family will one day bow down to him — fueling his '
        'brothers\' jealousy.',
    refs: [CuratedTopicRef('Genesis', 37, 1, 11)],
  ),
  CuratedTopic(
    name: "JOSEPH INTERPRETS PHARAOH'S DREAMS",
    category: 'story',
    description: 'Joseph interprets Pharaoh\'s dreams of coming famine and '
        'is made ruler over all Egypt to prepare for it.',
    refs: [CuratedTopicRef('Genesis', 41, 1, 40)],
  ),
  CuratedTopic(
    name: 'JOSEPH REVEALS HIMSELF TO HIS BROTHERS',
    category: 'story',
    description: 'Joseph, now Egypt\'s governor, breaks down and reveals his '
        'identity to the brothers who once sold him into slavery.',
    refs: [CuratedTopicRef('Genesis', 45, 1, 15)],
  ),

  // --- Exodus – Numbers ---
  CuratedTopic(
    name: 'MOSES FOUND IN THE BASKET',
    category: 'story',
    description: 'To save him from Pharaoh\'s decree, infant Moses is set '
        'adrift in a basket on the Nile and found by Pharaoh\'s daughter.',
    refs: [CuratedTopicRef('Exodus', 2, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE TEN PLAGUES OF EGYPT',
    category: 'story',
    description: 'God sends ten plagues on Egypt, from the Nile turning to '
        'blood to the death of the firstborn, until Pharaoh releases Israel.',
    refs: [
      CuratedTopicRef('Exodus', 7, 20, 21),
      CuratedTopicRef('Exodus', 12, 29, 30),
    ],
  ),
  CuratedTopic(
    name: 'MANNA AND QUAIL IN THE WILDERNESS',
    category: 'story',
    description: 'God feeds the grumbling Israelites with quail in the '
        'evening and bread-like manna every morning in the wilderness.',
    refs: [CuratedTopicRef('Exodus', 16, 4, 15)],
  ),
  CuratedTopic(
    name: 'WATER FROM THE ROCK',
    category: 'story',
    description: 'At Massah and Meribah, Moses strikes a rock at Horeb and '
        'water flows out for the thirsty Israelites.',
    refs: [CuratedTopicRef('Exodus', 17, 1, 7)],
  ),
  CuratedTopic(
    name: 'THE GOLDEN CALF',
    category: 'story',
    description: 'While Moses is on Mount Sinai, Israel persuades Aaron to '
        'make a golden calf to worship, provoking God\'s anger.',
    refs: [CuratedTopicRef('Exodus', 32)],
  ),
  CuratedTopic(
    name: 'THE TWELVE SPIES',
    category: 'story',
    description: 'Twelve spies scout Canaan; ten report giants and defeat, '
        'but Joshua and Caleb urge Israel to trust God and take the land.',
    refs: [CuratedTopicRef('Numbers', 13)],
  ),
  CuratedTopic(
    name: "BALAAM'S DONKEY",
    category: 'story',
    description: 'Balaam\'s donkey sees the angel of the LORD blocking the '
        'road and speaks aloud in protest before Balaam himself sees it.',
    refs: [CuratedTopicRef('Numbers', 22, 21, 35)],
  ),

  // --- Joshua – Ruth ---
  CuratedTopic(
    name: 'RAHAB AND THE SPIES',
    category: 'story',
    description: 'Rahab hides Israel\'s spies in Jericho and is promised '
        'safety for her family when the city falls.',
    refs: [CuratedTopicRef('Joshua', 2)],
  ),
  CuratedTopic(
    name: 'THE BATTLE OF JERICHO',
    category: 'story',
    description: 'Israel marches around Jericho for seven days; on the '
        'seventh, the walls collapse at the sound of trumpets and a shout.',
    refs: [CuratedTopicRef('Joshua', 6, 1, 20)],
  ),
  CuratedTopic(
    name: "ACHAN'S SIN",
    category: 'story',
    description: 'Achan\'s theft of devoted plunder from Jericho brings '
        'Israel\'s defeat at Ai, until his sin is uncovered and judged.',
    refs: [CuratedTopicRef('Joshua', 7)],
  ),
  CuratedTopic(
    name: 'DEBORAH AND BARAK',
    category: 'story',
    description: 'The prophetess Deborah leads Israel with Barak against '
        'Sisera\'s army, and Jael kills the fleeing Sisera in her tent.',
    refs: [CuratedTopicRef('Judges', 4)],
  ),
  CuratedTopic(
    name: "GIDEON'S FLEECE",
    category: 'story',
    description: 'Gideon asks God for two confirming signs with a wool '
        'fleece before leading Israel against the Midianites.',
    refs: [CuratedTopicRef('Judges', 6, 36, 40)],
  ),
  CuratedTopic(
    name: "GIDEON'S THREE HUNDRED",
    category: 'story',
    description: 'God pares Gideon\'s army down to three hundred men, who '
        'rout the vast Midianite camp with torches, trumpets, and jars.',
    refs: [CuratedTopicRef('Judges', 7)],
  ),
  CuratedTopic(
    name: "SAMSON'S BIRTH",
    category: 'story',
    description: 'An angel announces to Manoah\'s barren wife that she will '
        'bear Samson, a Nazirite set apart to deliver Israel.',
    refs: [CuratedTopicRef('Judges', 13)],
  ),
  CuratedTopic(
    name: 'SAMSON AND DELILAH',
    category: 'story',
    description: 'Delilah wears Samson down until he reveals that his '
        'strength lies in his uncut hair, and the Philistines seize him.',
    refs: [CuratedTopicRef('Judges', 16, 4, 22)],
  ),
  CuratedTopic(
    name: "SAMSON'S DEATH",
    category: 'story',
    description: 'Blinded and mocked in the Philistines\' temple, Samson '
        'prays for strength once more and pulls the pillars down on '
        'himself and his captors.',
    refs: [CuratedTopicRef('Judges', 16, 23, 30)],
  ),
  CuratedTopic(
    name: 'RUTH GLEANS IN THE FIELD OF BOAZ',
    category: 'story',
    description: 'The widowed Ruth gleans leftover grain in the field of '
        'Boaz, a relative of her late husband, who shows her favor.',
    refs: [CuratedTopicRef('Ruth', 2)],
  ),
  CuratedTopic(
    name: 'BOAZ REDEEMS RUTH',
    category: 'story',
    description: 'Boaz publicly redeems Ruth and her family\'s inheritance '
        'and marries her; their son Obed becomes David\'s grandfather.',
    refs: [CuratedTopicRef('Ruth', 4)],
  ),

  // --- 1–2 Samuel ---
  CuratedTopic(
    name: "HANNAH'S PRAYER AND SAMUEL'S BIRTH",
    category: 'story',
    description: 'The barren Hannah prays for a son and dedicates him to '
        'the LORD\'s service; Samuel is born in answer to her prayer.',
    refs: [CuratedTopicRef('1 Samuel', 1, 9, 20)],
  ),
  CuratedTopic(
    name: "SAMUEL'S CALLING",
    category: 'story',
    description: 'The boy Samuel hears the LORD calling his name in the '
        'night and, with Eli\'s guidance, answers, "Speak, for your '
        'servant hears."',
    refs: [CuratedTopicRef('1 Samuel', 3)],
  ),
  CuratedTopic(
    name: 'SAUL ANOINTED KING',
    category: 'story',
    description: 'Samuel privately anoints Saul as Israel\'s first king at '
        'God\'s direction, after the people demand a king like the nations.',
    refs: [
      CuratedTopicRef('1 Samuel', 9, 15, 21),
      CuratedTopicRef('1 Samuel', 10, 1),
    ],
  ),
  CuratedTopic(
    name: 'DAVID ANOINTED KING',
    category: 'story',
    description: 'Samuel passes over David\'s older brothers and secretly '
        'anoints the shepherd boy David as Israel\'s future king.',
    refs: [CuratedTopicRef('1 Samuel', 16, 1, 13)],
  ),
  CuratedTopic(
    name: "DAVID AND JONATHAN'S FRIENDSHIP",
    category: 'story',
    description: 'Jonathan, Saul\'s son, makes a covenant of friendship '
        'with David and later risks his father\'s wrath to warn him of '
        'danger.',
    refs: [
      CuratedTopicRef('1 Samuel', 18, 1, 4),
      CuratedTopicRef('1 Samuel', 20, 35, 42),
    ],
  ),
  CuratedTopic(
    name: "DAVID SPARES SAUL'S LIFE",
    category: 'story',
    description: 'David secretly cuts off a corner of Saul\'s robe in a '
        'cave at En Gedi rather than kill the king who is hunting him.',
    refs: [CuratedTopicRef('1 Samuel', 24)],
  ),
  CuratedTopic(
    name: 'THE MEDIUM OF ENDOR',
    category: 'story',
    description: 'On the eve of his final battle, a desperate Saul '
        'disguises himself to consult a medium, who summons the spirit of '
        'Samuel.',
    refs: [CuratedTopicRef('1 Samuel', 28, 3, 25)],
  ),
  CuratedTopic(
    name: 'DAVID BRINGS THE ARK TO JERUSALEM',
    category: 'story',
    description: 'David dances before the LORD with all his might as the '
        'ark of the covenant is brought into Jerusalem.',
    refs: [CuratedTopicRef('2 Samuel', 6)],
  ),
  CuratedTopic(
    name: "ABSALOM'S DEATH",
    category: 'story',
    description: "David's rebellious son Absalom is caught by his hair in "
        'an oak tree and killed by Joab against David\'s explicit orders.',
    refs: [CuratedTopicRef('2 Samuel', 18, 9, 15)],
  ),
  CuratedTopic(
    name: "DAVID'S CENSUS AND THE PLAGUE",
    category: 'story',
    description: "David's census of Israel brings a plague as judgment; it "
        'stops when he buys a threshing floor and offers sacrifices there.',
    refs: [CuratedTopicRef('2 Samuel', 24)],
  ),

  // --- 1–2 Kings ---
  CuratedTopic(
    name: "SOLOMON'S WISDOM AND THE TWO MOTHERS",
    category: 'story',
    description: 'Solomon exposes the true mother of a disputed infant by '
        'proposing to cut the child in two, revealing his famous wisdom.',
    refs: [CuratedTopicRef('1 Kings', 3, 16, 28)],
  ),
  CuratedTopic(
    name: 'SOLOMON BUILDS THE TEMPLE',
    category: 'story',
    description: 'Solomon constructs the temple in Jerusalem as a '
        'permanent house for the LORD, fulfilling David\'s wish.',
    refs: [CuratedTopicRef('1 Kings', 6)],
  ),
  CuratedTopic(
    name: 'THE QUEEN OF SHEBA VISITS SOLOMON',
    category: 'story',
    description: 'The Queen of Sheba tests Solomon with hard questions and '
        'is left breathless by his wisdom and wealth.',
    refs: [CuratedTopicRef('1 Kings', 10, 1, 13)],
  ),
  CuratedTopic(
    name: 'THE KINGDOM DIVIDED',
    category: 'story',
    description: "Rehoboam's harshness splits Solomon's kingdom in two: "
        'Jeroboam rules the northern ten tribes as Israel, Rehoboam the '
        'south as Judah.',
    refs: [CuratedTopicRef('1 Kings', 12, 1, 24)],
  ),
  CuratedTopic(
    name: 'ELIJAH FED BY RAVENS',
    category: 'story',
    description: 'During a drought, ravens bring Elijah bread and meat by '
        'the brook Cherith at God\'s command.',
    refs: [CuratedTopicRef('1 Kings', 17, 1, 6)],
  ),
  CuratedTopic(
    name: 'ELIJAH AND THE WIDOW OF ZAREPHATH',
    category: 'story',
    description: "A widow's jar of flour and jug of oil never run out "
        'through the famine after she feeds Elijah, and he later raises '
        'her dead son.',
    refs: [CuratedTopicRef('1 Kings', 17, 8, 24)],
  ),
  CuratedTopic(
    name: 'ELIJAH AT HOREB',
    category: 'story',
    description: 'Fleeing Jezebel in despair, Elijah encounters God not in '
        'wind, earthquake, or fire, but in a still small voice at Horeb.',
    refs: [CuratedTopicRef('1 Kings', 19)],
  ),
  CuratedTopic(
    name: 'ELIJAH TAKEN UP TO HEAVEN',
    category: 'story',
    description: 'A chariot and horses of fire carry Elijah up to heaven in '
        'a whirlwind as Elisha watches and receives his mantle.',
    refs: [CuratedTopicRef('2 Kings', 2, 1, 12)],
  ),
  CuratedTopic(
    name: "ELISHA AND THE WIDOW'S OIL",
    category: 'story',
    description: "A widow's small jar of oil miraculously fills every "
        'vessel she can borrow, enough to pay her debts and live on.',
    refs: [CuratedTopicRef('2 Kings', 4, 1, 7)],
  ),
  CuratedTopic(
    name: "ELISHA RAISES THE SHUNAMMITE'S SON",
    category: 'story',
    description: 'Elisha restores to life the son of the Shunammite woman '
        'who had provided him a room to stay in.',
    refs: [CuratedTopicRef('2 Kings', 4, 8, 37)],
  ),
  CuratedTopic(
    name: 'NAAMAN HEALED OF LEPROSY',
    category: 'story',
    description: 'The Aramean commander Naaman is healed of leprosy after '
        'reluctantly dipping seven times in the Jordan at Elisha\'s word.',
    refs: [CuratedTopicRef('2 Kings', 5)],
  ),
  CuratedTopic(
    name: 'ELISHA AND THE FLOATING AXE HEAD',
    category: 'story',
    description: 'When a borrowed axe head sinks in the Jordan, Elisha '
        'throws in a stick and makes the iron float.',
    refs: [CuratedTopicRef('2 Kings', 6, 1, 7)],
  ),
  CuratedTopic(
    name: "HEZEKIAH'S ILLNESS AND SIGN",
    category: 'story',
    description: 'Hezekiah weeps and prays when told he will die; God adds '
        'fifteen years to his life and confirms it by turning back a '
        'sundial\'s shadow.',
    refs: [CuratedTopicRef('2 Kings', 20, 1, 11)],
  ),
  CuratedTopic(
    name: 'THE FALL OF JERUSALEM',
    category: 'story',
    description: "Nebuchadnezzar's army breaches Jerusalem, burns the "
        'temple, and carries Judah into exile in Babylon.',
    refs: [CuratedTopicRef('2 Kings', 25, 1, 21)],
  ),

  // --- Esther – Daniel ---
  CuratedTopic(
    name: 'ESTHER BECOMES QUEEN',
    category: 'story',
    description: 'The Jewish orphan Esther is chosen queen of Persia, '
        'setting the stage for her to later intercede for her people.',
    refs: [CuratedTopicRef('Esther', 2, 1, 18)],
  ),
  CuratedTopic(
    name: "ESTHER SAVES HER PEOPLE",
    category: 'story',
    description: 'Esther risks her life to approach the king unbidden and '
        'exposes Haman\'s plot to destroy the Jews, who are saved instead.',
    refs: [
      CuratedTopicRef('Esther', 4, 12, 16),
      CuratedTopicRef('Esther', 7),
    ],
  ),
  CuratedTopic(
    name: "JOB'S TRIALS",
    category: 'story',
    description: 'Job loses his children, wealth, and health in rapid '
        'succession, yet refuses to curse God despite his wife\'s and '
        'friends\' urging.',
    refs: [CuratedTopicRef('Job', 1), CuratedTopicRef('Job', 2, 1, 10)],
  ),
  CuratedTopic(
    name: "ISAIAH'S CALL AND VISION",
    category: 'story',
    description: 'Isaiah sees the LORD high and lifted up in the temple '
        'and, cleansed by a burning coal, answers, "Here am I; send me."',
    refs: [CuratedTopicRef('Isaiah', 6, 1, 8)],
  ),
  CuratedTopic(
    name: 'JEREMIAH THROWN INTO THE CISTERN',
    category: 'story',
    description: 'Jeremiah is lowered into a muddy cistern to die for his '
        'unwelcome prophecies, then rescued by the Cushite official '
        'Ebed-melech.',
    refs: [CuratedTopicRef('Jeremiah', 38, 1, 13)],
  ),
  CuratedTopic(
    name: "EZEKIEL'S VALLEY OF DRY BONES",
    category: 'story',
    description: "Ezekiel prophesies to a valley of dry bones, and God's "
        'breath raises them into a vast living army — a vision of Israel\'s '
        'restoration.',
    refs: [CuratedTopicRef('Ezekiel', 37, 1, 14)],
  ),
  CuratedTopic(
    name: 'DANIEL AND HIS FRIENDS REFUSE THE ROYAL FOOD',
    category: 'story',
    description: 'Daniel and his three friends resolve not to defile '
        'themselves with the king\'s food, and are found healthier than '
        'the rest on a diet of vegetables.',
    refs: [CuratedTopicRef('Daniel', 1, 8, 21)],
  ),
  CuratedTopic(
    name: "DANIEL INTERPRETS NEBUCHADNEZZAR'S DREAM",
    category: 'story',
    description: 'Daniel reveals and interprets Nebuchadnezzar\'s forgotten '
        'dream of a great statue, when none of the king\'s wise men could.',
    refs: [CuratedTopicRef('Daniel', 2)],
  ),
  CuratedTopic(
    name: 'SHADRACH, MESHACH, AND ABEDNEGO IN THE FIERY FURNACE',
    category: 'story',
    description: 'Three young Hebrews refuse to bow to Nebuchadnezzar\'s '
        'golden image and walk unharmed out of a blazing furnace.',
    refs: [CuratedTopicRef('Daniel', 3)],
  ),
  CuratedTopic(
    name: "BELSHAZZAR'S FEAST",
    category: 'story',
    description: 'A disembodied hand writes Belshazzar\'s doom on the wall '
        'during a drunken feast, and Daniel interprets it that same night.',
    refs: [CuratedTopicRef('Daniel', 5)],
  ),

  // --- Gospels ---
  CuratedTopic(
    name: 'THE CALLING OF THE FIRST DISCIPLES',
    category: 'story',
    description: 'Jesus calls Peter, Andrew, James, and John from their '
        'fishing nets to follow him and become "fishers of men."',
    refs: [CuratedTopicRef('Matthew', 4, 18, 22)],
  ),
  CuratedTopic(
    name: 'THE WEDDING AT CANA',
    category: 'story',
    description: "Jesus turns water into wine at a wedding in Cana, his "
        'first public sign.',
    refs: [CuratedTopicRef('John', 2, 1, 11)],
  ),
  CuratedTopic(
    name: 'NICODEMUS VISITS JESUS',
    category: 'story',
    description: 'A Pharisee named Nicodemus comes to Jesus by night and '
        'is told he must be "born again" to see the kingdom of God.',
    refs: [CuratedTopicRef('John', 3)],
  ),
  CuratedTopic(
    name: 'THE WOMAN AT THE WELL',
    category: 'story',
    description: 'Jesus offers "living water" to a Samaritan woman at '
        "Jacob's well, who becomes one of the first to spread word of him.",
    refs: [CuratedTopicRef('John', 4)],
  ),
  CuratedTopic(
    name: "JESUS HEALS THE CENTURION'S SERVANT",
    category: 'story',
    description: 'A Roman centurion asks Jesus only to "say the word" to '
        'heal his servant, and Jesus marvels at his faith.',
    refs: [CuratedTopicRef('Matthew', 8, 5, 13)],
  ),
  CuratedTopic(
    name: 'JESUS CALMS THE STORM',
    category: 'story',
    description: 'Jesus rebukes a violent storm on the Sea of Galilee — '
        '"Peace! Be still!" — and the wind and waves obey him.',
    refs: [CuratedTopicRef('Mark', 4, 35, 41)],
  ),
  CuratedTopic(
    name: 'THE GERASENE DEMONIAC',
    category: 'story',
    description: 'Jesus casts a legion of demons out of a tormented man '
        'into a herd of pigs, which rush into the sea.',
    refs: [CuratedTopicRef('Mark', 5, 1, 20)],
  ),
  CuratedTopic(
    name: "JAIRUS'S DAUGHTER AND THE WOMAN WITH THE ISSUE OF BLOOD",
    category: 'story',
    description: 'On the way to raise a synagogue leader\'s dying daughter, '
        'Jesus is touched by and heals a woman who had bled for twelve '
        'years.',
    refs: [CuratedTopicRef('Mark', 5, 21, 43)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE SOWER',
    category: 'story',
    description: 'Jesus teaches how a sower\'s seed meets four kinds of '
        'soil, then explains it as the ways people receive God\'s word.',
    refs: [CuratedTopicRef('Matthew', 13, 1, 23)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE GOOD SAMARITAN',
    category: 'story',
    description: 'A despised Samaritan, not a priest or Levite, proves to '
        'be the true "neighbor" who stops to help a beaten traveler.',
    refs: [CuratedTopicRef('Luke', 10, 25, 37)],
  ),
  CuratedTopic(
    name: 'MARY AND MARTHA',
    category: 'story',
    description: 'Martha busies herself serving while her sister Mary sits '
        'at Jesus\' feet, and Jesus commends Mary\'s choice.',
    refs: [CuratedTopicRef('Luke', 10, 38, 42)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE LOST SHEEP',
    category: 'story',
    description: 'A shepherd leaves ninety-nine sheep to search for one '
        'lost sheep, rejoicing over its recovery like heaven over one '
        'repentant sinner.',
    refs: [CuratedTopicRef('Luke', 15, 1, 7)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE PRODIGAL SON',
    category: 'story',
    description: 'A wayward son squanders his inheritance and returns home '
        'in shame, only to be welcomed back by his father with open arms.',
    refs: [CuratedTopicRef('Luke', 15, 11, 32)],
  ),
  CuratedTopic(
    name: 'THE RICH MAN AND LAZARUS',
    category: 'story',
    description: "A parable of a poor beggar carried to Abraham's side "
        'after death, while the rich man who ignored him suffers in torment.',
    refs: [CuratedTopicRef('Luke', 16, 19, 31)],
  ),
  CuratedTopic(
    name: 'THE RICH YOUNG RULER',
    category: 'story',
    description: 'A wealthy young man walks away sorrowful when Jesus '
        'tells him to sell all he has and follow him.',
    refs: [CuratedTopicRef('Matthew', 19, 16, 30)],
  ),
  CuratedTopic(
    name: 'ZACCHAEUS',
    category: 'story',
    description: 'A short, despised tax collector climbs a tree to see '
        'Jesus, who invites himself to Zacchaeus\'s house and changes his '
        'life.',
    refs: [CuratedTopicRef('Luke', 19, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE WOMAN CAUGHT IN ADULTERY',
    category: 'story',
    description: '"Let him who is without sin among you be the first to '
        'throw a stone," Jesus tells the woman\'s accusers, and they leave '
        'one by one.',
    refs: [CuratedTopicRef('John', 8, 1, 11)],
  ),
  CuratedTopic(
    name: 'THE MAN BORN BLIND',
    category: 'story',
    description: 'Jesus heals a man born blind, whose simple testimony — '
        '"I was blind, now I see" — confounds the religious leaders who '
        'question him.',
    refs: [CuratedTopicRef('John', 9)],
  ),
  CuratedTopic(
    name: 'THE RAISING OF LAZARUS',
    category: 'story',
    description: 'Jesus weeps at the tomb of his friend Lazarus, then '
        'calls him back to life four days after his death.',
    refs: [CuratedTopicRef('John', 11, 1, 44)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE TEN VIRGINS',
    category: 'story',
    description: 'Five wise virgins keep enough oil for their lamps while '
        'five foolish ones run out, waiting for a bridegroom who comes at '
        'an unexpected hour.',
    refs: [CuratedTopicRef('Matthew', 25, 1, 13)],
  ),
  CuratedTopic(
    name: 'THE SHEEP AND THE GOATS',
    category: 'story',
    description: 'Jesus describes a final judgment separating "sheep" from '
        '"goats" by how they treated "the least of these" — the hungry, '
        'the stranger, the prisoner.',
    refs: [CuratedTopicRef('Matthew', 25, 31, 46)],
  ),
  CuratedTopic(
    name: 'JESUS WASHES THE DISCIPLES\' FEET',
    category: 'story',
    description: 'At the Last Supper, Jesus takes a towel and basin and '
        'washes his disciples\' feet, modeling humble service.',
    refs: [CuratedTopicRef('John', 13, 1, 17)],
  ),
  CuratedTopic(
    name: "JUDAS'S BETRAYAL",
    category: 'story',
    description: 'Judas Iscariot agrees to betray Jesus for thirty pieces '
        'of silver, then identifies him to the arresting crowd with a '
        'kiss.',
    refs: [
      CuratedTopicRef('Matthew', 26, 14, 16),
      CuratedTopicRef('Matthew', 26, 47, 50),
    ],
  ),
  CuratedTopic(
    name: "PETER'S DENIAL",
    category: 'story',
    description: 'Just as Jesus predicted, Peter denies knowing him three '
        'times before the rooster crows, then weeps bitterly.',
    refs: [CuratedTopicRef('Luke', 22, 54, 62)],
  ),
  CuratedTopic(
    name: 'DOUBTING THOMAS',
    category: 'story',
    description: 'Thomas refuses to believe the resurrection until he can '
        'touch Jesus\' wounds himself — and then confesses, "My Lord and '
        'my God!"',
    refs: [CuratedTopicRef('John', 20, 24, 29)],
  ),
  CuratedTopic(
    name: 'THE ROAD TO EMMAUS',
    category: 'story',
    description: 'The risen Jesus walks unrecognized with two disciples to '
        'Emmaus, and is finally known to them in the breaking of bread.',
    refs: [CuratedTopicRef('Luke', 24, 13, 35)],
  ),
  CuratedTopic(
    name: 'THE GREAT COMMISSION',
    category: 'story',
    description: 'The risen Jesus commissions his disciples to "go and '
        'make disciples of all nations," promising to be with them always.',
    refs: [CuratedTopicRef('Matthew', 28, 16, 20)],
  ),

  // --- Acts ---
  CuratedTopic(
    name: 'ANANIAS AND SAPPHIRA',
    category: 'story',
    description: 'A husband and wife fall dead in turn after lying to the '
        'Holy Spirit about money they claimed to have given in full.',
    refs: [CuratedTopicRef('Acts', 5, 1, 11)],
  ),
  CuratedTopic(
    name: "STEPHEN'S MARTYRDOM",
    category: 'story',
    description: 'Stephen is stoned to death for his testimony about '
        'Jesus, praying for his killers as Saul looks on approvingly.',
    refs: [CuratedTopicRef('Acts', 7, 54, 60)],
  ),
  CuratedTopic(
    name: 'PHILIP AND THE ETHIOPIAN EUNUCH',
    category: 'story',
    description: 'Philip explains the prophet Isaiah to an Ethiopian '
        'official on a desert road, who then asks to be baptized on the '
        'spot.',
    refs: [CuratedTopicRef('Acts', 8, 26, 40)],
  ),
  CuratedTopic(
    name: "PETER'S VISION AND CORNELIUS",
    category: 'story',
    description: 'A vision of unclean animals prepares Peter to visit the '
        'Roman centurion Cornelius, opening the gospel to the Gentiles.',
    refs: [CuratedTopicRef('Acts', 10)],
  ),
  CuratedTopic(
    name: "PETER'S ESCAPE FROM PRISON",
    category: 'story',
    description: "An angel wakes Peter in chains, and the prison's iron "
        'gate opens by itself as the church prays for his release.',
    refs: [CuratedTopicRef('Acts', 12, 1, 19)],
  ),
  CuratedTopic(
    name: 'THE JERUSALEM COUNCIL',
    category: 'story',
    description: 'The apostles and elders meet in Jerusalem to settle '
        'whether Gentile believers must keep the law of Moses.',
    refs: [CuratedTopicRef('Acts', 15)],
  ),
  CuratedTopic(
    name: 'PAUL AND SILAS IN PRISON AT PHILIPPI',
    category: 'story',
    description: 'An earthquake breaks open the prison doors after Paul '
        'and Silas sing hymns at midnight, and their jailer is converted.',
    refs: [CuratedTopicRef('Acts', 16, 16, 34)],
  ),
  CuratedTopic(
    name: 'PAUL AT THE AREOPAGUS',
    category: 'story',
    description: 'Paul addresses the philosophers of Athens at the '
        'Areopagus, proclaiming the "unknown god" they already worship in '
        'ignorance.',
    refs: [CuratedTopicRef('Acts', 17, 16, 34)],
  ),
  CuratedTopic(
    name: "PAUL'S SHIPWRECK",
    category: 'story',
    description: 'A violent storm wrecks the ship carrying Paul to Rome, '
        'and everyone aboard reaches shore safely on Malta as he had '
        'promised.',
    refs: [CuratedTopicRef('Acts', 27, 13, 44)],
  ),
];

final curatedTopics = <CuratedTopic>[..._feastTopics, ..._storyTopics];
