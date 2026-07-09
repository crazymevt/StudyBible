import 'prophecy.dart';

/// Hand-curated Old Testament prophecies paired with their New Testament
/// fulfillments, browsable in the reader's Prophecies tool.
///
/// References use canonical KJV book names in the shared "Book C:V" form; every
/// one is validated against `kjvVersification` by `test/prophecy_data_test.dart`.
/// Entries are grouped by [ProphecyCategory]; within the file they are kept in
/// category order so the source reads along the arc of redemptive history.
const List<Prophecy> prophecies = [
  // ---------------------------------------------------------------------------
  // Birth & Incarnation
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'seed_of_woman',
    title: 'The seed of the woman',
    category: ProphecyCategory.birth,
    prophecyText:
        'In the curse on the serpent, God promises that the offspring of the '
        'woman will crush its head, the first hint of a coming deliverer.',
    prophecy: ['Genesis 3:15'],
    fulfillmentText:
        'Paul declares that God sent forth his Son, born of a woman, and that '
        'the God of peace will soon crush Satan underfoot.',
    fulfillment: ['Galatians 4:4', 'Romans 16:20'],
  ),
  Prophecy(
    id: 'seed_of_abraham',
    title: 'Blessing to all nations through Abraham\'s seed',
    category: ProphecyCategory.birth,
    prophecyText:
        'God promises Abraham that in his seed all the families of the earth '
        'will be blessed.',
    prophecy: ['Genesis 12:3', 'Genesis 22:18'],
    fulfillmentText:
        'Paul identifies that single "seed" as Christ, through whom the '
        'blessing of Abraham comes to the Gentiles.',
    fulfillment: ['Galatians 3:16', 'Acts 3:25'],
  ),
  Prophecy(
    id: 'line_of_isaac',
    title: 'Descended from Isaac',
    category: ProphecyCategory.birth,
    prophecyText:
        'God confirms that the covenant line runs through Isaac, not Ishmael.',
    prophecy: ['Genesis 21:12'],
    fulfillmentText: 'Matthew\'s genealogy traces Jesus through Isaac.',
    fulfillment: ['Matthew 1:2', 'Luke 3:34'],
  ),
  Prophecy(
    id: 'line_of_jacob',
    title: 'Descended from Jacob',
    category: ProphecyCategory.birth,
    prophecyText:
        'At Bethel God renews the covenant to Jacob: in his seed all the '
        'families of the earth will be blessed.',
    prophecy: ['Genesis 28:14'],
    fulfillmentText: 'The genealogies record Jesus\' descent through Jacob.',
    fulfillment: ['Matthew 1:2', 'Luke 3:34'],
  ),
  Prophecy(
    id: 'tribe_of_judah',
    title: 'From the tribe of Judah',
    category: ProphecyCategory.birth,
    prophecyText:
        'Jacob prophesies that the sceptre will not depart from Judah until '
        'Shiloh comes, and the obedience of the peoples is his.',
    prophecy: ['Genesis 49:10'],
    fulfillmentText:
        'Hebrews notes the Lord sprang from Judah; Revelation calls him the '
        'Lion of the tribe of Judah.',
    fulfillment: ['Hebrews 7:14', 'Revelation 5:5'],
  ),
  Prophecy(
    id: 'heir_of_david',
    title: 'Heir to the throne of David',
    category: ProphecyCategory.birth,
    prophecyText:
        'God covenants with David that his throne will be established forever, '
        'and Isaiah foretells a child on David\'s throne without end.',
    prophecy: ['2 Samuel 7:12', 'Isaiah 9:7'],
    fulfillmentText:
        'The angel tells Mary that God will give Jesus the throne of his father '
        'David, and he will reign forever.',
    fulfillment: ['Luke 1:32', 'Matthew 1:1'],
  ),
  Prophecy(
    id: 'born_of_virgin',
    title: 'Born of a virgin',
    category: ProphecyCategory.birth,
    prophecyText:
        'Isaiah gives the sign of a virgin who will conceive and bear a son, '
        'and call his name Immanuel.',
    prophecy: ['Isaiah 7:14'],
    fulfillmentText:
        'Matthew records the virgin conception of Jesus as the direct '
        'fulfillment of Immanuel, "God with us".',
    fulfillment: ['Matthew 1:22', 'Luke 1:34'],
  ),
  Prophecy(
    id: 'born_in_bethlehem',
    title: 'Born in Bethlehem',
    category: ProphecyCategory.birth,
    prophecyText:
        'Micah names Bethlehem Ephratah as the birthplace of the ruler whose '
        'goings forth are from of old, from everlasting.',
    prophecy: ['Micah 5:2'],
    fulfillmentText:
        'Jesus is born in Bethlehem of Judea, and the chief priests cite Micah '
        'to Herod.',
    fulfillment: ['Matthew 2:1', 'Luke 2:4'],
  ),
  Prophecy(
    id: 'immanuel_god_with_us',
    title: 'Called Immanuel, "God with us"',
    category: ProphecyCategory.birth,
    prophecyText:
        'The promised child is named Immanuel — God present with his people.',
    prophecy: ['Isaiah 7:14', 'Isaiah 8:8'],
    fulfillmentText:
        'Matthew interprets the name Immanuel as "God with us", fulfilled in '
        'Jesus.',
    fulfillment: ['Matthew 1:23'],
  ),
  Prophecy(
    id: 'mighty_god_titles',
    title: 'The divine titles of the child',
    category: ProphecyCategory.birth,
    prophecyText:
        'Isaiah names the child Wonderful, Counsellor, The mighty God, The '
        'everlasting Father, The Prince of Peace.',
    prophecy: ['Isaiah 9:6'],
    fulfillmentText:
        'John declares the Word was God and became flesh, and the risen Jesus '
        'is confessed as "my Lord and my God".',
    fulfillment: ['John 1:1', 'John 20:28'],
  ),
  Prophecy(
    id: 'star_out_of_jacob',
    title: 'A star shall come out of Jacob',
    category: ProphecyCategory.birth,
    prophecyText:
        'Balaam foretells a star rising out of Jacob and a sceptre out of '
        'Israel.',
    prophecy: ['Numbers 24:17'],
    fulfillmentText:
        'The magi follow his star to worship the newborn King of the Jews.',
    fulfillment: ['Matthew 2:2', 'Matthew 2:9'],
  ),
  Prophecy(
    id: 'gifts_and_worship',
    title: 'Kings bring gifts and worship',
    category: ProphecyCategory.birth,
    prophecyText:
        'Psalm 72 and Isaiah 60 foresee kings bringing gifts of gold and '
        'incense and bowing before him.',
    prophecy: ['Psalms 72:10', 'Isaiah 60:6'],
    fulfillmentText:
        'The magi present gold, frankincense, and myrrh to the child.',
    fulfillment: ['Matthew 2:11'],
  ),
  Prophecy(
    id: 'weeping_in_ramah',
    title: 'Weeping for the children of Bethlehem',
    category: ProphecyCategory.birth,
    prophecyText:
        'Jeremiah hears Rachel weeping for her children, refusing comfort '
        'because they are no more.',
    prophecy: ['Jeremiah 31:15'],
    fulfillmentText:
        'Matthew applies this to Herod\'s slaughter of the infants of '
        'Bethlehem.',
    fulfillment: ['Matthew 2:16', 'Matthew 2:17'],
  ),
  Prophecy(
    id: 'out_of_egypt',
    title: 'Called out of Egypt',
    category: ProphecyCategory.birth,
    prophecyText: 'Hosea recalls that out of Egypt God called his son.',
    prophecy: ['Hosea 11:1'],
    fulfillmentText:
        'The holy family flees to Egypt and returns, which Matthew reads as '
        'this word fulfilled.',
    fulfillment: ['Matthew 2:15'],
  ),

  // ---------------------------------------------------------------------------
  // Life & Ministry
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'preceded_by_messenger',
    title: 'Preceded by a messenger',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Malachi and Isaiah foretell a messenger who prepares the way before '
        'the Lord, a voice crying in the wilderness.',
    prophecy: ['Malachi 3:1', 'Isaiah 40:3'],
    fulfillmentText:
        'John the Baptist is that voice, preparing the way for Jesus.',
    fulfillment: ['Matthew 3:3', 'Mark 1:2'],
  ),
  Prophecy(
    id: 'spirit_of_lord_upon_him',
    title: 'Anointed by the Spirit of the Lord',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah announces that the Spirit of the Lord God is upon the anointed '
        'one to preach good tidings to the poor and liberty to the captives.',
    prophecy: ['Isaiah 61:1', 'Isaiah 11:2'],
    fulfillmentText:
        'Jesus reads Isaiah 61 in the synagogue at Nazareth and declares, '
        '"Today this scripture is fulfilled in your ears".',
    fulfillment: ['Luke 4:18', 'Luke 4:21'],
  ),
  Prophecy(
    id: 'galilee_of_the_gentiles',
    title: 'A great light in Galilee',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah foresees that the land of Zebulun and Naphtali, Galilee of the '
        'nations, will see a great light.',
    prophecy: ['Isaiah 9:1', 'Isaiah 9:2'],
    fulfillmentText:
        'Jesus withdraws to Capernaum in that region and begins to preach, '
        'which Matthew cites as fulfillment.',
    fulfillment: ['Matthew 4:14', 'Matthew 4:16'],
  ),
  Prophecy(
    id: 'prophet_like_moses',
    title: 'A prophet like Moses',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Moses promises that God will raise up a prophet like him from among '
        'their brethren, and they must listen to him.',
    prophecy: ['Deuteronomy 18:15', 'Deuteronomy 18:18'],
    fulfillmentText: 'Peter and Stephen identify Jesus as that prophet.',
    fulfillment: ['Acts 3:22', 'Acts 7:37'],
  ),
  Prophecy(
    id: 'priest_after_melchizedek',
    title: 'A priest after the order of Melchizedek',
    category: ProphecyCategory.ministry,
    prophecyText:
        'David hears the Lord swear that the coming king is a priest forever '
        'after the order of Melchizedek.',
    prophecy: ['Psalms 110:4'],
    fulfillmentText: 'Hebrews expounds Jesus as this eternal high priest.',
    fulfillment: ['Hebrews 5:6', 'Hebrews 7:17'],
  ),
  Prophecy(
    id: 'zeal_for_gods_house',
    title: 'Zeal for God\'s house',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The psalmist confesses that zeal for God\'s house has consumed him.',
    prophecy: ['Psalms 69:9'],
    fulfillmentText:
        'When Jesus cleanses the temple, his disciples remember this word.',
    fulfillment: ['John 2:17'],
  ),
  Prophecy(
    id: 'teaching_in_parables',
    title: 'Teaching in parables',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The psalmist opens his mouth in a parable, uttering dark sayings of '
        'old.',
    prophecy: ['Psalms 78:2'],
    fulfillmentText:
        'Matthew notes that Jesus taught the crowds only in parables, '
        'fulfilling this word.',
    fulfillment: ['Matthew 13:34', 'Matthew 13:35'],
  ),
  Prophecy(
    id: 'healing_ministry',
    title: 'Healing the sick and bearing infirmities',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah says the servant has borne our griefs and carried our '
        'sorrows.',
    prophecy: ['Isaiah 53:4'],
    fulfillmentText:
        'Matthew reports Jesus healing the sick as a fulfillment of Isaiah.',
    fulfillment: ['Matthew 8:16', 'Matthew 8:17'],
  ),
  Prophecy(
    id: 'gentle_servant',
    title: 'The gentle, unassuming servant',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah\'s servant will not cry out or break a bruised reed, and in his '
        'name the Gentiles will hope.',
    prophecy: ['Isaiah 42:1', 'Isaiah 42:3'],
    fulfillmentText:
        'Matthew quotes this after Jesus withdraws quietly and charges the '
        'healed not to make him known.',
    fulfillment: ['Matthew 12:18', 'Matthew 12:20'],
  ),
  Prophecy(
    id: 'light_to_gentiles',
    title: 'A light to the Gentiles',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah appoints the servant as a light to the Gentiles and God\'s '
        'salvation to the ends of the earth.',
    prophecy: ['Isaiah 49:6', 'Isaiah 42:6'],
    fulfillmentText:
        'Simeon blesses the infant Jesus as a light to the Gentiles, and Paul '
        'and Barnabas cite it as their commission.',
    fulfillment: ['Luke 2:32', 'Acts 13:47'],
  ),
  Prophecy(
    id: 'triumphal_entry',
    title: 'Riding into Jerusalem on a donkey',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Zechariah calls Zion to rejoice, for her king comes lowly, riding on '
        'a donkey, on a colt the foal of a donkey.',
    prophecy: ['Zechariah 9:9'],
    fulfillmentText:
        'Jesus enters Jerusalem on a colt while the crowds cry Hosanna.',
    fulfillment: ['Matthew 21:5', 'John 12:15'],
  ),
  Prophecy(
    id: 'rejected_cornerstone',
    title: 'The stone the builders rejected',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The psalmist says the stone the builders refused has become the head '
        'of the corner.',
    prophecy: ['Psalms 118:22', 'Isaiah 28:16'],
    fulfillmentText:
        'Jesus applies this to himself, and Peter proclaims him the rejected '
        'but chief cornerstone.',
    fulfillment: ['Matthew 21:42', 'Acts 4:11'],
  ),
  Prophecy(
    id: 'rejected_by_own',
    title: 'Despised and rejected by his own',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah\'s servant is despised and rejected, and Israel disbelieves the '
        'report.',
    prophecy: ['Isaiah 53:1', 'Isaiah 53:3'],
    fulfillmentText:
        'John laments that despite his signs they did not believe, fulfilling '
        'Isaiah.',
    fulfillment: ['John 12:37', 'John 12:38'],
  ),
  Prophecy(
    id: 'stone_of_stumbling',
    title: 'A stone of stumbling',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah warns that the Lord will be a stone of stumbling and a rock of '
        'offence to both houses of Israel.',
    prophecy: ['Isaiah 8:14'],
    fulfillmentText:
        'Peter and Paul apply this to those who stumble at Christ.',
    fulfillment: ['1 Peter 2:8', 'Romans 9:33'],
  ),

  // ---------------------------------------------------------------------------
  // Betrayal, Trial & Suffering
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'betrayed_by_friend',
    title: 'Betrayed by a close friend',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist grieves that his own familiar friend, who ate his bread, '
        'has lifted up his heel against him.',
    prophecy: ['Psalms 41:9'],
    fulfillmentText:
        'Jesus quotes this at the Last Supper concerning Judas, who betrays '
        'him.',
    fulfillment: ['John 13:18', 'John 13:21'],
  ),
  Prophecy(
    id: 'thirty_pieces_silver',
    title: 'Sold for thirty pieces of silver',
    category: ProphecyCategory.passion,
    prophecyText:
        'Zechariah is weighed out thirty pieces of silver, the price at which '
        'they valued the shepherd.',
    prophecy: ['Zechariah 11:12'],
    fulfillmentText:
        'The chief priests pay Judas thirty pieces of silver to betray Jesus.',
    fulfillment: ['Matthew 26:15', 'Matthew 27:3'],
  ),
  Prophecy(
    id: 'silver_to_potter',
    title: 'The silver thrown to the potter',
    category: ProphecyCategory.passion,
    prophecyText:
        'Zechariah casts the thirty pieces to the potter in the house of the '
        'Lord.',
    prophecy: ['Zechariah 11:13'],
    fulfillmentText:
        'Judas throws the silver into the temple, and it buys the potter\'s '
        'field.',
    fulfillment: ['Matthew 27:7', 'Matthew 27:9'],
  ),
  Prophecy(
    id: 'accused_by_false_witnesses',
    title: 'Accused by false witnesses',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist is beset by false witnesses who lay to his charge things '
        'he did not know.',
    prophecy: ['Psalms 35:11', 'Psalms 27:12'],
    fulfillmentText: 'At his trial false witnesses come forward against Jesus.',
    fulfillment: ['Matthew 26:59', 'Mark 14:57'],
  ),
  Prophecy(
    id: 'silent_before_accusers',
    title: 'Silent before his accusers',
    category: ProphecyCategory.passion,
    prophecyText:
        'Isaiah\'s servant is oppressed and afflicted, yet like a lamb led to '
        'the slaughter he opens not his mouth.',
    prophecy: ['Isaiah 53:7'],
    fulfillmentText:
        'Jesus stays silent before the high priest and Pilate, who marvels.',
    fulfillment: ['Matthew 27:12', 'Matthew 27:14'],
  ),
  Prophecy(
    id: 'smitten_and_spit',
    title: 'Struck and spat upon',
    category: ProphecyCategory.passion,
    prophecyText:
        'Isaiah\'s servant gives his back to the smiters and his cheeks to '
        'those who pluck out the hair, not hiding his face from shame and '
        'spitting.',
    prophecy: ['Isaiah 50:6'],
    fulfillmentText:
        'The soldiers and council spit on Jesus, strike him, and scourge him.',
    fulfillment: ['Matthew 26:67', 'Matthew 27:26'],
  ),
  Prophecy(
    id: 'wounded_for_transgressions',
    title: 'Wounded for our transgressions',
    category: ProphecyCategory.passion,
    prophecyText:
        'Isaiah says the servant was wounded for our transgressions, and with '
        'his stripes we are healed.',
    prophecy: ['Isaiah 53:5'],
    fulfillmentText:
        'Peter proclaims that by his stripes we were healed, bearing our sins '
        'in his body.',
    fulfillment: ['1 Peter 2:24'],
  ),
  Prophecy(
    id: 'sheep_scattered',
    title: 'The disciples scattered',
    category: ProphecyCategory.passion,
    prophecyText:
        'Zechariah hears the command to strike the shepherd so the sheep are '
        'scattered.',
    prophecy: ['Zechariah 13:7'],
    fulfillmentText:
        'Jesus foretells that all will be offended and scattered that night, '
        'and they flee at his arrest.',
    fulfillment: ['Matthew 26:31', 'Matthew 26:56'],
  ),

  // ---------------------------------------------------------------------------
  // Crucifixion & Death
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'numbered_with_transgressors',
    title: 'Numbered with the transgressors',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Isaiah\'s servant is numbered with the transgressors and bears the sin '
        'of many.',
    prophecy: ['Isaiah 53:12'],
    fulfillmentText:
        'Jesus is crucified between two thieves, and cites Isaiah at the '
        'supper.',
    fulfillment: ['Mark 15:27', 'Luke 22:37'],
  ),
  Prophecy(
    id: 'hands_and_feet_pierced',
    title: 'Hands and feet pierced',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The psalmist cries that they pierced his hands and his feet, and he '
        'can count all his bones.',
    prophecy: ['Psalms 22:16'],
    fulfillmentText:
        'The risen Jesus shows Thomas the wounds in his hands and side.',
    fulfillment: ['John 20:25', 'John 20:27'],
  ),
  Prophecy(
    id: 'forsaken_cry',
    title: '"My God, why have you forsaken me?"',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Psalm 22 opens with the cry, "My God, my God, why hast thou forsaken '
        'me?"',
    prophecy: ['Psalms 22:1'],
    fulfillmentText: 'Jesus cries out these very words from the cross.',
    fulfillment: ['Matthew 27:46', 'Mark 15:34'],
  ),
  Prophecy(
    id: 'mocked_and_derided',
    title: 'Mocked and challenged to save himself',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The psalmist is scorned by those who wag their heads and sneer, '
        '"He trusted in the Lord; let him deliver him".',
    prophecy: ['Psalms 22:7', 'Psalms 22:8'],
    fulfillmentText:
        'The passers-by and rulers mock Jesus on the cross in nearly the same '
        'words.',
    fulfillment: ['Matthew 27:39', 'Matthew 27:43'],
  ),
  Prophecy(
    id: 'given_gall_and_vinegar',
    title: 'Given gall and vinegar',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The psalmist is given gall for food and vinegar for his thirst.',
    prophecy: ['Psalms 69:21'],
    fulfillmentText:
        'They offer Jesus wine mingled with gall, and vinegar on a sponge.',
    fulfillment: ['Matthew 27:34', 'John 19:29'],
  ),
  Prophecy(
    id: 'i_thirst',
    title: '"I thirst"',
    category: ProphecyCategory.crucifixion,
    prophecyText: 'The sufferer\'s tongue cleaves to his jaws in Psalm 22.',
    prophecy: ['Psalms 22:15'],
    fulfillmentText:
        'Jesus says "I thirst" so that the scripture might be fulfilled.',
    fulfillment: ['John 19:28'],
  ),
  Prophecy(
    id: 'garments_divided_lots',
    title: 'Garments divided, lots cast for his robe',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The psalmist says they part his garments and cast lots for his '
        'clothing.',
    prophecy: ['Psalms 22:18'],
    fulfillmentText:
        'The soldiers divide Jesus\' garments and cast lots for his seamless '
        'coat, which John cites explicitly.',
    fulfillment: ['John 19:24', 'Matthew 27:35'],
  ),
  Prophecy(
    id: 'no_bones_broken',
    title: 'Not a bone broken',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The Passover lamb must have no bone broken, and the psalmist says God '
        'keeps all his bones.',
    prophecy: ['Exodus 12:46', 'Psalms 34:20'],
    fulfillmentText:
        'The soldiers do not break Jesus\' legs, which John notes fulfills the '
        'scripture.',
    fulfillment: ['John 19:33', 'John 19:36'],
  ),
  Prophecy(
    id: 'pierced_side',
    title: 'His side pierced — "they shall look on me"',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Zechariah foretells that they will look on him whom they have '
        'pierced and mourn.',
    prophecy: ['Zechariah 12:10'],
    fulfillmentText:
        'A soldier pierces Jesus\' side, and John cites Zechariah.',
    fulfillment: ['John 19:34', 'John 19:37'],
  ),
  Prophecy(
    id: 'darkness_over_land',
    title: 'Darkness at noon',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Amos foretells that God will cause the sun to go down at noon and '
        'darken the earth in the clear day.',
    prophecy: ['Amos 8:9'],
    fulfillmentText:
        'Darkness covers the land from the sixth to the ninth hour at the '
        'crucifixion.',
    fulfillment: ['Matthew 27:45', 'Luke 23:44'],
  ),
  Prophecy(
    id: 'commit_my_spirit',
    title: '"Into your hands I commit my spirit"',
    category: ProphecyCategory.crucifixion,
    prophecyText: 'The psalmist commits his spirit into the Lord\'s hand.',
    prophecy: ['Psalms 31:5'],
    fulfillmentText: 'Jesus prays these words as he dies.',
    fulfillment: ['Luke 23:46'],
  ),
  Prophecy(
    id: 'buried_with_rich',
    title: 'Buried with the rich',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Isaiah says the servant was appointed a grave with the wicked but '
        'with the rich in his death.',
    prophecy: ['Isaiah 53:9'],
    fulfillmentText:
        'Joseph of Arimathea, a rich man, lays Jesus in his own new tomb.',
    fulfillment: ['Matthew 27:57', 'Matthew 27:60'],
  ),
  Prophecy(
    id: 'sin_bearer',
    title: 'The atoning sin-bearer',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Isaiah says the Lord laid on him the iniquity of us all, and he made '
        'his soul an offering for sin.',
    prophecy: ['Isaiah 53:6', 'Isaiah 53:10'],
    fulfillmentText:
        'Paul and John declare that Christ died for our sins and is the '
        'propitiation for the sins of the world.',
    fulfillment: ['1 Corinthians 15:3', '1 John 2:2'],
  ),
  Prophecy(
    id: 'lamb_of_god',
    title: 'The Passover lamb',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The unblemished Passover lamb is slain and its blood shields Israel '
        'from death.',
    prophecy: ['Exodus 12:5', 'Exodus 12:13'],
    fulfillmentText:
        'John the Baptist hails Jesus as the Lamb of God, and Paul calls him '
        'our Passover sacrificed for us.',
    fulfillment: ['John 1:29', '1 Corinthians 5:7'],
  ),

  // ---------------------------------------------------------------------------
  // Resurrection & Ascension
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'not_abandoned_to_sheol',
    title: 'Not abandoned to the grave',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'The psalmist trusts that God will not leave his soul in Sheol nor let '
        'his Holy One see corruption.',
    prophecy: ['Psalms 16:10'],
    fulfillmentText:
        'Peter and Paul cite this psalm as fulfilled in the resurrection of '
        'Jesus, whose body saw no decay.',
    fulfillment: ['Acts 2:27', 'Acts 13:35'],
  ),
  Prophecy(
    id: 'raised_third_day',
    title: 'Raised to life',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'Isaiah says that after his soul is made an offering, he will see his '
        'offspring and prolong his days; Hosea speaks of being raised up.',
    prophecy: ['Isaiah 53:10', 'Hosea 6:2'],
    fulfillmentText:
        'Jesus is raised on the third day according to the scriptures.',
    fulfillment: ['1 Corinthians 15:4', 'Luke 24:46'],
  ),
  Prophecy(
    id: 'ascended_on_high',
    title: 'Ascended on high',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'The psalmist sees the Lord ascend on high, leading captivity captive '
        'and receiving gifts for men.',
    prophecy: ['Psalms 68:18'],
    fulfillmentText:
        'Paul applies this to the ascended Christ who gives gifts to the '
        'church.',
    fulfillment: ['Ephesians 4:8', 'Acts 1:9'],
  ),
  Prophecy(
    id: 'seated_at_right_hand',
    title: 'Seated at God\'s right hand',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'The Lord says to David\'s Lord, "Sit thou at my right hand until I '
        'make thine enemies thy footstool".',
    prophecy: ['Psalms 110:1'],
    fulfillmentText:
        'Jesus cites this of himself, and Peter proclaims him exalted to God\'s '
        'right hand.',
    fulfillment: ['Matthew 22:44', 'Acts 2:34'],
  ),
  Prophecy(
    id: 'spirit_poured_out',
    title: 'The Spirit poured out on all flesh',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'Joel foretells that God will pour out his Spirit on all flesh, and '
        'sons and daughters will prophesy.',
    prophecy: ['Joel 2:28'],
    fulfillmentText:
        'Peter declares Pentecost to be this outpouring foretold by Joel.',
    fulfillment: ['Acts 2:16', 'Acts 2:17'],
  ),
  Prophecy(
    id: 'everlasting_dominion',
    title: 'Given everlasting dominion',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'Daniel sees one like a son of man come to the Ancient of Days and '
        'receive dominion, glory, and a kingdom that will not pass away.',
    prophecy: ['Daniel 7:13', 'Daniel 7:14'],
    fulfillmentText:
        'Jesus takes the title Son of Man and claims to come with the clouds '
        'of heaven; the risen Christ holds all authority.',
    fulfillment: ['Matthew 26:64', 'Matthew 28:18'],
  ),

  // ---------------------------------------------------------------------------
  // The Church & New Covenant
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'new_covenant',
    title: 'A new covenant',
    category: ProphecyCategory.church,
    prophecyText:
        'Jeremiah foretells a new covenant with the house of Israel, not like '
        'the one they broke.',
    prophecy: ['Jeremiah 31:31', 'Jeremiah 31:32'],
    fulfillmentText:
        'Jesus institutes the new covenant in his blood, and Hebrews cites '
        'Jeremiah at length.',
    fulfillment: ['Luke 22:20', 'Hebrews 8:8'],
  ),
  Prophecy(
    id: 'law_written_on_hearts',
    title: 'The law written on the heart',
    category: ProphecyCategory.church,
    prophecyText:
        'God promises to put his law in their inward parts and write it on '
        'their hearts.',
    prophecy: ['Jeremiah 31:33'],
    fulfillmentText:
        'Paul says believers are a letter written by the Spirit on hearts of '
        'flesh, and Hebrews applies the promise.',
    fulfillment: ['2 Corinthians 3:3', 'Hebrews 10:16'],
  ),
  Prophecy(
    id: 'new_heart_and_spirit',
    title: 'A new heart and a new spirit',
    category: ProphecyCategory.church,
    prophecyText:
        'Ezekiel foretells a new heart and God\'s Spirit put within his people, '
        'replacing the heart of stone.',
    prophecy: ['Ezekiel 36:26', 'Ezekiel 36:27'],
    fulfillmentText:
        'Jesus tells Nicodemus one must be born of water and the Spirit; Paul '
        'calls it the washing of regeneration.',
    fulfillment: ['John 3:5', 'Titus 3:5'],
  ),
  Prophecy(
    id: 'spirit_poured_thirsty',
    title: 'Rivers of living water',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah promises to pour water on the thirsty and God\'s Spirit on the '
        'offspring.',
    prophecy: ['Isaiah 44:3'],
    fulfillmentText:
        'Jesus promises that rivers of living water — the Spirit — will flow '
        'from the believer.',
    fulfillment: ['John 7:38', 'John 7:39'],
  ),
  Prophecy(
    id: 'circumcised_heart',
    title: 'Circumcision of the heart',
    category: ProphecyCategory.church,
    prophecyText:
        'Moses foretells that God will circumcise their hearts to love him.',
    prophecy: ['Deuteronomy 30:6'],
    fulfillmentText:
        'Paul teaches that true circumcision is of the heart, by the Spirit, '
        'made without hands in Christ.',
    fulfillment: ['Romans 2:29', 'Colossians 2:11'],
  ),
  Prophecy(
    id: 'justified_by_faith',
    title: 'The just shall live by faith',
    category: ProphecyCategory.church,
    prophecyText: 'Habakkuk declares that the just shall live by his faith.',
    prophecy: ['Habakkuk 2:4'],
    fulfillmentText:
        'Paul makes this the heart of the gospel in Romans and Galatians, and '
        'Hebrews urges endurance by it.',
    fulfillment: ['Romans 1:17', 'Galatians 3:11'],
  ),
  Prophecy(
    id: 'faith_counted_righteousness',
    title: 'Faith counted as righteousness',
    category: ProphecyCategory.church,
    prophecyText:
        'Abraham believed the Lord, and it was counted to him for '
        'righteousness.',
    prophecy: ['Genesis 15:6'],
    fulfillmentText:
        'Paul makes Abraham the pattern of justification by faith for all who '
        'believe.',
    fulfillment: ['Romans 4:3', 'Galatians 3:6'],
  ),
  Prophecy(
    id: 'call_on_the_name',
    title: 'Whoever calls on the name of the Lord',
    category: ProphecyCategory.church,
    prophecyText:
        'Joel promises that whoever calls on the name of the Lord will be '
        'delivered.',
    prophecy: ['Joel 2:32'],
    fulfillmentText:
        'Peter proclaims this at Pentecost, and Paul applies it to Jew and '
        'Greek alike.',
    fulfillment: ['Acts 2:21', 'Romans 10:13'],
  ),
  Prophecy(
    id: 'sure_mercies_of_david',
    title: 'The sure mercies of David',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah offers an everlasting covenant, the sure mercies of David.',
    prophecy: ['Isaiah 55:3'],
    fulfillmentText:
        'Paul preaches that God fulfilled these sure mercies by raising Jesus '
        'from the dead.',
    fulfillment: ['Acts 13:34'],
  ),
  Prophecy(
    id: 'root_of_jesse_gentiles',
    title: 'The root of Jesse, hope of the Gentiles',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah sees a root of Jesse standing as an ensign to whom the Gentiles '
        'will seek.',
    prophecy: ['Isaiah 11:10'],
    fulfillmentText:
        'Paul quotes this to show the Gentiles are brought in to hope in '
        'Christ.',
    fulfillment: ['Romans 15:12'],
  ),
  Prophecy(
    id: 'not_my_people',
    title: '"You are my people"',
    category: ProphecyCategory.church,
    prophecyText:
        'Hosea foretells that those called "not my people" will be called sons '
        'of the living God.',
    prophecy: ['Hosea 2:23', 'Hosea 1:10'],
    fulfillmentText:
        'Paul and Peter apply this to the calling of the Gentiles into God\'s '
        'people.',
    fulfillment: ['Romans 9:25', '1 Peter 2:10'],
  ),
  Prophecy(
    id: 'tabernacle_of_david',
    title: 'The rebuilt tabernacle of David',
    category: ProphecyCategory.church,
    prophecyText:
        'Amos foretells the raising of the fallen tent of David so the rest of '
        'mankind may seek the Lord.',
    prophecy: ['Amos 9:11', 'Amos 9:12'],
    fulfillmentText:
        'James cites Amos at the Jerusalem council to affirm the Gentiles\' '
        'inclusion.',
    fulfillment: ['Acts 15:16', 'Acts 15:17'],
  ),
  Prophecy(
    id: 'servant_a_covenant',
    title: 'A covenant for the people',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah appoints the servant as a covenant to the people in the day of '
        'salvation.',
    prophecy: ['Isaiah 49:8'],
    fulfillmentText:
        'Paul declares, "Now is the accepted time; now is the day of '
        'salvation".',
    fulfillment: ['2 Corinthians 6:2'],
  ),
  Prophecy(
    id: 'provoked_by_foolish_nation',
    title: 'Provoked to jealousy by the Gentiles',
    category: ProphecyCategory.church,
    prophecyText:
        'Moses foretells that God will provoke Israel to jealousy by those who '
        'are not a people, a foolish nation.',
    prophecy: ['Deuteronomy 32:21'],
    fulfillmentText:
        'Paul cites this to explain the Gentiles receiving the gospel.',
    fulfillment: ['Romans 10:19', 'Romans 11:11'],
  ),
  Prophecy(
    id: 'deliverer_from_zion',
    title: 'The Deliverer from Zion',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah foretells a Redeemer coming to Zion to turn away ungodliness '
        'from Jacob.',
    prophecy: ['Isaiah 59:20', 'Isaiah 59:21'],
    fulfillmentText:
        'Paul quotes this of Christ, promising that all Israel will be saved.',
    fulfillment: ['Romans 11:26', 'Romans 11:27'],
  ),
  Prophecy(
    id: 'resurrection_of_the_dead',
    title: 'The resurrection of the dead',
    category: ProphecyCategory.church,
    prophecyText:
        'Daniel foretells that many who sleep in the dust will awake, some to '
        'everlasting life and some to shame.',
    prophecy: ['Daniel 12:2'],
    fulfillmentText:
        'Jesus promises that all in the graves will hear his voice and come '
        'forth to the resurrection of life or judgment.',
    fulfillment: ['John 5:28', 'John 5:29'],
  ),
  Prophecy(
    id: 'death_swallowed_up',
    title: 'Death swallowed up in victory',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah foresees death swallowed up forever; Hosea taunts death and '
        'the grave.',
    prophecy: ['Isaiah 25:8', 'Hosea 13:14'],
    fulfillmentText:
        'Paul proclaims the sting of death undone in the resurrection: "O '
        'death, where is thy sting?"',
    fulfillment: ['1 Corinthians 15:54', '1 Corinthians 15:55'],
  ),

  // ---------------------------------------------------------------------------
  // His Reign & Return
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'declared_son_of_god',
    title: 'Declared the Son of God',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The Lord decrees, "Thou art my Son; this day have I begotten thee".',
    prophecy: ['Psalms 2:7'],
    fulfillmentText:
        'The apostles apply this psalm to Jesus\' sonship, resurrection, and '
        'high priesthood.',
    fulfillment: ['Acts 13:33', 'Hebrews 1:5'],
  ),
  Prophecy(
    id: 'rule_nations_rod_iron',
    title: 'Ruling the nations with a rod of iron',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'God grants the anointed King the nations as his inheritance, to rule '
        'them with a rod of iron.',
    prophecy: ['Psalms 2:8', 'Psalms 2:9'],
    fulfillmentText:
        'Revelation gives the same authority to Christ and to those who '
        'overcome.',
    fulfillment: ['Revelation 2:27', 'Revelation 19:15'],
  ),
  Prophecy(
    id: 'every_knee_bow',
    title: 'Every knee shall bow',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The Lord swears that to him every knee will bow and every tongue '
        'confess.',
    prophecy: ['Isaiah 45:23'],
    fulfillmentText:
        'Paul applies this to Christ, before whom every knee will bow, and to '
        'the judgment seat of God.',
    fulfillment: ['Philippians 2:10', 'Romans 14:11'],
  ),
  Prophecy(
    id: 'firstborn_over_kings',
    title: 'The firstborn, highest of the kings',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'God makes David\'s heir his firstborn, higher than the kings of the '
        'earth.',
    prophecy: ['Psalms 89:27'],
    fulfillmentText:
        'Paul and John call Christ the firstborn of all creation and the ruler '
        'of the kings of the earth.',
    fulfillment: ['Colossians 1:15', 'Revelation 1:5'],
  ),
  Prophecy(
    id: 'coming_with_clouds',
    title: 'Coming with the clouds of heaven',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Daniel sees one like a son of man coming with the clouds of heaven.',
    prophecy: ['Daniel 7:13'],
    fulfillmentText:
        'Jesus foretells his return on the clouds, and Revelation declares '
        'that every eye will see him.',
    fulfillment: ['Matthew 24:30', 'Revelation 1:7'],
  ),
  Prophecy(
    id: 'righteous_branch_king',
    title: 'The righteous Branch who reigns',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Jeremiah foretells a righteous Branch raised to David, a King who '
        'will reign and prosper.',
    prophecy: ['Jeremiah 23:5'],
    fulfillmentText:
        'Jesus calls himself the root and offspring of David, and Paul the '
        'root of Jesse who rises to reign.',
    fulfillment: ['Revelation 22:16', 'Romans 15:12'],
  ),
  Prophecy(
    id: 'one_shepherd',
    title: 'One shepherd over the flock',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Ezekiel promises one shepherd, God\'s servant David, set over the '
        'flock.',
    prophecy: ['Ezekiel 34:23'],
    fulfillmentText:
        'Jesus is the good shepherd who gathers one flock, the great shepherd '
        'brought again from the dead.',
    fulfillment: ['John 10:16', 'Hebrews 13:20'],
  ),
  Prophecy(
    id: 'comes_with_reward',
    title: 'Coming to reward and judge',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Isaiah foretells the Lord God coming with a strong hand, his reward '
        'with him.',
    prophecy: ['Isaiah 40:10'],
    fulfillmentText:
        'The risen Christ says, "Behold, I come quickly; and my reward is with '
        'me".',
    fulfillment: ['Revelation 22:12'],
  ),
  Prophecy(
    id: 'judge_the_world',
    title: 'Judging the world in righteousness',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The psalmist declares the Lord comes to judge the earth and the world '
        'in righteousness.',
    prophecy: ['Psalms 96:13', 'Psalms 9:8'],
    fulfillmentText:
        'Paul preaches that God has appointed a man — the risen Jesus — to '
        'judge the world in righteousness.',
    fulfillment: ['Acts 17:31'],
  ),
  Prophecy(
    id: 'books_opened_judgment',
    title: 'The books opened in judgment',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Daniel sees the court seated and the books opened before the Ancient '
        'of Days.',
    prophecy: ['Daniel 7:9', 'Daniel 7:10'],
    fulfillmentText:
        'John sees the dead judged before the throne, out of the things '
        'written in the books.',
    fulfillment: ['Revelation 20:12'],
  ),
  Prophecy(
    id: 'god_dwells_with_men',
    title: 'God dwelling with his people',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Ezekiel promises that God\'s dwelling will be with them; he will be '
        'their God and they his people.',
    prophecy: ['Ezekiel 37:27'],
    fulfillmentText:
        'Paul applies this to the church, and John sees it consummated in the '
        'new Jerusalem.',
    fulfillment: ['2 Corinthians 6:16', 'Revelation 21:3'],
  ),
  Prophecy(
    id: 'new_heavens_new_earth',
    title: 'New heavens and a new earth',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Isaiah foretells God creating new heavens and a new earth, the former '
        'things not remembered.',
    prophecy: ['Isaiah 65:17', 'Isaiah 66:22'],
    fulfillmentText:
        'Peter awaits new heavens and a new earth, and John beholds them.',
    fulfillment: ['2 Peter 3:13', 'Revelation 21:1'],
  ),
  Prophecy(
    id: 'elijah_before_the_day',
    title: 'Elijah before the great day',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Malachi foretells that Elijah the prophet will be sent before the '
        'great and dreadful day of the Lord.',
    prophecy: ['Malachi 4:5', 'Malachi 4:6'],
    fulfillmentText:
        'Jesus identifies John the Baptist as the promised Elijah who has come '
        'in that spirit and power.',
    fulfillment: ['Matthew 17:11', 'Matthew 17:12'],
  ),

  // ---------------------------------------------------------------------------
  // Fulfilled in the Old Testament
  //
  // Old Testament predictions whose fulfillment Scripture itself records, so
  // the fulfillment references here are Old Testament narrative.
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'egypt_four_hundred_years',
    title: 'Four hundred years in Egypt',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'God tells Abraham his offspring will be strangers in a land not '
        'theirs, afflicted four hundred years.',
    prophecy: ['Genesis 15:13'],
    fulfillmentText:
        'Israel dwells in Egypt, and the exodus comes at the appointed time.',
    fulfillment: ['Exodus 12:40', 'Exodus 12:41'],
  ),
  Prophecy(
    id: 'exodus_with_great_wealth',
    title: 'Leaving Egypt with great wealth',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'God promises Abraham that his descendants will come out of bondage '
        'with great possessions.',
    prophecy: ['Genesis 15:14'],
    fulfillmentText:
        'Israel plunders the Egyptians, who give them silver, gold, and '
        'clothing.',
    fulfillment: ['Exodus 12:35', 'Exodus 12:36'],
  ),
  Prophecy(
    id: 'possess_land_of_canaan',
    title: 'Given the land of Canaan',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'God covenants to give Abraham\'s seed the land from the river of Egypt '
        'to the Euphrates.',
    prophecy: ['Genesis 15:18'],
    fulfillmentText:
        'The Lord gives Israel all the land he swore, and not one good promise '
        'fails.',
    fulfillment: ['Joshua 21:43', 'Joshua 21:45'],
  ),
  Prophecy(
    id: 'house_of_eli_judged',
    title: 'Judgment on the house of Eli',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'A man of God foretells that Eli\'s house will be cut off and his two '
        'sons die on the same day.',
    prophecy: ['1 Samuel 2:31', '1 Samuel 2:34'],
    fulfillmentText:
        'Hophni and Phinehas fall together in battle, and Eli\'s line is later '
        'set aside from the priesthood.',
    fulfillment: ['1 Samuel 4:11', '1 Kings 2:27'],
  ),
  Prophecy(
    id: 'ahab_blood_dogs',
    title: 'Dogs would lick up Ahab\'s blood',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Elijah declares that in the place where dogs licked Naboth\'s blood, '
        'dogs will lick up Ahab\'s.',
    prophecy: ['1 Kings 21:19'],
    fulfillmentText:
        'When Ahab dies of his battle wound, the dogs lick his blood at the '
        'pool of Samaria.',
    fulfillment: ['1 Kings 22:38'],
  ),
  Prophecy(
    id: 'jezebel_eaten_by_dogs',
    title: 'Jezebel devoured by dogs',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Elijah foretells that the dogs will eat Jezebel by the wall of '
        'Jezreel.',
    prophecy: ['1 Kings 21:23'],
    fulfillmentText:
        'Jezebel is thrown down and eaten by dogs, exactly as Elijah spoke.',
    fulfillment: ['2 Kings 9:36'],
  ),
  Prophecy(
    id: 'josiah_named_before_birth',
    title: 'Josiah named three centuries early',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'A man of God cries against Jeroboam\'s altar that a child named Josiah '
        'will be born to the house of David and burn the priests\' bones on it.',
    prophecy: ['1 Kings 13:2'],
    fulfillmentText:
        'King Josiah tears down that very altar and burns bones on it, then '
        'spares the prophet\'s tomb.',
    fulfillment: ['2 Kings 23:15', '2 Kings 23:16'],
  ),
  Prophecy(
    id: 'jehu_four_generations',
    title: 'Jehu\'s throne to the fourth generation',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'The Lord promises Jehu that his sons will sit on Israel\'s throne to '
        'the fourth generation.',
    prophecy: ['2 Kings 10:30'],
    fulfillmentText:
        'Jehu\'s line reigns exactly four generations, ending with Zechariah.',
    fulfillment: ['2 Kings 15:12'],
  ),
  Prophecy(
    id: 'sennacherib_spared_jerusalem',
    title: 'Assyria would not take Jerusalem',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Isaiah declares that the king of Assyria will not enter the city nor '
        'shoot an arrow there, but return the way he came.',
    prophecy: ['2 Kings 19:32', 'Isaiah 37:33'],
    fulfillmentText:
        'The angel of the Lord strikes the Assyrian camp, and Sennacherib '
        'withdraws to Nineveh.',
    fulfillment: ['2 Kings 19:35', '2 Kings 19:36'],
  ),
  Prophecy(
    id: 'northern_kingdom_exiled',
    title: 'Israel exiled by Assyria',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Amos and Hosea foretell that the northern kingdom will be carried '
        'captive out of its land.',
    prophecy: ['Amos 7:17', 'Hosea 9:3'],
    fulfillmentText:
        'Assyria captures Samaria and carries Israel away, as the Lord had '
        'warned by his prophets.',
    fulfillment: ['2 Kings 17:6', '2 Kings 17:23'],
  ),
  Prophecy(
    id: 'babylon_captivity_hezekiah',
    title: 'Judah\'s treasures carried to Babylon',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Isaiah warns Hezekiah that all in his house will be carried to '
        'Babylon; nothing will be left.',
    prophecy: ['2 Kings 20:17', 'Isaiah 39:6'],
    fulfillmentText:
        'Nebuchadnezzar carries off the temple and palace treasures to '
        'Babylon.',
    fulfillment: ['2 Kings 24:13'],
  ),
  Prophecy(
    id: 'jerusalem_temple_destroyed',
    title: 'Jerusalem and the temple laid waste',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Micah foretells that Zion will be plowed as a field and the temple '
        'mount become wooded heights.',
    prophecy: ['Micah 3:12', 'Jeremiah 26:18'],
    fulfillmentText:
        'The Babylonians burn the temple and raze the walls of Jerusalem.',
    fulfillment: ['2 Kings 25:9', '2 Chronicles 36:19'],
  ),
  Prophecy(
    id: 'seventy_year_exile',
    title: 'Seventy years of captivity',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Jeremiah foretells that the nations will serve Babylon seventy years, '
        'after which God will visit his people.',
    prophecy: ['Jeremiah 25:11', 'Jeremiah 29:10'],
    fulfillmentText:
        'Daniel reckons the seventy years, and Chronicles notes the land kept '
        'its sabbaths until they were complete.',
    fulfillment: ['Daniel 9:2', '2 Chronicles 36:21'],
  ),
  Prophecy(
    id: 'babylon_falls_to_medes',
    title: 'Babylon falls to the Medes',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Isaiah and Jeremiah name the Medes as those God will stir up against '
        'Babylon.',
    prophecy: ['Isaiah 13:17', 'Jeremiah 51:11'],
    fulfillmentText:
        'Belshazzar is slain the night of the writing on the wall, and Darius '
        'the Mede takes the kingdom.',
    fulfillment: ['Daniel 5:30', 'Daniel 5:31'],
  ),
  Prophecy(
    id: 'cyrus_named_to_restore',
    title: 'Cyrus named to free the exiles',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Isaiah names Cyrus — long before his birth — as the Lord\'s shepherd '
        'who will say of Jerusalem, "She shall be built".',
    prophecy: ['Isaiah 44:28', 'Isaiah 45:1'],
    fulfillmentText:
        'Cyrus issues a decree freeing the Jews to return and rebuild the '
        'house of the Lord.',
    fulfillment: ['Ezra 1:1', 'Ezra 1:2'],
  ),
  Prophecy(
    id: 'temple_rebuilt',
    title: 'The temple rebuilt after exile',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Isaiah foretells that Jerusalem will be inhabited again and the '
        'temple\'s foundation laid.',
    prophecy: ['Isaiah 44:26'],
    fulfillmentText:
        'The returned exiles finish rebuilding the temple in the reign of '
        'Darius.',
    fulfillment: ['Ezra 6:15'],
  ),

  // ---------------------------------------------------------------------------
  // Additional entries (grouped by category at display time)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'opening_blind_and_deaf',
    title: 'Eyes of the blind opened',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah foresees the eyes of the blind opened, the ears of the deaf '
        'unstopped, and the lame leaping.',
    prophecy: ['Isaiah 35:5', 'Isaiah 35:6'],
    fulfillmentText:
        'Jesus points John\'s disciples to exactly these signs: the blind see, '
        'the deaf hear, the lame walk.',
    fulfillment: ['Matthew 11:5', 'Luke 7:22'],
  ),
  Prophecy(
    id: 'shepherd_feeds_flock',
    title: 'The shepherd who feeds his flock',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah pictures the Lord feeding his flock like a shepherd, gathering '
        'the lambs in his arms.',
    prophecy: ['Isaiah 40:11'],
    fulfillmentText:
        'Jesus is moved with compassion for the crowds as sheep without a '
        'shepherd, and calls himself the good shepherd.',
    fulfillment: ['Matthew 9:36', 'John 10:11'],
  ),
  Prophecy(
    id: 'meek_inherit_earth',
    title: 'The meek inherit the earth',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The psalmist promises that the meek will inherit the earth and delight '
        'in abundant peace.',
    prophecy: ['Psalms 37:11'],
    fulfillmentText:
        'Jesus blesses the meek in the Sermon on the Mount, for they will '
        'inherit the earth.',
    fulfillment: ['Matthew 5:5'],
  ),
  Prophecy(
    id: 'bread_from_heaven',
    title: 'Bread from heaven',
    category: ProphecyCategory.ministry,
    prophecyText:
        'God rains down manna, bread from heaven, and the psalmist calls it '
        'the corn of heaven and angels\' food.',
    prophecy: ['Exodus 16:4', 'Psalms 78:24'],
    fulfillmentText:
        'Jesus reveals himself as the true bread from heaven, the bread of '
        'life.',
    fulfillment: ['John 6:31', 'John 6:35'],
  ),
  Prophecy(
    id: 'water_from_the_rock',
    title: 'Water from the rock',
    category: ProphecyCategory.ministry,
    prophecyText:
        'God brings water from the rock at Horeb and Meribah to satisfy '
        'Israel\'s thirst.',
    prophecy: ['Exodus 17:6', 'Numbers 20:11'],
    fulfillmentText:
        'Paul says the rock that followed them was Christ, and Jesus gives the '
        'living water.',
    fulfillment: ['1 Corinthians 10:4'],
  ),
  Prophecy(
    id: 'the_prophet_intercedes',
    title: 'Interceding for the transgressors',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Isaiah\'s servant bears the sin of many and makes intercession for the '
        'transgressors.',
    prophecy: ['Isaiah 53:12'],
    fulfillmentText:
        'From the cross Jesus prays, "Father, forgive them", and he ever lives '
        'to intercede.',
    fulfillment: ['Luke 23:34', 'Hebrews 7:25'],
  ),
  Prophecy(
    id: 'lifted_up_like_serpent',
    title: 'Lifted up like the bronze serpent',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Moses lifts up a bronze serpent on a pole, and all who look on it '
        'live.',
    prophecy: ['Numbers 21:9'],
    fulfillmentText:
        'Jesus says that as Moses lifted up the serpent, so must the Son of '
        'Man be lifted up, that believers may have eternal life.',
    fulfillment: ['John 3:14', 'John 3:15'],
  ),
  Prophecy(
    id: 'day_of_atonement_blood',
    title: 'Atonement by blood',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'On the Day of Atonement the high priest enters the Most Holy Place '
        'with blood to atone for the people.',
    prophecy: ['Leviticus 16:15', 'Leviticus 16:16'],
    fulfillmentText:
        'Christ enters the holy place once for all by his own blood, obtaining '
        'eternal redemption.',
    fulfillment: ['Hebrews 9:12'],
  ),
  Prophecy(
    id: 'friends_stand_afar',
    title: 'Friends standing far off',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The psalmist laments that his loved ones and friends stand aloof from '
        'his affliction.',
    prophecy: ['Psalms 38:11'],
    fulfillmentText:
        'Jesus\' acquaintances and the women who followed him stand at a '
        'distance watching the crucifixion.',
    fulfillment: ['Luke 23:49'],
  ),
  Prophecy(
    id: 'hated_without_cause',
    title: 'Hated without a cause',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist says those who hate him without cause are more than the '
        'hairs of his head.',
    prophecy: ['Psalms 69:4', 'Psalms 35:19'],
    fulfillmentText:
        'Jesus tells his disciples this is fulfilled: "They hated me without a '
        'cause".',
    fulfillment: ['John 15:25'],
  ),
  Prophecy(
    id: 'sign_of_jonah',
    title: 'Three days, like Jonah',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'Jonah is three days and three nights in the belly of the great fish.',
    prophecy: ['Jonah 1:17'],
    fulfillmentText:
        'Jesus gives the sign of Jonah: as Jonah was in the fish, so the Son '
        'of Man will be three days in the heart of the earth.',
    fulfillment: ['Matthew 12:40'],
  ),
  Prophecy(
    id: 'throne_is_forever',
    title: 'His throne, O God, is forever',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The psalmist addresses the King: "Thy throne, O God, is for ever and '
        'ever".',
    prophecy: ['Psalms 45:6', 'Psalms 45:7'],
    fulfillmentText:
        'Hebrews applies these words directly to the Son, whose throne is '
        'eternal.',
    fulfillment: ['Hebrews 1:8', 'Hebrews 1:9'],
  ),
  Prophecy(
    id: 'crowned_with_glory',
    title: 'Crowned with glory and honour',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The psalmist marvels that God made man a little lower than the angels '
        'and crowned him with glory, putting all things under his feet.',
    prophecy: ['Psalms 8:5', 'Psalms 8:6'],
    fulfillmentText:
        'Hebrews and Paul see this fulfilled in Jesus, crowned with glory and '
        'all things subjected to him.',
    fulfillment: ['Hebrews 2:9', '1 Corinthians 15:27'],
  ),
  Prophecy(
    id: 'stone_crushes_kingdoms',
    title: 'The stone that fills the earth',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Daniel interprets a stone cut without hands that shatters the image '
        'and becomes a mountain filling the whole earth — a kingdom that will '
        'never be destroyed.',
    prophecy: ['Daniel 2:34', 'Daniel 2:44'],
    fulfillmentText:
        'Revelation announces that the kingdom of the world has become the '
        'kingdom of our Lord and of his Christ, who reigns forever.',
    fulfillment: ['Revelation 11:15'],
  ),
  Prophecy(
    id: 'dominion_sea_to_sea',
    title: 'Dominion from sea to sea',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The psalmist prays for a king whose dominion reaches from sea to sea, '
        'before whom all kings fall down and all nations serve him.',
    prophecy: ['Psalms 72:8', 'Psalms 72:11'],
    fulfillmentText:
        'Revelation declares Christ King of kings and Lord of lords, reigning '
        'over all.',
    fulfillment: ['Revelation 19:16', 'Revelation 11:15'],
  ),
  Prophecy(
    id: 'not_ashamed_to_call_brethren',
    title: 'Not ashamed to call them brethren',
    category: ProphecyCategory.church,
    prophecyText:
        'The psalmist declares he will proclaim God\'s name to his brethren in '
        'the midst of the congregation.',
    prophecy: ['Psalms 22:22'],
    fulfillmentText:
        'Hebrews says Jesus is not ashamed to call those he sanctifies his '
        'brothers.',
    fulfillment: ['Hebrews 2:12'],
  ),
  Prophecy(
    id: 'the_children_god_gave',
    title: 'The children God has given',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah says, "Behold, I and the children whom the LORD hath given '
        'me".',
    prophecy: ['Isaiah 8:18'],
    fulfillmentText:
        'Hebrews puts these words in the mouth of Christ, who shares flesh and '
        'blood with the children.',
    fulfillment: ['Hebrews 2:13'],
  ),
  Prophecy(
    id: 'sprinkle_many_nations',
    title: 'Sprinkling many nations',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah says the servant will sprinkle many nations, and kings will '
        'shut their mouths at him, for they will see what they had not been '
        'told.',
    prophecy: ['Isaiah 52:15'],
    fulfillmentText:
        'Paul makes it his ambition to preach where Christ was not named, '
        'quoting this promise of the nations who will see and understand.',
    fulfillment: ['Romans 15:21'],
  ),
  Prophecy(
    id: 'royal_priesthood',
    title: 'A kingdom of priests',
    category: ProphecyCategory.church,
    prophecyText:
        'At Sinai God calls Israel to be a kingdom of priests and a holy '
        'nation.',
    prophecy: ['Exodus 19:6'],
    fulfillmentText:
        'Peter and John apply this to the church: a royal priesthood, a holy '
        'nation, made kings and priests to God.',
    fulfillment: ['1 Peter 2:9', 'Revelation 1:6'],
  ),
  Prophecy(
    id: 'anointed_above_fellows',
    title: 'Anointed with the oil of gladness',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The King loves righteousness and is anointed with the oil of gladness '
        'above his fellows.',
    prophecy: ['Psalms 45:7'],
    fulfillmentText:
        'Peter proclaims that God anointed Jesus of Nazareth with the Holy '
        'Spirit and with power.',
    fulfillment: ['Acts 10:38'],
  ),
  Prophecy(
    id: 'presented_as_firstborn',
    title: 'Presented as the firstborn',
    category: ProphecyCategory.birth,
    prophecyText:
        'The law requires that every firstborn male be set apart as holy to '
        'the Lord.',
    prophecy: ['Exodus 13:2'],
    fulfillmentText:
        'Mary and Joseph bring the infant Jesus to Jerusalem to present him to '
        'the Lord as this law commands.',
    fulfillment: ['Luke 2:23'],
  ),
  Prophecy(
    id: 'glory_revealed_to_all',
    title: 'All flesh shall see God\'s salvation',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah foresees the glory of the Lord revealed, and all flesh seeing '
        'it together.',
    prophecy: ['Isaiah 40:5'],
    fulfillmentText:
        'Luke applies this to John\'s preparing the way, so that all flesh '
        'will see the salvation of God.',
    fulfillment: ['Luke 3:6'],
  ),
  Prophecy(
    id: 'rulers_conspire',
    title: 'Rulers conspire against the Anointed',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist asks why the nations rage and the kings and rulers take '
        'counsel together against the Lord and his Anointed.',
    prophecy: ['Psalms 2:1', 'Psalms 2:2'],
    fulfillmentText:
        'The church prays this psalm over Herod and Pilate, who gathered with '
        'the Gentiles and Israel against Jesus.',
    fulfillment: ['Acts 4:26', 'Acts 4:27'],
  ),
  Prophecy(
    id: 'reproaches_fell_on_him',
    title: 'The reproaches fell on him',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist bears reproach: "The reproaches of them that reproached '
        'thee are fallen upon me".',
    prophecy: ['Psalms 69:9'],
    fulfillmentText:
        'Paul applies these words to Christ, who did not please himself but '
        'bore the reproaches meant for God.',
    fulfillment: ['Romans 15:3'],
  ),
  Prophecy(
    id: 'judas_office_taken',
    title: 'Another takes his office',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist prays that the betrayer\'s days be few and another take '
        'his office.',
    prophecy: ['Psalms 109:8'],
    fulfillmentText:
        'Peter cites this psalm to justify choosing Matthias in Judas\' place.',
    fulfillment: ['Acts 1:20'],
  ),
  Prophecy(
    id: 'habitation_left_desolate',
    title: 'His habitation left desolate',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist asks that the betrayer\'s dwelling be made desolate, with '
        'none to dwell in it.',
    prophecy: ['Psalms 69:25'],
    fulfillmentText:
        'Peter joins this to the fate of Judas, whose field became desolate.',
    fulfillment: ['Acts 1:20'],
  ),
  Prophecy(
    id: 'i_come_to_do_your_will',
    title: '"I come to do your will"',
    category: ProphecyCategory.church,
    prophecyText:
        'The psalmist says sacrifice and offering God did not desire, but "Lo, '
        'I come to do thy will, O God".',
    prophecy: ['Psalms 40:6', 'Psalms 40:8'],
    fulfillmentText:
        'Hebrews puts these words in Christ\'s mouth: a body prepared for him '
        'to do God\'s will, replacing the old sacrifices.',
    fulfillment: ['Hebrews 10:5', 'Hebrews 10:7'],
  ),
  Prophecy(
    id: 'descendants_as_the_stars',
    title: 'Descendants as the stars',
    category: ProphecyCategory.church,
    prophecyText:
        'God promises Abraham offspring as numberless as the stars of heaven '
        'and the sand on the shore.',
    prophecy: ['Genesis 22:17'],
    fulfillmentText:
        'Hebrews notes that from one as good as dead came descendants as many '
        'as the stars, and Paul counts all who believe as Abraham\'s children.',
    fulfillment: ['Hebrews 11:12', 'Galatians 3:29'],
  ),
  Prophecy(
    id: 'firstfruits_of_the_dead',
    title: 'The firstfruits of the harvest',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'Israel brings the sheaf of firstfruits, the first of the harvest, and '
        'waves it before the Lord.',
    prophecy: ['Leviticus 23:10'],
    fulfillmentText:
        'Paul proclaims Christ risen as the firstfruits of those who have '
        'fallen asleep.',
    fulfillment: ['1 Corinthians 15:20'],
  ),
  Prophecy(
    id: 'angels_worship_him',
    title: 'Let all the angels worship him',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The psalmist summons all gods — the angels — to worship the Lord.',
    prophecy: ['Psalms 97:7'],
    fulfillmentText:
        'Hebrews says that when God brings the firstborn into the world, "Let '
        'all the angels of God worship him".',
    fulfillment: ['Hebrews 1:6'],
  ),
  Prophecy(
    id: 'slay_wicked_with_breath',
    title: 'Slaying the wicked with his breath',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Isaiah\'s coming king judges the poor with righteousness and slays the '
        'wicked with the breath of his lips.',
    prophecy: ['Isaiah 11:4'],
    fulfillmentText:
        'Paul says the Lord Jesus will slay the lawless one with the breath of '
        'his mouth at his coming.',
    fulfillment: ['2 Thessalonians 2:8'],
  ),
  Prophecy(
    id: 'law_goes_out_from_zion',
    title: 'The word goes out from Jerusalem',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah and Micah foresee the law going out of Zion and the word of '
        'the Lord from Jerusalem to all nations.',
    prophecy: ['Isaiah 2:3', 'Micah 4:2'],
    fulfillmentText:
        'The risen Jesus commissions repentance and forgiveness to be preached '
        'to all nations, beginning at Jerusalem.',
    fulfillment: ['Luke 24:47'],
  ),

  // --- Further Old Testament fulfillments ---
  Prophecy(
    id: 'joseph_foretells_famine',
    title: 'Seven years of famine foretold',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Joseph interprets Pharaoh\'s dreams: seven years of plenty followed by '
        'seven years of famine over the land.',
    prophecy: ['Genesis 41:29', 'Genesis 41:30'],
    fulfillmentText:
        'The seven plentiful years end and the famine comes, exactly as Joseph '
        'had said.',
    fulfillment: ['Genesis 41:54'],
  ),
  Prophecy(
    id: 'josephs_bones_carried',
    title: 'Joseph\'s bones carried from Egypt',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Joseph makes Israel swear that God will visit them and carry his bones '
        'up out of Egypt.',
    prophecy: ['Genesis 50:25'],
    fulfillmentText:
        'At the exodus Moses takes the bones of Joseph, honoring that oath.',
    fulfillment: ['Exodus 13:19'],
  ),
  Prophecy(
    id: 'david_anointed_to_reign',
    title: 'David anointed to be king',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Samuel anoints the young David among his brothers, and the Spirit of '
        'the Lord comes upon him.',
    prophecy: ['1 Samuel 16:12', '1 Samuel 16:13'],
    fulfillmentText: 'Years later all Israel anoints David king at Hebron.',
    fulfillment: ['2 Samuel 5:3'],
  ),
  Prophecy(
    id: 'solomon_builds_temple',
    title: 'David\'s son builds the temple',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'God tells David that his son will build a house for the Lord\'s name.',
    prophecy: ['2 Samuel 7:13'],
    fulfillmentText:
        'Solomon builds and dedicates the temple, fulfilling the word to '
        'David.',
    fulfillment: ['1 Kings 8:20'],
  ),
  Prophecy(
    id: 'micaiah_foretells_ahab_death',
    title: 'Ahab\'s death in battle',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Micaiah sees Israel scattered like sheep without a shepherd, warning '
        'that Ahab will not return in peace.',
    prophecy: ['1 Kings 22:17'],
    fulfillmentText: 'A random arrow strikes Ahab, and he dies that evening.',
    fulfillment: ['1 Kings 22:37'],
  ),
  Prophecy(
    id: 'elisha_foretells_plenty',
    title: 'Plenty in a besieged city',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Elisha foretells that by the next day flour and barley will sell '
        'cheaply at the gate of famine-struck Samaria.',
    prophecy: ['2 Kings 7:1', '2 Kings 7:2'],
    fulfillmentText:
        'The Syrians flee overnight, prices collapse at the gate, and the '
        'scoffing officer is trampled without tasting it — just as Elisha '
        'said.',
    fulfillment: ['2 Kings 7:16', '2 Kings 7:17'],
  ),
  Prophecy(
    id: 'sennacherib_slain_by_sons',
    title: 'Sennacherib slain in his own land',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Isaiah foretells that the Assyrian king will hear a rumor, return to '
        'his own land, and fall by the sword there.',
    prophecy: ['Isaiah 37:7'],
    fulfillmentText:
        'Sennacherib is killed by his own sons as he worships in the temple of '
        'his god.',
    fulfillment: ['2 Kings 19:37'],
  ),
  Prophecy(
    id: 'elijah_shuts_the_heavens',
    title: 'Drought at Elijah\'s word',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Elijah declares there will be neither dew nor rain these years except '
        'by his word.',
    prophecy: ['1 Kings 17:1'],
    fulfillmentText:
        'After the contest on Carmel the heavens grow black and a great rain '
        'finally falls at his word.',
    fulfillment: ['1 Kings 18:45'],
  ),

  // ---------------------------------------------------------------------------
  // Additional verified pairings (batch 3)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'isles_wait_for_his_law',
    title: 'The Gentiles trust in his name',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah\'s servant will not fail nor be discouraged till he has set '
        'judgment in the earth, and the isles wait for his law.',
    prophecy: ['Isaiah 42:4'],
    fulfillmentText:
        'Matthew closes his quotation of the servant song: "And in his name '
        'shall the Gentiles trust".',
    fulfillment: ['Matthew 12:21'],
  ),
  Prophecy(
    id: 'melchizedek_typology',
    title: 'Foreshadowed by Melchizedek',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Melchizedek, king of Salem and priest of the most high God, brings '
        'out bread and wine and blesses Abraham.',
    prophecy: ['Genesis 14:18'],
    fulfillmentText:
        'Hebrews presents this priest-king, without recorded beginning or end, '
        'as a type of the eternal priesthood of Christ.',
    fulfillment: ['Hebrews 7:1', 'Hebrews 7:3'],
  ),
  Prophecy(
    id: 'sun_of_righteousness',
    title: 'The Sun of righteousness',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Malachi foretells the Sun of righteousness rising with healing in his '
        'wings for those who fear God\'s name.',
    prophecy: ['Malachi 4:2'],
    fulfillmentText:
        'Zechariah\'s song hails the dayspring from on high visiting his '
        'people to give light to those in darkness.',
    fulfillment: ['Luke 1:78', 'Luke 1:79'],
  ),
  Prophecy(
    id: 'smitten_with_a_rod',
    title: 'The judge struck with a rod',
    category: ProphecyCategory.passion,
    prophecyText:
        'Micah says they will smite the judge of Israel with a rod upon the '
        'cheek.',
    prophecy: ['Micah 5:1'],
    fulfillmentText:
        'The soldiers strike Jesus on the head with a reed and buffet him.',
    fulfillment: ['Matthew 27:30', 'John 19:3'],
  ),
  Prophecy(
    id: 'taken_from_prison',
    title: 'Taken away by oppression and judgment',
    category: ProphecyCategory.passion,
    prophecyText:
        'Isaiah\'s servant is taken from prison and from judgment, cut off out '
        'of the land of the living.',
    prophecy: ['Isaiah 53:8'],
    fulfillmentText:
        'The Ethiopian eunuch is reading this very passage when Philip tells '
        'him it speaks of Jesus.',
    fulfillment: ['Acts 8:32', 'Acts 8:33'],
  ),
  Prophecy(
    id: 'curse_on_a_tree',
    title: 'Made a curse upon the tree',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The law declares that everyone hanged on a tree is accursed of God.',
    prophecy: ['Deuteronomy 21:23'],
    fulfillmentText:
        'Paul says Christ redeemed us from the curse of the law by becoming a '
        'curse for us, hanged on a tree.',
    fulfillment: ['Galatians 3:13'],
  ),
  Prophecy(
    id: 'scapegoat_bears_sins',
    title: 'The scapegoat bearing sins away',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'On the Day of Atonement the high priest lays the people\'s sins on the '
        'goat, which carries them away into the wilderness.',
    prophecy: ['Leviticus 16:21', 'Leviticus 16:22'],
    fulfillmentText:
        'Hebrews says Christ was once offered to bear the sins of many.',
    fulfillment: ['Hebrews 9:28'],
  ),
  Prophecy(
    id: 'justify_many',
    title: 'Justifying many, bearing their iniquities',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'By his knowledge God\'s righteous servant will justify many, for he '
        'shall bear their iniquities.',
    prophecy: ['Isaiah 53:11'],
    fulfillmentText:
        'Paul says by the obedience of one many are made righteous, and '
        'Hebrews that Christ bore the sins of many.',
    fulfillment: ['Romans 5:19', 'Hebrews 9:28'],
  ),
  Prophecy(
    id: 'exalted_and_lifted_up',
    title: 'The servant highly exalted',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'Isaiah\'s servant, after his suffering, will deal prudently and be '
        'exalted, extolled, and made very high.',
    prophecy: ['Isaiah 52:13'],
    fulfillmentText:
        'Paul proclaims that after his obedience unto death God has highly '
        'exalted Christ and given him the name above every name.',
    fulfillment: ['Philippians 2:9'],
  ),
  Prophecy(
    id: 'the_lord_our_righteousness',
    title: 'THE LORD OUR RIGHTEOUSNESS',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Jeremiah\'s righteous Branch will reign, and this is the name he is '
        'called: THE LORD OUR RIGHTEOUSNESS.',
    prophecy: ['Jeremiah 23:6'],
    fulfillmentText:
        'Paul says Christ is made unto us wisdom, righteousness, '
        'sanctification, and redemption.',
    fulfillment: ['1 Corinthians 1:30'],
  ),
  Prophecy(
    id: 'branch_king_and_priest',
    title: 'The Branch, king and priest',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Zechariah names the man called The BRANCH, who will build the temple '
        'of the Lord and be a priest upon his throne.',
    prophecy: ['Zechariah 6:12', 'Zechariah 6:13'],
    fulfillmentText:
        'Hebrews declares Jesus a high priest seated at the right hand of the '
        'throne of the Majesty in heaven.',
    fulfillment: ['Hebrews 8:1'],
  ),
  Prophecy(
    id: 'heavens_and_earth_shaken',
    title: 'Shaking the heavens and the earth',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Haggai foretells that once more God will shake the heavens and the '
        'earth, the sea and the dry land.',
    prophecy: ['Haggai 2:6'],
    fulfillmentText:
        'Hebrews cites this of a final shaking, leaving a kingdom that cannot '
        'be moved.',
    fulfillment: ['Hebrews 12:26', 'Hebrews 12:28'],
  ),
  Prophecy(
    id: 'sought_by_gentiles',
    title: 'Found by those who sought him not',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah says the Lord is found of them that sought him not, made '
        'manifest to those who asked not for him.',
    prophecy: ['Isaiah 65:1'],
    fulfillmentText:
        'Paul quotes this to show the Gentiles finding the God whom Israel had '
        'not sought.',
    fulfillment: ['Romans 10:20'],
  ),
  Prophecy(
    id: 'house_of_prayer_all_nations',
    title: 'A house of prayer for all nations',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah foretells that God\'s house will be called a house of prayer '
        'for all people.',
    prophecy: ['Isaiah 56:7'],
    fulfillmentText:
        'Jesus cleanses the temple, quoting Isaiah: "My house shall be called '
        'of all nations the house of prayer".',
    fulfillment: ['Mark 11:17'],
  ),
  Prophecy(
    id: 'fountain_for_sin',
    title: 'A fountain opened for sin',
    category: ProphecyCategory.church,
    prophecyText:
        'Zechariah foretells a fountain opened to the house of David for sin '
        'and for uncleanness.',
    prophecy: ['Zechariah 13:1'],
    fulfillmentText:
        'John says the blood of Jesus cleanses from all sin, and Hebrews that '
        'it purges the conscience.',
    fulfillment: ['1 John 1:7', 'Hebrews 9:14'],
  ),

  // --- Further Old Testament fulfillments (batch 3) ---
  Prophecy(
    id: 'sign_against_the_altar',
    title: 'The altar torn as a sign',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'The man of God gives a sign against Jeroboam\'s altar: it will be '
        'rent and its ashes poured out.',
    prophecy: ['1 Kings 13:3'],
    fulfillmentText:
        'That same hour the altar is rent and the ashes pour out, exactly as '
        'the sign said.',
    fulfillment: ['1 Kings 13:5'],
  ),
  Prophecy(
    id: 'jeroboam_hand_withered',
    title: 'Jeroboam\'s withered hand restored',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'When Jeroboam stretches out his hand against the prophet, it dries up '
        'so he cannot pull it back.',
    prophecy: ['1 Kings 13:4'],
    fulfillmentText:
        'At the prophet\'s prayer the king\'s hand is restored again.',
    fulfillment: ['1 Kings 13:6'],
  ),
  Prophecy(
    id: 'ahijah_foretells_child_death',
    title: 'The child dies at the threshold',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Ahijah tells Jeroboam\'s wife that the child will die the moment her '
        'feet enter the city.',
    prophecy: ['1 Kings 14:12'],
    fulfillmentText:
        'As she reaches the threshold of the door, the child dies.',
    fulfillment: ['1 Kings 14:17'],
  ),
  Prophecy(
    id: 'hezekiah_sundial_sign',
    title: 'The shadow turned back',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Isaiah offers Hezekiah a sign that the Lord will heal him: the shadow '
        'on the dial will go back ten degrees.',
    prophecy: ['2 Kings 20:9'],
    fulfillmentText:
        'Isaiah cries to the Lord, and the shadow returns ten degrees.',
    fulfillment: ['2 Kings 20:11'],
  ),
  Prophecy(
    id: 'elijah_taken_to_heaven',
    title: 'Elijah taken up in a whirlwind',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Elijah tells Elisha that if he sees him taken away, a double portion '
        'of his spirit will rest on him.',
    prophecy: ['2 Kings 2:10'],
    fulfillmentText:
        'A chariot of fire parts them, and Elijah goes up by a whirlwind into '
        'heaven as Elisha watches.',
    fulfillment: ['2 Kings 2:11'],
  ),
  Prophecy(
    id: 'hazael_becomes_king',
    title: 'Hazael foretold to reign over Syria',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Elisha weeps and tells Hazael the Lord has shown him that he will be '
        'king over Syria.',
    prophecy: ['2 Kings 8:13'],
    fulfillmentText:
        'Hazael returns, kills Ben-hadad, and reigns in his place.',
    fulfillment: ['2 Kings 8:15'],
  ),
  Prophecy(
    id: 'ahab_house_cut_off',
    title: 'The house of Ahab cut off',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Elijah declares that the Lord will take away Ahab\'s posterity and cut '
        'off every male of his house.',
    prophecy: ['1 Kings 21:21'],
    fulfillmentText:
        'Jehu slays all that remained of the house of Ahab in Samaria.',
    fulfillment: ['2 Kings 10:17'],
  ),
  Prophecy(
    id: 'josiah_gathered_in_peace',
    title: 'Josiah spared the coming judgment',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'The prophetess Huldah tells Josiah he will be gathered to his grave '
        'in peace and not see the evil coming on Jerusalem.',
    prophecy: ['2 Kings 22:20'],
    fulfillmentText:
        'Josiah dies and is buried in Jerusalem before Babylon destroys the '
        'city.',
    fulfillment: ['2 Kings 23:30'],
  ),

  // ---------------------------------------------------------------------------
  // Further Messianic prophecies (batch 4)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'called_a_nazarene',
    title: 'He shall be called a Nazarene',
    category: ProphecyCategory.birth,
    prophecyText:
        'Isaiah calls the coming king a "Branch" (Hebrew netzer) growing from '
        'the stump of Jesse\'s royal line.',
    prophecy: ['Isaiah 11:1'],
    fulfillmentText:
        'Matthew records that Jesus\' family settled in Nazareth, fulfilling '
        'what was spoken by the prophets: "He shall be called a Nazarene."',
    fulfillment: ['Matthew 2:23'],
  ),
  Prophecy(
    id: 'lord_suddenly_to_his_temple',
    title: 'The Lord suddenly comes to his temple',
    category: ProphecyCategory.birth,
    prophecyText:
        'Malachi foretells that the Lord whom Israel seeks will suddenly come '
        'to his temple.',
    prophecy: ['Malachi 3:1'],
    fulfillmentText:
        'Mary and Joseph bring the infant Jesus into the temple, where Simeon '
        'takes him up and blesses God for the salvation his eyes have seen.',
    fulfillment: ['Luke 2:27-32'],
  ),
  Prophecy(
    id: 'goings_forth_from_everlasting',
    title: 'His goings forth from everlasting',
    category: ProphecyCategory.birth,
    prophecyText:
        'Micah says the ruler born in Bethlehem has "goings forth" that have '
        'been from of old, from everlasting.',
    prophecy: ['Micah 5:2'],
    fulfillmentText: 'Jesus tells the Jews, "Before Abraham was, I am."',
    fulfillment: ['John 8:58'],
  ),
  Prophecy(
    id: 'named_from_the_womb',
    title: 'Named from the womb',
    category: ProphecyCategory.birth,
    prophecyText:
        'The Lord\'s servant says he was called from the womb, his name made '
        'mention of before he was born.',
    prophecy: ['Isaiah 49:1'],
    fulfillmentText:
        'The angel tells Joseph the child\'s name before his birth: "thou '
        'shalt call his name JESUS."',
    fulfillment: ['Matthew 1:21'],
  ),
  Prophecy(
    id: 'no_form_or_comeliness',
    title: 'No beauty that we should desire him',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah describes the servant growing up like a root out of dry '
        'ground, with no form or comeliness to attract attention.',
    prophecy: ['Isaiah 53:2'],
    fulfillmentText:
        'Paul writes that Christ made himself of no reputation, taking the '
        'form of a servant, made in the likeness of men.',
    fulfillment: ['Philippians 2:7'],
  ),
  Prophecy(
    id: 'voice_in_the_wilderness',
    title: 'A voice crying in the wilderness',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah hears a voice crying in the wilderness, "Prepare ye the way '
        'of the Lord."',
    prophecy: ['Isaiah 40:3'],
    fulfillmentText:
        'Matthew identifies John the Baptist as the one spoken of by Isaiah, '
        'preparing the way before Jesus.',
    fulfillment: ['Matthew 3:3'],
  ),
  Prophecy(
    id: 'grace_poured_on_his_lips',
    title: 'Grace poured into his lips',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The royal psalm says of the coming king, "grace is poured into thy '
        'lips: therefore God hath blessed thee for ever."',
    prophecy: ['Psalms 45:2'],
    fulfillmentText:
        'In the Nazareth synagogue, all bear witness and wonder at the '
        'gracious words proceeding from his mouth.',
    fulfillment: ['Luke 4:22'],
  ),
  Prophecy(
    id: 'gathers_the_outcasts_of_israel',
    title: 'Gathering the outcasts of Israel',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The Lord declares he will gather the outcasts of Israel, and '
        'others besides, to himself.',
    prophecy: ['Isaiah 56:8'],
    fulfillmentText:
        'Jesus says he has other sheep not of this fold that he must also '
        'bring, until there is one flock, one shepherd.',
    fulfillment: ['John 10:16'],
  ),
  Prophecy(
    id: 'dead_men_shall_live',
    title: 'Thy dead men shall live',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah promises, "Thy dead men shall live... awake and sing."',
    prophecy: ['Isaiah 26:19'],
    fulfillmentText:
        'At Nain, Jesus touches the bier of a widow\'s dead son and raises '
        'him: the young man sits up and speaks.',
    fulfillment: ['Luke 7:14-15'],
  ),
  Prophecy(
    id: 'tongue_of_the_learned',
    title: 'The tongue of the learned',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The servant is given "the tongue of the learned," to speak a word '
        'in season to the weary.',
    prophecy: ['Isaiah 50:4'],
    fulfillmentText:
        'Jesus calls out to the weary and heavy laden, offering them rest.',
    fulfillment: ['Matthew 11:28'],
  ),
  Prophecy(
    id: 'a_witness_to_the_people',
    title: 'A witness to the people',
    category: ProphecyCategory.ministry,
    prophecyText:
        'God gives his servant "for a witness to the people, a leader and '
        'commander to the people."',
    prophecy: ['Isaiah 55:4'],
    fulfillmentText:
        'John calls Jesus Christ "the faithful witness... the prince of the '
        'kings of the earth."',
    fulfillment: ['Revelation 1:5'],
  ),
  Prophecy(
    id: 'blessed_is_he_that_cometh',
    title: '"Blessed is he that cometh in the name of the Lord"',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The psalmist blesses the one who comes in the name of the Lord.',
    prophecy: ['Psalms 118:26'],
    fulfillmentText:
        'The crowds greet Jesus\' entry into Jerusalem with these very words.',
    fulfillment: ['Matthew 21:9'],
  ),
  Prophecy(
    id: 'stranger_to_his_brethren',
    title: 'A stranger unto his brethren',
    category: ProphecyCategory.passion,
    prophecyText:
        'The sufferer laments becoming "a stranger unto my brethren, and an '
        'alien unto my mother\'s children."',
    prophecy: ['Psalms 69:8'],
    fulfillmentText:
        'John records that even Jesus\' own brothers did not believe in him.',
    fulfillment: ['John 7:5'],
  ),
  Prophecy(
    id: 'no_man_to_comfort_him',
    title: 'None to comfort him',
    category: ProphecyCategory.passion,
    prophecyText:
        'Reproach has broken his heart; he looks for comforters and finds '
        'none.',
    prophecy: ['Psalms 69:20'],
    fulfillmentText:
        'In Gethsemane, Jesus\' soul is exceeding sorrowful, even unto '
        'death, as he asks his sleeping disciples to watch with him.',
    fulfillment: ['Matthew 26:38'],
  ),
  Prophecy(
    id: 'satan_stands_at_his_right_hand',
    title: 'Satan stands at his right hand',
    category: ProphecyCategory.passion,
    prophecyText:
        'Of the betrayer the psalmist says, "let Satan stand at his right '
        'hand."',
    prophecy: ['Psalms 109:6'],
    fulfillmentText: 'Luke records that Satan entered into Judas Iscariot.',
    fulfillment: ['Luke 22:3'],
  ),
  Prophecy(
    id: 'set_his_face_like_flint',
    title: 'Set his face like a flint',
    category: ProphecyCategory.passion,
    prophecyText:
        'The servant sets his face "like a flint," resolved not to be '
        'ashamed.',
    prophecy: ['Isaiah 50:7'],
    fulfillmentText:
        'Jesus steadfastly sets his face to go to Jerusalem, knowing what '
        'awaits him there.',
    fulfillment: ['Luke 9:51'],
  ),
  Prophecy(
    id: 'they_devised_to_take_his_life',
    title: 'They devised to take away his life',
    category: ProphecyCategory.passion,
    prophecyText:
        'Surrounded by slander, the psalmist says his enemies "took counsel '
        'together against me, they devised to take away my life."',
    prophecy: ['Psalms 31:13'],
    fulfillmentText:
        'The chief priests and elders take counsel to seize Jesus by '
        'subtlety and kill him.',
    fulfillment: ['Matthew 26:4'],
  ),
  Prophecy(
    id: 'god_did_not_hide_his_face',
    title: 'His cry was heard',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist says God did not hide his face from the afflicted, '
        'but heard when he cried.',
    prophecy: ['Psalms 22:24'],
    fulfillmentText:
        'The writer to the Hebrews says Jesus offered up prayers with '
        'strong crying and tears, "and was heard in that he feared."',
    fulfillment: ['Hebrews 5:7'],
  ),
  Prophecy(
    id: 'a_worm_and_no_man',
    title: '"I am a worm, and no man"',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The sufferer of Psalm 22 is despised as "a worm, and no man; a '
        'reproach of men."',
    prophecy: ['Psalms 22:6'],
    fulfillmentText:
        'Jesus tells his disciples it is written of the Son of man that he '
        'must suffer many things and "be set at nought."',
    fulfillment: ['Mark 9:12'],
  ),
  Prophecy(
    id: 'heart_melted_like_wax',
    title: 'Poured out like water',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        '"I am poured out like water... my heart is like wax; it is melted '
        'in the midst of my bowels."',
    prophecy: ['Psalms 22:14'],
    fulfillmentText:
        'A soldier pierces Jesus\' side with a spear, and forthwith blood '
        'and water come out.',
    fulfillment: ['John 19:34'],
  ),
  Prophecy(
    id: 'may_tell_all_my_bones',
    title: '"I may tell all my bones"',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The sufferer\'s body is so exposed that "they look and stare upon '
        'me."',
    prophecy: ['Psalms 22:17'],
    fulfillmentText:
        'The people stand beholding the crucifixion while the rulers deride '
        'him.',
    fulfillment: ['Luke 23:35'],
  ),
  Prophecy(
    id: 'iniquity_removed_in_one_day',
    title: 'Iniquity removed in one day',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The Lord promises to remove the iniquity of the land "in one day."',
    prophecy: ['Zechariah 3:9'],
    fulfillmentText:
        'Hebrews says Christ appeared once, in the end of the world, "to '
        'put away sin by the sacrifice of himself."',
    fulfillment: ['Hebrews 9:26'],
  ),
  Prophecy(
    id: 'blood_makes_atonement',
    title: 'The blood makes atonement',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The law of sacrifice teaches that "it is the blood that maketh an '
        'atonement for the soul."',
    prophecy: ['Leviticus 17:11'],
    fulfillmentText:
        'Hebrews concludes that "without shedding of blood is no remission."',
    fulfillment: ['Hebrews 9:22'],
  ),
  Prophecy(
    id: 'isaac_carries_the_wood',
    title: 'Isaac carries the wood',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Abraham lays the wood of the burnt offering on Isaac, his '
        'only son, for the journey to Moriah — a scene Hebrews later calls '
        'a figure of resurrection.',
    prophecy: ['Genesis 22:6'],
    fulfillmentText:
        'Jesus goes out bearing his own cross to the place called Golgotha.',
    fulfillment: ['John 19:17'],
  ),
  Prophecy(
    id: 'wounds_in_the_house_of_my_friends',
    title: 'Wounded in the house of my friends',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'Asked about wounds in his hands, the figure in Zechariah\'s '
        'vision answers, "those with which I was wounded in the house of '
        'my friends."',
    prophecy: ['Zechariah 13:6'],
    fulfillmentText:
        'The risen Jesus shows the disciples his hands and his side, and '
        'they are glad.',
    fulfillment: ['John 20:20'],
  ),
  Prophecy(
    id: 'path_of_life_fulness_of_joy',
    title: 'The path of life',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'David says God will show him "the path of life," and fulness of '
        'joy in his presence.',
    prophecy: ['Psalms 16:11'],
    fulfillmentText:
        'Peter, at Pentecost, quotes this psalm of David as testimony to '
        'the resurrection of Christ.',
    fulfillment: ['Acts 2:28'],
  ),
  Prophecy(
    id: 'my_redeemer_liveth',
    title: '"I know that my redeemer liveth"',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'Job declares his confidence that his redeemer lives, and will '
        'stand at the latter day upon the earth.',
    prophecy: ['Job 19:25'],
    fulfillmentText:
        'The risen Christ declares, "I am he that liveth, and was dead; '
        'and, behold, I am alive for evermore."',
    fulfillment: ['Revelation 1:18'],
  ),
  Prophecy(
    id: 'king_of_glory_shall_come_in',
    title: 'The King of glory shall come in',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'The psalmist calls for the everlasting doors to lift up, that the '
        'King of glory may come in.',
    prophecy: ['Psalms 24:7'],
    fulfillmentText:
        'Jesus is taken up into heaven, a cloud receiving him out of the '
        'disciples\' sight.',
    fulfillment: ['Acts 1:9'],
  ),
  Prophecy(
    id: 'a_seed_shall_serve_him',
    title: 'A seed shall serve him',
    category: ProphecyCategory.church,
    prophecyText:
        'Psalm 22 ends with a people yet to be born, who will be told what '
        'the Lord has done.',
    prophecy: ['Psalms 22:30-31'],
    fulfillmentText:
        'Jesus sends his disciples to teach and baptize all nations, in '
        'the name of the Father, Son, and Holy Ghost.',
    fulfillment: ['Matthew 28:19'],
  ),
  Prophecy(
    id: 'the_kings_glorious_bride',
    title: 'The king\'s glorious bride',
    category: ProphecyCategory.church,
    prophecyText:
        'The royal wedding psalm pictures the king\'s daughter, "all '
        'glorious within," brought to him in fine needlework.',
    prophecy: ['Psalms 45:13-14'],
    fulfillmentText:
        'Revelation pictures the marriage of the Lamb come, his wife '
        'having made herself ready.',
    fulfillment: ['Revelation 19:7'],
  ),
  Prophecy(
    id: 'children_made_princes',
    title: 'Children made princes',
    category: ProphecyCategory.church,
    prophecyText:
        'In place of fathers, the king will have children "whom thou '
        'mayest make princes in all the earth."',
    prophecy: ['Psalms 45:16'],
    fulfillmentText:
        'John writes that Christ has made believers "kings and priests," '
        'to reign on the earth.',
    fulfillment: ['Revelation 5:10'],
  ),
  Prophecy(
    id: 'covenant_sworn_to_david',
    title: 'The covenant sworn to David',
    category: ProphecyCategory.church,
    prophecyText:
        'The Lord swears to David that his seed will be established '
        'forever, his throne built up to all generations.',
    prophecy: ['Psalms 89:3-4'],
    fulfillmentText:
        'Gabriel tells Mary that the Lord God will give her son "the '
        'throne of his father David."',
    fulfillment: ['Luke 1:32'],
  ),
  Prophecy(
    id: 'beautiful_feet_good_tidings',
    title: 'Beautiful feet, good tidings',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah praises the feet of the messenger who publishes peace and '
        'good tidings, telling Zion, "Thy God reigneth!"',
    prophecy: ['Isaiah 52:7'],
    fulfillmentText:
        'Paul quotes this verse of those sent to preach the gospel of '
        'peace.',
    fulfillment: ['Romans 10:15'],
  ),
  Prophecy(
    id: 'pure_language_to_the_peoples',
    title: 'A pure language to the peoples',
    category: ProphecyCategory.church,
    prophecyText:
        'Zephaniah foresees a day when the Lord turns the peoples "a pure '
        'language," that they may call on his name with one consent.',
    prophecy: ['Zephaniah 3:9'],
    fulfillmentText:
        'At Pentecost, all are filled with the Holy Ghost and speak with '
        'other tongues, as the Spirit gives utterance.',
    fulfillment: ['Acts 2:4'],
  ),
  Prophecy(
    id: 'all_thy_children_taught_of_god',
    title: 'All thy children taught of the Lord',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah promises that all the Lord\'s children "shall be taught of '
        'the Lord," in great peace.',
    prophecy: ['Isaiah 54:13'],
    fulfillmentText:
        'Jesus quotes this promise directly: "It is written in the '
        'prophets, And they shall be all taught of God."',
    fulfillment: ['John 6:45'],
  ),
  Prophecy(
    id: 'the_lord_is_her_husband',
    title: 'Thy Maker is thine husband',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah tells Zion, "thy Maker is thine husband; the Lord of hosts '
        'is his name."',
    prophecy: ['Isaiah 54:5'],
    fulfillmentText:
        'Paul tells husbands to love their wives "even as Christ also '
        'loved the church, and gave himself for it."',
    fulfillment: ['Ephesians 5:25'],
  ),
  Prophecy(
    id: 'king_set_on_zion',
    title: 'My king upon my holy hill of Zion',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'God declares of his anointed, "I have set my king upon my holy '
        'hill of Zion."',
    prophecy: ['Psalms 2:6'],
    fulfillmentText:
        'John sees the Lamb standing on mount Sion with the redeemed.',
    fulfillment: ['Revelation 14:1'],
  ),
  Prophecy(
    id: 'kiss_the_son',
    title: '"Kiss the Son"',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The psalm warns the nations to submit to God\'s king: "Kiss the '
        'Son... blessed are all they that put their trust in him."',
    prophecy: ['Psalms 2:12'],
    fulfillmentText:
        'Jesus says all should honour the Son, even as they honour the '
        'Father.',
    fulfillment: ['John 5:23'],
  ),
  Prophecy(
    id: 'he_shall_judge_with_righteousness',
    title: 'He shall judge with righteousness',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The royal psalm asks that the king "judge thy people with '
        'righteousness, and thy poor with judgment."',
    prophecy: ['Psalms 72:2'],
    fulfillmentText:
        'John sees the rider called Faithful and True, who "in '
        'righteousness doth judge and make war."',
    fulfillment: ['Revelation 19:11'],
  ),
  Prophecy(
    id: 'abundance_of_peace',
    title: 'Abundance of peace',
    category: ProphecyCategory.kingdom,
    prophecyText:
        '"In his days shall the righteous flourish; and abundance of '
        'peace so long as the moon endureth."',
    prophecy: ['Psalms 72:7'],
    fulfillmentText:
        'John sees the souls of the faithful reigning with Christ a '
        'thousand years.',
    fulfillment: ['Revelation 20:4'],
  ),
  Prophecy(
    id: 'his_name_shall_endure_forever',
    title: 'His name shall endure forever',
    category: ProphecyCategory.kingdom,
    prophecyText:
        '"His name shall endure for ever... and men shall be blessed in '
        'him: all nations shall call him blessed."',
    prophecy: ['Psalms 72:17'],
    fulfillmentText:
        'Gabriel tells Mary he shall reign over the house of Jacob '
        'forever, "and of his kingdom there shall be no end."',
    fulfillment: ['Luke 1:33'],
  ),
  Prophecy(
    id: 'all_the_earth_shall_worship',
    title: 'All the earth shall worship',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Psalm 22 foresees "all they that be fat upon earth" eating and '
        'worshiping, and "all they that go down to the dust" bowing before '
        'him.',
    prophecy: ['Psalms 22:29'],
    fulfillmentText:
        'John hears every creature in heaven, earth, and sea giving glory '
        'to him who sits on the throne, and to the Lamb.',
    fulfillment: ['Revelation 5:13'],
  ),
  Prophecy(
    id: 'dominion_out_of_jacob',
    title: 'Dominion out of Jacob',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Balaam prophesies, "Out of Jacob shall come he that shall have '
        'dominion."',
    prophecy: ['Numbers 24:19'],
    fulfillmentText:
        'John hears the voice of a great multitude declaring, "the Lord '
        'God omnipotent reigneth."',
    fulfillment: ['Revelation 19:6'],
  ),
  Prophecy(
    id: 'despised_yet_kings_shall_arise',
    title: 'Kings shall see and arise',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The servant "whom man despiseth" will one day see "kings... '
        'arise, princes also... worship."',
    prophecy: ['Isaiah 49:7'],
    fulfillmentText:
        'John sees the kings of the earth bringing their glory and honour '
        'into the holy city.',
    fulfillment: ['Revelation 21:24'],
  ),
  Prophecy(
    id: 'sun_and_moon_no_longer_needed',
    title: 'The moon confounded, the sun ashamed',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Isaiah says the sun and moon will be outshone "when the Lord of '
        'hosts shall reign in mount Zion."',
    prophecy: ['Isaiah 24:23'],
    fulfillmentText:
        'John sees a city with no need of sun or moon, for the glory of '
        'God lightens it, and the Lamb is its light.',
    fulfillment: ['Revelation 21:23'],
  ),
  Prophecy(
    id: 'kingdom_given_to_the_saints',
    title: 'The kingdom given to the saints',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Daniel sees the kingdom and dominion under the whole heaven given '
        'to "the people of the saints of the most High."',
    prophecy: ['Daniel 7:27'],
    fulfillmentText:
        'Paul writes, "if we suffer, we shall also reign with him."',
    fulfillment: ['2 Timothy 2:12'],
  ),
  Prophecy(
    id: 'earth_filled_with_his_glory',
    title: 'The earth filled with his glory',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Habakkuk foresees the earth filled "with the knowledge of the '
        'glory of the Lord, as the waters cover the sea."',
    prophecy: ['Habakkuk 2:14'],
    fulfillmentText:
        'Paul says God has shined in believers\' hearts "to give the light '
        'of the knowledge of the glory of God in the face of Jesus '
        'Christ."',
    fulfillment: ['2 Corinthians 4:6'],
  ),
  Prophecy(
    id: 'the_day_that_burns_as_an_oven',
    title: 'The day that shall burn as an oven',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Malachi warns of a coming day that "shall burn as an oven," '
        'leaving the proud and wicked as stubble.',
    prophecy: ['Malachi 4:1'],
    fulfillmentText:
        'Peter describes the day of the Lord, when the heavens pass away '
        'and the elements melt with fervent heat.',
    fulfillment: ['2 Peter 3:10'],
  ),
  Prophecy(
    id: 'his_feet_on_the_mount_of_olives',
    title: 'His feet on the mount of Olives',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Zechariah says that in that day, the Lord\'s feet "shall stand... '
        'upon the mount of Olives."',
    prophecy: ['Zechariah 14:4'],
    fulfillmentText:
        'From Olivet, the angels tell the watching disciples that this '
        'same Jesus "shall so come in like manner as ye have seen him go '
        'into heaven."',
    fulfillment: ['Acts 1:11'],
  ),
  Prophecy(
    id: 'fruit_of_thy_body_on_thy_throne',
    title: 'The fruit of thy body on thy throne',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The Lord swears to David that "of the fruit of thy body" he will '
        'set one upon his throne.',
    prophecy: ['Psalms 132:11'],
    fulfillmentText:
        'Peter, at Pentecost, quotes this oath as fulfilled: God raised up '
        'Christ "to sit on his throne."',
    fulfillment: ['Acts 2:30'],
  ),
  Prophecy(
    id: 'the_lord_shall_be_king_over_all_the_earth',
    title: 'The Lord shall be king over all the earth',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Zechariah foresees a day when "the Lord shall be king over all '
        'the earth: in that day shall there be one Lord, and his name '
        'one."',
    prophecy: ['Zechariah 14:9'],
    fulfillmentText:
        'Paul writes that when all things are subdued to Christ, he too '
        'will be subject to the Father, "that God may be all in all."',
    fulfillment: ['1 Corinthians 15:28'],
  ),

  // ---------------------------------------------------------------------------
  // Further Messianic prophecies (batch 5)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'wisdom_before_the_world_was',
    title: 'Set up from everlasting',
    category: ProphecyCategory.birth,
    prophecyText:
        'Wisdom declares, "I was set up from everlasting, from the '
        'beginning, or ever the earth was."',
    prophecy: ['Proverbs 8:22-23'],
    fulfillmentText:
        'Jesus prays to be glorified with the glory he had with the '
        'Father "before the world was."',
    fulfillment: ['John 17:5'],
  ),
  Prophecy(
    id: 'a_mans_foes_his_own_household',
    title: "A man's foes shall be they of his own household",
    category: ProphecyCategory.ministry,
    prophecyText:
        'Micah laments a coming age of division: "a man\'s enemies are '
        'the men of his own house."',
    prophecy: ['Micah 7:6'],
    fulfillmentText:
        'Jesus quotes this saying almost word for word, warning that his '
        'coming brings division even within families.',
    fulfillment: ['Matthew 10:35-36'],
  ),
  Prophecy(
    id: 'sweet_counsel_together',
    title: 'We took sweet counsel together',
    category: ProphecyCategory.passion,
    prophecyText:
        'The psalmist is betrayed not by an enemy but by "a man mine '
        'equal, my guide, and mine acquaintance," with whom he had walked '
        'to the house of God.',
    prophecy: ['Psalms 55:12-14'],
    fulfillmentText:
        'Judas, one of the twelve, comes to Jesus, says "Hail, master," '
        'and kisses him.',
    fulfillment: ['Matthew 26:49'],
  ),
  Prophecy(
    id: 'until_he_come_whose_right_it_is',
    title: 'Until he come whose right it is',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Ezekiel declares the crown removed and the kingdom overturned '
        '"until he come whose right it is; and I will give it him."',
    prophecy: ['Ezekiel 21:26-27'],
    fulfillmentText:
        'John is told to weep no more: the Lion of the tribe of Juda, the '
        'Root of David, has prevailed to open the book.',
    fulfillment: ['Revelation 5:5'],
  ),
  Prophecy(
    id: 'vesture_dipped_in_blood',
    title: 'His vesture dipped in blood',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Isaiah pictures a conquering figure coming from Edom, garments '
        'red as one who has trodden the winepress alone.',
    prophecy: ['Isaiah 63:1-3'],
    fulfillmentText:
        'John sees the rider on the white horse "clothed with a vesture '
        'dipped in blood," whose name is called The Word of God.',
    fulfillment: ['Revelation 19:13'],
  ),
  Prophecy(
    id: 'heaven_is_my_throne',
    title: 'Heaven is my throne',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The Lord asks what house of stone could ever contain him: '
        '"heaven is my throne, and earth is my footstool."',
    prophecy: ['Isaiah 66:1'],
    fulfillmentText:
        'Stephen quotes this verse to the Sanhedrin, arguing that the '
        'Most High does not dwell in temples made with hands.',
    fulfillment: ['Acts 7:49'],
  ),
  Prophecy(
    id: 'valley_of_decision',
    title: 'Multitudes in the valley of decision',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Joel foresees a great gathering for judgment: "multitudes, '
        'multitudes in the valley of decision."',
    prophecy: ['Joel 3:14'],
    fulfillmentText:
        'Jesus says all nations will be gathered before him, and he will '
        'separate the sheep from the goats.',
    fulfillment: ['Matthew 25:32'],
  ),
  Prophecy(
    id: 'the_kingdom_shall_be_the_lords',
    title: "The kingdom shall be the Lord's",
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Obadiah ends with judgment on Edom and this promise: "the '
        'kingdom shall be the Lord\'s."',
    prophecy: ['Obadiah 1:21'],
    fulfillmentText:
        'Paul writes that at the end, Christ delivers up the kingdom to '
        'God the Father, having put down all rule and authority.',
    fulfillment: ['1 Corinthians 15:24'],
  ),
  Prophecy(
    id: 'day_of_vengeance_of_our_god',
    title: 'The day of vengeance of our God',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Isaiah\'s servant is anointed to proclaim good tidings and also '
        '"the day of vengeance of our God" — a clause Jesus stopped short '
        'of reading at Nazareth, since it awaits his return.',
    prophecy: ['Isaiah 61:2'],
    fulfillmentText:
        'Paul writes of the Lord Jesus revealed from heaven "in flaming '
        'fire, taking vengeance on them that know not God."',
    fulfillment: ['2 Thessalonians 1:8'],
  ),
  Prophecy(
    id: 'the_mercy_sworn_to_abraham',
    title: 'The mercy sworn to Abraham',
    category: ProphecyCategory.church,
    prophecyText:
        'Micah closes with hope in the God who casts sin into the depths '
        'of the sea and performs "the mercy... sworn unto our fathers '
        'from the days of old."',
    prophecy: ['Micah 7:19-20'],
    fulfillmentText:
        'Zacharias prophesies that God has remembered his holy covenant, '
        '"the oath which he sware to our father Abraham."',
    fulfillment: ['Luke 1:72-73'],
  ),
  Prophecy(
    id: 'hands_spread_to_a_rebellious_people',
    title: 'Hands spread out to a rebellious people',
    category: ProphecyCategory.church,
    prophecyText:
        'The Lord laments, "I have spread out my hands all the day unto a '
        'rebellious people."',
    prophecy: ['Isaiah 65:2'],
    fulfillmentText:
        'Paul quotes this same verse of Israel\'s unbelief, immediately '
        'after quoting the verse before it about being found by those who '
        'did not seek him.',
    fulfillment: ['Romans 10:21'],
  ),
  Prophecy(
    id: 'ten_men_take_hold_of_the_jew',
    title: 'Ten men take hold of the skirt of a Jew',
    category: ProphecyCategory.church,
    prophecyText:
        'Zechariah foresees people of every language taking hold of a '
        'Jew\'s garment, saying, "we have heard that God is with you."',
    prophecy: ['Zechariah 8:23'],
    fulfillmentText:
        'Greeks at the feast come to Philip with the request, "Sir, we '
        'would see Jesus."',
    fulfillment: ['John 12:20-21'],
  ),
  Prophecy(
    id: 'brought_up_from_the_depths_of_the_earth',
    title: 'Brought up again from the depths of the earth',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'The psalmist trusts God to "quicken me again, and... bring me up '
        'again from the depths of the earth."',
    prophecy: ['Psalms 71:20'],
    fulfillmentText:
        'Paul reasons that Christ\'s ascension implies he "also descended '
        'first into the lower parts of the earth."',
    fulfillment: ['Ephesians 4:9'],
  ),

  // ---------------------------------------------------------------------------
  // Further Messianic prophecies (batch 6)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'seventy_weeks_determined',
    title: 'Seventy weeks determined',
    category: ProphecyCategory.birth,
    prophecyText:
        'Gabriel gives Daniel a precise timetable: seventy weeks are '
        'determined to finish transgression, make an end of sins, and '
        'anoint the most Holy.',
    prophecy: ['Daniel 9:24'],
    fulfillmentText:
        'Paul writes that "when the fulness of the time was come, God '
        'sent forth his Son, made of a woman."',
    fulfillment: ['Galatians 4:4'],
  ),
  Prophecy(
    id: 'out_of_the_mouth_of_babes',
    title: 'Out of the mouth of babes',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The psalmist says God has ordained strength "out of the mouth of '
        'babes and sucklings."',
    prophecy: ['Psalms 8:2'],
    fulfillmentText:
        'When children cry "Hosanna" in the temple, Jesus answers the '
        'indignant chief priests by quoting this very verse.',
    fulfillment: ['Matthew 21:16'],
  ),
  Prophecy(
    id: 'beside_me_there_is_no_saviour',
    title: 'Beside me there is no saviour',
    category: ProphecyCategory.ministry,
    prophecyText: 'The Lord declares, "beside me there is no saviour."',
    prophecy: ['Isaiah 43:11'],
    fulfillmentText:
        'Peter tells the rulers there is salvation in no other name under '
        'heaven given among men.',
    fulfillment: ['Acts 4:12'],
  ),
  Prophecy(
    id: 'eyes_that_should_not_see',
    title: 'Seeing they should not see',
    category: ProphecyCategory.passion,
    prophecyText:
        'Isaiah is sent to a people whose hearts will be made fat, whose '
        'ears heavy, and whose eyes shut, lest they see and be healed.',
    prophecy: ['Isaiah 6:9-10'],
    fulfillmentText:
        'John explains why so many could not believe on Jesus, adding '
        'that "these things said Esaias, when he saw his glory, and spake '
        'of him."',
    fulfillment: ['John 12:39-41'],
  ),
  Prophecy(
    id: 'ransom_for_many',
    title: 'I have found a ransom',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Elihu describes God delivering a man from the pit: "I have found '
        'a ransom."',
    prophecy: ['Job 33:24'],
    fulfillmentText:
        'Jesus says the Son of man came to give his life "a ransom for '
        'many."',
    fulfillment: ['Matthew 20:28'],
  ),
  Prophecy(
    id: 'messiah_cut_off_not_for_himself',
    title: 'Messiah cut off, but not for himself',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Daniel foretells that after sixty-two weeks, "Messiah shall be '
        'cut off, but not for himself."',
    prophecy: ['Daniel 9:26'],
    fulfillmentText:
        'Peter writes that Christ suffered once for sins, "the just for '
        'the unjust," not for his own.',
    fulfillment: ['1 Peter 3:18'],
  ),
  Prophecy(
    id: 'he_shall_confirm_the_covenant',
    title: 'He shall confirm the covenant',
    category: ProphecyCategory.church,
    prophecyText:
        'Daniel\'s vision continues: "he shall confirm the covenant with '
        'many for one week."',
    prophecy: ['Daniel 9:27'],
    fulfillmentText:
        'Paul says Christ became a servant of the circumcision "to '
        'confirm the promises made unto the fathers."',
    fulfillment: ['Romans 15:8'],
  ),
  Prophecy(
    id: 'ruler_just_like_morning_light',
    title: 'As the light of the morning',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'David\'s last words describe a just ruler who "shall be as the '
        'light of the morning, when the sun riseth."',
    prophecy: ['2 Samuel 23:3-4'],
    fulfillmentText: 'Jesus declares, "I am the light of the world."',
    fulfillment: ['John 8:12'],
  ),
  Prophecy(
    id: 'rule_in_the_midst_of_thine_enemies',
    title: 'Rule thou in the midst of thine enemies',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The Lord sends the rod of the king\'s strength out of Zion: '
        '"rule thou in the midst of thine enemies."',
    prophecy: ['Psalms 110:2'],
    fulfillmentText:
        'Paul writes that Christ "must reign, till he hath put all '
        'enemies under his feet."',
    fulfillment: ['1 Corinthians 15:25'],
  ),
  Prophecy(
    id: 'the_lord_is_our_king_our_judge',
    title: 'The Lord is our king',
    category: ProphecyCategory.kingdom,
    prophecyText:
        '"The Lord is our judge, the Lord is our lawgiver, the Lord is '
        'our king; he will save us."',
    prophecy: ['Isaiah 33:22'],
    fulfillmentText:
        'Jesus says the Father has committed all judgment to the Son.',
    fulfillment: ['John 5:22'],
  ),
  Prophecy(
    id: 'thou_art_the_same_thy_years_have_no_end',
    title: 'Thy years shall have no end',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'The psalmist contrasts the perishing heavens and earth with the '
        'one whose "years shall have no end."',
    prophecy: ['Psalms 102:25-27'],
    fulfillmentText:
        'Hebrews applies this psalm directly to the Son: "thou remainest '
        '... but thou art the same, and thy years shall not fail."',
    fulfillment: ['Hebrews 1:10-12'],
  ),

  // ---------------------------------------------------------------------------
  // Further Messianic prophecies (batch 7)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'coats_of_skins',
    title: 'Coats of skins',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'After the fall, the Lord God clothes Adam and Eve with coats of '
        'skins — the first death in Scripture, covering their sin.',
    prophecy: ['Genesis 3:21'],
    fulfillmentText:
        'John sees all who dwell on earth worshiping the beast except '
        'those written in the book of "the Lamb slain from the foundation '
        'of the world."',
    fulfillment: ['Revelation 13:8'],
  ),
  Prophecy(
    id: 'blood_that_speaketh_better_things',
    title: 'Blood that speaketh better things than Abel',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Abel\'s blood, spilled by his brother, cries out from the ground.',
    prophecy: ['Genesis 4:10'],
    fulfillmentText:
        'Hebrews contrasts that cry with "the blood of sprinkling, that '
        'speaketh better things than that of Abel."',
    fulfillment: ['Hebrews 12:24'],
  ),
  Prophecy(
    id: 'abraham_saw_my_day',
    title: 'Abraham saw my day',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Abraham names the place of Isaac\'s binding "Jehovah-jireh," '
        'because there "in the mount of the Lord it shall be seen."',
    prophecy: ['Genesis 22:14'],
    fulfillmentText:
        'Jesus tells the Jews, "Your father Abraham rejoiced to see my '
        'day: and he saw it, and was glad."',
    fulfillment: ['John 8:56'],
  ),
  Prophecy(
    id: 'blood_of_the_covenant',
    title: 'The blood of the covenant',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Moses sprinkles blood on the people and says, "Behold the blood '
        'of the covenant, which the Lord hath made with you."',
    prophecy: ['Exodus 24:8'],
    fulfillmentText:
        'At the last supper, Jesus says of the cup, "this is my blood of '
        'the new testament, which is shed for many for the remission of '
        'sins."',
    fulfillment: ['Matthew 26:28'],
  ),
  Prophecy(
    id: 'suffered_without_the_gate',
    title: 'Suffered without the gate',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'On the Day of Atonement, the bodies of the sin-offering animals '
        'whose blood atones in the holy place are burned outside the '
        'camp.',
    prophecy: ['Leviticus 16:27'],
    fulfillmentText:
        'Hebrews draws the parallel directly: Jesus, "that he might '
        'sanctify the people with his own blood, suffered without the '
        'gate."',
    fulfillment: ['Hebrews 13:11-12'],
  ),
  Prophecy(
    id: 'filthy_garments_exchanged',
    title: 'Filthy garments exchanged',
    category: ProphecyCategory.church,
    prophecyText:
        'In Zechariah\'s vision, the high priest Joshua stands in filthy '
        'garments until the Lord removes his iniquity and clothes him '
        'with a change of raiment.',
    prophecy: ['Zechariah 3:3-4'],
    fulfillmentText:
        'Paul writes that God "made him to be sin for us, who knew no '
        'sin; that we might be made the righteousness of God in him."',
    fulfillment: ['2 Corinthians 5:21'],
  ),
  Prophecy(
    id: 'seek_and_save_that_which_was_lost',
    title: 'Seeking that which was lost',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The Lord promises to seek out his scattered sheep himself: "I '
        'will seek that which was lost, and bring again that which was '
        'driven away."',
    prophecy: ['Ezekiel 34:16'],
    fulfillmentText:
        'Jesus says, "the Son of man is come to seek and to save that '
        'which was lost."',
    fulfillment: ['Luke 19:10'],
  ),

  // ---------------------------------------------------------------------------
  // Further Messianic prophecies (batch 8)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'the_veil_is_his_flesh',
    title: 'The veil is his flesh',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The tabernacle veil hangs between the holy place and the most '
        'holy, barring the way into God\'s presence.',
    prophecy: ['Exodus 26:31-33'],
    fulfillmentText:
        'At the moment Jesus dies, the temple veil is torn in two from '
        'top to bottom; Hebrews later calls it "a new and living way... '
        'through the veil, that is to say, his flesh."',
    fulfillment: ['Matthew 27:51', 'Hebrews 10:19-20'],
  ),

  // ---------------------------------------------------------------------------
  // Birth & Incarnation (batch 9)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'i_will_be_his_father',
    title: 'God will be his Father, and he His Son',
    category: ProphecyCategory.birth,
    prophecyText:
        'In the covenant given through Nathan, God promises that David\'s '
        'offspring will be his own son: "I will be his father, and he shall '
        'be my son."',
    prophecy: ['2 Samuel 7:14'],
    fulfillmentText:
        'Hebrews sets this promise beside "Thou art my Son" to show that God '
        'has spoken this way of no angel, only of his own Son.',
    fulfillment: ['Hebrews 1:5'],
  ),
  Prophecy(
    id: 'gods_only_son_given',
    title: 'The Father gives his only, beloved Son',
    category: ProphecyCategory.birth,
    prophecyText:
        'God tests Abraham by commanding him to offer "thy son, thine only '
        'son Isaac, whom thou lovest" — a father surrendering his beloved '
        'son that later ages read as a shadow of a far greater gift.',
    prophecy: ['Genesis 22:2'],
    fulfillmentText:
        'John writes that God so loved the world that he gave his only '
        'begotten Son.',
    fulfillment: ['John 3:16'],
  ),
  Prophecy(
    id: 'horn_of_salvation_for_david',
    title: 'A horn of salvation for David\'s house',
    category: ProphecyCategory.birth,
    prophecyText:
        'The Lord promises David, "There will I make the horn of David to '
        'bud," raising up strength and salvation within his line.',
    prophecy: ['Psalms 132:17'],
    fulfillmentText:
        'At his son\'s birth, Zechariah prophesies that God "hath raised up '
        'an horn of salvation for us in the house of his servant David."',
    fulfillment: ['Luke 1:69'],
  ),
  Prophecy(
    id: 'good_tidings_of_great_joy',
    title: 'Good tidings proclaimed from on high',
    category: ProphecyCategory.birth,
    prophecyText:
        'Isaiah calls Zion to climb the high mountain and lift up her voice '
        'with good tidings, crying, "Behold your God!"',
    prophecy: ['Isaiah 40:9'],
    fulfillmentText:
        'An angel brings the shepherds "good tidings of great joy, which '
        'shall be to all people" — that a Saviour is born.',
    fulfillment: ['Luke 2:10'],
  ),
  Prophecy(
    id: 'he_shall_save_his_people',
    title: 'He shall redeem Israel from its sins',
    category: ProphecyCategory.birth,
    prophecyText:
        'The psalmist trusts that the Lord "shall redeem Israel from all '
        'his iniquities."',
    prophecy: ['Psalms 130:8'],
    fulfillmentText:
        'Peter proclaims that God has exalted Jesus "to be a Prince and a '
        'Saviour, for to give repentance to Israel, and forgiveness of '
        'sins" — the very redemption named for him at his birth.',
    fulfillment: ['Acts 5:31'],
  ),

  // ---------------------------------------------------------------------------
  // Life & Ministry (batch 9)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'preached_in_the_great_congregation',
    title: 'Preached righteousness in the great assembly',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The psalmist speaks as one who has "preached righteousness in the '
        'great congregation," his lips not restrained.',
    prophecy: ['Psalms 40:9'],
    fulfillmentText:
        'Jesus begins his public ministry proclaiming, "Repent: for the '
        'kingdom of heaven is at hand."',
    fulfillment: ['Matthew 4:17'],
  ),
  Prophecy(
    id: 'faithful_priest_raised_up',
    title: 'A faithful priest raised up',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The Lord promises to raise up a faithful priest who will act '
        'according to his own heart and mind, walking before his anointed '
        'forever.',
    prophecy: ['1 Samuel 2:35'],
    fulfillmentText:
        'Hebrews calls Jesus a merciful and faithful high priest, made like '
        'his brethren to make reconciliation for the sins of the people.',
    fulfillment: ['Hebrews 2:17'],
  ),
  Prophecy(
    id: 'key_of_david',
    title: 'The key of the house of David',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah pictures the key of David\'s house laid on a steward\'s '
        'shoulder, so that what he opens none can shut, and what he shuts '
        'none can open.',
    prophecy: ['Isaiah 22:22'],
    fulfillmentText:
        'The risen Christ takes this very title for himself, holding "the '
        'key of David, he that openeth, and no man shutteth."',
    fulfillment: ['Revelation 3:7'],
  ),
  Prophecy(
    id: 'comfort_for_those_who_mourn',
    title: 'Comfort for those who mourn',
    category: ProphecyCategory.ministry,
    prophecyText: 'Isaiah\'s anointed one is sent "to comfort all that mourn."',
    prophecy: ['Isaiah 61:2'],
    fulfillmentText:
        'Jesus opens his ministry teaching, "Blessed are they that mourn: '
        'for they shall be comforted."',
    fulfillment: ['Matthew 5:4'],
  ),
  Prophecy(
    id: 'opened_ear_not_rebellious',
    title: 'The opened ear, not rebellious',
    category: ProphecyCategory.ministry,
    prophecyText:
        'Isaiah\'s servant says, "The Lord God hath opened mine ear, and I '
        'was not rebellious, neither turned away back."',
    prophecy: ['Isaiah 50:5'],
    fulfillmentText:
        'Jesus says the Father has not left him alone, "for I do always '
        'those things that please him."',
    fulfillment: ['John 8:29'],
  ),
  Prophecy(
    id: 'he_maketh_the_storm_a_calm',
    title: 'He maketh the storm a calm',
    category: ProphecyCategory.ministry,
    prophecyText:
        'The psalmist praises the Lord who "maketh the storm a calm, so '
        'that the waves thereof are still."',
    prophecy: ['Psalms 107:29'],
    fulfillmentText:
        'Jesus rebukes the wind and sea, "Peace, be still," and the storm '
        'subsides into a great calm.',
    fulfillment: ['Mark 4:39'],
  ),

  // ---------------------------------------------------------------------------
  // Betrayal, Trial & Suffering (batch 9)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'sold_by_brothers_for_envy',
    title: 'Sold by his own, moved with envy',
    category: ProphecyCategory.passion,
    prophecyText:
        'Joseph\'s own brothers, moved with envy, sell him to strangers for '
        'twenty pieces of silver.',
    prophecy: ['Genesis 37:11', 'Genesis 37:28'],
    fulfillmentText:
        'Pilate perceives that it was for envy the chief priests had '
        'delivered Jesus up, betrayed by his own people.',
    fulfillment: ['Matthew 27:18'],
  ),
  Prophecy(
    id: 'visage_marred_more_than_any_man',
    title: 'His visage marred more than any man',
    category: ProphecyCategory.passion,
    prophecyText:
        'Isaiah says many will be astonished at the servant, for his visage '
        'is marred more than any man, and his form more than the sons of '
        'men.',
    prophecy: ['Isaiah 52:14'],
    fulfillmentText:
        'Pilate has Jesus scourged and crowned with thorns, then presents '
        'the bloodied, battered man to the crowd: "Behold the man!"',
    fulfillment: ['John 19:1', 'John 19:5'],
  ),
  Prophecy(
    id: 'isaac_bound_on_the_altar',
    title: 'Isaac bound on the altar',
    category: ProphecyCategory.passion,
    prophecyText:
        'Abraham builds the altar, lays the wood in order, and binds Isaac '
        'his son upon it.',
    prophecy: ['Genesis 22:9'],
    fulfillmentText:
        'At Gethsemane the band of soldiers and officers take Jesus and '
        'bind him.',
    fulfillment: ['John 18:12'],
  ),
  Prophecy(
    id: 'cup_of_the_lords_fury',
    title: 'The cup of the Lord\'s fury',
    category: ProphecyCategory.passion,
    prophecyText:
        'The Lord hands Jeremiah the wine cup of his fury, to make the '
        'nations drink it to the dregs.',
    prophecy: ['Jeremiah 25:15', 'Jeremiah 25:17'],
    fulfillmentText:
        'In Gethsemane Jesus prays that the cup might pass from him, then '
        'accepts it: "if this cup may not pass away from me, except I '
        'drink it, thy will be done."',
    fulfillment: ['Matthew 26:39', 'Matthew 26:42'],
  ),

  // ---------------------------------------------------------------------------
  // Crucifixion & Death (batch 9)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'red_heifer_ashes_purify',
    title: 'The ashes of the red heifer',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The law calls for a red heifer without spot or blemish; its ashes, '
        'kept outside the camp, become water of purification for sin.',
    prophecy: ['Numbers 19:2', 'Numbers 19:9'],
    fulfillmentText:
        'Hebrews argues that if the ashes of a heifer sanctify to the '
        'purifying of the flesh, how much more the blood of Christ, '
        'offered without spot, purges the conscience from dead works.',
    fulfillment: ['Hebrews 9:13', 'Hebrews 9:14'],
  ),
  Prophecy(
    id: 'ram_in_the_thicket',
    title: 'A ram offered in his son\'s stead',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'Abraham lifts up his eyes and sees a ram caught in a thicket, and '
        'offers it up for a burnt offering in the stead of his son.',
    prophecy: ['Genesis 22:13'],
    fulfillmentText:
        'Paul says God commends his love toward us in this: while we were '
        'yet sinners, Christ died for us — a substitute in our place.',
    fulfillment: ['Romans 5:8'],
  ),
  Prophecy(
    id: 'they_shaked_their_heads',
    title: 'They shaked their heads at him',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The psalmist becomes a reproach; when his enemies see him, they '
        'shake their heads.',
    prophecy: ['Psalms 109:25'],
    fulfillmentText:
        'Those who pass the cross rail on Jesus, wagging their heads.',
    fulfillment: ['Mark 15:29'],
  ),
  Prophecy(
    id: 'unleavened_bread_of_sincerity',
    title: 'Unleavened bread of sincerity and truth',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'At Passover Israel must put away all leaven and eat unleavened '
        'bread for seven days.',
    prophecy: ['Exodus 12:15'],
    fulfillmentText:
        'Paul reasons that since Christ our passover is sacrificed for us, '
        'believers are to keep the feast not with the old leaven of '
        'malice, but with the unleavened bread of sincerity and truth.',
    fulfillment: ['1 Corinthians 5:8'],
  ),
  Prophecy(
    id: 'blood_frees_prisoners_from_the_pit',
    title: 'Prisoners freed by the blood of the covenant',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'By the blood of his covenant, the Lord promises to send forth '
        'prisoners out of the waterless pit.',
    prophecy: ['Zechariah 9:11'],
    fulfillmentText:
        'Paul says the Father has delivered believers from the power of '
        'darkness, in whom we have redemption through his blood, the '
        'forgiveness of sins.',
    fulfillment: ['Colossians 1:13', 'Colossians 1:14'],
  ),
  Prophecy(
    id: 'redeemed_not_with_silver_or_gold',
    title: 'Not redeemed with silver or gold',
    category: ProphecyCategory.crucifixion,
    prophecyText:
        'The psalmist observes that no man can by any means redeem his '
        'brother, nor give to God a ransom for him, for the redemption of '
        'the soul is precious.',
    prophecy: ['Psalms 49:7', 'Psalms 49:8'],
    fulfillmentText:
        'Peter says believers were redeemed not with corruptible things '
        'like silver and gold, but with the precious blood of Christ, a '
        'lamb without blemish.',
    fulfillment: ['1 Peter 1:18', '1 Peter 1:19'],
  ),

  // ---------------------------------------------------------------------------
  // Resurrection & Ascension (batch 9)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'isaac_received_in_a_figure',
    title: 'Isaac received back "in a figure"',
    category: ProphecyCategory.resurrection,
    prophecyText:
        'On the third day of the journey to Moriah, Abraham lifts up his '
        'eyes and sees the place where he must offer up his only son, '
        'having already reckoned Isaac as good as dead.',
    prophecy: ['Genesis 22:4'],
    fulfillmentText:
        'Hebrews explains that Abraham believed God could raise Isaac from '
        'the dead, and so received him back "in a figure" — a shadow of '
        'the greater Son raised on the third day.',
    fulfillment: ['Hebrews 11:17-19'],
  ),

  // ---------------------------------------------------------------------------
  // The Church & New Covenant (batch 9)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'tongues_a_sign_to_unbelief',
    title: 'Foreign tongues, a sign to unbelief',
    category: ProphecyCategory.church,
    prophecyText:
        'Because Israel would not hear the Lord\'s plain word, Isaiah warns '
        'that God will instead speak to them "with stammering lips and '
        'another tongue" — a sign of judgment on their unbelief.',
    prophecy: ['Isaiah 28:11', 'Isaiah 28:12'],
    fulfillmentText:
        'Paul quotes this warning to explain the gift of tongues at '
        'Corinth: a sign not to believers but to those who refuse to '
        'believe.',
    fulfillment: ['1 Corinthians 14:21', '1 Corinthians 14:22'],
  ),
  Prophecy(
    id: 'father_of_many_nations',
    title: 'Father of many nations',
    category: ProphecyCategory.church,
    prophecyText:
        'God renames Abram "Abraham," declaring, "a father of many nations '
        'have I made thee" — a promise reaching beyond his physical '
        'descendants.',
    prophecy: ['Genesis 17:5'],
    fulfillmentText:
        'Paul quotes this directly: Abraham is "the father of us all," of '
        'everyone who shares his faith and not his bloodline only.',
    fulfillment: ['Romans 4:16', 'Romans 4:17'],
  ),
  Prophecy(
    id: 'sing_o_barren_woman',
    title: 'Sing, O barren — more children than the married wife',
    category: ProphecyCategory.church,
    prophecyText:
        'Isaiah calls the barren woman to sing and cry aloud, for her '
        'children will be more than the children of her that has a '
        'husband.',
    prophecy: ['Isaiah 54:1'],
    fulfillmentText:
        'Paul quotes this of "Jerusalem which is above," the free woman '
        'whose children — born by promise, not by the law — are the '
        'church.',
    fulfillment: ['Galatians 4:26', 'Galatians 4:27'],
  ),
  Prophecy(
    id: 'praise_the_lord_all_ye_gentiles',
    title: 'Praise the Lord, all ye Gentiles',
    category: ProphecyCategory.church,
    prophecyText:
        'The shortest psalm summons not Israel alone but all nations and '
        'all people to praise the Lord.',
    prophecy: ['Psalms 117:1'],
    fulfillmentText:
        'Paul quotes this psalm as scriptural proof that the gospel was '
        'always meant to reach — and be received by — the Gentiles.',
    fulfillment: ['Romans 15:11'],
  ),
  Prophecy(
    id: 'eight_souls_saved_by_water',
    title: 'Eight souls saved by water',
    category: ProphecyCategory.church,
    prophecyText:
        'Noah, his wife, his three sons, and their wives — eight souls in '
        'all — enter the ark and are carried safely through the flood '
        'waters.',
    prophecy: ['Genesis 7:13'],
    fulfillmentText:
        'Peter calls this "the like figure" of baptism, which now saves '
        'through the resurrection of Jesus Christ.',
    fulfillment: ['1 Peter 3:20', '1 Peter 3:21'],
  ),
  Prophecy(
    id: 'wave_loaves_of_pentecost',
    title: 'The wave loaves of Pentecost',
    category: ProphecyCategory.church,
    prophecyText:
        'The law appoints a grain offering of two wave loaves, the '
        'firstfruits of the wheat harvest, fifty days after the wave '
        'sheaf — the feast later called Pentecost.',
    prophecy: ['Leviticus 23:15', 'Leviticus 23:16'],
    fulfillmentText:
        'On that very feast day the Spirit is poured out and the church '
        'is born: "when the day of Pentecost was fully come."',
    fulfillment: ['Acts 2:1'],
  ),

  // ---------------------------------------------------------------------------
  // His Reign & Return (batch 9)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'king_reigns_in_righteousness',
    title: 'A king shall reign in righteousness',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Isaiah foresees a king who will reign in righteousness, with princes '
        'ruling in judgment.',
    prophecy: ['Isaiah 32:1'],
    fulfillmentText:
        'Before Pilate, Jesus owns the title: "Thou sayest that I am a '
        'king," come into the world to bear witness to the truth.',
    fulfillment: ['John 18:37'],
  ),
  Prophecy(
    id: 'settled_in_an_everlasting_kingdom',
    title: 'Settled in an everlasting kingdom',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'In Nathan\'s oracle to David, the Lord promises to settle David\'s '
        'heir in his house and kingdom for ever, his throne established for '
        'evermore.',
    prophecy: ['1 Chronicles 17:14'],
    fulfillmentText:
        'Peter promises believers an entrance "ministered unto you '
        'abundantly into the everlasting kingdom of our Lord and Saviour '
        'Jesus Christ."',
    fulfillment: ['2 Peter 1:11'],
  ),
  Prophecy(
    id: 'nations_worship_the_king',
    title: 'All nations worship the King',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Zechariah foresees the survivors of every nation going up year by '
        'year to worship the King, the Lord of hosts.',
    prophecy: ['Zechariah 14:16'],
    fulfillmentText:
        'John hears the redeemed sing that all nations will come and '
        'worship before the Lord, for his judgments are made manifest.',
    fulfillment: ['Revelation 15:4'],
  ),
  Prophecy(
    id: 'shepherd_king_ends_of_earth',
    title: 'Great unto the ends of the earth',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Micah\'s ruler from Bethlehem will stand and shepherd his flock in '
        'the strength of the Lord, and his greatness will reach the ends of '
        'the earth.',
    prophecy: ['Micah 5:4'],
    fulfillmentText:
        'John sees the Lamb at the centre of the throne shepherding the '
        'redeemed of every nation, feeding them and wiping every tear from '
        'their eyes.',
    fulfillment: ['Revelation 7:17'],
  ),
  Prophecy(
    id: 'sun_and_moon_darkened_at_his_return',
    title: 'Sun and moon darkened before his return',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Joel foretells the sun turned to darkness and the moon to blood '
        'before the great and terrible day of the Lord comes.',
    prophecy: ['Joel 2:31'],
    fulfillmentText:
        'Jesus describes his own return in the same terms: immediately '
        'after the tribulation the sun will be darkened, the moon will not '
        'give her light, and the stars will fall.',
    fulfillment: ['Matthew 24:29'],
  ),
  Prophecy(
    id: 'refiners_fire_purifies',
    title: 'Who may abide the day of his coming?',
    category: ProphecyCategory.kingdom,
    prophecyText:
        'Malachi warns that when the Lord suddenly comes to his temple, '
        'none can abide the day of his coming, for he is like a refiner\'s '
        'fire who will purify and purge.',
    prophecy: ['Malachi 3:2', 'Malachi 3:3'],
    fulfillmentText:
        'Paul says the day will declare every man\'s work, since it will be '
        'revealed by fire, and the fire will test what sort it is.',
    fulfillment: ['1 Corinthians 3:13'],
  ),

  // ---------------------------------------------------------------------------
  // Fulfilled in the Old Testament (batch 9)
  // ---------------------------------------------------------------------------
  Prophecy(
    id: 'isaac_born_in_old_age',
    title: 'Isaac born in Sarah\'s old age',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'God tells Abraham that Sarah will bear him a son, to be named '
        'Isaac, at the set time the following year.',
    prophecy: ['Genesis 17:19', 'Genesis 18:10'],
    fulfillmentText:
        'Sarah conceives and bears Abraham a son in his old age, "at the '
        'set time of which God had spoken to him," and he names him Isaac.',
    fulfillment: ['Genesis 21:2', 'Genesis 21:3'],
  ),
  Prophecy(
    id: 'shunammites_son_promised',
    title: 'The Shunammite promised a son',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Elisha tells the childless Shunammite woman that about that '
        'season, the following year, she will embrace a son.',
    prophecy: ['2 Kings 4:16'],
    fulfillmentText:
        'The woman conceives and bears a son at that very season, '
        '"according to the time of life" that Elisha had spoken.',
    fulfillment: ['2 Kings 4:17'],
  ),
  Prophecy(
    id: 'moses_barred_from_canaan',
    title: 'Moses barred from the promised land',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Because Moses failed to sanctify the Lord at Meribah, God tells him '
        'he will see the land of Canaan but not enter it.',
    prophecy: ['Numbers 20:12'],
    fulfillmentText:
        'The Lord shows Moses the land from Pisgah, and he dies there in '
        'Moab, "according to the word of the Lord," without crossing over.',
    fulfillment: ['Deuteronomy 34:4', 'Deuteronomy 34:5'],
  ),
  Prophecy(
    id: 'kingdom_torn_from_solomon',
    title: 'Ten tribes torn from Solomon\'s son',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'The prophet Ahijah tears his new garment into twelve pieces and '
        'gives ten to Jeroboam, declaring that the Lord will rend the '
        'kingdom from Solomon and give him ten tribes.',
    prophecy: ['1 Kings 11:29', '1 Kings 11:31'],
    fulfillmentText:
        'When Rehoboam\'s harsh answer drives Israel to revolt, the ten '
        'tribes make Jeroboam king, leaving only Judah loyal to David\'s '
        'house.',
    fulfillment: ['1 Kings 12:20'],
  ),
  Prophecy(
    id: 'baasha_house_cut_off',
    title: 'The house of Baasha destroyed',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'The prophet Jehu son of Hanani declares that the Lord will take '
        'away Baasha\'s posterity and make his house like Jeroboam\'s.',
    prophecy: ['1 Kings 16:1-4'],
    fulfillmentText:
        'When Zimri seizes the throne he slays every survivor of Baasha\'s '
        'house, "according to the word of the Lord, which he spake against '
        'Baasha by Jehu the prophet."',
    fulfillment: ['1 Kings 16:11', '1 Kings 16:12'],
  ),
  Prophecy(
    id: 'davids_child_by_bathsheba_dies',
    title: 'The child born to David and Bathsheba dies',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Nathan tells David that because of his sin, the child born to him '
        'will surely die.',
    prophecy: ['2 Samuel 12:14'],
    fulfillmentText:
        'The Lord strikes the child, and on the seventh day he dies, just '
        'as Nathan had said.',
    fulfillment: ['2 Samuel 12:18'],
  ),
  Prophecy(
    id: 'evil_raised_from_his_own_house',
    title: 'Evil raised up out of David\'s own house',
    category: ProphecyCategory.oldTestament,
    prophecyText:
        'Nathan warns David that the Lord will raise up evil against him '
        'out of his own house, and will do before all Israel and the sun '
        'what David did in secret.',
    prophecy: ['2 Samuel 12:11', '2 Samuel 12:12'],
    fulfillmentText:
        'Absalom pitches a tent on the roof of the palace and goes in to '
        'his father\'s concubines "in the sight of all Israel."',
    fulfillment: ['2 Samuel 16:22'],
  ),
];
