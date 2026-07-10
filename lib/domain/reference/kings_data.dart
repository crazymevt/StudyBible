import 'king_reign.dart';

/// The curated Kings & Reigns dataset: the united kingdom, the divided
/// kingdoms of Israel and Judah, and foreign monarchs scripture names
/// directly. Ordered chronologically by [KingReign.sortKey] (approximate
/// traditional dates; BC years are negative, AD positive — see
/// [KingReign.reignSummary] doc).
///
/// Deliberately excludes rulers scripture only alludes to without naming
/// (e.g. the "king of Greece" figure of Daniel 8) or whose identification
/// with a named biblical Ahasuerus/Artaxerxes is disputed among scholars —
/// same bar as the Prophecies dataset: a real, checkable citation, not a
/// padded identification.
const List<KingReign> kingReigns = [
  // --- United Kingdom ---
  KingReign(
    id: 'saul',
    name: 'Saul',
    realm: Realm.united,
    title: 'King',
    reignSummary: 'c. 1050–1010 BC (40 years)',
    sortKey: -1050,
    verdict: Verdict.bad,
    notes:
        "Israel's first king, anointed by Samuel at the people's demand for a "
        'king "like all the nations." Began well but disobeyed repeatedly and '
        'was rejected by God; died by his own sword at Gilboa.',
    citations: ['1 Samuel 10:1', '1 Samuel 15:22-23', '1 Samuel 31:1-6', 'Acts 13:21'],
    explorerPersonId: 2463,
  ),
  KingReign(
    id: 'david',
    name: 'David',
    realm: Realm.united,
    title: 'King',
    reignSummary: 'c. 1010–970 BC (40 years)',
    sortKey: -1010,
    verdict: Verdict.good,
    notes:
        'Shepherd, giant-slayer, and Israel\'s greatest king; "a man after '
        "God's own heart\" despite his sin with Bathsheba. Given God's "
        'covenant promise of an eternal throne.',
    citations: ['1 Samuel 16:13', '2 Samuel 5:3-4', '2 Samuel 7:12-16', '1 Kings 2:10-11'],
    explorerPersonId: 991,
  ),
  KingReign(
    id: 'solomon',
    name: 'Solomon',
    realm: Realm.united,
    title: 'King',
    reignSummary: 'c. 970–930 BC (40 years)',
    sortKey: -970,
    verdict: Verdict.mixed,
    notes:
        'Built the Jerusalem temple and was famed for God-given wisdom, but '
        'his many foreign wives turned his heart to idolatry in old age, '
        'setting up the kingdom\'s division.',
    citations: ['1 Kings 3:9-12', '1 Kings 6:1', '1 Kings 11:1-8', '1 Kings 11:42-43'],
    explorerPersonId: 2746,
  ),

  // --- Northern Kingdom (Israel) ---
  KingReign(
    id: 'jeroboam-1',
    name: 'Jeroboam I',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 930–909 BC',
    sortKey: -930,
    verdict: Verdict.bad,
    notes:
        'Led the ten northern tribes\' revolt against Rehoboam; set up golden '
        'calves at Bethel and Dan so the "sin of Jeroboam" became the '
        "refrain for every king of Israel after him.",
    citations: ['1 Kings 12:20', '1 Kings 12:28-33'],
  ),
  KingReign(
    id: 'nadab',
    name: 'Nadab',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 909–908 BC (2 years)',
    sortKey: -909,
    verdict: Verdict.bad,
    notes: "Jeroboam's son; assassinated by Baasha while besieging Gibbethon.",
    citations: ['1 Kings 15:25-31'],
  ),
  KingReign(
    id: 'baasha',
    name: 'Baasha',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 908–885 BC (24 years)',
    sortKey: -908,
    verdict: Verdict.bad,
    notes: 'Wiped out Jeroboam\'s house, then repeated its sins himself.',
    citations: ['1 Kings 15:33-34', '1 Kings 16:1-7'],
  ),
  KingReign(
    id: 'elah',
    name: 'Elah',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 885–884 BC (2 years)',
    sortKey: -885,
    verdict: Verdict.bad,
    notes: 'Assassinated by Zimri while drunk in his steward\'s house.',
    citations: ['1 Kings 16:8-14'],
  ),
  KingReign(
    id: 'zimri',
    name: 'Zimri',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 884 BC (7 days)',
    sortKey: -884,
    verdict: Verdict.bad,
    notes:
        'Reigned only seven days before Omri besieged the capital; burned '
        'the palace down over himself rather than surrender.',
    citations: ['1 Kings 16:15-20'],
  ),
  KingReign(
    id: 'omri',
    name: 'Omri',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 884–873 BC (12 years)',
    sortKey: -883,
    verdict: Verdict.bad,
    notes:
        'Founded Samaria as Israel\'s new capital; a militarily significant '
        'king outside scripture, but summarized there only as worse than all '
        'before him.',
    citations: ['1 Kings 16:21-28'],
  ),
  KingReign(
    id: 'ahab',
    name: 'Ahab',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 873–852 BC (22 years)',
    sortKey: -873,
    verdict: Verdict.bad,
    notes:
        'Married Jezebel and built a temple to Baal in Samaria; opposed by '
        'Elijah. His dynasty ended violently with Jehu\'s purge.',
    citations: ['1 Kings 16:29-33', '1 Kings 21:25-26'],
  ),
  KingReign(
    id: 'ahaziah-israel',
    name: 'Ahaziah of Israel',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 852–851 BC',
    sortKey: -852,
    verdict: Verdict.bad,
    notes:
        "Ahab's son; injured in a fall and, seeking healing from a foreign "
        'god, was condemned by Elijah for it.',
    citations: ['1 Kings 22:51-53', '2 Kings 1:2-4'],
  ),
  KingReign(
    id: 'jehoram-israel',
    name: 'Jehoram (Joram) of Israel',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 851–841 BC',
    sortKey: -851,
    verdict: Verdict.mixed,
    notes:
        'Removed the sacred pillar of Baal his father set up, but kept the '
        "golden-calf worship; reigned during Elisha's ministry.",
    citations: ['2 Kings 3:1-3'],
  ),
  KingReign(
    id: 'jehu',
    name: 'Jehu',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 841–814 BC (28 years)',
    sortKey: -841,
    verdict: Verdict.mixed,
    notes:
        "Anointed by Elisha's servant to destroy Ahab's house; wiped out "
        'Baal worship in Israel but kept the golden calves.',
    citations: ['2 Kings 9:6-10', '2 Kings 10:28-31'],
  ),
  KingReign(
    id: 'jehoahaz-israel',
    name: 'Jehoahaz of Israel',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 814–798 BC (17 years)',
    sortKey: -814,
    verdict: Verdict.bad,
    notes: "Israel was reduced militarily under Aram's oppression.",
    citations: ['2 Kings 13:1-9'],
  ),
  KingReign(
    id: 'jehoash-israel',
    name: 'Jehoash (Joash) of Israel',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 798–782 BC (16 years)',
    sortKey: -798,
    verdict: Verdict.bad,
    notes: 'Wept at the dying Elisha\'s bedside and recovered cities from Aram.',
    citations: ['2 Kings 13:10-13'],
  ),
  KingReign(
    id: 'jeroboam-2',
    name: 'Jeroboam II',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 793–753 BC (41 years)',
    sortKey: -793,
    verdict: Verdict.bad,
    notes:
        "Israel's most prosperous and militarily successful king, restoring "
        "its borders — yet judged as evil; Amos and Hosea prophesied "
        'against the era\'s social injustice.',
    citations: ['2 Kings 14:23-29'],
  ),
  KingReign(
    id: 'zechariah-israel',
    name: 'Zechariah',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 753 BC (6 months)',
    sortKey: -753,
    verdict: Verdict.bad,
    notes:
        "Jeroboam II's son; assassinated by Shallum, ending Jehu's dynasty in "
        'the fourth generation exactly as God had promised Jehu.',
    citations: ['2 Kings 15:8-12'],
  ),
  KingReign(
    id: 'shallum',
    name: 'Shallum',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 752 BC (1 month)',
    sortKey: -752,
    verdict: Verdict.bad,
    notes: 'Assassinated Zechariah, then was assassinated by Menahem in turn.',
    citations: ['2 Kings 15:13-15'],
  ),
  KingReign(
    id: 'menahem',
    name: 'Menahem',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 752–742 BC (10 years)',
    sortKey: -751,
    verdict: Verdict.bad,
    notes: 'Paid tribute to Assyria\'s Pul (Tiglath-Pileser III) to secure his throne.',
    citations: ['2 Kings 15:16-22'],
  ),
  KingReign(
    id: 'pekahiah',
    name: 'Pekahiah',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 742–740 BC (2 years)',
    sortKey: -742,
    verdict: Verdict.bad,
    notes: 'Assassinated by his own captain, Pekah.',
    citations: ['2 Kings 15:23-26'],
  ),
  KingReign(
    id: 'pekah',
    name: 'Pekah',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 740–732 BC',
    sortKey: -740,
    verdict: Verdict.bad,
    notes:
        'Allied with Syria against Judah (the Syro-Ephraimite war of Isaiah '
        '7); Tiglath-Pileser III annexed much of Israel\'s territory during '
        'his reign.',
    citations: ['2 Kings 15:27-31'],
  ),
  KingReign(
    id: 'hoshea',
    name: 'Hoshea',
    realm: Realm.israel,
    title: 'King',
    reignSummary: 'c. 732–722 BC (9 years)',
    sortKey: -732,
    verdict: Verdict.bad,
    notes:
        "Israel's last king; his rebellion brought Assyria's Shalmaneser V to "
        'besiege and finally destroy Samaria, ending the northern kingdom.',
    citations: ['2 Kings 17:1-6'],
  ),

  // --- Southern Kingdom (Judah) ---
  KingReign(
    id: 'rehoboam',
    name: 'Rehoboam',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 930–913 BC (17 years)',
    sortKey: -930,
    verdict: Verdict.bad,
    notes:
        "Solomon's son; his harsh response to the tribes' request for relief "
        'split the kingdom in two.',
    citations: ['1 Kings 12:1-19', '1 Kings 14:21-24'],
  ),
  KingReign(
    id: 'abijam',
    name: 'Abijam (Abijah)',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 913–911 BC (3 years)',
    sortKey: -913,
    verdict: Verdict.bad,
    notes: 'Continued his father\'s sins, though he defeated Jeroboam in battle.',
    citations: ['1 Kings 15:1-8'],
  ),
  KingReign(
    id: 'asa',
    name: 'Asa',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 911–870 BC (41 years)',
    sortKey: -911,
    verdict: Verdict.good,
    notes: 'Removed idols and his own grandmother from her position for idolatry.',
    citations: ['1 Kings 15:9-24'],
  ),
  KingReign(
    id: 'jehoshaphat',
    name: 'Jehoshaphat',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 870–848 BC (25 years)',
    sortKey: -870,
    verdict: Verdict.good,
    notes:
        'Strengthened Judah and sent teachers throughout the land, though he '
        "allied uneasily with Israel's Ahab.",
    citations: ['1 Kings 22:41-50'],
  ),
  KingReign(
    id: 'jehoram-judah',
    name: 'Jehoram of Judah',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 848–841 BC (8 years)',
    sortKey: -848,
    verdict: Verdict.bad,
    notes:
        "Married Ahab's daughter Athaliah and killed his own brothers to "
        'secure the throne.',
    citations: ['2 Kings 8:16-24'],
  ),
  KingReign(
    id: 'ahaziah-judah',
    name: 'Ahaziah of Judah',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 841 BC (1 year)',
    sortKey: -841,
    verdict: Verdict.bad,
    notes: 'Killed by Jehu\'s purge while visiting his uncle Joram of Israel.',
    citations: ['2 Kings 8:25-29', '2 Kings 9:27-29'],
  ),
  KingReign(
    id: 'athaliah',
    name: 'Athaliah',
    realm: Realm.judah,
    title: 'Queen',
    reignSummary: 'c. 841–835 BC (6 years)',
    sortKey: -840,
    verdict: Verdict.bad,
    notes:
        "Ahab and Jezebel's daughter; seized the throne by killing the royal "
        "family, but her grandson Joash was hidden and survived to depose "
        'her.',
    citations: ['2 Kings 11:1-3', '2 Kings 11:13-16'],
  ),
  KingReign(
    id: 'joash-judah',
    name: 'Joash (Jehoash) of Judah',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 835–796 BC (40 years)',
    sortKey: -835,
    verdict: Verdict.mixed,
    notes:
        'Repaired the temple while the priest Jehoiada lived, but turned to '
        'idolatry after his death and had Jehoiada\'s son murdered.',
    citations: ['2 Kings 11:21', '2 Kings 12:1-3', '2 Kings 12:19-21'],
  ),
  KingReign(
    id: 'amaziah',
    name: 'Amaziah',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 796–767 BC (29 years)',
    sortKey: -796,
    verdict: Verdict.mixed,
    notes:
        'Defeated Edom but then worshipped its gods; provoked a disastrous '
        'war with Israel.',
    citations: ['2 Kings 14:1-6', '2 Kings 14:17-20'],
  ),
  KingReign(
    id: 'uzziah',
    name: 'Uzziah (Azariah)',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 792–740 BC (52 years)',
    sortKey: -792,
    verdict: Verdict.mixed,
    notes:
        'A long, strong reign undone at the end by pride: he entered the '
        "temple to burn incense himself and was struck with leprosy for it.",
    citations: ['2 Kings 15:1-4', '2 Chronicles 26:16-21'],
  ),
  KingReign(
    id: 'jotham',
    name: 'Jotham',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 750–735 BC (16 years)',
    sortKey: -750,
    verdict: Verdict.good,
    notes: 'Built extensively but the high places of idol worship remained.',
    citations: ['2 Kings 15:32-35'],
  ),
  KingReign(
    id: 'ahaz',
    name: 'Ahaz',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 735–715 BC (16 years)',
    sortKey: -735,
    verdict: Verdict.bad,
    notes:
        'Sacrificed his own son and appealed to Assyria for help against '
        "Israel and Syria — the setting for Isaiah's Immanuel sign.",
    citations: ['2 Kings 16:1-4', '2 Kings 16:10-13'],
  ),
  KingReign(
    id: 'hezekiah',
    name: 'Hezekiah',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 715–686 BC (29 years)',
    sortKey: -715,
    verdict: Verdict.good,
    notes:
        'Removed idolatry, survived Sennacherib\'s siege of Jerusalem after '
        "praying in the temple, and recovered from a terminal illness when "
        'God granted him 15 more years.',
    citations: ['2 Kings 18:1-6', '2 Kings 19:35-37', '2 Kings 20:1-11'],
  ),
  KingReign(
    id: 'manasseh',
    name: 'Manasseh',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 697–642 BC (55 years, Judah\'s longest reign)',
    sortKey: -697,
    verdict: Verdict.mixed,
    notes:
        "Judah's most idolatrous king, filling Jerusalem with innocent "
        'blood — yet, taken captive to Babylon, he humbled himself and was '
        'restored, per 2 Chronicles.',
    citations: ['2 Kings 21:1-9', '2 Chronicles 33:10-13'],
  ),
  KingReign(
    id: 'amon',
    name: 'Amon',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 642–640 BC (2 years)',
    sortKey: -642,
    verdict: Verdict.bad,
    notes: 'Continued his father\'s early idolatry; assassinated by his own servants.',
    citations: ['2 Kings 21:19-24'],
  ),
  KingReign(
    id: 'josiah',
    name: 'Josiah',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 640–609 BC (31 years)',
    sortKey: -640,
    verdict: Verdict.good,
    notes:
        "Became king at age 8; rediscovered the Book of the Law during "
        'temple repairs and led Judah\'s last great reform. Killed in battle '
        'against Pharaoh Necho at Megiddo.',
    citations: ['2 Kings 22:1-2', '2 Kings 23:1-3', '2 Kings 23:29-30'],
  ),
  KingReign(
    id: 'jehoahaz-judah',
    name: 'Jehoahaz of Judah',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 609 BC (3 months)',
    sortKey: -609,
    verdict: Verdict.bad,
    notes: 'Deposed by Pharaoh Necho after only three months and taken captive to Egypt.',
    citations: ['2 Kings 23:31-34'],
  ),
  KingReign(
    id: 'jehoiakim',
    name: 'Jehoiakim',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 609–598 BC (11 years)',
    sortKey: -608,
    verdict: Verdict.bad,
    notes:
        'Installed by Egypt, later vassal to Babylon; burned a scroll of '
        "Jeremiah's prophecies section by section as it was read to him.",
    citations: ['2 Kings 23:34-35', '2 Kings 24:1-2'],
  ),
  KingReign(
    id: 'jehoiachin',
    name: 'Jehoiachin (Jeconiah)',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 598–597 BC (3 months)',
    sortKey: -598,
    verdict: Verdict.bad,
    notes:
        'Surrendered Jerusalem to Nebuchadnezzar and was carried to Babylon '
        'with the nobility and craftsmen; later released from prison in his '
        'old age, per the book\'s closing verses.',
    citations: ['2 Kings 24:6-9', '2 Kings 24:12-15'],
  ),
  KingReign(
    id: 'zedekiah',
    name: 'Zedekiah',
    realm: Realm.judah,
    title: 'King',
    reignSummary: 'c. 597–586 BC (11 years)',
    sortKey: -597,
    verdict: Verdict.bad,
    notes:
        "Judah's last king; his rebellion brought Nebuchadnezzar to destroy "
        "Jerusalem and the temple, ending the kingdom.",
    citations: ['2 Kings 24:17-18', '2 Kings 25:1-7'],
  ),

  // --- Egypt ---
  KingReign(
    id: 'pharaoh-joseph',
    name: 'Pharaoh of Joseph',
    realm: Realm.egypt,
    title: 'Pharaoh',
    reignSummary: 'c. 1876 BC (unnamed)',
    sortKey: -1876,
    notes:
        "Elevated Joseph to rule Egypt second only to himself after Joseph "
        'interpreted his dreams of coming famine.',
    citations: ['Genesis 41:37-41'],
  ),
  KingReign(
    id: 'pharaoh-oppression',
    name: 'Pharaoh of the Oppression',
    realm: Realm.egypt,
    title: 'Pharaoh',
    reignSummary: 'c. 1526 BC (unnamed)',
    sortKey: -1526,
    notes:
        'A new king "who knew not Joseph" enslaved the Israelites and '
        'ordered Hebrew infant boys killed.',
    citations: ['Exodus 1:8-11'],
  ),
  KingReign(
    id: 'pharaoh-exodus',
    name: 'Pharaoh of the Exodus',
    realm: Realm.egypt,
    title: 'Pharaoh',
    reignSummary: 'c. 1446 BC (unnamed)',
    sortKey: -1446,
    notes:
        'Refused Moses\' demand to let Israel go through nine plagues; his '
        "army drowned in the Red Sea pursuing them after the tenth.",
    citations: ['Exodus 5:1-2', 'Exodus 14:5-9'],
  ),
  KingReign(
    id: 'shishak',
    name: 'Shishak',
    realm: Realm.egypt,
    title: 'Pharaoh',
    reignSummary: 'c. 925 BC',
    sortKey: -925,
    notes: 'Invaded Judah and plundered the temple treasures in Rehoboam\'s reign.',
    citations: ['1 Kings 14:25-26'],
  ),
  KingReign(
    id: 'so',
    name: 'So',
    realm: Realm.egypt,
    title: 'King',
    reignSummary: 'c. 725 BC',
    sortKey: -725,
    notes: "Hoshea's failed alliance-partner against Assyria, named only in passing.",
    citations: ['2 Kings 17:4'],
  ),
  KingReign(
    id: 'necho',
    name: 'Necho II',
    realm: Realm.egypt,
    title: 'Pharaoh',
    reignSummary: 'c. 610–595 BC',
    sortKey: -610,
    notes:
        'Killed Josiah in battle at Megiddo, then deposed Jehoahaz and '
        'installed Jehoiakim as Judah\'s vassal king.',
    citations: ['2 Kings 23:29', '2 Kings 23:33-35'],
  ),
  KingReign(
    id: 'hophra',
    name: 'Hophra',
    realm: Realm.egypt,
    title: 'Pharaoh',
    reignSummary: 'c. 589–570 BC',
    sortKey: -589,
    notes: 'Jeremiah prophesied his downfall as he did Zedekiah\'s.',
    citations: ['Jeremiah 44:30'],
  ),

  // --- Assyria ---
  KingReign(
    id: 'tiglath-pileser',
    name: 'Tiglath-Pileser III (Pul)',
    realm: Realm.assyria,
    title: 'King',
    reignSummary: 'c. 745–727 BC',
    sortKey: -745,
    notes: 'Received tribute from Menahem and annexed Israelite territory under Pekah.',
    citations: ['2 Kings 15:19-20', '2 Kings 16:7-10'],
  ),
  KingReign(
    id: 'shalmaneser-5',
    name: 'Shalmaneser V',
    realm: Realm.assyria,
    title: 'King',
    reignSummary: 'c. 727–722 BC',
    sortKey: -727,
    notes: 'Besieged Samaria for three years, bringing Hoshea\'s rebellion to an end.',
    citations: ['2 Kings 17:3-6'],
  ),
  KingReign(
    id: 'sargon-2',
    name: 'Sargon II',
    realm: Realm.assyria,
    title: 'King',
    reignSummary: 'c. 722–705 BC',
    sortKey: -722,
    notes: 'Completed Samaria\'s conquest and deportation; named once by Isaiah.',
    citations: ['Isaiah 20:1'],
  ),
  KingReign(
    id: 'sennacherib',
    name: 'Sennacherib',
    realm: Realm.assyria,
    title: 'King',
    reignSummary: 'c. 705–681 BC',
    sortKey: -705,
    notes:
        "Invaded Judah and besieged Jerusalem under Hezekiah; his army was "
        'struck down overnight, and he was later assassinated by his own sons.',
    citations: ['2 Kings 18:13-16', '2 Kings 19:35-37'],
  ),
  KingReign(
    id: 'esarhaddon',
    name: 'Esarhaddon',
    realm: Realm.assyria,
    title: 'King',
    reignSummary: 'c. 681–669 BC',
    sortKey: -681,
    notes: 'Succeeded his father Sennacherib; resettled foreign peoples in Samaria\'s territory.',
    citations: ['2 Kings 19:37', 'Ezra 4:2'],
  ),
  KingReign(
    id: 'ashurbanipal',
    name: 'Ashurbanipal (Asnapper)',
    realm: Realm.assyria,
    title: 'King',
    reignSummary: 'c. 669–631 BC',
    sortKey: -669,
    notes: 'Assyria\'s last great king, named once in Ezra as the one who resettled Samaria.',
    citations: ['Ezra 4:10'],
  ),

  // --- Babylon ---
  KingReign(
    id: 'merodach-baladan',
    name: 'Merodach-baladan',
    realm: Realm.babylon,
    title: 'King',
    reignSummary: 'c. 721–710 BC',
    sortKey: -721,
    notes: "Sent envoys to Hezekiah, who unwisely showed off Judah's treasuries to them.",
    citations: ['2 Kings 20:12-13', 'Isaiah 39:1'],
  ),
  KingReign(
    id: 'nebuchadnezzar',
    name: 'Nebuchadnezzar II',
    realm: Realm.babylon,
    title: 'King',
    reignSummary: 'c. 605–562 BC',
    sortKey: -605,
    notes:
        'Destroyed Jerusalem and its temple, taking Judah captive; humbled '
        'to madness for seven years in Daniel\'s account, then restored.',
    citations: ['2 Kings 24:1', '2 Kings 25:8-10', 'Daniel 4:28-33'],
  ),
  KingReign(
    id: 'evil-merodach',
    name: 'Evil-Merodach (Amel-Marduk)',
    realm: Realm.babylon,
    title: 'King',
    reignSummary: 'c. 562–560 BC',
    sortKey: -562,
    notes: 'Released the exiled Jehoiachin from prison and gave him a seat of honor.',
    citations: ['2 Kings 25:27-30'],
  ),
  KingReign(
    id: 'belshazzar',
    name: 'Belshazzar',
    realm: Realm.babylon,
    title: 'King',
    reignSummary: 'c. 553–539 BC',
    sortKey: -553,
    notes:
        'Saw the handwriting on the wall at his own feast and was slain that '
        'same night when Babylon fell.',
    citations: ['Daniel 5:1-4', 'Daniel 5:30'],
  ),
  KingReign(
    id: 'darius-the-mede',
    name: 'Darius the Mede',
    realm: Realm.babylon,
    title: 'King',
    reignSummary: 'c. 539 BC',
    sortKey: -539,
    notes: 'Received the kingdom at Babylon\'s fall; the ruler of Daniel\'s lions\' den account.',
    citations: ['Daniel 5:31', 'Daniel 6:16'],
  ),

  // --- Persia ---
  KingReign(
    id: 'cyrus',
    name: 'Cyrus the Great',
    realm: Realm.persia,
    title: 'King',
    reignSummary: 'c. 559–530 BC',
    sortKey: -559,
    notes:
        'Named by Isaiah more than a century before his birth; decreed the '
        'exiles\' return and the temple\'s rebuilding.',
    citations: ['2 Chronicles 36:22-23', 'Ezra 1:1-4', 'Isaiah 44:28'],
  ),
  KingReign(
    id: 'darius-1',
    name: 'Darius I (the Great)',
    realm: Realm.persia,
    title: 'King',
    reignSummary: 'c. 522–486 BC',
    sortKey: -522,
    notes: 'Confirmed Cyrus\' decree and let temple construction resume after local opposition.',
    citations: ['Ezra 4:24', 'Ezra 6:1-5'],
  ),
  KingReign(
    id: 'ahasuerus',
    name: 'Ahasuerus (Xerxes I)',
    realm: Realm.persia,
    title: 'King',
    reignSummary: 'c. 486–465 BC',
    sortKey: -486,
    notes: 'Made Esther queen; his edict against the Jews was reversed through her intervention.',
    citations: ['Esther 1:1-2', 'Esther 8:1-2'],
  ),
  KingReign(
    id: 'artaxerxes-1',
    name: 'Artaxerxes I (Longimanus)',
    realm: Realm.persia,
    title: 'King',
    reignSummary: 'c. 465–424 BC',
    sortKey: -465,
    notes: 'Commissioned Ezra\'s return to teach the Law, then Nehemiah\'s to rebuild Jerusalem\'s walls.',
    citations: ['Ezra 7:11-13', 'Nehemiah 2:1-6'],
  ),

  // --- Rome ---
  KingReign(
    id: 'augustus',
    name: 'Caesar Augustus',
    realm: Realm.rome,
    title: 'Emperor',
    reignSummary: '27 BC–AD 14',
    sortKey: -27,
    notes: 'His census decree brought Joseph and Mary to Bethlehem for Jesus\' birth.',
    citations: ['Luke 2:1'],
  ),
  KingReign(
    id: 'herod-great',
    name: 'Herod the Great',
    realm: Realm.rome,
    title: 'King',
    reignSummary: '37–4 BC',
    sortKey: -37,
    notes:
        'Client king of Judea when Jesus was born; ordered the massacre of '
        'Bethlehem\'s infant boys after the magi\'s visit.',
    citations: ['Matthew 2:1-3', 'Matthew 2:16'],
  ),
  KingReign(
    id: 'archelaus',
    name: 'Herod Archelaus',
    realm: Realm.rome,
    title: 'Ethnarch',
    reignSummary: '4 BC–AD 6',
    sortKey: -4,
    notes: 'Ruled Judea after his father; Joseph avoided him by settling in Nazareth instead.',
    citations: ['Matthew 2:22'],
  ),
  KingReign(
    id: 'antipas',
    name: 'Herod Antipas',
    realm: Realm.rome,
    title: 'Tetrarch',
    reignSummary: '4 BC–AD 39',
    sortKey: -3,
    notes:
        'Ruled Galilee through Jesus\' entire ministry; beheaded John the '
        'Baptist and mocked Jesus at his trial.',
    citations: ['Luke 3:19-20', 'Matthew 14:3-5', 'Luke 23:8-11'],
  ),
  KingReign(
    id: 'tiberius',
    name: 'Tiberius Caesar',
    realm: Realm.rome,
    title: 'Emperor',
    reignSummary: 'AD 14–37',
    sortKey: 14,
    notes: 'Reigning emperor when John the Baptist and Jesus began their public ministries.',
    citations: ['Luke 3:1'],
  ),
  KingReign(
    id: 'agrippa-1',
    name: 'Herod Agrippa I',
    realm: Realm.rome,
    title: 'King',
    reignSummary: 'AD 37–44',
    sortKey: 37,
    notes:
        'Executed the apostle James and imprisoned Peter; struck down by an '
        'angel after accepting worship as a god.',
    citations: ['Acts 12:1-4', 'Acts 12:21-23'],
  ),
  KingReign(
    id: 'claudius',
    name: 'Claudius Caesar',
    realm: Realm.rome,
    title: 'Emperor',
    reignSummary: 'AD 41–54',
    sortKey: 41,
    notes: 'His expulsion of Jews from Rome scattered Priscilla and Aquila to meet Paul in Corinth.',
    citations: ['Acts 11:28', 'Acts 18:2'],
  ),
  KingReign(
    id: 'nero',
    name: 'Caesar (Nero)',
    realm: Realm.rome,
    title: 'Emperor',
    reignSummary: 'AD 54–68',
    sortKey: 54,
    notes:
        'Never named directly in the New Testament — only as "Caesar," the '
        'emperor to whom Paul appealed and was ultimately sent.',
    citations: ['Acts 25:11-12', 'Philippians 4:22'],
  ),
  KingReign(
    id: 'agrippa-2',
    name: 'Herod Agrippa II',
    realm: Realm.rome,
    title: 'King',
    reignSummary: 'AD 50–c. 93',
    sortKey: 50,
    notes: 'Heard Paul\'s defense and famously replied, "Almost thou persuadest me to be a Christian."',
    citations: ['Acts 25:13', 'Acts 26:27-28'],
  ),
];
