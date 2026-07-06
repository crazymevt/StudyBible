import '../../domain/feasts/feast_data.dart';

/// One scripture reference for a [CuratedTopic] entry — same shape as the
/// bundled Nave's Topical Bible's `topic_references` rows: a whole-chapter
/// reference leaves [verse] null, and a single verse leaves [verseEnd] null.
class CuratedTopicRef {
  final String bookName;
  final int chapter;
  final int? verse;
  final int? verseEnd;

  const CuratedTopicRef(
    this.bookName,
    this.chapter, [
    this.verse,
    this.verseEnd,
  ]);
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
    description:
        'God creates the heavens, the earth, and all living things '
        'in six days, then rests on the seventh.',
    refs: [CuratedTopicRef('Genesis', 1), CuratedTopicRef('Genesis', 2, 1, 3)],
  ),
  CuratedTopic(
    name: 'THE FALL OF MAN',
    category: 'story',
    description:
        'The serpent tempts Eve, Adam and Eve eat the forbidden '
        'fruit, and sin and death enter the world.',
    refs: [CuratedTopicRef('Genesis', 3)],
  ),
  CuratedTopic(
    name: 'NOAH AND THE FLOOD',
    category: 'story',
    description:
        'God floods the earth to judge its wickedness, sparing '
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
    description:
        'Humanity builds a tower to make a name for itself; God '
        'confuses their language and scatters them across the earth.',
    refs: [CuratedTopicRef('Genesis', 11, 1, 9)],
  ),
  CuratedTopic(
    name: "ABRAHAM'S CALL AND COVENANT",
    category: 'story',
    description:
        'God calls Abram out of Haran and repeatedly covenants to '
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
    description:
        'God tests Abraham by commanding him to sacrifice Isaac, '
        'then provides a ram in his place at the last moment.',
    refs: [CuratedTopicRef('Genesis', 22, 1, 19)],
  ),
  CuratedTopic(
    name: 'JOSEPH SOLD INTO SLAVERY',
    category: 'story',
    description:
        "Joseph's jealous brothers throw him into a pit and sell "
        'him to traders bound for Egypt.',
    refs: [CuratedTopicRef('Genesis', 37, 12, 36)],
  ),
  CuratedTopic(
    name: 'MOSES AND THE BURNING BUSH',
    category: 'story',
    description:
        'God appears to Moses in a bush that burns without being '
        'consumed and commissions him to deliver Israel from Egypt.',
    refs: [CuratedTopicRef('Exodus', 3, 1, 15)],
  ),
  CuratedTopic(
    name: 'THE EXODUS FROM EGYPT',
    category: 'story',
    description:
        'After the tenth plague, Pharaoh finally lets Israel go, '
        'and they set out from Egypt in haste after four hundred years.',
    refs: [CuratedTopicRef('Exodus', 12, 29, 42)],
  ),
  CuratedTopic(
    name: 'CROSSING THE RED SEA',
    category: 'story',
    description:
        'Trapped between Pharaoh\'s pursuing army and the sea, '
        'Israel crosses the Red Sea on dry ground as the waters part, then '
        'close again to drown the Egyptians.',
    refs: [CuratedTopicRef('Exodus', 14, 21, 31)],
  ),
  CuratedTopic(
    name: "MIRIAM'S SONG AT THE SEA",
    category: 'story',
    description:
        'After Israel crosses the Red Sea, the prophetess Miriam '
        'takes up a tambourine and leads the women in dancing, singing, '
        '"Sing to the LORD, for he has triumphed gloriously."',
    refs: [CuratedTopicRef('Exodus', 15, 20, 21)],
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
    description:
        'The shepherd boy David kills the Philistine champion '
        'Goliath with a sling and a stone.',
    refs: [CuratedTopicRef('1 Samuel', 17)],
  ),
  CuratedTopic(
    name: "DANIEL IN THE LIONS' DEN",
    category: 'story',
    description:
        'Daniel is thrown into a den of lions for praying to God '
        'in defiance of a royal decree, and God shuts the lions\' mouths.',
    refs: [CuratedTopicRef('Daniel', 6)],
  ),
  CuratedTopic(
    name: 'THE ANNUNCIATION',
    category: 'story',
    description:
        'The angel Gabriel tells the virgin Mary she will '
        'conceive by the Holy Spirit and bear the Son of God, and she '
        'answers, "Let it be to me according to your word."',
    refs: [CuratedTopicRef('Luke', 1, 26, 38)],
  ),
  CuratedTopic(
    name: "THE VISITATION AND MARY'S MAGNIFICAT",
    category: 'story',
    description:
        'Mary visits her relative Elizabeth, whose unborn son '
        'leaps at her greeting, and Mary responds with her song of '
        'praise: "My soul magnifies the Lord."',
    refs: [CuratedTopicRef('Luke', 1, 39, 56)],
  ),
  CuratedTopic(
    name: "ZECHARIAH, ELIZABETH, AND THE BIRTH OF JOHN THE BAPTIST",
    category: 'story',
    description:
        'An angel strikes the priest Zechariah mute for '
        'doubting that his aged wife Elizabeth will bear a son; his '
        'speech returns the moment he names the baby John.',
    refs: [
      CuratedTopicRef('Luke', 1, 5, 25),
      CuratedTopicRef('Luke', 1, 57, 80),
    ],
  ),
  CuratedTopic(
    name: 'THE BIRTH OF JESUS',
    category: 'story',
    description:
        'Jesus is born to Mary in Bethlehem and laid in a manger; '
        'angels announce the news to shepherds keeping watch nearby.',
    refs: [
      CuratedTopicRef('Luke', 2, 1, 20),
      CuratedTopicRef('Matthew', 1, 18, 25),
    ],
  ),
  CuratedTopic(
    name: 'THE VISIT OF THE MAGI',
    category: 'story',
    description:
        'Magi from the east follow a star to Bethlehem and worship '
        'the infant Jesus with gifts of gold, frankincense, and myrrh.',
    refs: [CuratedTopicRef('Matthew', 2, 1, 12)],
  ),
  CuratedTopic(
    name: 'THE FLIGHT TO EGYPT AND THE MASSACRE OF THE INNOCENTS',
    category: 'story',
    description:
        'Warned in a dream, Joseph flees with Mary and Jesus to '
        'Egypt just before Herod, enraged by the magi, orders every boy '
        'in Bethlehem under two years old put to death.',
    refs: [CuratedTopicRef('Matthew', 2, 13, 23)],
  ),
  CuratedTopic(
    name: 'SIMEON AND ANNA AT THE TEMPLE',
    category: 'story',
    description:
        'The aged Simeon and the prophetess Anna, who had long '
        'awaited Israel\'s redemption, recognize the infant Jesus as the '
        'promised Messiah when Mary and Joseph present him at the temple.',
    refs: [CuratedTopicRef('Luke', 2, 22, 38)],
  ),
  CuratedTopic(
    name: 'THE BOY JESUS AT THE TEMPLE',
    category: 'story',
    description:
        'Twelve-year-old Jesus stays behind in Jerusalem, found '
        'three days later sitting among the teachers in the temple, '
        '"listening to them and asking them questions."',
    refs: [CuratedTopicRef('Luke', 2, 41, 52)],
  ),
  CuratedTopic(
    name: "JESUS' BAPTISM",
    category: 'story',
    description:
        'John the Baptist baptizes Jesus in the Jordan; the Spirit '
        'descends like a dove and a voice from heaven declares him God\'s '
        'Son.',
    refs: [CuratedTopicRef('Matthew', 3, 13, 17)],
  ),
  CuratedTopic(
    name: 'THE TEMPTATION OF JESUS',
    category: 'story',
    description:
        'Led by the Spirit into the wilderness, Jesus fasts '
        'forty days and refuses Satan\'s three temptations — bread from '
        'stones, a leap from the temple, and the kingdoms of the world.',
    refs: [CuratedTopicRef('Matthew', 4, 1, 11)],
  ),
  CuratedTopic(
    name: 'THE SERMON AT NAZARETH',
    category: 'story',
    description:
        'In his hometown synagogue, Jesus reads from Isaiah and '
        'declares, "Today this Scripture is fulfilled in your hearing" — '
        'and the crowd tries to throw him off a cliff for it.',
    refs: [CuratedTopicRef('Luke', 4, 16, 30)],
  ),
  CuratedTopic(
    name: 'THE SERMON ON THE MOUNT',
    category: 'story',
    description:
        "Jesus teaches the Beatitudes and the core of his ethical "
        'teaching to a crowd gathered on a mountainside, from prayer and '
        'fasting to the Golden Rule.',
    refs: [
      CuratedTopicRef('Matthew', 5),
      CuratedTopicRef('Matthew', 6),
      CuratedTopicRef('Matthew', 7),
    ],
  ),
  CuratedTopic(
    name: 'THE BEATITUDES',
    category: 'story',
    description:
        'Jesus opens the Sermon on the Mount with a series of '
        'blessings — "Blessed are the poor in spirit... the meek... the '
        'merciful..." — describing the character of the kingdom of heaven.',
    refs: [CuratedTopicRef('Matthew', 5, 1, 12)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE WISE AND FOOLISH BUILDERS',
    category: 'story',
    description:
        'Jesus closes the Sermon on the Mount by contrasting a '
        'wise man who built his house on rock with a foolish man who '
        'built on sand, and only the first survives the storm.',
    refs: [CuratedTopicRef('Matthew', 7, 24, 27)],
  ),
  CuratedTopic(
    name: 'THE FEEDING OF THE FIVE THOUSAND',
    category: 'story',
    description:
        'Jesus multiplies five loaves and two fish to feed a crowd '
        'of five thousand, with twelve baskets of food left over.',
    refs: [CuratedTopicRef('John', 6, 1, 14)],
  ),
  CuratedTopic(
    name: 'THE TRANSFIGURATION',
    category: 'story',
    description:
        "Jesus is transfigured before Peter, James, and John; his "
        'face and clothes shine, and Moses and Elijah appear with him.',
    refs: [CuratedTopicRef('Matthew', 17, 1, 8)],
  ),
  CuratedTopic(
    name: 'THE LAST SUPPER',
    category: 'story',
    description:
        'Jesus shares a final Passover meal with his disciples '
        'and institutes the bread and cup in remembrance of him.',
    refs: [CuratedTopicRef('Luke', 22, 14, 20)],
  ),
  CuratedTopic(
    name: 'THE CRUCIFIXION',
    category: 'story',
    description:
        'Jesus is crucified at Golgotha between two criminals and '
        'dies, committing his spirit into the Father\'s hands.',
    refs: [CuratedTopicRef('Luke', 23, 33, 46)],
  ),
  CuratedTopic(
    name: 'JOHN AT THE FOOT OF THE CROSS',
    category: 'story',
    description:
        "Standing at the cross with Jesus' mother, John receives "
        'his dying charge to care for her: "Woman, behold your son!" and '
        '"Behold your mother."',
    refs: [CuratedTopicRef('John', 19, 25, 27)],
  ),
  CuratedTopic(
    name: 'THE BURIAL OF JESUS',
    category: 'story',
    description:
        'Joseph of Arimathea asks Pilate for the body of Jesus '
        'and lays it in his own new tomb, wrapped in linen with Nicodemus\' '
        'spices, and rolls a stone across the entrance.',
    refs: [CuratedTopicRef('John', 19, 38, 42)],
  ),
  CuratedTopic(
    name: 'THE GUARD AT THE TOMB',
    category: 'story',
    description:
        'Pilate has the tomb sealed and posts a guard at the '
        'chief priests\' request, who later bribe the guards to spread the '
        'story that the disciples stole Jesus\' body.',
    refs: [
      CuratedTopicRef('Matthew', 27, 62, 66),
      CuratedTopicRef('Matthew', 28, 11, 15),
    ],
  ),
  CuratedTopic(
    name: 'THE RESURRECTION',
    category: 'story',
    description:
        'Women find the tomb empty on the third day; angels '
        'announce that Jesus has risen.',
    refs: [CuratedTopicRef('Luke', 24, 1, 12)],
  ),
  CuratedTopic(
    name: 'THE ASCENSION',
    category: 'story',
    description:
        'Jesus commissions his disciples and is taken up into '
        'heaven before their eyes.',
    refs: [CuratedTopicRef('Acts', 1, 6, 11)],
  ),
  CuratedTopic(
    name: 'THE CHOOSING OF MATTHIAS',
    category: 'story',
    description:
        "After Judas's betrayal and death, the disciples cast "
        'lots between two candidates to restore the number of the Twelve, '
        'and Matthias is added to the apostles.',
    refs: [CuratedTopicRef('Acts', 1, 15, 26)],
  ),
  CuratedTopic(
    name: 'THE DAY OF PENTECOST',
    category: 'story',
    description:
        'The Holy Spirit descends on the gathered believers with '
        'the sound of wind and tongues of fire, and they speak in other '
        'tongues.',
    refs: [CuratedTopicRef('Acts', 2, 1, 13)],
  ),
  CuratedTopic(
    name: "PETER'S SERMON AT PENTECOST",
    category: 'story',
    description:
        'Peter preaches to the gathered crowd that the risen '
        'Jesus is Lord and Christ; cut to the heart, three thousand '
        'repent and are baptized that day.',
    refs: [CuratedTopicRef('Acts', 2, 14, 41)],
  ),
  CuratedTopic(
    name: 'PETER HEALS THE LAME MAN AT THE TEMPLE',
    category: 'story',
    description:
        'Peter heals a man lame from birth at the Beautiful Gate '
        'of the temple, "in the name of Jesus Christ of Nazareth."',
    refs: [CuratedTopicRef('Acts', 3, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE CONVERSION OF SAUL',
    category: 'story',
    description:
        'A blinding light and the voice of Jesus confront Saul on '
        'the road to Damascus; Ananias restores his sight and he is '
        'baptized.',
    refs: [CuratedTopicRef('Acts', 9, 1, 19)],
  ),
  CuratedTopic(
    name: 'SAUL ESCAPES DAMASCUS IN A BASKET',
    category: 'story',
    description:
        'When the Jews in Damascus plot to kill him, Saul\'s '
        'disciples lower him over the city wall by night in a large '
        'basket.',
    refs: [CuratedTopicRef('Acts', 9, 23, 25)],
  ),

  // --- Genesis ---
  CuratedTopic(
    name: 'CAIN AND ABEL',
    category: 'story',
    description:
        'Cain murders his brother Abel out of jealousy and is '
        'marked and banished by God.',
    refs: [CuratedTopicRef('Genesis', 4, 1, 16)],
  ),
  CuratedTopic(
    name: 'ABRAHAM AND MELCHIZEDEK',
    category: 'story',
    description:
        'The king-priest Melchizedek blesses Abraham with bread '
        'and wine after his rescue of Lot, and Abraham gives him a tenth '
        'of everything.',
    refs: [CuratedTopicRef('Genesis', 14, 17, 20)],
  ),
  CuratedTopic(
    name: "SARAH'S LAUGHTER AND THE BIRTH OF ISAAC",
    category: 'story',
    description:
        'Sarah laughs to herself at the promise that she will '
        'bear a son in her old age, then laughs again for joy when Isaac '
        '— "he laughs" — is born just as the LORD had said.',
    refs: [
      CuratedTopicRef('Genesis', 18, 1, 15),
      CuratedTopicRef('Genesis', 21, 1, 7),
    ],
  ),
  CuratedTopic(
    name: 'THE DESTRUCTION OF SODOM AND GOMORRAH',
    category: 'story',
    description:
        'Angels rescue Lot and his family before God rains fire '
        'and sulfur on Sodom and Gomorrah; Lot\'s wife looks back and '
        'becomes a pillar of salt.',
    refs: [CuratedTopicRef('Genesis', 19, 1, 29)],
  ),
  CuratedTopic(
    name: 'HAGAR AND ISHMAEL SENT AWAY',
    category: 'story',
    description:
        'Sarah has Hagar and Ishmael sent into the wilderness, '
        'where God provides water and promises to make Ishmael a great '
        'nation.',
    refs: [CuratedTopicRef('Genesis', 21, 8, 21)],
  ),
  CuratedTopic(
    name: 'ISAAC AND REBEKAH',
    category: 'story',
    description:
        'Abraham\'s servant prays for a sign at a well and finds '
        'Rebekah, who returns with him to become Isaac\'s wife.',
    refs: [CuratedTopicRef('Genesis', 24)],
  ),
  CuratedTopic(
    name: "JACOB'S BIRTHRIGHT AND BLESSING",
    category: 'story',
    description:
        'Esau sells his birthright for a bowl of stew, and Jacob '
        'later deceives their blind father Isaac to steal Esau\'s blessing.',
    refs: [
      CuratedTopicRef('Genesis', 25, 29, 34),
      CuratedTopicRef('Genesis', 27, 1, 40),
    ],
  ),
  CuratedTopic(
    name: 'JACOB WRESTLES WITH THE ANGEL',
    category: 'story',
    description:
        'Jacob wrestles with a divine visitor all night at Peniel, '
        'refusing to let go until he is blessed, and is renamed Israel.',
    refs: [CuratedTopicRef('Genesis', 32, 22, 32)],
  ),
  CuratedTopic(
    name: "JACOB AND ESAU RECONCILE",
    category: 'story',
    description:
        'Dreading revenge for the stolen blessing, Jacob bows '
        'seven times before Esau — who instead runs to embrace him, kisses '
        'him, and weeps.',
    refs: [CuratedTopicRef('Genesis', 33)],
  ),
  CuratedTopic(
    name: 'THE DEATH OF RACHEL',
    category: 'story',
    description:
        'Rachel dies giving birth to Benjamin on the road to '
        'Bethlehem, naming him with her last breath before Jacob buries '
        'her and sets up a pillar over her tomb.',
    refs: [CuratedTopicRef('Genesis', 35, 16, 20)],
  ),
  CuratedTopic(
    name: "JOSEPH'S DREAMS",
    category: 'story',
    description:
        'Joseph, favored by his father with a special coat, '
        'dreams that his family will one day bow down to him — fueling his '
        'brothers\' jealousy.',
    refs: [CuratedTopicRef('Genesis', 37, 1, 11)],
  ),
  CuratedTopic(
    name: "JOSEPH INTERPRETS PHARAOH'S DREAMS",
    category: 'story',
    description:
        'Joseph interprets Pharaoh\'s dreams of coming famine and '
        'is made ruler over all Egypt to prepare for it.',
    refs: [CuratedTopicRef('Genesis', 41, 1, 40)],
  ),
  CuratedTopic(
    name: "JOSEPH TESTS HIS BROTHERS",
    category: 'story',
    description:
        'Joseph, unrecognized by the brothers who once sold him, '
        "tests them by planting his silver cup in Benjamin's sack before "
        'revealing who he is.',
    refs: [CuratedTopicRef('Genesis', 42), CuratedTopicRef('Genesis', 44)],
  ),
  CuratedTopic(
    name: 'JOSEPH REVEALS HIMSELF TO HIS BROTHERS',
    category: 'story',
    description:
        'Joseph, now Egypt\'s governor, breaks down and reveals his '
        'identity to the brothers who once sold him into slavery.',
    refs: [CuratedTopicRef('Genesis', 45, 1, 15)],
  ),
  CuratedTopic(
    name: "JACOB'S LADDER",
    category: 'story',
    description:
        'Fleeing Esau, Jacob dreams of a stairway to heaven with '
        'angels ascending and descending, and God renews the covenant '
        'promise to him at Bethel.',
    refs: [CuratedTopicRef('Genesis', 28, 10, 22)],
  ),
  CuratedTopic(
    name: 'JACOB MEETS RACHEL AND SERVES LABAN',
    category: 'story',
    description:
        'Jacob falls in love with Rachel at a well, works seven '
        'years for her, and is deceived into marrying Leah first.',
    refs: [CuratedTopicRef('Genesis', 29, 1, 30)],
  ),
  CuratedTopic(
    name: "RACHEL AND LEAH'S RIVALRY",
    category: 'story',
    description:
        'Rachel envies her fertile sister Leah and gives Jacob '
        'her servant to bear children in her place, until God finally '
        '"remembers" Rachel and she bears Joseph.',
    refs: [CuratedTopicRef('Genesis', 30, 1, 24)],
  ),
  CuratedTopic(
    name: 'DINAH AND THE SHECHEMITES',
    category: 'story',
    description:
        "After Shechem violates Jacob's daughter Dinah, her "
        'brothers Simeon and Levi avenge her by slaughtering the men of '
        'the city.',
    refs: [CuratedTopicRef('Genesis', 34)],
  ),
  CuratedTopic(
    name: 'JUDAH AND TAMAR',
    category: 'story',
    description:
        'Denied a husband from Judah\'s family, Tamar disguises '
        'herself and conceives by Judah himself, who admits, "She is more '
        'righteous than I."',
    refs: [CuratedTopicRef('Genesis', 38)],
  ),
  CuratedTopic(
    name: "JOSEPH AND POTIPHAR'S WIFE",
    category: 'story',
    description:
        'Joseph flees the advances of his master\'s wife, who then '
        'falsely accuses him and has him thrown into prison.',
    refs: [CuratedTopicRef('Genesis', 39)],
  ),
  CuratedTopic(
    name: 'JACOB BLESSES HIS SONS',
    category: 'story',
    description:
        'On his deathbed in Egypt, Jacob gathers his twelve sons '
        'and pronounces a blessing and prophecy over each of them.',
    refs: [CuratedTopicRef('Genesis', 49, 1, 28)],
  ),

  // --- Exodus – Numbers ---
  CuratedTopic(
    name: 'MOSES FOUND IN THE BASKET',
    category: 'story',
    description:
        'To save him from Pharaoh\'s decree, infant Moses is set '
        'adrift in a basket on the Nile and found by Pharaoh\'s daughter.',
    refs: [CuratedTopicRef('Exodus', 2, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE TEN PLAGUES OF EGYPT',
    category: 'story',
    description:
        'God sends ten plagues on Egypt, from the Nile turning to '
        'blood to the death of the firstborn, until Pharaoh releases Israel.',
    refs: [
      CuratedTopicRef('Exodus', 7, 20, 21),
      CuratedTopicRef('Exodus', 12, 29, 30),
    ],
  ),
  CuratedTopic(
    name: 'MANNA AND QUAIL IN THE WILDERNESS',
    category: 'story',
    description:
        'God feeds the grumbling Israelites with quail in the '
        'evening and bread-like manna every morning in the wilderness.',
    refs: [CuratedTopicRef('Exodus', 16, 4, 15)],
  ),
  CuratedTopic(
    name: 'WATER FROM THE ROCK',
    category: 'story',
    description:
        'At Massah and Meribah, Moses strikes a rock at Horeb and '
        'water flows out for the thirsty Israelites.',
    refs: [CuratedTopicRef('Exodus', 17, 1, 7)],
  ),
  CuratedTopic(
    name: "AARON AND HUR HOLD UP MOSES' HANDS",
    category: 'story',
    description:
        "As long as Moses holds up his hands, Israel prevails "
        'against Amalek in battle, so Aaron and Hur hold his arms steady '
        'until sunset.',
    refs: [CuratedTopicRef('Exodus', 17, 8, 16)],
  ),
  CuratedTopic(
    name: 'THE GOLDEN CALF',
    category: 'story',
    description:
        'While Moses is on Mount Sinai, Israel persuades Aaron to '
        'make a golden calf to worship, provoking God\'s anger.',
    refs: [CuratedTopicRef('Exodus', 32)],
  ),
  CuratedTopic(
    name: "MIRIAM AND AARON'S REBELLION",
    category: 'story',
    description:
        'Miriam and Aaron challenge Moses\' unique authority and '
        'Miriam is struck with leprosy, healed only after Moses intercedes '
        'and she is shut out of the camp for seven days.',
    refs: [CuratedTopicRef('Numbers', 12)],
  ),
  CuratedTopic(
    name: 'THE TWELVE SPIES',
    category: 'story',
    description:
        'Twelve spies scout Canaan; ten report giants and defeat, '
        'but Joshua and Caleb urge Israel to trust God and take the land.',
    refs: [CuratedTopicRef('Numbers', 13)],
  ),
  CuratedTopic(
    name: "BALAAM'S DONKEY",
    category: 'story',
    description:
        'Balaam\'s donkey sees the angel of the LORD blocking the '
        'road and speaks aloud in protest before Balaam himself sees it.',
    refs: [CuratedTopicRef('Numbers', 22, 21, 35)],
  ),
  CuratedTopic(
    name: "MOSES' FACE SHINES",
    category: 'story',
    description:
        'Moses comes down from Sinai with the second set of '
        'tablets, his face radiant from speaking with the LORD, and must '
        'veil it before the people.',
    refs: [CuratedTopicRef('Exodus', 34, 29, 35)],
  ),
  CuratedTopic(
    name: "KORAH'S REBELLION",
    category: 'story',
    description:
        "Korah and his followers challenge Moses and Aaron's "
        'authority; the earth opens and swallows them, and fire consumes '
        'their company.',
    refs: [CuratedTopicRef('Numbers', 16)],
  ),
  CuratedTopic(
    name: "AARON'S ROD BUDS",
    category: 'story',
    description:
        "God confirms Aaron's priesthood when his staff alone, "
        'left overnight before the ark, sprouts buds, blossoms, and '
        'ripe almonds.',
    refs: [CuratedTopicRef('Numbers', 17)],
  ),
  CuratedTopic(
    name: 'THE WATERS OF MERIBAH',
    category: 'story',
    description:
        'Moses strikes the rock in anger instead of speaking to it '
        'as commanded, and God bars him from entering the promised land '
        'because of it.',
    refs: [CuratedTopicRef('Numbers', 20, 1, 13)],
  ),
  CuratedTopic(
    name: 'THE BRONZE SERPENT',
    category: 'story',
    description:
        'When venomous snakes plague the grumbling Israelites, God '
        'has Moses lift up a bronze serpent so that anyone who looks at it '
        'lives.',
    refs: [CuratedTopicRef('Numbers', 21, 4, 9)],
  ),
  CuratedTopic(
    name: "PHINEHAS' ZEAL AT BAAL-PEOR",
    category: 'story',
    description:
        "Phinehas stops a plague on Israel by killing an Israelite "
        'man and a Midianite woman caught flagrantly worshiping Baal '
        'together, and is rewarded with a covenant of peace.',
    refs: [CuratedTopicRef('Numbers', 25)],
  ),

  // --- Leviticus ---
  CuratedTopic(
    name: 'THE DEATH OF NADAB AND ABIHU',
    category: 'story',
    description:
        "Aaron's sons Nadab and Abihu offer \"strange fire\" "
        'before the LORD and are struck dead on the spot.',
    refs: [CuratedTopicRef('Leviticus', 10, 1, 7)],
  ),

  // --- Deuteronomy ---
  CuratedTopic(
    name: 'MOSES VIEWS THE PROMISED LAND AND DIES',
    category: 'story',
    description:
        'Barred from entering Canaan, Moses views it from Mount '
        'Nebo before dying at 120, "his eye undimmed and his vigor '
        'unabated."',
    refs: [CuratedTopicRef('Deuteronomy', 34)],
  ),

  // --- Joshua – Ruth ---
  CuratedTopic(
    name: 'RAHAB AND THE SPIES',
    category: 'story',
    description:
        'Rahab hides Israel\'s spies in Jericho and is promised '
        'safety for her family when the city falls.',
    refs: [CuratedTopicRef('Joshua', 2)],
  ),
  CuratedTopic(
    name: 'THE BATTLE OF JERICHO',
    category: 'story',
    description:
        'Israel marches around Jericho for seven days; on the '
        'seventh, the walls collapse at the sound of trumpets and a shout.',
    refs: [CuratedTopicRef('Joshua', 6, 1, 20)],
  ),
  CuratedTopic(
    name: "ACHAN'S SIN",
    category: 'story',
    description:
        'Achan\'s theft of devoted plunder from Jericho brings '
        'Israel\'s defeat at Ai, until his sin is uncovered and judged.',
    refs: [CuratedTopicRef('Joshua', 7)],
  ),
  CuratedTopic(
    name: 'ISRAEL CROSSES THE JORDAN',
    category: 'story',
    description:
        'The priests carrying the ark step into the flooding '
        'Jordan and its waters stop, letting Israel cross into Canaan on '
        'dry ground.',
    refs: [CuratedTopicRef('Joshua', 3), CuratedTopicRef('Joshua', 4, 1, 18)],
  ),
  CuratedTopic(
    name: 'THE GIBEONITE DECEPTION',
    category: 'story',
    description:
        'The Gibeonites trick Israel into a treaty of peace by '
        'disguising themselves as weary travelers from a distant land.',
    refs: [CuratedTopicRef('Joshua', 9)],
  ),
  CuratedTopic(
    name: 'THE SUN STANDS STILL',
    category: 'story',
    description:
        'Joshua commands the sun and moon to stand still over '
        'Gibeon so Israel can finish routing its enemies by daylight.',
    refs: [CuratedTopicRef('Joshua', 10, 1, 15)],
  ),
  CuratedTopic(
    name: 'EHUD THE LEFT-HANDED JUDGE',
    category: 'story',
    description:
        'Ehud smuggles a hidden dagger past the obese Moabite king '
        'Eglon and delivers Israel from eighteen years of oppression.',
    refs: [CuratedTopicRef('Judges', 3, 12, 30)],
  ),
  CuratedTopic(
    name: 'DEBORAH AND BARAK',
    category: 'story',
    description:
        'The prophetess Deborah leads Israel with Barak against '
        'Sisera\'s army, and Jael kills the fleeing Sisera in her tent.',
    refs: [CuratedTopicRef('Judges', 4)],
  ),
  CuratedTopic(
    name: 'JAEL KILLS SISERA',
    category: 'story',
    description:
        "Fleeing the battle, the Canaanite general Sisera takes "
        "refuge in Jael's tent, where she lulls him to sleep with milk "
        'and drives a tent peg through his temple.',
    refs: [CuratedTopicRef('Judges', 4, 17, 22)],
  ),
  CuratedTopic(
    name: "GIDEON'S CALL AT THE WINEPRESS",
    category: 'story',
    description:
        'An angel finds Gideon threshing wheat in a winepress to '
        'hide it from Midian and calls him a "mighty man of valor"; Gideon '
        'tears down his father\'s altar to Baal in response.',
    refs: [CuratedTopicRef('Judges', 6, 11, 32)],
  ),
  CuratedTopic(
    name: "GIDEON'S FLEECE",
    category: 'story',
    description:
        'Gideon asks God for two confirming signs with a wool '
        'fleece before leading Israel against the Midianites.',
    refs: [CuratedTopicRef('Judges', 6, 36, 40)],
  ),
  CuratedTopic(
    name: "GIDEON'S THREE HUNDRED",
    category: 'story',
    description:
        'God pares Gideon\'s army down to three hundred men, who '
        'rout the vast Midianite camp with torches, trumpets, and jars.',
    refs: [CuratedTopicRef('Judges', 7)],
  ),
  CuratedTopic(
    name: "ABIMELECH'S KINGSHIP AND DEATH",
    category: 'story',
    description:
        "Gideon's son Abimelech murders his brothers to seize "
        "kingship over Shechem, and dies ignobly when a woman drops a "
        'millstone on his head during a siege.',
    refs: [CuratedTopicRef('Judges', 9)],
  ),
  CuratedTopic(
    name: "JEPHTHAH'S VOW",
    category: 'story',
    description:
        'Jephthah vows to sacrifice whatever comes out of his house '
        'first if God grants him victory — and his daughter is the one who '
        'comes out to meet him.',
    refs: [CuratedTopicRef('Judges', 11, 29, 40)],
  ),
  CuratedTopic(
    name: "SAMSON'S BIRTH",
    category: 'story',
    description:
        'An angel announces to Manoah\'s barren wife that she will '
        'bear Samson, a Nazirite set apart to deliver Israel.',
    refs: [CuratedTopicRef('Judges', 13)],
  ),
  CuratedTopic(
    name: "SAMSON'S RIDDLE AND WEDDING",
    category: 'story',
    description:
        'Samson poses a riddle from a lion carcass full of honey '
        'at his wedding feast, and the Philistines coax the answer out of '
        'his bride to win the bet.',
    refs: [CuratedTopicRef('Judges', 14)],
  ),
  CuratedTopic(
    name: 'SAMSON AND DELILAH',
    category: 'story',
    description:
        'Delilah wears Samson down until he reveals that his '
        'strength lies in his uncut hair, and the Philistines seize him.',
    refs: [CuratedTopicRef('Judges', 16, 4, 22)],
  ),
  CuratedTopic(
    name: "SAMSON'S DEATH",
    category: 'story',
    description:
        'Blinded and mocked in the Philistines\' temple, Samson '
        'prays for strength once more and pulls the pillars down on '
        'himself and his captors.',
    refs: [CuratedTopicRef('Judges', 16, 23, 30)],
  ),
  CuratedTopic(
    name: 'RUTH GLEANS IN THE FIELD OF BOAZ',
    category: 'story',
    description:
        'The widowed Ruth gleans leftover grain in the field of '
        'Boaz, a relative of her late husband, who shows her favor.',
    refs: [CuratedTopicRef('Ruth', 2)],
  ),
  CuratedTopic(
    name: 'BOAZ REDEEMS RUTH',
    category: 'story',
    description:
        'Boaz publicly redeems Ruth and her family\'s inheritance '
        'and marries her; their son Obed becomes David\'s grandfather.',
    refs: [CuratedTopicRef('Ruth', 4)],
  ),

  // --- 1–2 Samuel ---
  CuratedTopic(
    name: "HANNAH'S PRAYER AND SAMUEL'S BIRTH",
    category: 'story',
    description:
        'The barren Hannah prays for a son and dedicates him to '
        'the LORD\'s service; Samuel is born in answer to her prayer.',
    refs: [CuratedTopicRef('1 Samuel', 1, 9, 20)],
  ),
  CuratedTopic(
    name: "SAMUEL'S CALLING",
    category: 'story',
    description:
        'The boy Samuel hears the LORD calling his name in the '
        'night and, with Eli\'s guidance, answers, "Speak, for your '
        'servant hears."',
    refs: [CuratedTopicRef('1 Samuel', 3)],
  ),
  CuratedTopic(
    name: 'THE ARK CAPTURED AND THE FALL OF DAGON',
    category: 'story',
    description:
        "The Philistines capture the ark of the covenant in "
        'battle, and their idol Dagon topples before it until they send it '
        'back with a plague-stricken tribute.',
    refs: [
      CuratedTopicRef('1 Samuel', 4, 1, 11),
      CuratedTopicRef('1 Samuel', 5),
    ],
  ),
  CuratedTopic(
    name: 'SAUL ANOINTED KING',
    category: 'story',
    description:
        'Samuel privately anoints Saul as Israel\'s first king at '
        'God\'s direction, after the people demand a king like the nations.',
    refs: [
      CuratedTopicRef('1 Samuel', 9, 15, 21),
      CuratedTopicRef('1 Samuel', 10, 1),
    ],
  ),
  CuratedTopic(
    name: 'SAUL REJECTED AS KING',
    category: 'story',
    description:
        "Saul's incomplete obedience against Amalek — sparing "
        'King Agag and the best plunder — leads Samuel to declare that '
        'the LORD has rejected him as king.',
    refs: [CuratedTopicRef('1 Samuel', 15)],
  ),
  CuratedTopic(
    name: 'DAVID ANOINTED KING',
    category: 'story',
    description:
        'Samuel passes over David\'s older brothers and secretly '
        'anoints the shepherd boy David as Israel\'s future king.',
    refs: [CuratedTopicRef('1 Samuel', 16, 1, 13)],
  ),
  CuratedTopic(
    name: "DAVID AND JONATHAN'S FRIENDSHIP",
    category: 'story',
    description:
        'Jonathan, Saul\'s son, makes a covenant of friendship '
        'with David and later risks his father\'s wrath to warn him of '
        'danger.',
    refs: [
      CuratedTopicRef('1 Samuel', 18, 1, 4),
      CuratedTopicRef('1 Samuel', 20, 35, 42),
    ],
  ),
  CuratedTopic(
    name: 'DAVID FEIGNS MADNESS AT GATH',
    category: 'story',
    description:
        "Fleeing Saul, David seeks refuge with the Philistines but "
        'is recognized, so he pretends to be insane to escape King '
        'Achish unharmed.',
    refs: [CuratedTopicRef('1 Samuel', 21, 10, 15)],
  ),
  CuratedTopic(
    name: "DAVID SPARES SAUL'S LIFE",
    category: 'story',
    description:
        'David secretly cuts off a corner of Saul\'s robe in a '
        'cave at En Gedi rather than kill the king who is hunting him.',
    refs: [CuratedTopicRef('1 Samuel', 24)],
  ),
  CuratedTopic(
    name: 'DAVID AND ABIGAIL',
    category: 'story',
    description:
        'The wise Abigail intercepts David with provisions and '
        'talks him out of avenging himself on her foolish husband Nabal, '
        'and later becomes David\'s wife.',
    refs: [CuratedTopicRef('1 Samuel', 25)],
  ),
  CuratedTopic(
    name: 'THE MEDIUM OF ENDOR',
    category: 'story',
    description:
        'On the eve of his final battle, a desperate Saul '
        'disguises himself to consult a medium, who summons the spirit of '
        'Samuel.',
    refs: [CuratedTopicRef('1 Samuel', 28, 3, 25)],
  ),
  CuratedTopic(
    name: 'DAVID MOURNS SAUL AND JONATHAN',
    category: 'story',
    description:
        'On hearing of Saul and Jonathan\'s deaths, David tears '
        'his clothes, executes the messenger who claims to have killed '
        'Saul, and laments them in song.',
    refs: [CuratedTopicRef('2 Samuel', 1, 1, 27)],
  ),
  CuratedTopic(
    name: 'DAVID BRINGS THE ARK TO JERUSALEM',
    category: 'story',
    description:
        'David dances before the LORD with all his might as the '
        'ark of the covenant is brought into Jerusalem.',
    refs: [CuratedTopicRef('2 Samuel', 6)],
  ),
  CuratedTopic(
    name: "MICHAL DESPISES DAVID'S DANCING",
    category: 'story',
    description:
        'Watching David dance before the LORD as the ark enters '
        'Jerusalem, his wife Michal despises him in her heart for it, '
        'and is left childless the rest of her life.',
    refs: [CuratedTopicRef('2 Samuel', 6, 16, 23)],
  ),
  CuratedTopic(
    name: 'DAVID AND MEPHIBOSHETH',
    category: 'story',
    description:
        "For Jonathan's sake, David shows kindness to his lame son "
        "Mephibosheth, restoring Saul's land to him and seating him always "
        "at the king's table.",
    refs: [CuratedTopicRef('2 Samuel', 9)],
  ),
  CuratedTopic(
    name: 'DAVID AND BATHSHEBA',
    category: 'story',
    description:
        'David commits adultery with Bathsheba and then arranges '
        'the death of her husband Uriah to cover it up.',
    refs: [CuratedTopicRef('2 Samuel', 11)],
  ),
  CuratedTopic(
    name: "NATHAN'S REBUKE OF DAVID",
    category: 'story',
    description:
        'The prophet Nathan confronts David with a parable of a '
        "rich man's theft of a poor man's ewe lamb, and David confesses, "
        '"I have sinned against the LORD."',
    refs: [CuratedTopicRef('2 Samuel', 12, 1, 14)],
  ),
  CuratedTopic(
    name: "ABSALOM'S REBELLION",
    category: 'story',
    description:
        'David\'s son Absalom steals the hearts of Israel and '
        'drives his father from Jerusalem in an attempted coup.',
    refs: [CuratedTopicRef('2 Samuel', 15)],
  ),
  CuratedTopic(
    name: "ABSALOM'S DEATH",
    category: 'story',
    description:
        "David's rebellious son Absalom is caught by his hair in "
        'an oak tree and killed by Joab against David\'s explicit orders.',
    refs: [CuratedTopicRef('2 Samuel', 18, 9, 15)],
  ),
  CuratedTopic(
    name: "DAVID'S CENSUS AND THE PLAGUE",
    category: 'story',
    description:
        "David's census of Israel brings a plague as judgment; it "
        'stops when he buys a threshing floor and offers sacrifices there.',
    refs: [CuratedTopicRef('2 Samuel', 24)],
  ),

  // --- 1–2 Kings ---
  CuratedTopic(
    name: 'BATHSHEBA SECURES THE THRONE FOR SOLOMON',
    category: 'story',
    description:
        "As the aging David's son Adonijah moves to seize the "
        'throne, Bathsheba goes to David and reminds him of his oath '
        'that Solomon would reign after him.',
    refs: [CuratedTopicRef('1 Kings', 1, 11, 31)],
  ),
  CuratedTopic(
    name: "SOLOMON'S WISDOM AND THE TWO MOTHERS",
    category: 'story',
    description:
        'Solomon exposes the true mother of a disputed infant by '
        'proposing to cut the child in two, revealing his famous wisdom.',
    refs: [CuratedTopicRef('1 Kings', 3, 16, 28)],
  ),
  CuratedTopic(
    name: 'SOLOMON BUILDS THE TEMPLE',
    category: 'story',
    description:
        'Solomon constructs the temple in Jerusalem as a '
        'permanent house for the LORD, fulfilling David\'s wish.',
    refs: [CuratedTopicRef('1 Kings', 6)],
  ),
  CuratedTopic(
    name: 'THE QUEEN OF SHEBA VISITS SOLOMON',
    category: 'story',
    description:
        'The Queen of Sheba tests Solomon with hard questions and '
        'is left breathless by his wisdom and wealth.',
    refs: [CuratedTopicRef('1 Kings', 10, 1, 13)],
  ),
  CuratedTopic(
    name: "SOLOMON'S DOWNFALL",
    category: 'story',
    description:
        "Solomon's foreign wives turn his heart after other gods "
        'in his old age, provoking the LORD to tear most of the kingdom '
        'from his son.',
    refs: [CuratedTopicRef('1 Kings', 11, 1, 13)],
  ),
  CuratedTopic(
    name: 'THE KINGDOM DIVIDED',
    category: 'story',
    description:
        "Rehoboam's harshness splits Solomon's kingdom in two: "
        'Jeroboam rules the northern ten tribes as Israel, Rehoboam the '
        'south as Judah.',
    refs: [CuratedTopicRef('1 Kings', 12, 1, 24)],
  ),
  CuratedTopic(
    name: "JEROBOAM'S GOLDEN CALVES",
    category: 'story',
    description:
        'To keep Israel from worshiping at Jerusalem, Jeroboam '
        'sets up golden calves at Bethel and Dan, launching the northern '
        'kingdom into idolatry.',
    refs: [CuratedTopicRef('1 Kings', 12, 25, 33)],
  ),
  CuratedTopic(
    name: 'ELIJAH FED BY RAVENS',
    category: 'story',
    description:
        'During a drought, ravens bring Elijah bread and meat by '
        'the brook Cherith at God\'s command.',
    refs: [CuratedTopicRef('1 Kings', 17, 1, 6)],
  ),
  CuratedTopic(
    name: 'ELIJAH AND THE WIDOW OF ZAREPHATH',
    category: 'story',
    description:
        "A widow's jar of flour and jug of oil never run out "
        'through the famine after she feeds Elijah, and he later raises '
        'her dead son.',
    refs: [CuratedTopicRef('1 Kings', 17, 8, 24)],
  ),
  CuratedTopic(
    name: 'ELIJAH AND THE PROPHETS OF BAAL',
    category: 'story',
    description:
        'Elijah challenges 450 prophets of Baal to a contest of '
        'fire at Mount Carmel; the LORD answers with fire from heaven and '
        'Elijah has the false prophets put to death.',
    refs: [CuratedTopicRef('1 Kings', 18)],
  ),
  CuratedTopic(
    name: 'ELIJAH AT HOREB',
    category: 'story',
    description:
        'Fleeing Jezebel in despair, Elijah encounters God not in '
        'wind, earthquake, or fire, but in a still small voice at Horeb.',
    refs: [CuratedTopicRef('1 Kings', 19)],
  ),
  CuratedTopic(
    name: "AHAB AND NABOTH'S VINEYARD",
    category: 'story',
    description:
        "Jezebel has Naboth falsely accused and stoned so Ahab can "
        'seize his vineyard, and Elijah confronts Ahab with God\'s judgment '
        'on the murder.',
    refs: [CuratedTopicRef('1 Kings', 21)],
  ),
  CuratedTopic(
    name: 'MICAIAH PROPHESIES AGAINST AHAB',
    category: 'story',
    description:
        'While four hundred court prophets promise victory, '
        'Micaiah alone tells Ahab the truth — that he will die in battle — '
        'and is struck and imprisoned for it.',
    refs: [CuratedTopicRef('1 Kings', 22, 1, 40)],
  ),
  CuratedTopic(
    name: 'ELIJAH TAKEN UP TO HEAVEN',
    category: 'story',
    description:
        'A chariot and horses of fire carry Elijah up to heaven in '
        'a whirlwind as Elisha watches and receives his mantle.',
    refs: [CuratedTopicRef('2 Kings', 2, 1, 12)],
  ),
  CuratedTopic(
    name: "ELISHA AND THE WIDOW'S OIL",
    category: 'story',
    description:
        "A widow's small jar of oil miraculously fills every "
        'vessel she can borrow, enough to pay her debts and live on.',
    refs: [CuratedTopicRef('2 Kings', 4, 1, 7)],
  ),
  CuratedTopic(
    name: "ELISHA RAISES THE SHUNAMMITE'S SON",
    category: 'story',
    description:
        'Elisha restores to life the son of the Shunammite woman '
        'who had provided him a room to stay in.',
    refs: [CuratedTopicRef('2 Kings', 4, 8, 37)],
  ),
  CuratedTopic(
    name: 'NAAMAN HEALED OF LEPROSY',
    category: 'story',
    description:
        'The Aramean commander Naaman is healed of leprosy after '
        'reluctantly dipping seven times in the Jordan at Elisha\'s word.',
    refs: [CuratedTopicRef('2 Kings', 5)],
  ),
  CuratedTopic(
    name: 'ELISHA AND THE FLOATING AXE HEAD',
    category: 'story',
    description:
        'When a borrowed axe head sinks in the Jordan, Elisha '
        'throws in a stick and makes the iron float.',
    refs: [CuratedTopicRef('2 Kings', 6, 1, 7)],
  ),
  CuratedTopic(
    name: 'ELISHA BLINDS THE SYRIAN ARMY',
    category: 'story',
    description:
        "Elisha prays the pursuing Syrian army blind, leads them "
        "into Samaria, and has the king feed them and send them home in "
        'peace instead of killing them.',
    refs: [CuratedTopicRef('2 Kings', 6, 8, 23)],
  ),
  CuratedTopic(
    name: "JEHU'S PURGE OF AHAB'S HOUSE",
    category: 'story',
    description:
        'Anointed king by a prophet, Jehu drives furiously against '
        "Jezebel and Ahab's entire dynasty, ending Baal worship in Israel "
        'by force.',
    refs: [
      CuratedTopicRef('2 Kings', 9),
      CuratedTopicRef('2 Kings', 10, 18, 28),
    ],
  ),
  CuratedTopic(
    name: 'THE DEATH OF JEZEBEL',
    category: 'story',
    description:
        'Painted and adorned, Jezebel taunts Jehu from a window '
        'as he arrives, until her own eunuchs throw her down at his '
        'command and dogs devour her body, just as Elijah had prophesied.',
    refs: [CuratedTopicRef('2 Kings', 9, 30, 37)],
  ),
  CuratedTopic(
    name: "ATHALIAH'S USURPATION AND FALL",
    category: 'story',
    description:
        'Queen Athaliah murders the royal family to seize the '
        'throne, but her infant grandson Joash is hidden away in the '
        'temple for six years until the priest Jehoiada crowns him king '
        'and has her put to death.',
    refs: [CuratedTopicRef('2 Kings', 11)],
  ),
  CuratedTopic(
    name: "SENNACHERIB'S SIEGE OF JERUSALEM",
    category: 'story',
    description:
        "Assyria's Sennacherib besieges Jerusalem and mocks the "
        "LORD; Hezekiah prays in the temple, and the angel of the LORD "
        "strikes down the Assyrian camp overnight.",
    refs: [
      CuratedTopicRef('2 Kings', 18, 13, 37),
      CuratedTopicRef('2 Kings', 19),
    ],
  ),
  CuratedTopic(
    name: "HEZEKIAH'S ILLNESS AND SIGN",
    category: 'story',
    description:
        'Hezekiah weeps and prays when told he will die; God adds '
        'fifteen years to his life and confirms it by turning back a '
        'sundial\'s shadow.',
    refs: [CuratedTopicRef('2 Kings', 20, 1, 11)],
  ),
  CuratedTopic(
    name: 'JOSIAH FINDS THE BOOK OF THE LAW',
    category: 'story',
    description:
        'A forgotten Book of the Law turns up during temple '
        'repairs; hearing it read, young King Josiah tears his clothes '
        'and leads Judah in sweeping religious reform.',
    refs: [
      CuratedTopicRef('2 Kings', 22, 1, 20),
      CuratedTopicRef('2 Kings', 23, 1, 3),
    ],
  ),
  CuratedTopic(
    name: 'HULDAH THE PROPHETESS',
    category: 'story',
    description:
        "King Josiah sends his officials to the prophetess "
        'Huldah to inquire about the newly found Book of the Law; she '
        'confirms coming judgment but promises Josiah he will be spared '
        'in his lifetime.',
    refs: [CuratedTopicRef('2 Kings', 22, 14, 20)],
  ),
  CuratedTopic(
    name: 'THE FALL OF JERUSALEM',
    category: 'story',
    description:
        "Nebuchadnezzar's army breaches Jerusalem, burns the "
        'temple, and carries Judah into exile in Babylon.',
    refs: [CuratedTopicRef('2 Kings', 25, 1, 21)],
  ),

  // --- 1–2 Chronicles ---
  CuratedTopic(
    name: 'DAVID PREPARES FOR THE TEMPLE',
    category: 'story',
    description:
        'Barred from building the temple himself, David gathers '
        'materials and charges Solomon and the people to build "a house '
        'not for man but for the LORD God."',
    refs: [
      CuratedTopicRef('1 Chronicles', 28),
      CuratedTopicRef('1 Chronicles', 29, 1, 20),
    ],
  ),
  CuratedTopic(
    name: "JEHOSHAPHAT'S SINGERS WIN THE BATTLE",
    category: 'story',
    description:
        "Facing a vast invading army, Jehoshaphat sends singers "
        "ahead of the troops praising God, and the enemy coalition turns "
        'on itself before Judah ever fights.',
    refs: [CuratedTopicRef('2 Chronicles', 20)],
  ),
  CuratedTopic(
    name: "MANASSEH'S REPENTANCE",
    category: 'story',
    description:
        'The wicked king Manasseh is dragged to Babylon in '
        'chains, humbles himself before God, and is restored to his '
        'throne in Jerusalem.',
    refs: [CuratedTopicRef('2 Chronicles', 33, 1, 13)],
  ),

  // --- Ezra – Nehemiah ---
  CuratedTopic(
    name: 'THE TEMPLE REBUILT UNDER ZERUBBABEL',
    category: 'story',
    description:
        'Returning exiles lay the foundation of a new temple amid '
        'mixed shouts of joy and weeping, and finish it years later '
        'despite fierce local opposition.',
    refs: [CuratedTopicRef('Ezra', 3), CuratedTopicRef('Ezra', 6, 13, 22)],
  ),
  CuratedTopic(
    name: 'NEHEMIAH REBUILDS THE WALL',
    category: 'story',
    description:
        "Nehemiah leads Jerusalem's exiles in rebuilding its "
        'broken walls in fifty-two days, working with a sword in one hand '
        'despite constant threats and mockery.',
    refs: [
      CuratedTopicRef('Nehemiah', 2, 11, 20),
      CuratedTopicRef('Nehemiah', 4),
      CuratedTopicRef('Nehemiah', 6),
    ],
  ),
  CuratedTopic(
    name: 'EZRA READS THE LAW TO THE PEOPLE',
    category: 'story',
    description:
        'Ezra reads the Law aloud to the assembled people from '
        'daybreak till noon; they weep at hearing it, then celebrate with '
        'a feast at Nehemiah\'s urging.',
    refs: [CuratedTopicRef('Nehemiah', 8)],
  ),

  // --- Esther – Daniel ---
  CuratedTopic(
    name: 'VASHTI REFUSES THE KING',
    category: 'story',
    description:
        "Queen Vashti refuses King Ahasuerus's summons to "
        "display her beauty before his drunken guests, and is deposed — "
        'opening the way for Esther to become queen.',
    refs: [CuratedTopicRef('Esther', 1)],
  ),
  CuratedTopic(
    name: 'ESTHER BECOMES QUEEN',
    category: 'story',
    description:
        'The Jewish orphan Esther is chosen queen of Persia, '
        'setting the stage for her to later intercede for her people.',
    refs: [CuratedTopicRef('Esther', 2, 1, 18)],
  ),
  CuratedTopic(
    name: "ESTHER SAVES HER PEOPLE",
    category: 'story',
    description:
        'Esther risks her life to approach the king unbidden and '
        'exposes Haman\'s plot to destroy the Jews, who are saved instead.',
    refs: [CuratedTopicRef('Esther', 4, 12, 16), CuratedTopicRef('Esther', 7)],
  ),
  CuratedTopic(
    name: "JOB'S TRIALS",
    category: 'story',
    description:
        'Job loses his children, wealth, and health in rapid '
        'succession, yet refuses to curse God despite his wife\'s and '
        'friends\' urging.',
    refs: [CuratedTopicRef('Job', 1), CuratedTopicRef('Job', 2, 1, 10)],
  ),
  CuratedTopic(
    name: "JOB'S THREE FRIENDS COME TO COMFORT HIM",
    category: 'story',
    description:
        "Job's three friends — Eliphaz, Bildad, and Zophar — "
        'hear of his suffering and come to comfort him, then sit with '
        'him on the ground in silence for seven days and nights, seeing '
        'that his grief was very great.',
    refs: [CuratedTopicRef('Job', 2, 11, 13)],
  ),
  CuratedTopic(
    name: 'JOB CURSES THE DAY OF HIS BIRTH',
    category: 'story',
    description:
        'Breaking his silence, Job curses the day he was born '
        'and longs for death, wondering "why is light given to him who '
        'is in misery."',
    refs: [CuratedTopicRef('Job', 3)],
  ),
  CuratedTopic(
    name: '"I KNOW THAT MY REDEEMER LIVES"',
    category: 'story',
    description:
        'In the depths of his suffering, Job declares his '
        'confidence that his Redeemer lives and that he will see God '
        'with his own eyes, even after his body has decayed.',
    refs: [CuratedTopicRef('Job', 19, 23, 27)],
  ),
  CuratedTopic(
    name: "JOB'S FINAL DEFENSE OF HIS INTEGRITY",
    category: 'story',
    description:
        'Job swears a detailed oath of innocence, calling down '
        'curses on himself for every sin he has not committed, and '
        'rests his case, having said all he has to say.',
    refs: [CuratedTopicRef('Job', 31)],
  ),
  CuratedTopic(
    name: "ELIHU'S SPEECHES",
    category: 'story',
    description:
        'Young Elihu, angry that Job justified himself and the '
        "friends found no answer, speaks at length in God's defense, "
        'insisting that God speaks to people through suffering and that '
        'his power and justice are beyond question.',
    refs: [
      CuratedTopicRef('Job', 32),
      CuratedTopicRef('Job', 33),
      CuratedTopicRef('Job', 34),
      CuratedTopicRef('Job', 35),
      CuratedTopicRef('Job', 36),
      CuratedTopicRef('Job', 37),
    ],
  ),
  CuratedTopic(
    name: 'THE LORD ANSWERS JOB OUT OF THE WHIRLWIND',
    category: 'story',
    description:
        'After Job demands an answer for his suffering, the LORD '
        'speaks from a whirlwind, questioning Job with the wonders of '
        'creation until Job repents "in dust and ashes."',
    refs: [CuratedTopicRef('Job', 38, 1, 11), CuratedTopicRef('Job', 42, 1, 6)],
  ),
  CuratedTopic(
    name: "GOD'S SECOND SPEECH: BEHEMOTH AND LEVIATHAN",
    category: 'story',
    description:
        'The LORD speaks a second time, pointing Job to two '
        'untamable creatures, Behemoth and Leviathan, as proof of a '
        'wisdom and power far beyond human reach or control.',
    refs: [CuratedTopicRef('Job', 40), CuratedTopicRef('Job', 41)],
  ),
  CuratedTopic(
    name: "JOB'S RESTORATION",
    category: 'story',
    description:
        "The LORD rebukes Job's three friends and restores Job's "
        'fortunes twofold after he prays for them, giving him a new '
        'family and twice what he had before, and Job lives another '
        'hundred and forty years.',
    refs: [CuratedTopicRef('Job', 42, 7, 17)],
  ),
  CuratedTopic(
    name: "ISAIAH'S CALL AND VISION",
    category: 'story',
    description:
        'Isaiah sees the LORD high and lifted up in the temple '
        'and, cleansed by a burning coal, answers, "Here am I; send me."',
    refs: [CuratedTopicRef('Isaiah', 6, 1, 8)],
  ),
  CuratedTopic(
    name: 'THE SIGN OF IMMANUEL',
    category: 'story',
    description:
        'When King Ahaz refuses to ask for a sign, Isaiah '
        'declares that the LORD himself will give one: "Behold, the '
        'virgin shall conceive and bear a son, and shall call his name '
        'Immanuel."',
    refs: [CuratedTopicRef('Isaiah', 7, 1, 17)],
  ),
  CuratedTopic(
    name: "JEREMIAH'S CALL",
    category: 'story',
    description:
        'God tells the young Jeremiah, "Before I formed you in '
        'the womb I knew you," and appoints him a prophet to the nations '
        'despite his protest that he is only a child.',
    refs: [CuratedTopicRef('Jeremiah', 1, 4, 19)],
  ),
  CuratedTopic(
    name: "JEREMIAH AT THE POTTER'S HOUSE",
    category: 'story',
    description:
        "Watching a potter rework a spoiled clay vessel, Jeremiah "
        "hears the LORD compare Israel to clay in the potter's hand, free "
        'to reshape or destroy as he wills.',
    refs: [CuratedTopicRef('Jeremiah', 18, 1, 11)],
  ),
  CuratedTopic(
    name: "JEREMIAH'S TEMPLE SERMON AND TRIAL",
    category: 'story',
    description:
        'Jeremiah warns that the temple will become like Shiloh '
        'unless the people repent; the priests and prophets seize him and '
        'demand his death, but the officials and elders spare his life.',
    refs: [CuratedTopicRef('Jeremiah', 26)],
  ),
  CuratedTopic(
    name: "JEREMIAH'S LETTER TO THE EXILES",
    category: 'story',
    description:
        'Jeremiah writes to the exiles in Babylon urging them to '
        'build houses and seek the welfare of the city, promising that '
        'God knows "the plans I have for you... plans for welfare and '
        'not for evil."',
    refs: [CuratedTopicRef('Jeremiah', 29, 1, 14)],
  ),
  CuratedTopic(
    name: 'JEREMIAH BUYS A FIELD AT ANATHOTH',
    category: 'story',
    description:
        "With Jerusalem under siege and the Babylonians at the "
        "gates, Jeremiah buys his cousin's field at Anathoth as a sign "
        'that houses and fields will again be bought in the land.',
    refs: [CuratedTopicRef('Jeremiah', 32, 6, 15)],
  ),
  CuratedTopic(
    name: "THE RECHABITES' FAITHFULNESS",
    category: 'story',
    description:
        "The Rechabites refuse the wine Jeremiah offers, obeying "
        "their ancestor's centuries-old command, and God holds up their "
        "obedience to shame Judah's unfaithfulness.",
    refs: [CuratedTopicRef('Jeremiah', 35)],
  ),
  CuratedTopic(
    name: 'JEREMIAH THROWN INTO THE CISTERN',
    category: 'story',
    description:
        'Jeremiah is lowered into a muddy cistern to die for his '
        'unwelcome prophecies, then rescued by the Cushite official '
        'Ebed-melech.',
    refs: [CuratedTopicRef('Jeremiah', 38, 1, 13)],
  ),
  CuratedTopic(
    name: 'KING JEHOIAKIM BURNS THE SCROLL',
    category: 'story',
    description:
        "As Jeremiah's scroll of prophecies is read to him, King "
        "Jehoiakim slices off each column with a knife and burns it in a "
        'firepot, then has the scroll rewritten with even more added.',
    refs: [CuratedTopicRef('Jeremiah', 36)],
  ),
  CuratedTopic(
    name: 'THE ASSASSINATION OF GEDALIAH AND THE FLIGHT TO EGYPT',
    category: 'story',
    description:
        "After Jerusalem's fall, Ishmael assassinates Gedaliah, "
        'the governor appointed over the remnant left in the land; the '
        'fearful survivors then force Jeremiah to go with them into '
        'Egypt.',
    refs: [
      CuratedTopicRef('Jeremiah', 41, 1, 3),
      CuratedTopicRef('Jeremiah', 43, 1, 7),
    ],
  ),
  CuratedTopic(
    name: "EZEKIEL'S VISION OF THE LIVING CREATURES",
    category: 'story',
    description:
        "By the Kebar River, the exiled priest Ezekiel sees a "
        "storm-driven vision of four living creatures and wheels within "
        'wheels, and is commissioned as a prophet to the exiles.',
    refs: [CuratedTopicRef('Ezekiel', 1), CuratedTopicRef('Ezekiel', 2, 1, 10)],
  ),
  CuratedTopic(
    name: 'EZEKIEL ACTS OUT THE SIEGE OF JERUSALEM',
    category: 'story',
    description:
        'Ezekiel enacts a living prophecy for the exiles, drawing '
        'Jerusalem on a brick and laying siege to it, then lying bound on '
        "his side for over a year to bear the nation's punishment.",
    refs: [CuratedTopicRef('Ezekiel', 4)],
  ),
  CuratedTopic(
    name: 'THE GLORY OF THE LORD DEPARTS THE TEMPLE',
    category: 'story',
    description:
        "In a vision, Ezekiel watches the glory of the LORD rise "
        "from the temple's threshold and depart the city, abandoning it "
        'to judgment.',
    refs: [
      CuratedTopicRef('Ezekiel', 10),
      CuratedTopicRef('Ezekiel', 11, 22, 23),
    ],
  ),
  CuratedTopic(
    name: "EZEKIEL'S WIFE DIES AS A SIGN",
    category: 'story',
    description:
        "God tells Ezekiel his wife will die suddenly and forbids "
        'him to mourn openly — a sign to the exiles that they will grieve '
        'too deeply for tears when Jerusalem falls.',
    refs: [CuratedTopicRef('Ezekiel', 24, 15, 27)],
  ),
  CuratedTopic(
    name: "EZEKIEL'S VALLEY OF DRY BONES",
    category: 'story',
    description:
        "Ezekiel prophesies to a valley of dry bones, and God's "
        'breath raises them into a vast living army — a vision of Israel\'s '
        'restoration.',
    refs: [CuratedTopicRef('Ezekiel', 37, 1, 14)],
  ),
  CuratedTopic(
    name: 'THE RIVER FROM THE TEMPLE',
    category: 'story',
    description:
        'Ezekiel sees a river flowing from beneath the temple '
        'threshold, deepening as it goes and bringing life wherever it '
        'flows, with trees on its banks whose fruit is for food and '
        'leaves for healing.',
    refs: [CuratedTopicRef('Ezekiel', 47, 1, 12)],
  ),
  CuratedTopic(
    name: 'DANIEL AND HIS FRIENDS REFUSE THE ROYAL FOOD',
    category: 'story',
    description:
        'Daniel and his three friends resolve not to defile '
        'themselves with the king\'s food, and are found healthier than '
        'the rest on a diet of vegetables.',
    refs: [CuratedTopicRef('Daniel', 1, 8, 21)],
  ),
  CuratedTopic(
    name: "DANIEL INTERPRETS NEBUCHADNEZZAR'S DREAM",
    category: 'story',
    description:
        'Daniel reveals and interprets Nebuchadnezzar\'s forgotten '
        'dream of a great statue, when none of the king\'s wise men could.',
    refs: [CuratedTopicRef('Daniel', 2)],
  ),
  CuratedTopic(
    name: 'SHADRACH, MESHACH, AND ABEDNEGO IN THE FIERY FURNACE',
    category: 'story',
    description:
        'Three young Hebrews refuse to bow to Nebuchadnezzar\'s '
        'golden image and walk unharmed out of a blazing furnace.',
    refs: [CuratedTopicRef('Daniel', 3)],
  ),
  CuratedTopic(
    name: "NEBUCHADNEZZAR'S MADNESS",
    category: 'story',
    description:
        'Boasting over his own greatness, Nebuchadnezzar is '
        'struck with madness and lives like a beast for seven years, '
        "until he acknowledges that \"the Most High rules the kingdom of "
        'men."',
    refs: [CuratedTopicRef('Daniel', 4)],
  ),
  CuratedTopic(
    name: "BELSHAZZAR'S FEAST",
    category: 'story',
    description:
        'A disembodied hand writes Belshazzar\'s doom on the wall '
        'during a drunken feast, and Daniel interprets it that same night.',
    refs: [CuratedTopicRef('Daniel', 5)],
  ),
  CuratedTopic(
    name: "DANIEL'S VISION OF THE FOUR BEASTS",
    category: 'story',
    description:
        'Daniel sees four great beasts rise from the sea, then '
        'the Ancient of Days take his throne and give everlasting '
        'dominion to "one like a son of man."',
    refs: [CuratedTopicRef('Daniel', 7)],
  ),
  CuratedTopic(
    name: "DANIEL'S VISION BY THE TIGRIS",
    category: 'story',
    description:
        'After three weeks of mourning and fasting, Daniel sees a '
        'radiant heavenly being who tells him his words were heard from '
        'the first day, but the "prince of the kingdom of Persia" '
        'withstood him twenty-one days.',
    refs: [CuratedTopicRef('Daniel', 10)],
  ),

  // --- Minor Prophets ---
  CuratedTopic(
    name: 'HOSEA MARRIES GOMER',
    category: 'story',
    description:
        'God commands Hosea to marry the unfaithful Gomer as a '
        "living parable of the LORD's persistent love for wayward Israel.",
    refs: [CuratedTopicRef('Hosea', 1), CuratedTopicRef('Hosea', 3)],
  ),
  CuratedTopic(
    name: 'AMOS CONFRONTS AMAZIAH AT BETHEL',
    category: 'story',
    description:
        'When Amos prophesies judgment at Bethel, the priest '
        'Amaziah orders him to flee back to Judah; Amos answers that he '
        'was no professional prophet but a shepherd whom the LORD took '
        'and sent.',
    refs: [CuratedTopicRef('Amos', 7, 10, 17)],
  ),
  CuratedTopic(
    name: 'JONAH AND THE GREAT FISH',
    category: 'story',
    description:
        'Fleeing God\'s call to preach to Nineveh, Jonah is '
        'thrown overboard in a storm and swallowed by a great fish, '
        'praying from its belly for three days and nights.',
    refs: [CuratedTopicRef('Jonah', 1), CuratedTopicRef('Jonah', 2)],
  ),
  CuratedTopic(
    name: "NINEVEH REPENTS AND JONAH'S ANGER",
    category: 'story',
    description:
        'Nineveh repents at Jonah\'s preaching and God relents of '
        'judgment, but Jonah sulks over God\'s mercy until a withered '
        'plant teaches him a lesson in compassion.',
    refs: [CuratedTopicRef('Jonah', 3), CuratedTopicRef('Jonah', 4)],
  ),
  CuratedTopic(
    name: 'MICAH\'S COURTROOM: "WHAT DOES THE LORD REQUIRE?"',
    category: 'story',
    description:
        'The LORD brings a covenant lawsuit against Israel, '
        'recounting his saving acts, until Micah answers what is '
        'required: "to do justice, and to love kindness, and to walk '
        'humbly with your God."',
    refs: [CuratedTopicRef('Micah', 6, 1, 8)],
  ),
  CuratedTopic(
    name: "HABAKKUK'S COMPLAINT AND THE LORD'S ANSWER",
    category: 'story',
    description:
        'Habakkuk complains to God about violence and injustice '
        'going unanswered; God replies that the Babylonians are coming '
        'as judgment, and tells the prophet to wait at his watchpost, '
        'for "the righteous shall live by his faith."',
    refs: [
      CuratedTopicRef('Habakkuk', 1),
      CuratedTopicRef('Habakkuk', 2, 1, 4),
    ],
  ),
  CuratedTopic(
    name: 'HAGGAI STIRS THE PEOPLE TO REBUILD THE TEMPLE',
    category: 'story',
    description:
        "While the people excuse their neglect of God's house by "
        "building their own paneled houses, Haggai's rebuke stirs "
        'Zerubbabel, Joshua, and the remnant to resume work on the '
        'temple.',
    refs: [CuratedTopicRef('Haggai', 1)],
  ),
  CuratedTopic(
    name: 'THE CLEANSING OF JOSHUA THE HIGH PRIEST',
    category: 'story',
    description:
        'In a vision, Zechariah sees Satan accusing the high '
        'priest Joshua as he stands in filthy garments; the LORD rebukes '
        'Satan and has Joshua reclothed in clean garments as a sign of '
        'forgiveness.',
    refs: [CuratedTopicRef('Zechariah', 3)],
  ),
  CuratedTopic(
    name: "ZECHARIAH'S VISION OF THE LAMPSTAND",
    category: 'story',
    description:
        'Zechariah sees a golden lampstand fed by two olive '
        'trees, and is told Zerubbabel will finish the temple "not by '
        'might, nor by power, but by my Spirit."',
    refs: [CuratedTopicRef('Zechariah', 4)],
  ),

  // --- Gospels ---
  CuratedTopic(
    name: 'ANDREW BRINGS PETER TO JESUS',
    category: 'story',
    description:
        'Andrew, a disciple of John the Baptist, follows Jesus '
        'after hearing him called "the Lamb of God," then finds his '
        'brother Simon and brings him to Jesus, who renames him Peter.',
    refs: [CuratedTopicRef('John', 1, 35, 42)],
  ),
  CuratedTopic(
    name: 'THE CALLING OF PHILIP AND NATHANAEL',
    category: 'story',
    description:
        "Jesus calls Philip, who finds Nathanael and tells him "
        "they've found the Messiah; Nathanael doubts anything good can "
        'come from Nazareth until Jesus reveals he saw him under the fig '
        'tree.',
    refs: [CuratedTopicRef('John', 1, 43, 51)],
  ),
  CuratedTopic(
    name: 'THE CALLING OF THE FIRST DISCIPLES',
    category: 'story',
    description:
        'Jesus calls Peter, Andrew, James, and John from their '
        'fishing nets to follow him and become "fishers of men."',
    refs: [CuratedTopicRef('Matthew', 4, 18, 22)],
  ),
  CuratedTopic(
    name: 'THE MIRACULOUS CATCH OF FISH',
    category: 'story',
    description:
        'After a fruitless night, Peter lets down his nets at '
        "Jesus' word and hauls in so many fish the boats begin to sink — "
        'and falls at Jesus\' knees saying, "Depart from me, for I am a '
        'sinful man."',
    refs: [CuratedTopicRef('Luke', 5, 1, 11)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A MAN WITH AN UNCLEAN SPIRIT',
    category: 'story',
    description:
        'In the Capernaum synagogue, Jesus rebukes an unclean '
        'spirit with a word of authority, and the crowd marvels that even '
        'the demons obey him.',
    refs: [CuratedTopicRef('Mark', 1, 21, 28)],
  ),
  CuratedTopic(
    name: "JESUS HEALS PETER'S MOTHER-IN-LAW",
    category: 'story',
    description:
        "Jesus heals Simon Peter's mother-in-law of a fever with "
        'a touch, and she immediately gets up and begins serving them.',
    refs: [CuratedTopicRef('Mark', 1, 29, 31)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A LEPER',
    category: 'story',
    description:
        'Moved with compassion, Jesus touches a man covered in '
        'leprosy — "I am willing; be cleansed" — and he is healed '
        'instantly.',
    refs: [CuratedTopicRef('Mark', 1, 40, 45)],
  ),
  CuratedTopic(
    name: 'THE PARALYTIC LOWERED THROUGH THE ROOF',
    category: 'story',
    description:
        "Four friends dig through a roof to lower a paralyzed man "
        "in front of Jesus, who forgives his sins and heals him, to the "
        'crowd\'s astonishment.',
    refs: [CuratedTopicRef('Mark', 2, 1, 12)],
  ),
  CuratedTopic(
    name: 'THE CALLING OF MATTHEW THE TAX COLLECTOR',
    category: 'story',
    description:
        'Jesus calls the despised tax collector Matthew away '
        'from his booth with two words — "Follow me" — then dines with '
        'sinners, telling critics, "I desire mercy, not sacrifice."',
    refs: [CuratedTopicRef('Matthew', 9, 9, 13)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A MAN WITH A WITHERED HAND',
    category: 'story',
    description:
        'Watched by hostile Pharisees looking for a reason to '
        'accuse him, Jesus heals a man\'s withered hand on the Sabbath, '
        'asking, "Is it lawful to do good on the Sabbath?"',
    refs: [CuratedTopicRef('Mark', 3, 1, 6)],
  ),
  CuratedTopic(
    name: 'JESUS CHOOSES THE TWELVE APOSTLES',
    category: 'story',
    description:
        'After a night spent praying on the mountain, Jesus '
        'chooses twelve of his disciples and names them apostles — '
        'including Simon Peter, Andrew, James, John, Philip, Bartholomew, '
        'Thomas, Matthew, James son of Alphaeus, Simon the Zealot, Judas '
        'son of James, and Judas Iscariot.',
    refs: [CuratedTopicRef('Luke', 6, 12, 16)],
  ),
  CuratedTopic(
    name: 'THE SERMON ON THE PLAIN',
    category: 'story',
    description:
        'After choosing his twelve apostles, Jesus teaches a '
        'crowd on a level place — blessings and woes, love for enemies, '
        'and not judging others — in Luke\'s counterpart to the Sermon on '
        'the Mount.',
    refs: [CuratedTopicRef('Luke', 6, 17, 49)],
  ),
  CuratedTopic(
    name: 'THE WEDDING AT CANA',
    category: 'story',
    description:
        "Jesus turns water into wine at a wedding in Cana, his "
        'first public sign.',
    refs: [CuratedTopicRef('John', 2, 1, 11)],
  ),
  CuratedTopic(
    name: 'NICODEMUS VISITS JESUS',
    category: 'story',
    description:
        'A Pharisee named Nicodemus comes to Jesus by night and '
        'is told he must be "born again" to see the kingdom of God.',
    refs: [CuratedTopicRef('John', 3)],
  ),
  CuratedTopic(
    name: 'THE WOMAN AT THE WELL',
    category: 'story',
    description:
        'Jesus offers "living water" to a Samaritan woman at '
        "Jacob's well, who becomes one of the first to spread word of him.",
    refs: [CuratedTopicRef('John', 4)],
  ),
  CuratedTopic(
    name: 'THE HEALING AT THE POOL OF BETHESDA',
    category: 'story',
    description:
        'Jesus heals a man who had been an invalid for '
        'thirty-eight years, waiting by the pool for someone to help him '
        'in — "Sir, I have no one to put me into the pool."',
    refs: [CuratedTopicRef('John', 5, 1, 9)],
  ),
  CuratedTopic(
    name: "JESUS HEALS THE CENTURION'S SERVANT",
    category: 'story',
    description:
        'A Roman centurion asks Jesus only to "say the word" to '
        'heal his servant, and Jesus marvels at his faith.',
    refs: [CuratedTopicRef('Matthew', 8, 5, 13)],
  ),
  CuratedTopic(
    name: "THE WIDOW OF NAIN'S SON",
    category: 'story',
    description:
        'Moved with compassion at a funeral procession, Jesus '
        'touches the coffin of a widow\'s only son and raises him back to '
        'life.',
    refs: [CuratedTopicRef('Luke', 7, 11, 17)],
  ),
  CuratedTopic(
    name: "THE SINFUL WOMAN ANOINTS JESUS' FEET",
    category: 'story',
    description:
        'A sinful woman washes Jesus\' feet with her tears at a '
        'Pharisee\'s house; Jesus tells of two debtors to show that "he '
        'who is forgiven little, loves little."',
    refs: [CuratedTopicRef('Luke', 7, 36, 50)],
  ),
  CuratedTopic(
    name: 'JESUS CALMS THE STORM',
    category: 'story',
    description:
        'Jesus rebukes a violent storm on the Sea of Galilee — '
        '"Peace! Be still!" — and the wind and waves obey him.',
    refs: [CuratedTopicRef('Mark', 4, 35, 41)],
  ),
  CuratedTopic(
    name: 'THE GERASENE DEMONIAC',
    category: 'story',
    description:
        'Jesus casts a legion of demons out of a tormented man '
        'into a herd of pigs, which rush into the sea.',
    refs: [CuratedTopicRef('Mark', 5, 1, 20)],
  ),
  CuratedTopic(
    name: 'THE DEATH OF JOHN THE BAPTIST',
    category: 'story',
    description:
        'Herod beheads John the Baptist at a birthday banquet '
        "after his stepdaughter's dance earns her a rash promise, at her "
        "mother Herodias's urging.",
    refs: [CuratedTopicRef('Mark', 6, 14, 29)],
  ),
  CuratedTopic(
    name: 'JESUS WALKS ON WATER',
    category: 'story',
    description:
        'Jesus comes to his disciples walking on the sea in the '
        'fourth watch of the night, and Peter briefly walks toward him '
        'before losing faith and sinking.',
    refs: [
      CuratedTopicRef('Mark', 6, 45, 52),
      CuratedTopicRef('John', 6, 16, 21),
    ],
  ),
  CuratedTopic(
    name: 'THE BREAD OF LIFE DISCOURSE',
    category: 'story',
    description:
        'The day after feeding the five thousand, Jesus declares '
        'in the Capernaum synagogue, "I am the bread of life," and many '
        'disciples turn back, unable to accept the hard teaching.',
    refs: [CuratedTopicRef('John', 6, 22, 59)],
  ),
  CuratedTopic(
    name: "THE SYROPHOENICIAN WOMAN'S FAITH",
    category: 'story',
    description:
        'A Gentile woman begs Jesus to free her daughter from a '
        'demon, and her persistent faith — "even the dogs eat the '
        'crumbs" — earns her daughter\'s healing.',
    refs: [CuratedTopicRef('Mark', 7, 24, 30)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A DEAF MAN',
    category: 'story',
    description:
        'Jesus puts his fingers in a deaf man\'s ears and says '
        '"Ephphatha" — "Be opened" — and the man\'s ears are opened and '
        'his tongue loosed.',
    refs: [CuratedTopicRef('Mark', 7, 31, 37)],
  ),
  CuratedTopic(
    name: 'THE FEEDING OF THE FOUR THOUSAND',
    category: 'story',
    description:
        'Jesus multiplies seven loaves and a few small fish to '
        'feed a crowd of four thousand in the Gentile region of the '
        'Decapolis, with seven baskets left over.',
    refs: [CuratedTopicRef('Mark', 8, 1, 9)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A BLIND MAN AT BETHSAIDA',
    category: 'story',
    description:
        'Jesus heals a blind man in two stages, spitting on his '
        'eyes and laying on hands twice, until the man sees everything '
        'clearly.',
    refs: [CuratedTopicRef('Mark', 8, 22, 26)],
  ),
  CuratedTopic(
    name: "PETER'S CONFESSION AT CAESAREA PHILIPPI",
    category: 'story',
    description:
        'Asked who people say he is, Peter declares, "You are the '
        'Christ, the Son of the living God," and Jesus begins to foretell '
        'his coming death and resurrection.',
    refs: [CuratedTopicRef('Matthew', 16, 13, 20)],
  ),
  CuratedTopic(
    name: 'JESUS REBUKES PETER',
    category: 'story',
    description:
        'When Peter rebukes Jesus for predicting his death, Jesus '
        'turns and rebukes him in turn: "Get behind me, Satan! You are a '
        'hindrance to me."',
    refs: [CuratedTopicRef('Matthew', 16, 21, 23)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A BOY WITH A DEMON',
    category: 'story',
    description:
        'After his disciples fail to cast out a demon tormenting '
        'a boy with seizures, Jesus heals him and explains that "this kind '
        'never comes out except by prayer."',
    refs: [CuratedTopicRef('Matthew', 17, 14, 21)],
  ),
  CuratedTopic(
    name: "THE COIN IN THE FISH'S MOUTH",
    category: 'story',
    description:
        'To pay the temple tax without giving offense, Jesus '
        'sends Peter to catch a fish, telling him he will find a coin in '
        "its mouth enough for them both.",
    refs: [CuratedTopicRef('Matthew', 17, 24, 27)],
  ),
  CuratedTopic(
    name: "JAIRUS'S DAUGHTER AND THE WOMAN WITH THE ISSUE OF BLOOD",
    category: 'story',
    description:
        'On the way to raise a synagogue leader\'s dying daughter, '
        'Jesus is touched by and heals a woman who had bled for twelve '
        'years.',
    refs: [CuratedTopicRef('Mark', 5, 21, 43)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS TWO BLIND MEN',
    category: 'story',
    description:
        'Two blind men follow Jesus into a house begging for '
        'mercy, and he heals them, saying, "According to your faith be it '
        'done to you."',
    refs: [CuratedTopicRef('Matthew', 9, 27, 31)],
  ),
  CuratedTopic(
    name: 'THE COMMISSIONING OF THE TWELVE',
    category: 'story',
    description:
        'Seeing the crowds like sheep without a shepherd, Jesus '
        'sends out his twelve disciples with authority to heal and cast '
        'out demons, warning them they go out "as sheep in the midst of '
        'wolves."',
    refs: [CuratedTopicRef('Matthew', 10)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A BLIND AND MUTE DEMONIAC',
    category: 'story',
    description:
        'Jesus heals a man who was blind and mute because of a '
        'demon; when the crowds wonder if he is the Son of David, the '
        'Pharisees accuse him of casting out demons by Beelzebul.',
    refs: [CuratedTopicRef('Matthew', 12, 22, 28)],
  ),
  CuratedTopic(
    name: "THE WOMEN WHO SUPPORTED JESUS' MINISTRY",
    category: 'story',
    description:
        'Mary Magdalene, healed of seven demons, along with '
        'Joanna, Susanna, and many other women, travel with Jesus and '
        'the Twelve and provide for them out of their own means.',
    refs: [CuratedTopicRef('Luke', 8, 1, 3)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE SOWER',
    category: 'story',
    description:
        'Jesus teaches how a sower\'s seed meets four kinds of '
        'soil, then explains it as the ways people receive God\'s word.',
    refs: [CuratedTopicRef('Matthew', 13, 1, 23)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE WHEAT AND THE WEEDS',
    category: 'story',
    description:
        "A farmer's enemy sows weeds among his wheat; both grow "
        'together until harvest, when the weeds are burned and the wheat '
        'gathered into the barn — a picture of the final judgment.',
    refs: [
      CuratedTopicRef('Matthew', 13, 24, 30),
      CuratedTopicRef('Matthew', 13, 36, 43),
    ],
  ),
  CuratedTopic(
    name: 'THE GROWING SEED',
    category: 'story',
    description:
        'A man scatters seed that sprouts and grows he knows not '
        'how, all by itself, until the harvest comes — a picture of the '
        'quietly growing kingdom of God.',
    refs: [CuratedTopicRef('Mark', 4, 26, 29)],
  ),
  CuratedTopic(
    name: 'THE MUSTARD SEED AND THE LEAVEN',
    category: 'story',
    description:
        'Jesus compares the kingdom of heaven to a mustard seed '
        'that grows into a tree from the smallest of seeds, and to leaven '
        'a woman works through a whole batch of dough.',
    refs: [CuratedTopicRef('Matthew', 13, 31, 33)],
  ),
  CuratedTopic(
    name: 'THE HIDDEN TREASURE AND THE PEARL OF GREAT PRICE',
    category: 'story',
    description:
        'Jesus compares the kingdom of heaven to treasure hidden '
        'in a field and to a pearl of great price — each worth selling '
        'everything else to obtain.',
    refs: [CuratedTopicRef('Matthew', 13, 44, 46)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE NET',
    category: 'story',
    description:
        'Jesus compares the kingdom of heaven to a net cast into '
        'the sea that gathers fish of every kind, sorted only at the end '
        'of the age.',
    refs: [CuratedTopicRef('Matthew', 13, 47, 50)],
  ),
  CuratedTopic(
    name: 'JAMES AND JOHN CALL FOR FIRE FROM A SAMARITAN VILLAGE',
    category: 'story',
    description:
        'When a Samaritan village refuses to welcome Jesus, James '
        'and John ask if he wants them to call down fire from heaven to '
        'consume it; Jesus rebukes them instead.',
    refs: [CuratedTopicRef('Luke', 9, 51, 56)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE GOOD SAMARITAN',
    category: 'story',
    description:
        'A despised Samaritan, not a priest or Levite, proves to '
        'be the true "neighbor" who stops to help a beaten traveler.',
    refs: [CuratedTopicRef('Luke', 10, 25, 37)],
  ),
  CuratedTopic(
    name: 'MARY AND MARTHA',
    category: 'story',
    description:
        'Martha busies herself serving while her sister Mary sits '
        'at Jesus\' feet, and Jesus commends Mary\'s choice.',
    refs: [CuratedTopicRef('Luke', 10, 38, 42)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE FRIEND AT MIDNIGHT',
    category: 'story',
    description:
        'Jesus tells of a man who pesters his neighbor for bread '
        'at midnight until he gets up and gives it, urging his hearers to '
        'ask, seek, and knock in prayer.',
    refs: [CuratedTopicRef('Luke', 11, 5, 8)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE RICH FOOL',
    category: 'story',
    description:
        'A rich man plans bigger barns for his abundant harvest, '
        'only to hear, "Fool! This night your soul is required of you" — '
        'a warning against storing up treasure for oneself.',
    refs: [CuratedTopicRef('Luke', 12, 13, 21)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE BARREN FIG TREE',
    category: 'story',
    description:
        'A gardener persuades the owner of a fruitless fig tree '
        'to spare it one more year, giving it a chance to bear fruit '
        'before it is cut down.',
    refs: [CuratedTopicRef('Luke', 13, 6, 9)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A CRIPPLED WOMAN ON THE SABBATH',
    category: 'story',
    description:
        'Jesus heals a woman bent double for eighteen years, '
        'calling her "a daughter of Abraham" whom Satan had bound, over '
        'a synagogue leader\'s objection that it was the Sabbath.',
    refs: [CuratedTopicRef('Luke', 13, 10, 17)],
  ),
  CuratedTopic(
    name: 'JESUS HEALS A MAN WITH DROPSY',
    category: 'story',
    description:
        'At a Pharisee\'s Sabbath dinner, Jesus heals a man '
        'suffering from dropsy and silences his host\'s legalism with a '
        'question: "Which of you... will not immediately pull him out?"',
    refs: [CuratedTopicRef('Luke', 14, 1, 6)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE GREAT BANQUET',
    category: 'story',
    description:
        'Invited guests all make excuses to skip a great banquet, '
        'so the host sends his servant to bring in the poor, crippled, '
        'blind, and lame from the streets instead.',
    refs: [CuratedTopicRef('Luke', 14, 15, 24)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE LOST SHEEP',
    category: 'story',
    description:
        'A shepherd leaves ninety-nine sheep to search for one '
        'lost sheep, rejoicing over its recovery like heaven over one '
        'repentant sinner.',
    refs: [CuratedTopicRef('Luke', 15, 1, 7)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE LOST COIN',
    category: 'story',
    description:
        'A woman lights a lamp and sweeps her house to find one '
        'lost coin, then calls her friends to celebrate — as heaven '
        'rejoices over one sinner who repents.',
    refs: [CuratedTopicRef('Luke', 15, 8, 10)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE PRODIGAL SON',
    category: 'story',
    description:
        'A wayward son squanders his inheritance and returns home '
        'in shame, only to be welcomed back by his father with open arms.',
    refs: [CuratedTopicRef('Luke', 15, 11, 32)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE DISHONEST MANAGER',
    category: 'story',
    description:
        'A steward about to be fired shrewdly slashes his '
        "master's debtors' bills to win future favor, and is commended for "
        'his shrewdness — a lesson in using worldly wealth wisely.',
    refs: [CuratedTopicRef('Luke', 16, 1, 13)],
  ),
  CuratedTopic(
    name: 'THE RICH MAN AND LAZARUS',
    category: 'story',
    description:
        "A parable of a poor beggar carried to Abraham's side "
        'after death, while the rich man who ignored him suffers in torment.',
    refs: [CuratedTopicRef('Luke', 16, 19, 31)],
  ),
  CuratedTopic(
    name: 'JESUS CLEANSES TEN LEPERS',
    category: 'story',
    description:
        'Jesus heals ten lepers at once, but only one — a '
        'Samaritan — returns to give thanks, prompting Jesus to ask, '
        '"Where are the nine?"',
    refs: [CuratedTopicRef('Luke', 17, 11, 19)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE PERSISTENT WIDOW AND THE UNJUST JUDGE',
    category: 'story',
    description:
        'A widow wears down an uncaring judge with her persistent '
        'pleas for justice, and Jesus urges his hearers to pray always '
        'and not lose heart.',
    refs: [CuratedTopicRef('Luke', 18, 1, 8)],
  ),
  CuratedTopic(
    name: 'THE PHARISEE AND THE TAX COLLECTOR',
    category: 'story',
    description:
        'A boastful Pharisee\'s prayer is contrasted with a tax '
        'collector\'s humble plea, "God, be merciful to me, a sinner!" — '
        'and it is the latter who goes home justified.',
    refs: [CuratedTopicRef('Luke', 18, 9, 14)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE UNFORGIVING SERVANT',
    category: 'story',
    description:
        'A servant forgiven an enormous debt turns and chokes a '
        'fellow servant over a pittance, teaching that God expects those '
        'forgiven much to forgive "seventy times seven" in turn.',
    refs: [CuratedTopicRef('Matthew', 18, 21, 35)],
  ),
  CuratedTopic(
    name: 'JESUS BLESSES THE LITTLE CHILDREN',
    category: 'story',
    description:
        'Jesus rebukes his disciples for turning away children '
        'brought to him, saying, "Let the little children come to me... '
        'for to such belongs the kingdom of heaven."',
    refs: [CuratedTopicRef('Matthew', 19, 13, 15)],
  ),
  CuratedTopic(
    name: 'THE RICH YOUNG RULER',
    category: 'story',
    description:
        'A wealthy young man walks away sorrowful when Jesus '
        'tells him to sell all he has and follow him.',
    refs: [CuratedTopicRef('Matthew', 19, 16, 30)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE WORKERS IN THE VINEYARD',
    category: 'story',
    description:
        'A landowner pays workers hired at the eleventh hour the '
        'same wage as those who worked all day, illustrating that "the '
        'last will be first, and the first last."',
    refs: [CuratedTopicRef('Matthew', 20, 1, 16)],
  ),
  CuratedTopic(
    name: 'THE REQUEST OF JAMES AND JOHN FOR THE HIGHEST PLACE',
    category: 'story',
    description:
        "James and John (through their mother, in Matthew's "
        "account) ask to sit at Jesus' right and left hand in his "
        'kingdom; Jesus tells the indignant Ten that greatness means '
        'becoming a servant of all.',
    refs: [
      CuratedTopicRef('Mark', 10, 35, 45),
      CuratedTopicRef('Matthew', 20, 20, 28),
    ],
  ),
  CuratedTopic(
    name: 'BLIND BARTIMAEUS RECEIVES HIS SIGHT',
    category: 'story',
    description:
        'Blind beggar Bartimaeus cries out to "Jesus, Son of '
        'David" outside Jericho despite the crowd\'s rebukes, and Jesus '
        'restores his sight for his persistent faith.',
    refs: [CuratedTopicRef('Mark', 10, 46, 52)],
  ),
  CuratedTopic(
    name: 'ZACCHAEUS',
    category: 'story',
    description:
        'A short, despised tax collector climbs a tree to see '
        'Jesus, who invites himself to Zacchaeus\'s house and changes his '
        'life.',
    refs: [CuratedTopicRef('Luke', 19, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE MINAS',
    category: 'story',
    description:
        'A nobleman entrusts ten servants with ten minas before '
        'going away, and rewards on his return in proportion to how each '
        'servant put the money to work.',
    refs: [CuratedTopicRef('Luke', 19, 11, 27)],
  ),
  CuratedTopic(
    name: 'JESUS WEEPS OVER JERUSALEM',
    category: 'story',
    description:
        'Approaching Jerusalem before his triumphal entry, Jesus '
        'weeps over the city, lamenting that it did not recognize "the '
        'things that make for peace."',
    refs: [CuratedTopicRef('Luke', 19, 41, 44)],
  ),
  CuratedTopic(
    name: 'THE WOMAN CAUGHT IN ADULTERY',
    category: 'story',
    description:
        '"Let him who is without sin among you be the first to '
        'throw a stone," Jesus tells the woman\'s accusers, and they leave '
        'one by one.',
    refs: [CuratedTopicRef('John', 8, 1, 11)],
  ),
  CuratedTopic(
    name: 'THE MAN BORN BLIND',
    category: 'story',
    description:
        'Jesus heals a man born blind, whose simple testimony — '
        '"I was blind, now I see" — confounds the religious leaders who '
        'question him.',
    refs: [CuratedTopicRef('John', 9)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE GOOD SHEPHERD',
    category: 'story',
    description:
        'Jesus calls himself the good shepherd who knows his '
        'sheep by name and lays down his life for them, unlike a hired '
        'hand who flees when the wolf comes.',
    refs: [CuratedTopicRef('John', 10, 1, 18)],
  ),
  CuratedTopic(
    name: "THOMAS'S WILLINGNESS TO DIE WITH JESUS",
    category: 'story',
    description:
        'When Jesus resolves to return to Judea despite the '
        'danger, Thomas tells the other disciples, "Let us also go, that '
        'we may die with him."',
    refs: [CuratedTopicRef('John', 11, 7, 16)],
  ),
  CuratedTopic(
    name: 'THE RAISING OF LAZARUS',
    category: 'story',
    description:
        'Jesus weeps at the tomb of his friend Lazarus, then '
        'calls him back to life four days after his death.',
    refs: [CuratedTopicRef('John', 11, 1, 44)],
  ),
  CuratedTopic(
    name: 'THE TRIUMPHAL ENTRY',
    category: 'story',
    description:
        'Jesus rides into Jerusalem on a donkey\'s colt as crowds '
        'spread their cloaks and palm branches before him, shouting '
        '"Hosanna to the Son of David!"',
    refs: [CuratedTopicRef('Matthew', 21, 1, 11)],
  ),
  CuratedTopic(
    name: 'JESUS CLEANSES THE TEMPLE',
    category: 'story',
    description:
        'Jesus drives out the money changers and merchants from '
        'the temple courts, declaring, "My house shall be called a house '
        'of prayer, but you have made it a den of robbers."',
    refs: [CuratedTopicRef('Matthew', 21, 12, 17)],
  ),
  CuratedTopic(
    name: 'PHILIP AND ANDREW BRING THE GREEKS TO JESUS',
    category: 'story',
    description:
        'Greeks who came to worship at the feast ask Philip to '
        'see Jesus; Philip tells Andrew, and together they bring the '
        'request to him.',
    refs: [CuratedTopicRef('John', 12, 20, 22)],
  ),
  CuratedTopic(
    name: 'JESUS CURSES THE FIG TREE',
    category: 'story',
    description:
        'Jesus curses a fruitless fig tree, and it withers to '
        'its roots overnight — a sign to his astonished disciples about '
        'faith that does not doubt.',
    refs: [CuratedTopicRef('Matthew', 21, 18, 22)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE TWO SONS',
    category: 'story',
    description:
        'Asked which of two sons truly did his father\'s will — '
        'the one who refused then went, or the one who agreed then '
        'didn\'t — Jesus tells the chief priests that tax collectors and '
        'prostitutes are entering the kingdom ahead of them.',
    refs: [CuratedTopicRef('Matthew', 21, 28, 32)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE WICKED TENANTS',
    category: 'story',
    description:
        'Tenants beat and kill the servants — and finally the '
        'son — sent to collect a vineyard owner\'s share of the harvest, '
        'a parable the chief priests recognize is aimed at them.',
    refs: [CuratedTopicRef('Matthew', 21, 33, 46)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE WEDDING FEAST',
    category: 'story',
    description:
        'Invited guests refuse a king\'s invitation to his son\'s '
        'wedding feast, so he fills the hall with people from the streets '
        '— but casts out one who came without a wedding garment.',
    refs: [CuratedTopicRef('Matthew', 22, 1, 14)],
  ),
  CuratedTopic(
    name: 'RENDER UNTO CAESAR',
    category: 'story',
    description:
        'Trying to trap Jesus over the tax question, the '
        'Pharisees hear him settle it with a coin: "Render to Caesar the '
        'things that are Caesar\'s, and to God the things that are God\'s."',
    refs: [CuratedTopicRef('Matthew', 22, 15, 22)],
  ),
  CuratedTopic(
    name: 'THE GREAT COMMANDMENT',
    category: 'story',
    description:
        'Asked which commandment is greatest, Jesus answers: '
        'love the Lord your God with all your heart, and love your '
        'neighbor as yourself — "on these two commandments depend all the '
        'Law and the Prophets."',
    refs: [CuratedTopicRef('Matthew', 22, 34, 40)],
  ),
  CuratedTopic(
    name: 'THE SEVEN WOES TO THE PHARISEES',
    category: 'story',
    description:
        'Jesus denounces the scribes and Pharisees in the temple '
        'courts — "Woe to you... hypocrites!" — for their hollow, '
        'showy religion, and laments over Jerusalem.',
    refs: [CuratedTopicRef('Matthew', 23)],
  ),
  CuratedTopic(
    name: "THE WIDOW'S MITE",
    category: 'story',
    description:
        'Watching the temple treasury, Jesus commends a poor '
        'widow\'s two small copper coins above the large gifts of the '
        'rich, "for they... out of their abundance, but she out of her '
        'poverty put in everything she had."',
    refs: [CuratedTopicRef('Mark', 12, 41, 44)],
  ),
  CuratedTopic(
    name: 'THE OLIVET DISCOURSE',
    category: 'story',
    description:
        'On the Mount of Olives, Jesus foretells the destruction '
        'of the temple, wars and rumors of wars, and his own return, '
        'teaching that "of that day and hour no one knows."',
    refs: [CuratedTopicRef('Matthew', 24, 1, 44)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE FAITHFUL AND WISE SERVANT',
    category: 'story',
    description:
        'Jesus contrasts a servant who faithfully manages his '
        "master's household while he is away with a wicked one who abuses "
        'it, warning his disciples to stay ready for his return.',
    refs: [CuratedTopicRef('Matthew', 24, 45, 51)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE TEN VIRGINS',
    category: 'story',
    description:
        'Five wise virgins keep enough oil for their lamps while '
        'five foolish ones run out, waiting for a bridegroom who comes at '
        'an unexpected hour.',
    refs: [CuratedTopicRef('Matthew', 25, 1, 13)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE TALENTS',
    category: 'story',
    description:
        'A master entrusts his servants with talents while away; '
        'those who invest theirs hear, "Well done, good and faithful '
        'servant," but the one who buried his is condemned.',
    refs: [CuratedTopicRef('Matthew', 25, 14, 30)],
  ),
  CuratedTopic(
    name: 'THE SHEEP AND THE GOATS',
    category: 'story',
    description:
        'Jesus describes a final judgment separating "sheep" from '
        '"goats" by how they treated "the least of these" — the hungry, '
        'the stranger, the prisoner.',
    refs: [CuratedTopicRef('Matthew', 25, 31, 46)],
  ),
  CuratedTopic(
    name: 'MARY ANOINTS JESUS AT BETHANY',
    category: 'story',
    description:
        'Mary pours expensive perfume on Jesus\' feet and wipes '
        "them with her hair; Judas objects to the waste, but Jesus says "
        'she has anointed him beforehand for burial.',
    refs: [CuratedTopicRef('John', 12, 1, 8)],
  ),
  CuratedTopic(
    name: 'JESUS WASHES THE DISCIPLES\' FEET',
    category: 'story',
    description:
        'At the Last Supper, Jesus takes a towel and basin and '
        'washes his disciples\' feet, modeling humble service.',
    refs: [CuratedTopicRef('John', 13, 1, 17)],
  ),
  CuratedTopic(
    name: 'THE PARABLE OF THE VINE AND THE BRANCHES',
    category: 'story',
    description:
        'At the Last Supper, Jesus tells his disciples, "I am the '
        'vine, you are the branches," urging them to remain in him so '
        'they can bear fruit.',
    refs: [CuratedTopicRef('John', 15, 1, 8)],
  ),
  CuratedTopic(
    name: 'THE UPPER ROOM DISCOURSE AND THE HIGH PRIESTLY PRAYER',
    category: 'story',
    description:
        'Jesus comforts his disciples before his death — "Let '
        'not your hearts be troubled" — promises the Holy Spirit, and '
        'prays for them and all future believers.',
    refs: [
      CuratedTopicRef('John', 14),
      CuratedTopicRef('John', 16),
      CuratedTopicRef('John', 17),
    ],
  ),
  CuratedTopic(
    name: 'THOMAS ASKS THE WAY',
    category: 'story',
    description:
        "Thomas objects that the disciples don't know where "
        'Jesus is going, prompting his answer: "I am the way, and the '
        'truth, and the life. No one comes to the Father except through '
        'me."',
    refs: [CuratedTopicRef('John', 14, 5, 6)],
  ),
  CuratedTopic(
    name: 'PHILIP\'S QUESTION: "SHOW US THE FATHER"',
    category: 'story',
    description:
        'Philip asks Jesus to show them the Father; Jesus replies, '
        '"Whoever has seen me has seen the Father," after being with them '
        'so long.',
    refs: [CuratedTopicRef('John', 14, 8, 9)],
  ),
  CuratedTopic(
    name: "THADDAEUS'S QUESTION AT THE LAST SUPPER",
    category: 'story',
    description:
        'Judas (not Iscariot), also called Thaddaeus, asks Jesus '
        'why he will show himself to the disciples but not to the world; '
        'Jesus answers that whoever loves him will keep his word.',
    refs: [CuratedTopicRef('John', 14, 22, 24)],
  ),
  CuratedTopic(
    name: 'JESUS PRAYS IN GETHSEMANE',
    category: 'story',
    description:
        'In anguish before his arrest, Jesus prays "let this cup '
        'pass from me... yet not as I will, but as you will" while his '
        'disciples fall asleep instead of keeping watch.',
    refs: [CuratedTopicRef('Matthew', 26, 36, 46)],
  ),
  CuratedTopic(
    name: "JUDAS'S BETRAYAL",
    category: 'story',
    description:
        'Judas Iscariot agrees to betray Jesus for thirty pieces '
        'of silver, then identifies him to the arresting crowd with a '
        'kiss.',
    refs: [
      CuratedTopicRef('Matthew', 26, 14, 16),
      CuratedTopicRef('Matthew', 26, 47, 50),
    ],
  ),
  CuratedTopic(
    name: "JESUS HEALS MALCHUS'S EAR",
    category: 'story',
    description:
        "As Peter draws his sword against the arresting party, "
        'cutting off the high priest\'s servant\'s ear, Jesus performs his '
        'last miracle before the cross by healing it.',
    refs: [CuratedTopicRef('Luke', 22, 50, 51)],
  ),
  CuratedTopic(
    name: 'JESUS BEFORE CAIAPHAS AND THE SANHEDRIN',
    category: 'story',
    description:
        'Brought before the high priest and the council at '
        'night, Jesus is condemned for blasphemy after declaring himself '
        'the Son of God, then mocked, spit on, and struck.',
    refs: [CuratedTopicRef('Matthew', 26, 57, 68)],
  ),
  CuratedTopic(
    name: "PETER'S DENIAL",
    category: 'story',
    description:
        'Just as Jesus predicted, Peter denies knowing him three '
        'times before the rooster crows, then weeps bitterly.',
    refs: [CuratedTopicRef('Luke', 22, 54, 62)],
  ),
  CuratedTopic(
    name: "JUDAS'S REMORSE AND DEATH",
    category: 'story',
    description:
        'Seeing Jesus condemned, Judas returns the thirty pieces '
        'of silver to the chief priests, confessing "I have betrayed '
        'innocent blood," then goes and hangs himself.',
    refs: [CuratedTopicRef('Matthew', 27, 3, 10)],
  ),
  CuratedTopic(
    name: 'JESUS BEFORE HEROD',
    category: 'story',
    description:
        'Pilate sends Jesus to Herod Antipas, who has long '
        'wanted to see him perform a sign; Jesus stays silent, and Herod '
        'mocks him and sends him back to Pilate.',
    refs: [CuratedTopicRef('Luke', 23, 6, 12)],
  ),
  CuratedTopic(
    name: "PILATE'S WIFE'S WARNING",
    category: 'story',
    description:
        'While Pilate is seated on the judgment seat, his wife '
        'sends word urging him to have nothing to do with "that '
        'righteous man," for she had suffered much that day in a dream '
        'because of him.',
    refs: [CuratedTopicRef('Matthew', 27, 19)],
  ),
  CuratedTopic(
    name: 'JESUS BEFORE PILATE AND THE RELEASE OF BARABBAS',
    category: 'story',
    description:
        'Pilate finds no fault in Jesus but yields to the crowd, '
        'releasing the rebel Barabbas in his place and handing Jesus over '
        'to be crucified.',
    refs: [CuratedTopicRef('Matthew', 27, 11, 26)],
  ),
  CuratedTopic(
    name: 'JESUS APPEARS TO MARY MAGDALENE',
    category: 'story',
    description:
        'Weeping at the empty tomb, Mary Magdalene mistakes the '
        'risen Jesus for the gardener until he speaks her name — "Mary!" '
        '— and she recognizes him, crying, "Rabboni!"',
    refs: [CuratedTopicRef('John', 20, 11, 18)],
  ),
  CuratedTopic(
    name: 'JESUS APPEARS TO THE DISCIPLES',
    category: 'story',
    description:
        'The risen Jesus appears to his disciples behind locked '
        'doors, saying, "Peace be with you," and breathes on them, "Receive '
        'the Holy Spirit."',
    refs: [CuratedTopicRef('John', 20, 19, 23)],
  ),
  CuratedTopic(
    name: 'DOUBTING THOMAS',
    category: 'story',
    description:
        'Thomas refuses to believe the resurrection until he can '
        'touch Jesus\' wounds himself — and then confesses, "My Lord and '
        'my God!"',
    refs: [CuratedTopicRef('John', 20, 24, 29)],
  ),
  CuratedTopic(
    name: 'THE ROAD TO EMMAUS',
    category: 'story',
    description:
        'The risen Jesus walks unrecognized with two disciples to '
        'Emmaus, and is finally known to them in the breaking of bread.',
    refs: [CuratedTopicRef('Luke', 24, 13, 35)],
  ),
  CuratedTopic(
    name: 'THE GREAT COMMISSION',
    category: 'story',
    description:
        'The risen Jesus commissions his disciples to "go and '
        'make disciples of all nations," promising to be with them always.',
    refs: [CuratedTopicRef('Matthew', 28, 16, 20)],
  ),
  CuratedTopic(
    name: "PETER RESTORED ON THE SHORE",
    category: 'story',
    description:
        'After a miraculous catch of fish and breakfast on the '
        'beach, the risen Jesus asks Peter three times, "Do you love me?" '
        'restoring him and commissioning him to "feed my sheep."',
    refs: [CuratedTopicRef('John', 21)],
  ),

  // --- Acts ---
  CuratedTopic(
    name: 'PETER AND JOHN BEFORE THE SANHEDRIN',
    category: 'story',
    description:
        'Arrested for healing a lame man and preaching Jesus, '
        'Peter and John tell the council, "We cannot but speak of what we '
        'have seen and heard."',
    refs: [CuratedTopicRef('Acts', 4, 1, 22)],
  ),
  CuratedTopic(
    name: 'ANANIAS AND SAPPHIRA',
    category: 'story',
    description:
        'A husband and wife fall dead in turn after lying to the '
        'Holy Spirit about money they claimed to have given in full.',
    refs: [CuratedTopicRef('Acts', 5, 1, 11)],
  ),
  CuratedTopic(
    name: "STEPHEN'S MARTYRDOM",
    category: 'story',
    description:
        'Stephen is stoned to death for his testimony about '
        'Jesus, praying for his killers as Saul looks on approvingly.',
    refs: [CuratedTopicRef('Acts', 7, 54, 60)],
  ),
  CuratedTopic(
    name: 'SIMON THE SORCERER',
    category: 'story',
    description:
        'A sorcerer named Simon believes and is baptized, then '
        'tries to buy the power to bestow the Holy Spirit — earning '
        'Peter\'s rebuke, "Your money perish with you."',
    refs: [CuratedTopicRef('Acts', 8, 9, 24)],
  ),
  CuratedTopic(
    name: 'PHILIP AND THE ETHIOPIAN EUNUCH',
    category: 'story',
    description:
        'Philip explains the prophet Isaiah to an Ethiopian '
        'official on a desert road, who then asks to be baptized on the '
        'spot.',
    refs: [CuratedTopicRef('Acts', 8, 26, 40)],
  ),
  CuratedTopic(
    name: 'DORCAS RAISED TO LIFE',
    category: 'story',
    description:
        'When the beloved disciple Dorcas, known for her charity '
        'to widows, falls sick and dies, Peter kneels to pray and then '
        'commands her, "Tabitha, arise" — and she opens her eyes.',
    refs: [CuratedTopicRef('Acts', 9, 36, 42)],
  ),
  CuratedTopic(
    name: "PETER'S VISION AND CORNELIUS",
    category: 'story',
    description:
        'A vision of unclean animals prepares Peter to visit the '
        'Roman centurion Cornelius, opening the gospel to the Gentiles.',
    refs: [CuratedTopicRef('Acts', 10)],
  ),
  CuratedTopic(
    name: 'PAUL REBUKES PETER AT ANTIOCH',
    category: 'story',
    description:
        "Paul opposes Peter to his face at Antioch for drawing "
        "back from eating with Gentile believers out of fear of the "
        "circumcision party, telling him he is not acting in step with "
        'the truth of the gospel.',
    refs: [CuratedTopicRef('Galatians', 2, 11, 14)],
  ),
  CuratedTopic(
    name: 'THE MARTYRDOM OF JAMES, SON OF ZEBEDEE',
    category: 'story',
    description:
        'King Herod has James, the brother of John, put to death '
        'with the sword — the first of the Twelve to be martyred.',
    refs: [CuratedTopicRef('Acts', 12, 1, 2)],
  ),
  CuratedTopic(
    name: "PETER'S ESCAPE FROM PRISON",
    category: 'story',
    description:
        "An angel wakes Peter in chains, and the prison's iron "
        'gate opens by itself as the church prays for his release.',
    refs: [CuratedTopicRef('Acts', 12, 1, 19)],
  ),
  CuratedTopic(
    name: "HEROD AGRIPPA'S DEATH",
    category: 'story',
    description:
        'Herod Agrippa accepts a crowd\'s praise as a god instead '
        'of giving glory to God, and is struck down and eaten by worms on '
        'the spot.',
    refs: [CuratedTopicRef('Acts', 12, 20, 23)],
  ),
  CuratedTopic(
    name: 'PAUL AND BARNABAS SENT OUT FROM ANTIOCH',
    category: 'story',
    description:
        'While the church at Antioch worships and fasts, the '
        'Holy Spirit sets apart Barnabas and Saul for the work of the '
        'first missionary journey, and the church sends them off with '
        'the laying on of hands.',
    refs: [CuratedTopicRef('Acts', 13, 1, 3)],
  ),
  CuratedTopic(
    name: 'ELYMAS THE SORCERER STRUCK BLIND',
    category: 'story',
    description:
        'On Cyprus, the sorcerer Elymas opposes Paul\'s preaching '
        'to the proconsul; Paul denounces him as a "son of the devil," '
        'and he is struck blind on the spot.',
    refs: [CuratedTopicRef('Acts', 13, 6, 12)],
  ),
  CuratedTopic(
    name: 'PAUL AND BARNABAS MISTAKEN FOR GODS AT LYSTRA',
    category: 'story',
    description:
        'After Paul heals a lame man, the crowd at Lystra hails '
        'Paul and Barnabas as Hermes and Zeus and tries to sacrifice to '
        'them, until the two tear their clothes in protest.',
    refs: [CuratedTopicRef('Acts', 14, 8, 18)],
  ),
  CuratedTopic(
    name: 'PAUL STONED AT LYSTRA',
    category: 'story',
    description:
        'The same crowd at Lystra is turned against Paul, stones '
        'him, and drags him out of the city supposing him dead; he gets '
        'up and walks back in.',
    refs: [CuratedTopicRef('Acts', 14, 19, 20)],
  ),
  CuratedTopic(
    name: 'THE JERUSALEM COUNCIL',
    category: 'story',
    description:
        'The apostles and elders meet in Jerusalem to settle '
        'whether Gentile believers must keep the law of Moses.',
    refs: [CuratedTopicRef('Acts', 15)],
  ),
  CuratedTopic(
    name: 'PAUL AND BARNABAS PART WAYS OVER JOHN MARK',
    category: 'story',
    description:
        'Preparing for a second journey, Paul and Barnabas have '
        'a sharp disagreement over whether to take John Mark, who had '
        'deserted them before, and separate — Barnabas sailing with Mark, '
        'Paul setting out with Silas.',
    refs: [CuratedTopicRef('Acts', 15, 36, 41)],
  ),
  CuratedTopic(
    name: 'THE MACEDONIAN CALL',
    category: 'story',
    description:
        'Forbidden by the Spirit to preach in Asia, Paul sees a '
        'vision of a man of Macedonia pleading, "Come over... and help '
        'us," and the missionary band sets sail for Europe.',
    refs: [CuratedTopicRef('Acts', 16, 6, 10)],
  ),
  CuratedTopic(
    name: "LYDIA'S CONVERSION AT PHILIPPI",
    category: 'story',
    description:
        'At a riverside prayer meeting outside Philippi, the '
        "LORD opens the heart of Lydia, a seller of purple goods, and she "
        'and her household are baptized.',
    refs: [CuratedTopicRef('Acts', 16, 11, 15)],
  ),
  CuratedTopic(
    name: 'PAUL AND SILAS IN PRISON AT PHILIPPI',
    category: 'story',
    description:
        'An earthquake breaks open the prison doors after Paul '
        'and Silas sing hymns at midnight, and their jailer is converted.',
    refs: [CuratedTopicRef('Acts', 16, 16, 34)],
  ),
  CuratedTopic(
    name: 'PAUL AT THESSALONICA AND BEREA',
    category: 'story',
    description:
        'Paul reasons from the Scriptures in the Thessalonian '
        'synagogue, then moves on to Berea, whose people are commended '
        'for examining the Scriptures daily to see if his teaching was so.',
    refs: [CuratedTopicRef('Acts', 17, 1, 15)],
  ),
  CuratedTopic(
    name: 'PAUL AT THE AREOPAGUS',
    category: 'story',
    description:
        'Paul addresses the philosophers of Athens at the '
        'Areopagus, proclaiming the "unknown god" they already worship in '
        'ignorance.',
    refs: [CuratedTopicRef('Acts', 17, 16, 34)],
  ),
  CuratedTopic(
    name: 'PAUL IN CORINTH: AQUILA, PRISCILLA, AND GALLIO',
    category: 'story',
    description:
        'Paul settles in Corinth with the tentmakers Aquila and '
        'Priscilla, and when the Jews bring him before the proconsul '
        'Gallio, Gallio dismisses the case as an internal Jewish dispute.',
    refs: [CuratedTopicRef('Acts', 18, 1, 17)],
  ),
  CuratedTopic(
    name: 'THE SONS OF SCEVA',
    category: 'story',
    description:
        'Seven Jewish exorcists try to invoke "the Jesus whom '
        'Paul preaches" over a demon-possessed man, who overpowers them '
        'all, sending them fleeing naked and wounded.',
    refs: [CuratedTopicRef('Acts', 19, 13, 20)],
  ),
  CuratedTopic(
    name: 'THE RIOT OF THE SILVERSMITHS AT EPHESUS',
    category: 'story',
    description:
        'A silversmith named Demetrius incites a riot over lost '
        'idol-making business, and the city\'s theater erupts in two hours '
        'of chanting, "Great is Artemis of the Ephesians!"',
    refs: [CuratedTopicRef('Acts', 19, 23, 41)],
  ),
  CuratedTopic(
    name: 'EUTYCHUS FALLS FROM THE WINDOW',
    category: 'story',
    description:
        "A young man named Eutychus dozes off during Paul's "
        'long midnight sermon, falls three stories from a window, and is '
        'taken up dead — until Paul embraces him and he lives.',
    refs: [CuratedTopicRef('Acts', 20, 7, 12)],
  ),
  CuratedTopic(
    name: "PAUL'S FAREWELL TO THE EPHESIAN ELDERS",
    category: 'story',
    description:
        'Meeting the Ephesian elders at Miletus, Paul warns that '
        'fierce wolves will come in among them and commends them to God, '
        'recalling the Lord Jesus\' words: "It is more blessed to give '
        'than to receive."',
    refs: [CuratedTopicRef('Acts', 20, 17, 38)],
  ),
  CuratedTopic(
    name: 'PAUL ARRESTED IN THE TEMPLE',
    category: 'story',
    description:
        'A mob drags Paul from the temple and beats him, '
        'supposing he had defiled it by bringing in a Gentile; a Roman '
        'commander rescues him from the riot by arresting him.',
    refs: [CuratedTopicRef('Acts', 21, 27, 36)],
  ),
  CuratedTopic(
    name: "PAUL'S DEFENSE BEFORE THE JERUSALEM CROWD",
    category: 'story',
    description:
        'From the barracks steps, Paul addresses the hostile '
        'crowd in Hebrew, recounting his conversion on the Damascus '
        'road, until they cry out for his death at the mention of the '
        'Gentiles.',
    refs: [CuratedTopicRef('Acts', 22, 1, 21)],
  ),
  CuratedTopic(
    name: 'PAUL BEFORE THE SANHEDRIN',
    category: 'story',
    description:
        'Paul declares himself on trial over the resurrection of '
        'the dead, splitting the council between Pharisees and Sadducees '
        'until the dispute turns violent and he must be rescued.',
    refs: [CuratedTopicRef('Acts', 23, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE PLOT TO KILL PAUL',
    category: 'story',
    description:
        "More than forty men bind themselves by an oath to kill "
        "Paul, but his nephew overhears the plot and warns the Roman "
        'commander, who has Paul escorted to Caesarea by night.',
    refs: [CuratedTopicRef('Acts', 23, 12, 24)],
  ),
  CuratedTopic(
    name: 'PAUL BEFORE FELIX',
    category: 'story',
    description:
        'Paul defends himself before Governor Felix, who leaves '
        'him in custody for two years hoping for a bribe, though he '
        'trembles when Paul reasons about righteousness and judgment to '
        'come.',
    refs: [CuratedTopicRef('Acts', 24)],
  ),
  CuratedTopic(
    name: "PAUL BEFORE FESTUS AND AGRIPPA",
    category: 'story',
    description:
        'Paul defends himself before King Agrippa and Governor '
        'Festus, recounting his conversion, until Agrippa remarks he is '
        'almost persuaded to become a Christian.',
    refs: [CuratedTopicRef('Acts', 25, 13, 27), CuratedTopicRef('Acts', 26)],
  ),
  CuratedTopic(
    name: "PAUL'S SHIPWRECK",
    category: 'story',
    description:
        'A violent storm wrecks the ship carrying Paul to Rome, '
        'and everyone aboard reaches shore safely on Malta as he had '
        'promised.',
    refs: [CuratedTopicRef('Acts', 27, 13, 44)],
  ),
  CuratedTopic(
    name: 'PAUL BITTEN BY A VIPER ON MALTA',
    category: 'story',
    description:
        'Shipwrecked on Malta, Paul is bitten by a viper while '
        'gathering firewood; when he shakes it off unharmed, the '
        'islanders decide he must be a god.',
    refs: [CuratedTopicRef('Acts', 28, 1, 6)],
  ),
  CuratedTopic(
    name: "PAUL'S TWO YEARS UNDER HOUSE ARREST IN ROME",
    category: 'story',
    description:
        'Awaiting trial in Rome, Paul lives at his own expense '
        'under guard for two years, welcoming all who came to him and '
        'proclaiming the kingdom of God "with all boldness and without '
        'hindrance."',
    refs: [CuratedTopicRef('Acts', 28, 16, 31)],
  ),

  // --- Revelation ---
  CuratedTopic(
    name: "JOHN'S VISION ON PATMOS",
    category: 'story',
    description:
        'Exiled on the island of Patmos, John sees the risen '
        'Christ walking among seven golden lampstands and falls at his '
        'feet as though dead, before being commissioned to write what he '
        'has seen.',
    refs: [CuratedTopicRef('Revelation', 1, 9, 19)],
  ),
  CuratedTopic(
    name: 'THE LETTERS TO THE SEVEN CHURCHES',
    category: 'story',
    description:
        'The risen Christ dictates seven letters to the churches '
        'of Asia — Ephesus, Smyrna, Pergamum, Thyatira, Sardis, '
        'Philadelphia, and Laodicea — commending, warning, and calling '
        'each "to hear what the Spirit says to the churches."',
    refs: [CuratedTopicRef('Revelation', 2), CuratedTopicRef('Revelation', 3)],
  ),
  CuratedTopic(
    name: 'THE THRONE ROOM IN HEAVEN',
    category: 'story',
    description:
        'John is caught up through an open door in heaven and '
        'sees a throne encircled by twenty-four elders and four living '
        'creatures, who cry day and night, "Holy, holy, holy, is the '
        'Lord God Almighty."',
    refs: [CuratedTopicRef('Revelation', 4)],
  ),
  CuratedTopic(
    name: 'THE SCROLL AND THE LAMB WHO IS WORTHY',
    category: 'story',
    description:
        'John weeps that no one is found worthy to open the '
        'sealed scroll, until a Lamb looking as though it had been slain '
        'takes it, and all creation falls down singing, "Worthy is the '
        'Lamb who was slain."',
    refs: [CuratedTopicRef('Revelation', 5)],
  ),
  CuratedTopic(
    name: 'THE SEVEN SEALS AND THE FOUR HORSEMEN',
    category: 'story',
    description:
        'The Lamb opens six of the seven seals, releasing four '
        'horsemen — conquest, war, famine, and death — followed by the '
        'cry of martyred souls and a cosmic upheaval that makes the '
        'mighty hide in the rocks.',
    refs: [CuratedTopicRef('Revelation', 6)],
  ),
  CuratedTopic(
    name: 'THE 144,000 SEALED AND THE GREAT MULTITUDE',
    category: 'story',
    description:
        '144,000 from the twelve tribes of Israel are sealed on '
        'their foreheads, and John sees a great multitude from every '
        'nation, robed in white and washed in the blood of the Lamb, '
        'worshiping before the throne.',
    refs: [CuratedTopicRef('Revelation', 7)],
  ),
  CuratedTopic(
    name: 'THE SEVEN TRUMPETS',
    category: 'story',
    description:
        'Seven angels sound seven trumpets, unleashing hail and '
        'fire, a burning mountain cast into the sea, the star Wormwood, '
        'darkened skies, and locusts and horsemen from the abyss.',
    refs: [CuratedTopicRef('Revelation', 8), CuratedTopicRef('Revelation', 9)],
  ),
  CuratedTopic(
    name: 'THE ANGEL AND THE LITTLE SCROLL',
    category: 'story',
    description:
        'A mighty angel wrapped in a cloud gives John a little '
        'scroll to eat, sweet as honey in his mouth but bitter in his '
        'stomach, and commissions him to prophesy again.',
    refs: [CuratedTopicRef('Revelation', 10)],
  ),
  CuratedTopic(
    name: 'THE TWO WITNESSES',
    category: 'story',
    description:
        'Two witnesses prophesy in sackcloth for 1,260 days, are '
        'killed by the beast and left unburied in the street, then are '
        'raised to life and taken up to heaven before the watching world.',
    refs: [CuratedTopicRef('Revelation', 11)],
  ),
  CuratedTopic(
    name: 'THE WOMAN, THE CHILD, AND THE DRAGON',
    category: 'story',
    description:
        'A woman clothed with the sun gives birth to a son while '
        'a great red dragon waits to devour him; the child is caught up '
        'to God\'s throne, and Michael and his angels cast the dragon '
        'down from heaven.',
    refs: [CuratedTopicRef('Revelation', 12)],
  ),
  CuratedTopic(
    name: 'THE BEAST FROM THE SEA AND THE BEAST FROM THE EARTH',
    category: 'story',
    description:
        'A beast rises from the sea with authority to make war '
        'on the saints, and a second beast from the earth compels the '
        'world to worship it and take its mark, "666," on hand or '
        'forehead.',
    refs: [CuratedTopicRef('Revelation', 13)],
  ),
  CuratedTopic(
    name: 'THE 144,000 ON MOUNT ZION',
    category: 'story',
    description:
        'John sees the Lamb standing on Mount Zion with the '
        '144,000, who sing a new song no one else can learn and follow '
        'the Lamb wherever he goes.',
    refs: [CuratedTopicRef('Revelation', 14, 1, 5)],
  ),
  CuratedTopic(
    name: 'THE HARVEST OF THE EARTH',
    category: 'story',
    description:
        'One like a son of man reaps the earth with a sickle '
        "from a cloud, and an angel gathers the grapes of wrath into "
        "the great winepress of God's judgment.",
    refs: [CuratedTopicRef('Revelation', 14, 14, 20)],
  ),
  CuratedTopic(
    name: "THE SEVEN BOWLS OF GOD'S WRATH",
    category: 'story',
    description:
        "Seven angels pour out seven bowls of God's wrath on "
        'the earth — sores, seas and rivers turned to blood, scorching '
        'sun, darkness, and a final earthquake — culminating in the '
        'cry, "It is done."',
    refs: [
      CuratedTopicRef('Revelation', 15),
      CuratedTopicRef('Revelation', 16),
    ],
  ),
  CuratedTopic(
    name: 'THE GREAT PROSTITUTE AND THE BEAST',
    category: 'story',
    description:
        'John sees a woman named "Babylon the Great," drunk '
        'with the blood of the saints, riding a scarlet beast with seven '
        'heads and ten horns, who will ultimately be destroyed by the '
        'beast she rides.',
    refs: [CuratedTopicRef('Revelation', 17)],
  ),
  CuratedTopic(
    name: 'THE FALL OF BABYLON',
    category: 'story',
    description:
        'An angel announces, "Fallen, fallen is Babylon the '
        'great," and the kings, merchants, and sailors of the earth '
        'mourn the sudden destruction of the city that had grown rich '
        'on her luxury.',
    refs: [CuratedTopicRef('Revelation', 18)],
  ),
  CuratedTopic(
    name: 'THE MARRIAGE SUPPER OF THE LAMB',
    category: 'story',
    description:
        'Heaven resounds with "Hallelujah" over Babylon\'s fall, '
        'and an angel announces the marriage supper of the Lamb, where '
        'his bride has made herself ready, clothed in fine linen.',
    refs: [CuratedTopicRef('Revelation', 19, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE RIDER ON THE WHITE HORSE',
    category: 'story',
    description:
        'Heaven opens and a rider called Faithful and True, '
        'robed in blood and named the Word of God, leads heaven\'s '
        'armies to defeat the beast and false prophet, who are thrown '
        'alive into the lake of fire.',
    refs: [CuratedTopicRef('Revelation', 19, 11, 21)],
  ),
  CuratedTopic(
    name: "THE MILLENNIUM AND SATAN'S FINAL DEFEAT",
    category: 'story',
    description:
        'An angel binds Satan for a thousand years while the '
        'martyrs reign with Christ; released briefly afterward, Satan '
        'gathers the nations for a final battle before being thrown '
        'into the lake of fire forever.',
    refs: [CuratedTopicRef('Revelation', 20, 1, 10)],
  ),
  CuratedTopic(
    name: 'THE GREAT WHITE THRONE JUDGMENT',
    category: 'story',
    description:
        'The dead, great and small, stand before a great white '
        'throne to be judged by what is written in the books, and '
        'anyone whose name is not found in the book of life is thrown '
        'into the lake of fire.',
    refs: [CuratedTopicRef('Revelation', 20, 11, 15)],
  ),
  CuratedTopic(
    name: 'THE NEW HEAVEN AND THE NEW JERUSALEM',
    category: 'story',
    description:
        'John sees a new heaven and a new earth, and the new '
        'Jerusalem descending like a bride, as God declares, "Behold, I '
        'am making all things new," and promises to wipe away every '
        'tear.',
    refs: [CuratedTopicRef('Revelation', 21)],
  ),
  CuratedTopic(
    name: 'THE RIVER OF LIFE AND THE TREE OF LIFE',
    category: 'story',
    description:
        'John sees the river of the water of life flowing from '
        "God's throne, with the tree of life on either side bearing "
        'fruit each month, its leaves for the healing of the nations.',
    refs: [CuratedTopicRef('Revelation', 22, 1, 5)],
  ),
];

final curatedTopics = <CuratedTopic>[..._feastTopics, ..._storyTopics];
