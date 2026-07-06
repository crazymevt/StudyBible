import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/app/feast_providers.dart';

void main() {
  test('feastsOnDateProvider finds the Feast of Trumpets on Rosh Hashana 2026', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = container.read(feastsOnDateProvider(DateTime(2026, 9, 12)));

    expect(result, hasLength(1));
    expect(result.single.$1.name, 'Feast of Trumpets');
  });

  test('feastsOnDateProvider finds a multi-day feast anywhere in its range', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Tabernacles 2026 runs 2026-09-26 through 2026-10-03.
    final result = container.read(feastsOnDateProvider(DateTime(2026, 9, 30)));

    expect(result, hasLength(1));
    expect(result.single.$1.name, 'Feast of Tabernacles');
  });

  test('feastsOnDateProvider returns nothing on an ordinary day', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = container.read(feastsOnDateProvider(DateTime(2026, 1, 15)));

    expect(result, isEmpty);
  });
}
