import 'covenant.dart';

/// The five major covenants of scripture, in the order God makes them
/// across redemptive history.
const List<Covenant> covenants = [
  Covenant(
    id: 'noahic',
    name: 'Noahic Covenant',
    parties: 'God and every living creature on earth, through Noah',
    terms: 'God will never again destroy all life with a flood.',
    sign: 'The rainbow',
    notes:
        'The first covenant after the flood — unconditional, and universal '
        'in scope rather than limited to Israel.',
    citations: ['Genesis 9:8-11', 'Genesis 9:12-17'],
  ),
  Covenant(
    id: 'abrahamic',
    name: 'Abrahamic Covenant',
    parties: 'God and Abraham, and his descendants after him',
    terms:
        'Abraham would become a great nation, possess the land of Canaan, '
        'and all the families of the earth would be blessed through him.',
    sign: 'Circumcision',
    notes:
        'The foundational promise the rest of scripture\'s storyline traces '
        'back to — land, descendants, and blessing to the nations.',
    citations: ['Genesis 12:1-3', 'Genesis 15:18-21', 'Genesis 17:9-11'],
  ),
  Covenant(
    id: 'mosaic',
    name: 'Mosaic Covenant',
    parties: 'God and the nation of Israel, through Moses at Sinai',
    terms:
        'If Israel obeyed God\'s voice and kept his covenant, they would be '
        'his treasured possession and a kingdom of priests — codified in '
        'the Law given at Sinai.',
    sign: 'The Sabbath',
    notes:
        'Conditional, unlike the Noahic and Abrahamic covenants: Israel\'s '
        'blessing under it depended on obedience, and the nation\'s later '
        'history is largely the story of breaking it.',
    citations: ['Exodus 19:5-6', 'Exodus 24:7-8', 'Exodus 31:16-17'],
  ),
  Covenant(
    id: 'davidic',
    name: 'Davidic Covenant',
    parties: 'God and King David',
    terms:
        'David\'s house, kingdom, and throne would be established forever — '
        'his offspring would build God\'s house, and God would never take '
        'his steadfast love from him.',
    notes:
        'No physical sign is named for this covenant, unlike the others — '
        'it stands as a direct promise. The New Testament identifies Jesus '
        'as its ultimate fulfillment, the eternal heir to David\'s throne.',
    citations: ['2 Samuel 7:12-16', 'Psalms 89:3-4'],
  ),
  Covenant(
    id: 'new',
    name: 'New Covenant',
    parties:
        'God and the house of Israel and Judah — extended, in the New '
        'Testament, to all who believe in Christ',
    terms:
        'God would put his law within them and write it on their hearts, '
        'and remember their sins no more.',
    sign: 'The Lord\'s Supper (the cup as "the new covenant in my blood")',
    notes:
        'Foretold by Jeremiah centuries before Christ; the writer of '
        'Hebrews quotes Jeremiah\'s promise at length to argue it is now '
        'fulfilled.',
    citations: ['Jeremiah 31:31-34', 'Luke 22:20', 'Hebrews 8:8-12'],
  ),
];
