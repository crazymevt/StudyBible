import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:study_bible/data/content_store.dart';

void main() {
  test('Generate sample DB', () async {
    final dbFile = File('assets/content.db');
    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }
    
    if (!Directory('assets').existsSync()) {
      Directory('assets').createSync();
    }

    final db = ContentStore(NativeDatabase(dbFile));
    
    // Insert Version
    await db.into(db.versions).insert(
      VersionsCompanion.insert(
        id: 'NLT',
        abbreviation: 'NLT',
        name: 'New Living Translation',
        language: const Value('en'),
      )
    );

    // Insert Book
    final bookId = await db.into(db.books).insert(
      BooksCompanion.insert(
        versionId: 'NLT',
        name: 'John',
        bookOrder: 43,
        testament: 'NT',
      )
    );

    // Insert Verses
    final segments1 = [
      {"text": "In the beginning the Word already existed. The Word was with God, and the Word was God."},
    ];
    final segments2 = [
      {"text": "He existed in the beginning with God."},
    ];
    final segments3 = [
      {"text": "God created everything through him, and nothing was created except through him."},
    ];

    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: bookId,
        chapter: 1,
        verse: 1,
        textContent: "In the beginning the Word already existed. The Word was with God, and the Word was God.",
        segments: jsonEncode(segments1),
      )
    );
    
    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: bookId,
        chapter: 1,
        verse: 2,
        textContent: "He existed in the beginning with God.",
        segments: jsonEncode(segments2),
      )
    );

    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: bookId,
        chapter: 1,
        verse: 3,
        textContent: "God created everything through him, and nothing was created except through him.",
        segments: jsonEncode(segments3),
      )
    );

    await db.close();
    print("✅ Generated sample assets/content.db");
  });
}
