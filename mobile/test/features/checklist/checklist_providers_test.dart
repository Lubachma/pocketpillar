import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/core/utils/clock.dart';
import 'package:pocketpillar/features/checklist/application/checklist_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;
  late int year;

  setUp(() async {
    year = 2026;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(year, 11, 15)),
      ],
    );
    addTearDown(container.dispose);
  });

  Set<String> readCompleted() => container.read(checklistCompletedIdsProvider);

  Future<void> toggle(String id) =>
      container.read(checklistCompletedIdsProvider.notifier).toggle(id);

  test('empty initial state', () {
    expect(readCompleted(), isEmpty);
  });

  test('toggle checks and persists under checklist.<year>.completed', () async {
    await toggle('tax_documents');

    expect(readCompleted(), {'tax_documents'});
    expect(prefs.getStringList('checklist.2026.completed'), ['tax_documents']);
  });

  test('persistence is reread by a fresh repository instance', () async {
    await toggle('max_3a');
    await toggle('bvg_buyback');

    // Proves the state doesn't live only in memory.
    expect(
      PreferencesRepository(prefs).getCompletedChecklistItems(2026).toSet(),
      {'max_3a', 'bvg_buyback'},
    );
  });

  test('a second toggle unchecks and updates persistence', () async {
    await toggle('max_3a');
    await toggle('max_3a');

    expect(readCompleted(), isEmpty);
    expect(prefs.getStringList('checklist.2026.completed'), isEmpty);
  });

  test('annual reset: new year → new empty key, year N kept', () async {
    await toggle('tax_documents');

    // New year (reload, e.g. app relaunch): reset.
    year = 2027;
    container.invalidate(checklistCompletedIdsProvider);
    expect(readCompleted(), isEmpty);
    // Previous year isn't purged (iOS parity).
    expect(prefs.getStringList('checklist.2026.completed'), ['tax_documents']);

    // Back to 2026: checked items are still there.
    year = 2026;
    container.invalidate(checklistCompletedIdsProvider);
    expect(readCompleted(), {'tax_documents'});
  });

  test('checking an item notifies provider listeners (dashboard ring '
      'refreshed on return — TODO 3.2 resolved)', () async {
    final seen = <Set<String>>[];
    container.listen(
      checklistCompletedIdsProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );

    await toggle('plan_next_year');

    // The dashboard card watches the same provider: it receives the new
    // state without manual invalidation.
    expect(seen, [
      <String>{},
      {'plan_next_year'},
    ]);
  });
}
