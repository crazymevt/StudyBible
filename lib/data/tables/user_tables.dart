import 'package:drift/drift.dart';

@DataClassName('Highlight')
class Highlights extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get colorHex => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Note')
class Notes extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer().nullable()();
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Bookmark')
class Bookmarks extends Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get label => text()();

  @override
  Set<Column> get primaryKey => {id};
}
