import 'thread.dart';

/// Hand-curated thematic threads, browsable in the Explorer and walkable in
/// the reader (see `thread_walk_providers.dart`).
///
/// Every stop's passage is validated against `kjvVersification` by
/// `test/thread_data_test.dart`, which also enforces canonical stop order
/// within each thread. More threads can be appended here without any code
/// changes; keep the file grouped by [ThreadCategory] so it reads as a
/// library, and keep each note to one or two sentences that say why the
/// thread jumps to that passage — the note is what makes this a guided walk
/// rather than a reference list.
const List<Thread> threads = [
  // ---------------------------------------------------------------------------
  // Motifs & Symbols
  // ---------------------------------------------------------------------------
  Thread(
    id: 'living_water',
    title: 'Living Water',
    category: ThreadCategory.motif,
    description:
        'A river runs through the whole Bible: it rises in Eden, springs '
        'from a struck rock in the wilderness, is promised to the thirsty by '
        'the prophets, and is finally offered by Jesus as the Spirit welling '
        'up to everlasting life — until the last chapter of Scripture ends '
        'where the first began, with a river flowing from the throne.',
    stops: [
      ThreadStop(
        title: 'A river goes out of Eden',
        passage: 'Genesis 2:10',
        note:
            'The Bible\'s first geography lesson is a river: life in God\'s '
            'presence is pictured from the start as a garden watered from '
            'within.',
      ),
      ThreadStop(
        title: 'Water from the rock',
        passage: 'Exodus 17:5-6',
        note:
            'East of Eden the picture inverts — a desert, a thirsty people, '
            'and water that comes only when the rock is struck. Keep this '
            'scene in mind; Paul will return to it.',
      ),
      ThreadStop(
        title: 'The soul\'s thirst',
        passage: 'Psalms 42:1-2',
        note:
            'The psalmist names what the desert dramatized: the thirst was '
            'never only physical. "My soul thirsteth for God."',
      ),
      ThreadStop(
        title: 'Ho, every one that thirsteth',
        passage: 'Isaiah 55:1',
        note:
            'The prophets turn the motif into an invitation — water without '
            'money and without price, for anyone who will come.',
      ),
      ThreadStop(
        title: 'The river from the temple',
        passage: 'Ezekiel 47:1-9',
        note:
            'Ezekiel\'s vision joins the two pictures: Eden\'s river returns, '
            'but now it flows from God\'s dwelling place, deepening as it '
            'goes and healing everything it touches.',
      ),
      ThreadStop(
        title: 'The well of Sychar',
        passage: 'John 4:10-14',
        note:
            'Jesus sits down at a well and claims the whole motif for '
            'himself: the water he gives becomes a spring inside the drinker, '
            '"springing up into everlasting life."',
      ),
      ThreadStop(
        title: 'Rivers of living water',
        passage: 'John 7:37-39',
        note:
            'At the feast Jesus stands and cries Isaiah\'s "come" — and John '
            'tells us plainly what the water is: the Spirit, given once Jesus '
            'is glorified.',
      ),
      ThreadStop(
        title: 'That Rock was Christ',
        passage: '1 Corinthians 10:4',
        note:
            'Paul looks back at Exodus 17 and names the struck rock: the '
            'water in the wilderness was always flowing from Christ.',
      ),
      ThreadStop(
        title: 'The river of the water of life',
        passage: 'Revelation 22:1-2',
        note:
            'The Bible closes where it opened — a river in a garden city, '
            'now proceeding from the throne of God and of the Lamb. The '
            'chapter\'s last invitation (v. 17) is still Isaiah\'s: let him '
            'that is athirst come.',
      ),
    ],
  ),
  Thread(
    id: 'god_with_us',
    title: 'The Dwelling Place',
    category: ThreadCategory.motif,
    description:
        'The story of the Bible can be told as one question: where does God '
        'live, and can we be near him? From the garden where he walked, to '
        'tabernacle and temple, to glory departing, to "the Word was made '
        'flesh, and dwelt among us," the thread runs to the last promise of '
        'Scripture — the tabernacle of God is with men.',
    stops: [
      ThreadStop(
        title: 'Walking in the garden',
        passage: 'Genesis 3:8',
        note:
            'The first picture of God\'s presence is domestic — a voice '
            'walking in the garden in the cool of the day. The tragedy of '
            'the verse is that man now hides from it.',
      ),
      ThreadStop(
        title: 'That I may dwell among them',
        passage: 'Exodus 25:8',
        note:
            'After the exile from Eden, God\'s stated purpose for the '
            'tabernacle is the thread in a single line: a sanctuary, "that I '
            'may dwell among them."',
      ),
      ThreadStop(
        title: 'Glory fills the tabernacle',
        passage: 'Exodus 40:34-38',
        note:
            'The tent is finished and the glory moves in — so thick that '
            'Moses himself cannot enter. Presence has returned, but behind '
            'a veil.',
      ),
      ThreadStop(
        title: 'Glory fills the temple',
        passage: '1 Kings 8:10-13',
        note:
            'Solomon\'s temple repeats Exodus 40 in stone: the cloud fills '
            'the house, and the priests cannot stand to minister. Later in '
            'this same dedication (v. 27) Solomon already wonders aloud '
            'whether any house can hold God.',
      ),
      ThreadStop(
        title: 'The glory departs',
        passage: 'Ezekiel 10:18-19',
        note:
            'The thread\'s darkest turn: Ezekiel watches the glory lift from '
            'the threshold and leave the temple. A building without the '
            'presence is just a building.',
      ),
      ThreadStop(
        title: 'My tabernacle shall be with them',
        passage: 'Ezekiel 37:26-28',
        note:
            'The same prophet who saw the glory leave is given the promise '
            'of its return — an everlasting covenant with God\'s sanctuary '
            'set among his people for evermore.',
      ),
      ThreadStop(
        title: 'Emmanuel',
        passage: 'Matthew 1:23',
        note:
            'The New Testament opens by naming the child with the thread '
            'itself: God with us.',
      ),
      ThreadStop(
        title: 'The Word tabernacled among us',
        passage: 'John 1:14',
        note:
            'John\'s verb is Exodus\'s noun — the Word "dwelt" (literally, '
            'pitched his tent) among us, "and we beheld his glory." The '
            'glory that left in Ezekiel walks back in on human feet.',
      ),
      ThreadStop(
        title: 'Ye are the temple',
        passage: '1 Corinthians 3:16',
        note:
            'After the resurrection the dwelling moves again — not to a '
            'building but to a people. The Spirit of God dwells in the '
            'church.',
      ),
      ThreadStop(
        title: 'The tabernacle of God is with men',
        passage: 'Revelation 21:3',
        note:
            'The thread\'s destination: no temple in the city, because the '
            'presence fills it. Eden\'s walking-together is restored, this '
            'time forever.',
      ),
    ],
  ),
  Thread(
    id: 'tree_of_life',
    title: 'The Tree of Life',
    category: ThreadCategory.motif,
    description:
        'Planted in the middle of Eden, barred by a flaming sword, glimpsed '
        'in Proverbs, and startlingly reclaimed at the cross — "the tree" — '
        'this thread follows the Bible\'s oldest symbol of life with God '
        'from the first garden to the healing leaves of the last.',
    stops: [
      ThreadStop(
        title: 'In the midst of the garden',
        passage: 'Genesis 2:8-9',
        note:
            'Before there is any command or fall, there is a tree of life at '
            'the centre of the garden — life with God pictured as fruit '
            'freely within reach.',
      ),
      ThreadStop(
        title: 'The way is barred',
        passage: 'Genesis 3:22-24',
        note:
            'After the fall, the first thing guarded is this tree. The '
            'cherubim and flaming sword pose the thread\'s question: how '
            'does anyone get back to it?',
      ),
      ThreadStop(
        title: 'Wisdom is a tree of life',
        passage: 'Proverbs 3:13-18',
        note:
            'Proverbs keeps the image alive in exile from Eden: wisdom — '
            'life lived God\'s way — is "a tree of life to them that lay '
            'hold upon her."',
      ),
      ThreadStop(
        title: 'Leaves for medicine',
        passage: 'Ezekiel 47:12',
        note:
            'On the banks of Ezekiel\'s temple river grow trees whose fruit '
            'never fails and whose leaves heal — Eden\'s tree multiplied '
            'into an orchard. Revelation will quote this verse almost '
            'word for word.',
      ),
      ThreadStop(
        title: 'Hanged on a tree',
        passage: 'Galatians 3:13',
        note:
            'The thread\'s great reversal: Christ takes the curse "on a '
            'tree." The instrument of death is about to be spoken of as the '
            'place life was won back.',
      ),
      ThreadStop(
        title: 'His own body on the tree',
        passage: '1 Peter 2:24',
        note:
            'Peter uses the same word — Jesus "bare our sins in his own body '
            'on the tree, that we... should live." A tree once again holds '
            'the difference between life and death.',
      ),
      ThreadStop(
        title: 'To him that overcometh',
        passage: 'Revelation 2:7',
        note:
            'The risen Christ\'s first promise to the churches reaches all '
            'the way back to Genesis 3: "to eat of the tree of life, which '
            'is in the midst of the paradise of God." The barred way is open '
            'again.',
      ),
      ThreadStop(
        title: 'The healing of the nations',
        passage: 'Revelation 22:2',
        note:
            'The last page of the Bible: the tree stands on both banks of '
            'the river, bearing fruit every month, its leaves for the '
            'healing of the nations. What was lost in Eden is not merely '
            'restored but enlarged.',
      ),
    ],
  ),
  Thread(
    id: 'the_shepherd',
    title: 'The Shepherd',
    category: ThreadCategory.motif,
    description:
        'Before it is ever a title, "shepherd" is a memory — Jacob blesses '
        'by "the God which fed me all my life long." The image gathers force '
        'through Psalm 23 and the prophets, turns to grief over shepherdless '
        'sheep, and is finally claimed at full strength: "I am the good '
        'shepherd: the good shepherd giveth his life for the sheep."',
    stops: [
      ThreadStop(
        title: 'The God which fed me',
        passage: 'Genesis 48:15',
        note:
            'The Bible\'s first "shepherd" for God is spoken by a dying '
            'herdsman about his whole life: Jacob blesses by "the God which '
            'fed me" — in Hebrew, shepherded me — "all my life long."',
      ),
      ThreadStop(
        title: 'Sheep which have no shepherd',
        passage: 'Numbers 27:16-17',
        note:
            'Moses\' last request is a shepherd for Israel, "that the '
            'congregation of the LORD be not as sheep which have no '
            'shepherd." Hold the phrase; Matthew will pick it up.',
      ),
      ThreadStop(
        title: 'The LORD is my shepherd',
        passage: 'Psalms 23:1-4',
        note:
            'David turns his own trade into the Bible\'s best-loved '
            'confession: provision, guidance, and — in the valley of the '
            'shadow of death — presence. "Thou art with me."',
      ),
      ThreadStop(
        title: 'He shall feed his flock',
        passage: 'Isaiah 40:11',
        note:
            'The God whose coming levels mountains earlier in this chapter '
            '(v. 4) arrives carrying lambs "in his bosom" — the thread\'s '
            'power and its gentleness in a single verse.',
      ),
      ThreadStop(
        title: 'I will seek that which was lost',
        passage: 'Ezekiel 34:11-16',
        note:
            'After indicting Israel\'s shepherds for feeding themselves '
            '(vv. 2-10), God announces the turning point: "I, even I, will '
            'both search my sheep, and seek them out" — and later in the '
            'chapter (v. 23) promises one shepherd, "my servant David."',
      ),
      ThreadStop(
        title: 'Moved with compassion',
        passage: 'Matthew 9:36',
        note:
            'Jesus looks at the crowds and Matthew reaches for Moses\' '
            'phrase: "as sheep having no shepherd." Numbers 27\'s request is '
            'about to be answered in person.',
      ),
      ThreadStop(
        title: 'I am the good shepherd',
        passage: 'John 10:11-16',
        note:
            'Jesus claims Ezekiel 34 for himself and goes beyond it: this '
            'shepherd does not only seek the lost, he "giveth his life for '
            'the sheep" — and other sheep, outside the fold, will hear his '
            'voice.',
      ),
      ThreadStop(
        title: 'The chief Shepherd',
        passage: '1 Peter 5:2-4',
        note:
            'Peter — once told "feed my sheep" — passes the charge to every '
            'elder: flocks tended willingly, under "the chief Shepherd" '
            'whose appearing crowns the work.',
      ),
      ThreadStop(
        title: 'The Lamb shall feed them',
        passage: 'Revelation 7:17',
        note:
            'The thread ends in a glorious inversion: the Lamb in the midst '
            'of the throne "shall feed them" — shall shepherd them — "unto '
            'living fountains of waters," and God wipes away every tear.',
      ),
    ],
  ),
  Thread(
    id: 'bread_from_heaven',
    title: 'Bread from Heaven',
    category: ThreadCategory.motif,
    description:
        'Manna is the Bible\'s strangest staple: bread that falls with the '
        'dew, spoils if hoarded, and comes with a lesson attached — man does '
        'not live by bread alone. This walk follows bread from the '
        'wilderness floor to "I am the bread of life," and ends with the '
        'promise of hidden manna.',
    stops: [
      ThreadStop(
        title: 'I will rain bread from heaven',
        passage: 'Exodus 16:4',
        note:
            'A hungry people, and a strange promise: bread from heaven, '
            'gathered "a certain rate every day" — a ration deliberately '
            'designed to teach dependence one morning at a time.',
      ),
      ThreadStop(
        title: 'Man doth not live by bread only',
        passage: 'Deuteronomy 8:2-3',
        note:
            'Forty years later Moses explains the menu: God let them hunger '
            'and fed them with manna "that he might make thee know that man '
            'doth not live by bread only."',
      ),
      ThreadStop(
        title: 'Angels\' food',
        passage: 'Psalms 78:23-25',
        note:
            'The psalmist retells the story with wonder — God "opened the '
            'doors of heaven... man did eat angels\' food" — and with grief, '
            'for the generation that ate it and still did not trust.',
      ),
      ThreadStop(
        title: 'It is written',
        passage: 'Matthew 4:4',
        note:
            'Hungry in the wilderness where Israel was hungry, Jesus answers '
            'the tempter with Deuteronomy 8:3 — and passes the test the '
            'manna generation failed.',
      ),
      ThreadStop(
        title: 'Our daily bread',
        passage: 'Matthew 6:11',
        note:
            'The Lord\'s Prayer builds manna\'s rhythm into everyday '
            'discipleship: bread asked for one day at a time, from the same '
            'Father who once rained it.',
      ),
      ThreadStop(
        title: 'I am the bread of life',
        passage: 'John 6:32-35',
        note:
            'A crowd fed on loaves asks for manna as proof (v. 31); Jesus '
            'answers that the manna was the shadow and he is the substance — '
            'and later in the discourse (v. 51) the living bread is his '
            'flesh, given for the life of the world.',
      ),
      ThreadStop(
        title: 'One bread, one body',
        passage: '1 Corinthians 10:16-17',
        note:
            'At the Lord\'s table the motif becomes communion: "we being '
            'many are one bread, and one body: for we are all partakers of '
            'that one bread."',
      ),
      ThreadStop(
        title: 'The hidden manna',
        passage: 'Revelation 2:17',
        note:
            'The golden pot of manna once kept in the ark reappears as a '
            'promise: "to him that overcometh will I give to eat of the '
            'hidden manna" — wilderness bread, kept for the world to come.',
      ),
    ],
  ),
  Thread(
    id: 'light_in_darkness',
    title: 'Light in the Darkness',
    category: ThreadCategory.motif,
    description:
        'The Bible\'s first recorded words are "Let there be light." This '
        'walk follows light out of that first darkness — a pillar of fire, '
        'a promise to a people in gloom, a great light rising over Galilee — '
        'to the city where there is no night, "for the Lord God giveth them '
        'light."',
    stops: [
      ThreadStop(
        title: 'Let there be light',
        passage: 'Genesis 1:3-4',
        note:
            'Creation begins with light spoken into darkness and divided '
            'from it — the separation the whole thread turns on.',
      ),
      ThreadStop(
        title: 'A pillar of fire by night',
        passage: 'Exodus 13:21-22',
        note:
            'For Israel in the wilderness, light is not an idea but a '
            'presence: God himself goes before them, fire against the dark, '
            'and the pillar never departs.',
      ),
      ThreadStop(
        title: 'The LORD is my light',
        passage: 'Psalms 27:1',
        note:
            'David makes the motif personal and fearless: "The LORD is my '
            'light and my salvation; whom shall I fear?"',
      ),
      ThreadStop(
        title: 'The people that walked in darkness',
        passage: 'Isaiah 9:2',
        note:
            'Isaiah promises light precisely where the dark was thickest — '
            'the humiliated north country of verse 1 — "upon them hath the '
            'light shined." Matthew is watching this verse.',
      ),
      ThreadStop(
        title: 'Arise, shine',
        passage: 'Isaiah 60:1-3',
        note:
            'The promise widens to the world: Zion\'s light rises, "and the '
            'Gentiles shall come to thy light, and kings to the brightness '
            'of thy rising."',
      ),
      ThreadStop(
        title: 'Light springs up in Galilee',
        passage: 'Matthew 4:14-16',
        note:
            'Jesus settles in Capernaum and Matthew quotes Isaiah 9 in '
            'full: the great light has dawned exactly where it was promised.',
      ),
      ThreadStop(
        title: 'Ye are the light of the world',
        passage: 'Matthew 5:14-16',
        note:
            'Astonishingly, Jesus gives the title away — a city on a hill, '
            'a candle on a candlestick — so that men "glorify your Father '
            'which is in heaven."',
      ),
      ThreadStop(
        title: 'I am the light of the world',
        passage: 'John 8:12',
        note:
            'Teaching in the temple treasury (v. 20), Jesus claims the '
            'motif whole: "he that followeth me shall not walk in darkness, '
            'but shall have the light of life."',
      ),
      ThreadStop(
        title: 'Light shined in our hearts',
        passage: '2 Corinthians 4:6',
        note:
            'Paul closes the loop with Genesis 1: the God who commanded '
            'light out of darkness "hath shined in our hearts" — creation\'s '
            'first word repeated in every conversion.',
      ),
      ThreadStop(
        title: 'No night there',
        passage: 'Revelation 22:5',
        note:
            'The thread\'s destination: no candle, no sun, no night — "for '
            'the Lord God giveth them light: and they shall reign for ever '
            'and ever."',
      ),
    ],
  ),
  // ---------------------------------------------------------------------------
  // Covenants & Promises
  // ---------------------------------------------------------------------------
  Thread(
    id: 'the_covenants',
    title: 'The Covenants',
    category: ThreadCategory.covenant,
    description:
        'God binds himself to his people by promise — to Noah, to Abraham, '
        'at Sinai, to David — and when every human party proves faithless, '
        'he promises a new covenant written on the heart. This walk follows '
        'the covenants in order, to the cup Jesus lifts "in my blood" and '
        'the covenant formula spoken over the new creation.',
    stops: [
      ThreadStop(
        title: 'The bow in the cloud',
        passage: 'Genesis 9:8-13',
        note:
            'The first covenant is with every living creature: after the '
            'flood, God hangs up his bow and promises stability to the very '
            'world the rest of the covenants will unfold in.',
      ),
      ThreadStop(
        title: 'Counted for righteousness',
        passage: 'Genesis 15:5-6',
        note:
            'God promises Abram descendants beyond counting, and Abram '
            '"believed in the LORD" — the verse the New Testament returns '
            'to again and again as the shape of covenant faith.',
      ),
      ThreadStop(
        title: 'A kingdom of priests',
        passage: 'Exodus 19:4-6',
        note:
            'At Sinai the family becomes a nation with a vocation: if they '
            'keep the covenant, they will be a kingdom of priests — the '
            'people through whom the nations meet God.',
      ),
      ThreadStop(
        title: 'A house and a throne forever',
        passage: '2 Samuel 7:12-16',
        note:
            'David wants to build God a house; God promises to build David '
            'one instead — a son whose kingdom is established forever. Every '
            'later hope of a Messiah is this promise waiting.',
      ),
      ThreadStop(
        title: 'A new covenant',
        passage: 'Jeremiah 31:31-34',
        note:
            'With the old covenant broken beyond repair, Jeremiah announces '
            'the astonishing next move: a new covenant, the law written on '
            'hearts, sins remembered no more.',
      ),
      ThreadStop(
        title: 'This cup is the new testament',
        passage: 'Luke 22:19-20',
        note:
            'In an upper room at Passover, Jesus takes Jeremiah\'s promise '
            'and locates it in himself: "this cup is the new testament in '
            'my blood."',
      ),
      ThreadStop(
        title: 'Mediator of a better covenant',
        passage: 'Hebrews 8:6-13',
        note:
            'Hebrews quotes Jeremiah 31 in full and draws the conclusion: '
            'in Christ the new covenant is not still coming — it has come, '
            'and the old is ready to vanish away.',
      ),
      ThreadStop(
        title: 'They shall be his people',
        passage: 'Revelation 21:3',
        note:
            'The covenant formula that echoes through the whole Bible — "I '
            'will be their God, and they shall be my people" — is spoken one '
            'last time, over a world where nothing can break it again.',
      ),
    ],
  ),
  Thread(
    id: 'seed_of_the_woman',
    title: 'The Seed of the Woman',
    category: ThreadCategory.covenant,
    description:
        'The Bible\'s first promise is spoken to the serpent: the seed of '
        'the woman will bruise thy head. This walk traces that seed as it '
        'narrows — through Abraham, Judah, and David — to a virgin\'s son, '
        'is named by Paul ("to thy seed, which is Christ"), and faces the '
        'dragon one last time in Revelation 12.',
    stops: [
      ThreadStop(
        title: 'It shall bruise thy head',
        passage: 'Genesis 3:15',
        note:
            'Before any sentence falls on the man and woman, God promises '
            'the serpent its destroyer: the seed of the woman, wounded in '
            'the striking, crushing in the wound. Every later promise in '
            'this walk refines this one.',
      ),
      ThreadStop(
        title: 'In thy seed, all nations',
        passage: 'Genesis 22:17-18',
        note:
            'On Moriah the seed-line is fixed to Abraham, and its scope is '
            'fixed too: "in thy seed shall all the nations of the earth be '
            'blessed."',
      ),
      ThreadStop(
        title: 'Until Shiloh come',
        passage: 'Genesis 49:10',
        note:
            'Jacob\'s deathbed blessing narrows the line again — to Judah, '
            'whose sceptre will not depart "until Shiloh come; and unto him '
            'shall the gathering of the people be."',
      ),
      ThreadStop(
        title: 'Thy seed will I establish for ever',
        passage: 'Psalms 89:3-4',
        note:
            'The promise to David is sung as covenant: "Thy seed will I '
            'establish for ever, and build up thy throne to all '
            'generations." One family now carries the whole thread.',
      ),
      ThreadStop(
        title: 'A virgin shall conceive',
        passage: 'Isaiah 7:14',
        note:
            'To a faithless king of David\'s house, Isaiah gives a sign '
            'that answers Genesis 3\'s odd phrase — the seed of the woman: '
            '"a virgin shall conceive, and bear a son, and shall call his '
            'name Immanuel."',
      ),
      ThreadStop(
        title: 'The book of the generation',
        passage: 'Matthew 1:1',
        note:
            'The New Testament opens with a receipt: "Jesus Christ, the son '
            'of David, the son of Abraham" — the seed-line\'s ledger, '
            'closed and complete.',
      ),
      ThreadStop(
        title: 'Bruised under your feet',
        passage: 'Romans 16:20',
        note:
            'Paul turns Eden\'s promise toward the church: "the God of '
            'peace shall bruise Satan under your feet shortly." The seed\'s '
            'victory is shared with the seed\'s people.',
      ),
      ThreadStop(
        title: 'To thy seed, which is Christ',
        passage: 'Galatians 3:16',
        note:
            'Paul reads Genesis with a jeweller\'s eye: "He saith not, And '
            'to seeds, as of many; but as of one... which is Christ." The '
            'singular seed has a name.',
      ),
      ThreadStop(
        title: 'The dragon stood before the woman',
        passage: 'Revelation 12:1-5',
        note:
            'The whole thread replayed as apocalypse: the woman, the child, '
            'and the dragon waiting to devour him — "and her child was '
            'caught up unto God, and to his throne." Genesis 3:15\'s enmity '
            'ends at the throne.',
      ),
    ],
  ),
  // ---------------------------------------------------------------------------
  // Types & Shadows
  // ---------------------------------------------------------------------------
  Thread(
    id: 'the_lamb',
    title: 'The Lamb',
    category: ThreadCategory.typology,
    description:
        'From Abraham\'s strange assurance on the road up Moriah, through '
        'the Passover night and Isaiah\'s suffering servant, to the Baptist\'s '
        'cry at the Jordan and the throne of heaven itself — the Bible\'s '
        'longest-running picture of substitution: the lamb God provides.',
    stops: [
      ThreadStop(
        title: 'God will provide himself a lamb',
        passage: 'Genesis 22:7-8',
        note:
            'Isaac\'s question — "where is the lamb?" — hangs over the whole '
            'Bible, and Abraham\'s answer sets the thread\'s direction: the '
            'lamb will be God\'s own provision, not ours.',
      ),
      ThreadStop(
        title: 'The Passover lamb',
        passage: 'Exodus 12:3-13',
        note:
            'On the night of the exodus the picture sharpens: a lamb without '
            'blemish, its blood on the doorposts, death passing over. '
            'Substitution becomes the founding memory of Israel.',
      ),
      ThreadStop(
        title: 'As a lamb to the slaughter',
        passage: 'Isaiah 53:6-7',
        note:
            'Isaiah does something new: the lamb is now a person, silent '
            'before his shearers, bearing "the iniquity of us all." The type '
            'has a face.',
      ),
      ThreadStop(
        title: 'Behold the Lamb of God',
        passage: 'John 1:29',
        note:
            'At the Jordan, John the Baptist answers Isaac\'s question by '
            'pointing: "Behold the Lamb of God, which taketh away the sin of '
            'the world."',
      ),
      ThreadStop(
        title: 'Of whom speaketh the prophet this?',
        passage: 'Acts 8:32-35',
        note:
            'An Ethiopian official is reading Isaiah 53 in his chariot and '
            'asks the thread\'s own question — who is the lamb? "Philip... '
            'began at the same scripture, and preached unto him Jesus."',
      ),
      ThreadStop(
        title: 'A lamb without blemish',
        passage: '1 Peter 1:18-19',
        note:
            'Peter gathers Exodus and Isaiah into one sentence: redeemed '
            '"with the precious blood of Christ, as of a lamb without '
            'blemish and without spot."',
      ),
      ThreadStop(
        title: 'A Lamb as it had been slain',
        passage: 'Revelation 5:6-10',
        note:
            'In heaven\'s throne room the conquering Lion turns out to be a '
            'slain Lamb, standing — and the whole of creation sings to him. '
            'The scars are now the credentials.',
      ),
      ThreadStop(
        title: 'The Lamb is the light thereof',
        passage: 'Revelation 21:22-23',
        note:
            'The thread ends with the Lamb not on an altar but on the '
            'throne: the city needs no temple and no sun, "for the glory of '
            'God did lighten it, and the Lamb is the light thereof."',
      ),
    ],
  ),
  Thread(
    id: 'greater_exodus',
    title: 'The Greater Exodus',
    category: ThreadCategory.typology,
    description:
        'The exodus is the Bible\'s master pattern of rescue, and the Bible '
        'itself keeps saying so: the prophets promise a new exodus, Matthew '
        'walks the child Jesus through Israel\'s steps, and at the '
        'transfiguration Moses discusses with Jesus "his decease" — in '
        'Luke\'s Greek, his exodus — "which he should accomplish at '
        'Jerusalem."',
    stops: [
      ThreadStop(
        title: 'Promised to Abram',
        passage: 'Genesis 15:13-14',
        note:
            'The exodus is announced four hundred years before it happens, '
            'inside the covenant ceremony itself: enslavement, judgment on '
            'the enslaver, and a departure "with great substance."',
      ),
      ThreadStop(
        title: 'I will redeem you',
        passage: 'Exodus 6:6-7',
        note:
            'God sets out the rescue as a cascade of "I will"s — bring out, '
            'rid, redeem, take — and welds it to the covenant formula: "I '
            'will take you to me for a people."',
      ),
      ThreadStop(
        title: 'Through the midst of the sea',
        passage: 'Exodus 14:29-31',
        note:
            'The pattern\'s signature scene: walls of water, dry ground, '
            'and a people who on the far shore "believed the LORD."',
      ),
      ThreadStop(
        title: 'Behold, I will do a new thing',
        passage: 'Isaiah 43:16-19',
        note:
            'The prophet invokes the sea-parting God by title, then says '
            'the unthinkable — "remember ye not the former things" — '
            'because a new exodus is coming that will outshine the first.',
      ),
      ThreadStop(
        title: 'Out of Egypt have I called my son',
        passage: 'Hosea 11:1',
        note:
            'Hosea compresses the exodus into a father\'s memory: "when '
            'Israel was a child, then I loved him, and called my son out of '
            'Egypt." Matthew will read this line forward.',
      ),
      ThreadStop(
        title: 'That it might be fulfilled',
        passage: 'Matthew 2:14-15',
        note:
            'The child Jesus goes down to Egypt and comes up again, and '
            'Matthew cites Hosea: Israel\'s story is being rewalked, step '
            'for step, by the Son who will get it right.',
      ),
      ThreadStop(
        title: 'His decease at Jerusalem',
        passage: 'Luke 9:30-31',
        note:
            'At the transfiguration Moses himself appears, talking with '
            'Jesus about "his decease" — Luke\'s word is exodus — "which he '
            'should accomplish at Jerusalem." The cross is the greater '
            'exodus\'s Red Sea.',
      ),
      ThreadStop(
        title: 'Christ our passover',
        passage: '1 Corinthians 5:7',
        note:
            'Paul makes the type explicit in four words: "Christ our '
            'passover is sacrificed for us" — so the church\'s whole life '
            'is the feast that follows.',
      ),
      ThreadStop(
        title: 'The song of Moses, and of the Lamb',
        passage: 'Revelation 15:2-3',
        note:
            'The redeemed stand on the far shore of a sea of glass and sing '
            'the exodus anthem with its final verse added at last: "the '
            'song of Moses... and the song of the Lamb."',
      ),
    ],
  ),
  // ---------------------------------------------------------------------------
  // Names of God
  // ---------------------------------------------------------------------------
  Thread(
    id: 'i_am',
    title: 'I AM: The Name',
    category: ThreadCategory.name,
    description:
        'At the burning bush God gives Moses a name that is really a claim: '
        'I AM THAT I AM. This walk follows the Name through the prophets\' '
        'courtroom speeches to the moment Jesus takes it on his own lips in '
        'Jerusalem — and what it cost him, and where it is honoured at the '
        'last.',
    stops: [
      ThreadStop(
        title: 'The burning bush',
        passage: 'Exodus 3:13-14',
        note:
            'Moses asks for a name to carry back to Egypt and receives "I AM '
            'THAT I AM" — not a label but a declaration of absolute, '
            'underived being. Everything in this thread hangs on these two '
            'verses.',
      ),
      ThreadStop(
        title: 'That is my name',
        passage: 'Isaiah 42:8',
        note:
            '"I am the LORD: that is my name: and my glory will I not give '
            'to another." The Name is exclusive — which is precisely what '
            'makes the thread\'s later stops so startling.',
      ),
      ThreadStop(
        title: 'Ye are my witnesses',
        passage: 'Isaiah 43:10-11',
        note:
            'In Isaiah\'s courtroom scenes the Name becomes a repeated "I am '
            'he" — before me there was no God formed, beside me there is no '
            'saviour. Remember the phrase "I am he."',
      ),
      ThreadStop(
        title: 'Before Abraham was, I am',
        passage: 'John 8:56-58',
        note:
            'In the temple, Jesus reaches past Abraham to the bush: "Before '
            'Abraham was, I am." His hearers understand exactly what he has '
            'claimed — the next verse, they take up stones.',
      ),
      ThreadStop(
        title: 'I am he — and they fell',
        passage: 'John 18:4-6',
        note:
            'At the arrest, Jesus answers "I am he" and the armed cohort '
            'goes backward to the ground — John\'s quiet signal that even '
            'bound, the one being taken carries the Name.',
      ),
      ThreadStop(
        title: 'The name above every name',
        passage: 'Philippians 2:9-11',
        note:
            'Paul\'s hymn gives the crucified Jesus "a name which is above '
            'every name" — and every knee bowing, every tongue confessing, '
            'is Isaiah 45\'s oath to the LORD, now paid to the Lord Jesus.',
      ),
      ThreadStop(
        title: 'Which is, and which was, and which is to come',
        passage: 'Revelation 1:8',
        note:
            'The thread closes with the Name unfolded across time — Alpha '
            'and Omega, "which is, and which was, and which is to come, the '
            'Almighty" — the burning bush\'s claim, spoken over all of '
            'history.',
      ),
    ],
  ),
];
