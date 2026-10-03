# Session 10 — App shell, theme, settings (theme + engine rules editor)

**Branch:** `dc3d/s10-settings` · **Depends on:** 02, 05 (the rule definitions).
**Skills:** `vgv-ai-flutter-plugin:bloc`, `…:material-theming`, `…:navigation`,
`…:internationalization`, `…:accessibility`, `…:testing`, `…:layered-architecture`.

## Goal

The app gets its real structure: navigation, Material 3 theme with
system/light/dark, a **settings** screen where the user changes the theme and the
**engine rules**, persisted across launches, and a **home** screen skeleton.

## 1. `settings_repository` (Flutter package)

`flutter_package` `settings_repository` in `packages/`, `workspace: true`, wired.
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
- l10n: every string in ARB files (English). Keep the template's l10n setup.

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

- [ ] Theme change applies immediately and survives restart (test with a fresh repository instance on the same store).
- [ ] Every MVP rule from `architecture.md` §5.3 is editable; adding a new rule to `RuleCatalog` makes it appear with no UI change (prove it with a test-only catalog).
- [ ] Goldens committed and listed in the PR with images.
- [ ] Analyze/format clean, 100% coverage for app + `settings_repository`.

## Session log

_(to be filled by the agent)_
