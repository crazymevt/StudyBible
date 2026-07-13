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
            'the house, and the priests cannot stand to minister. Yet Solomon '
            'already wonders aloud whether any house can hold God.',
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
