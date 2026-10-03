# Session 10 — App shell, theme, settings (theme + engine rules editor)

**Branch:** `dc3d/s10-settings` · **Depends on:** 02, 05 (the rule definitions).
**Skills:** `vgv-ai-flutter-plugin:bloc`, `…:material-theming`, `…:navigation`,
`…:internationalization`, `…:accessibility`, `…:testing`, `…:layered-architecture`.

## Goal

The app gets its real structure: navigation, Material 3 theme with
system/light/dark, a **settings** screen where the user changes the theme and the
**engine rules**, persisted across launches, and a **home** screen skeleton.

## 1. `settings_repository` (Flutter package)

`flutter_package` `settings_repository` in `packages/`, `workspace: true`, wired, in its
own repository + submodule (`agent-workflow.md` §2 procedure).
Dependencies: `shared_preferences` (use `SharedPreferencesAsync`),
`code_analysis_engine` (only for `AnalysisRules` / `RuleCatalog`), `equatable`.

```dart
enum AppThemeMode { system, light, dark }
class SettingsRepository {
  SettingsRepository({required SharedPreferencesAsync preferences});
  Future<AppThemeMode> themeMode();  Future<void> setThemeMode(AppThemeMode mode);
  Future<AnalysisRules> rules();     Future<void> setRules(AnalysisRules rules);
  Future<void> resetRules();
  Stream<AnalysisRules> watchRules();
}
```
Rules are stored as one JSON string (`AnalysisRules.toJson`). Corrupt JSON → defaults,
never a crash.

## 2. App structure

- `go_router` with typed routes (`navigation` skill): `/` home, `/settings`,
  `/analysis/new` (placeholder until session 15), `/viewer` (placeholder until 11).
- `App` provides `SettingsRepository` (and later `CodeMapRepository`) with
  `MultiRepositoryProvider`. `main_<flavor>.dart` → bootstrap builds them.
- `ThemeCubit` (or `SettingsBloc`, your choice; justify it in the log) drives
  `MaterialApp.router(themeMode: …)`.
- Theme: a `ThemeData` for light and dark in `lib/app/theme/` (`material-theming` skill:
  color scheme from a seed, text theme with the font from session 02, spacing tokens).
  Also expose `CodeWorldColors` as a `ThemeExtension` (background, per-`CodeNodeKind`
  sphere colors, link colors per `LinkKind`, selection highlight) so the 3D viewer
  follows the theme.
- l10n: every string in ARB files, in **English and French** (`app_en.arb`, `app_fr.arb`; owner
  decision, no other locale). Give `MaterialApp` the `appLocalizationsDelegates` list from
  `lib/l10n/l10n.dart`, **never** the generated `AppLocalizations.localizationsDelegates`
  (it registers `flutter_localizations` delegates that do not serve `material_ui` widgets).
  Goldens: add a French variant for at least one phone golden per screen.

## 3. Settings screen (`settings/`)

- Section **Appearance**: theme mode (system / light / dark), as a segmented button.
- Section **Analysis rules**: rendered **generically** from `RuleCatalog.all`,
  grouped by `group`:
  - `BoolParameter` → `SwitchListTile`;
  - `EnumParameter` → dropdown or segmented button; disabled options are shown greyed
    out with their note (e.g. `fullResolution` → "Coming later". Tapping it shows the
    note in a dialog that also explains why it will be slow and heavy);
  - `EnumSetParameter` → filter chips;
  - `GlobListParameter` → chips with delete + a text field to add, validating the glob;
  - `StringParameter` → text field.
  - Each rule shows its title and description.
  - "Reset to defaults" with a confirmation dialog.
- `SettingsBloc` with events `ThemeModeChanged`, `RuleChanged(id, value)`,
  `RulesReset`; states sealed + Equatable.
- Changing rules does **not** re-analyze existing maps. Show a hint: "Applies to new analyses".

## 4. Home screen skeleton (`home/`)

App bar with settings button; empty state ("No code maps yet") with two actions:
**New analysis** and **Open file** (both navigate to placeholders for now). The
recent list arrives in session 15.

