# Home-screen widgets — implementation plan

Status: **planned, not started** (written 2026-07-08).

Goal: ship three home-screen widgets — **Verse of the Day**, **Upcoming
Actions**, and **Ribbons** — where tapping a verse reference (VOTD card or a
ribbon row) opens the Bible reader at that exact spot.

## Scope & platform strategy

| Platform | Plan |
|----------|------|
| Android  | Phase 1 — App Widgets, primary target |
| iOS / macOS | Phase 2 — one WidgetKit extension covers both; do after Android proves the data plumbing |
| Windows / Linux / web | Out of scope (no viable third-party widget surface) |

Bridge plugin: [`home_widget`](https://pub.dev/packages/home_widget). Flutter
never renders the widgets; Dart writes data into shared storage
(`SharedPreferences` on Android, App Group `UserDefaults` on Apple platforms)
and requests a refresh, and small native UIs (RemoteViews XML / SwiftUI) render
it. Widgets ship inside the existing APK/AAB and `.ipa` — no separate install.

## Existing code to build on

- **Verse of the Day**: `versesOfTheDay` in
  `lib/data/verse_of_the_day_list.dart` — a `const` list of
  `(reference, text)` pairs indexed by `dayOfYear % length`
  (see `_buildVerseOfTheDayCard` in `lib/ui/dashboard/dashboard_screen.dart`).
  Pure function of the date — the widget payload can be precomputed for future
  days.
- **Action items**: `actionItemsProvider` (drift stream) and the pure helper
  `actionsNeedingAlert` in `lib/app/action_providers.dart`; rows have
  `dueAt`, `completedAt`, `deleted`.
- **Ribbons**: `allBookmarksProvider` in `lib/app/user_providers.dart`
  (non-deleted bookmarks, newest-first); rows have
  `bookName`/`chapter`/`verse`/`label`.
- **Navigate-to-verse**: `_RibbonTile._goTo` in
  `lib/ui/reader/ribbons_panel.dart:109` and the VOTD card's `onTap` in
  `lib/ui/dashboard/dashboard_screen.dart:932` both do the same provider dance
  (set book/chapter, `targetVerseToScrollProvider`, select verse,
  `recordHistory`, switch to `AppModule.reader`).
- **External-launch handling precedent**: `NotificationService(onTap:)` wiring
  in `lib/main.dart:117` — widget deep links follow the same shape.

## Phase 0 — shared groundwork (pure Flutter/Dart, no native code)

1. **Extract an `openVerse` helper.** Add
   `NavigationController.openVerse(String bookName, int chapter, int verse)`
   (in `lib/app/content_providers.dart`, where `NavigationController` lives)
   encapsulating the set-book/chapter/scroll-target/selection/history/module
   sequence. Refactor `_RibbonTile._goTo` and the dashboard VOTD card to use
   it. This is a standalone `refactor:` commit.
2. **Widget payload builders (pure Dart, unit-testable).** New
   `lib/domain/widget_payload.dart`: functions that turn
   `List<Bookmark>` / `List<ActionItem>` / a date into small JSON maps for the
   native side. Rules:
   - VOTD: emit today + the next ~7 days keyed by `yyyy-MM-dd`, so the native
     widget stays correct across midnight without the app running.
   - Actions: not completed, not deleted, `dueAt != null`, sorted by `dueAt`
     ascending, capped at 5; include id, title, due timestamp, and an
     overdue flag (reuse the `kActionLeadMs` semantics).
   - Ribbons: newest-first, capped at 5; include bookName, chapter, verse,
     label, and a preformatted `"Book C:V"` reference string.
   - **Caveat:** if ribbon rows ever include verse *text*, clean it with
     `MyBibleVerseParser` first — `Verse.textContent` carries inline
     Strong's/footnote markup. (V1 shows reference + label only, so this
     doesn't bite yet.)
   - Domain purity: no Flutter/`dart:io` imports here — `tool/lint_domain.sh`
     enforces it.
3. **Widget data sync service.** New `lib/app/widget_sync_providers.dart`:
   a controller that (on supported platforms only) listens to
   `actionItemsProvider` + `allBookmarksProvider`, debounces, writes payloads
   via `HomeWidget.saveWidgetData`, and calls `HomeWidget.updateWidget` for
   each widget. Kick it off in `main.dart` next to
   `actionNotificationSchedulerProvider` (same idempotent-on-resume pattern).
   Data freshness model: user data only changes while the app runs (sync is
   file-based, in-app), so "push on change + refresh on app open" is correct;
   only VOTD needs the multi-day precompute above.
4. **Deep-link handling.** URI scheme carried through `home_widget`'s click
   plumbing (no Android intent-filter / iOS URL-scheme registration needed —
   the plugin delivers it):
   - `studybible://read?book=<name>&chapter=<n>&verse=<n>` → `openVerse(...)`
   - `studybible://actions` (and optionally `?id=<uuid>`) → journals/actions
     module
   In `main.dart`, handle both `HomeWidget.initiallyLaunchedFromHomeWidget()`
   (cold start — run after `runApp`, mirroring the notification-payload
   pattern) and `HomeWidget.widgetClicked` (warm resume). Parse in a pure
   helper (unit-test it; book names contain spaces — URL-encode).

## Phase 1 — Android

App id / namespace: `io.github.crazymevt.studybible`; Kotlin sources at
`android/app/src/main/kotlin/io/github/crazymevt/studybible/`.

1. Add `home_widget` to `pubspec.yaml`.
2. Three `AppWidgetProvider` subclasses (Kotlin) + `<receiver>` entries in
   `AndroidManifest.xml` + `res/xml/` widget-info files + `res/layout/`
   RemoteViews layouts:
   - `VerseOfTheDayWidget` — resizable card, reference + text, whole card
     tappable → verse deep link. 2×2 default.
   - `UpcomingActionsWidget` — header + up to 5 rows. Use the **fixed-row-slot
     trick** (inflate 5 hidden row views, show as needed) instead of
     `RemoteViewsService`/`ListView` — far less native code, fine at 5 rows.
     Rows tap → `studybible://actions`. Empty state: "No upcoming actions."
   - `RibbonsWidget` — same fixed-slot pattern; each row taps to its own
     verse deep link (per-row `PendingIntent` with distinct request codes).
   Keep classic RemoteViews XML (no Jetpack Glance) — avoids pulling the
   Compose runtime into a Flutter app for three simple layouts.
3. Widget-info details: `updatePeriodMillis` = 12 h (only matters for VOTD's
   date rollover — payload already contains future days, so the provider's
   `onUpdate` just re-reads and re-renders; no background Dart needed),
   `previewImage`, min sizes, light/dark via
   `values-night/` theme colors to match system.
4. `HomeWidget.setAppGroupId` is Apple-only; on Android the plugin uses
   `HomeWidgetPlugin` shared prefs — note the dev-isolation caveat: debug
   builds namespace `SharedPreferences` with `flutter_dev.`
   (`main.dart:106`), but `home_widget` writes its own prefs file, so dev and
   release installs of the widget would share data **only if both are
   installed** — they can't be (same application id), so this is a non-issue;
   just verify once on the emulator.
5. Manual verification (emulator notes: JDK 17 required — see memory
   `android-build-needs-jdk17`): add each widget from the picker, check empty
   states, add a ribbon/action in-app and confirm the widget refreshes, tap a
   ribbon row → reader lands on the verse (cold start *and* warm), cross
   midnight (or fake the clock) for VOTD rollover.

## Phase 2 — iOS + macOS (later)

1. One WidgetKit extension target added in Xcode (`ios/Runner.xcworkspace`),
   SwiftUI views for the three widgets; macOS gets the same widgets via a
   sibling target sharing the Swift files.
2. App Groups capability on Runner + extension
   (`group.io.github.crazymevt.studybible`), `HomeWidget.setAppGroupId` in the
   sync service.
3. Timeline provider: VOTD uses a real `Timeline` with one entry per day (the
   multi-day payload maps directly onto this); actions/ribbons use `.atEnd`
   reload + `WidgetCenter` reloads triggered from `home_widget`.
4. Deep links via `widgetURL`/`Link` with the same `studybible://` URIs.

## Testing

- Unit tests: payload builders (empty lists, >5 items, markup stripping,
  VOTD year boundary / leap day) and the deep-link URI parser (spaces in book
  names, malformed input). All pure Dart — no widget-test infra fights.
- `flutter analyze` + full `flutter test` before merge (CI analyzer is
  stricter; provider lifecycle issues only surface in tests).
- No widget-rendering tests: the native layouts are verified manually
  (screenshots on emulator).

## Commit / changelog notes

- Phase 0 refactor: `refactor:` (user-facing changelog) or `dev:` if kept
  invisible; the widget features themselves: `feat: add home-screen widgets
  (verse of the day, upcoming actions, ribbons)` — one `feat:` per shippable
  slice is fine.
- `./scripts/release.sh` gate must pass (`tool/lint_domain.sh` will catch any
  accidental Flutter import in `lib/domain/widget_payload.dart`).

## Open decisions (resolve when starting)

1. **Action row tap target** — whole widget → actions list (simple, v1
   recommendation) vs. per-item deep link into the editor.
2. **Ribbon count/ordering** — newest-first cap of 5 matches
   `allBookmarksProvider`; canonical book order (like the panel) is a
   possible refinement.
3. **VOTD translation** — the curated list is KJV text baked into
   `verse_of_the_day_list.dart`; fetching the user's active translation for
   the widget would need DB access in the sync service (doable — same
   provider graph — but adds churn; skip for v1).