## Tests (100% coverage) + goldens

- Repository unit tests with a fake `SharedPreferencesAsync`
  (`SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty()`
  or a mock; check the current recommended way).
- Bloc tests for every event; widget tests for every control type of the generic
  rules editor; routing tests.
- **Goldens** (helper from session 02, 3 sizes × light/dark): home empty state,
  settings top (appearance), settings rules section scrolled to each group, the
  "coming later" dialog, the reset confirmation dialog, a glob list with 5 long patterns.
- Accessibility: semantics labels, 48 px tap targets, text scaling 2.0 golden for the
  settings screen on phone (one extra golden).

## Acceptance criteria

- [x] Theme change applies immediately and survives restart (test with a fresh repository instance on the same store).
- [x] Every MVP rule from `architecture.md` §5.3 is editable; adding a new rule to `RuleCatalog` makes it appear with no UI change (prove it with a test-only catalog).
- [x] Goldens committed and listed in the PR with images.
- [x] Analyze/format clean, 100% coverage for app + `settings_repository`.

## Session log

**2026-10-04. Run by Claude (the planning model), not by a session agent.** Stacked on
session 09 (branch `dc3d/s10-settings` created from `dc3d/s09-repository`).

### Built
- `packages/settings_repository`: public repo
  [hawkbee1/settings_repository](https://github.com/hawkbee1/settings_repository), submodule +
  workspace member. Keys `dc3d.theme_mode` and `dc3d.rules` (one JSON string); corrupt or
  unknown values fall back to the defaults. Re-exports the rule types, so the app only imports
  `settings_repository`. 6 tests, coverage 100%.
- App: typed `go_router` routes (`HomeRoute` `/` with sub-routes `settings`, `new-analysis` and
  `viewer`, generated by `go_router_builder`), `App` → `AppView` with `MaterialApp.router`,
  `AppSpacing` and `CodeWorldColors` theme extensions (`context.spacing`,
  `context.worldColors`), settings screen with the generic rules editor, home empty state,
  new analysis placeholder, 75 strings in English and French.
- Tests: 58 unit/widget tests (coverage 100%, `*.g.dart` excluded), 91 golden tests including
  French, dark and text scale 2.0 variants, and the Android tap target + labelled tap target
  guidelines on home and settings.

### Decisions and deviations
- **`SettingsBloc` rather than a `ThemeCubit`**: theme and rules are loaded, saved and reset
  together from one repository, with one event per user action (`SettingsStarted`,
  `SettingsThemeModeChanged`, `SettingsRuleChanged`, `SettingsRulesReset`). Session 15 reads
  the current rules from the same bloc when starting an analysis.
- **One Equatable `SettingsState` with a `status`** (`loading`/`ready`) instead of sealed
  states: the screen always shows the full settings, starting from the defaults while the
  stored ones load.
- **Route `/new-analysis`** instead of `/analysis/new`: every route is a sub-route of home, so
  the back button returns home (navigation skill).
- **Large text**: above 1.5× text scale, the theme picker becomes wrapping chips; three
  segments broke "System" over two lines at 2.0×.
- The app provides `SettingsRepository` with a single `RepositoryProvider`; switch to
  `MultiRepositoryProvider` when `CodeMapRepository` arrives (session 11 or 15).

### Things the next agents must know
- **Mocktail errors cascade across files**: Very Good CLI merges test files into one, so a
  missing `registerFallbackValue` leaves mocktail stuck mid-`verify` and dozens of unrelated
  tests fail afterwards. Fix the **first** failure, or run one file with `paths`.
- The settings list is lazy: a widget test must scroll to a rule before finding it
  (`scrollUntilVisible` on `find.byKey(ValueKey(ruleId))`, then `Scrollable.ensureVisible`
  before tapping).
- A `MockSettingsBloc` only rebuilds widgets through its stream: use `whenListen` to change
  its state during a test.
- `ViewerPage()` needs the GPU, so the routing test checks that `ViewerRoute.build` returns
  it rather than pumping it.
