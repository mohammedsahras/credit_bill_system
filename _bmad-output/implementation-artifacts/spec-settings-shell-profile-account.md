---
title: 'Settings Shell, Profile & Account'
type: 'feature'
created: '2026-11-16'
status: 'in-review'
baseline_commit: 'e4ee5865439b20f3817ca3f168c91820c28720c3'
route: 'dispatch'
review_loop_iteration: 0
context: ['{project-root}/_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The app has no Settings section at all. Users cannot view or edit their profile (name, email, phone, photo) and there is nowhere to reach app configuration; the `users` table stores only name/email/password.

**Approach:** Add a WhatsApp-inspired Settings feature (feature-first Clean Architecture) with a main settings screen — profile header, edit-profile entry, search, and an icon category list — plus a Profile/Account editor that persists changes to the existing SQLite `users` table through an additive migration and refreshes the active session.

## Boundaries & Constraints

**Always:** Preserve the existing DB, migrations v1–v5, all users/customers/transactions/payments/reports, bcrypt + legacy hash login, and the current session flow. Schema change must be additive-only (nullable columns, guarded). Changing email requires current-password confirmation. Profile is DB-sourced and survives restart (`session.json` re-saved after updates). Follow AD-1/AD-3: UI → Bloc → UseCase → Repository → DataSource; presentation never imports `data/`. Reuse `CreditBill*` widgets and colors; every control has real behavior.

**Never:** No DB reset/recreate/overwrite, no drop/alter of existing columns, no plain-text password storage, no network calls, no WhatsApp branding. ~~Do not implement deferred goals (theme, l10n, notifications, security, backup, help).~~ **Amended 2026-11-16 (human renegotiation):** every visible settings category must be fully functional — no "Coming soon" labels, placeholder pages, or controls that do nothing. Categories whose feature cannot be built offline with existing dependencies and existing infra (language/l10n, notification scheduling, biometric app lock, backup/restore) are omitted from the list entirely until their epics (3, 7) or the deferred l10n work lands; they are never shown as stubs.

**Decisions (2026-11-16):** (1) Profile photo ships now: add `image_picker` and a nullable `photo` column storing resized base64. (2) ~~The settings screen shows the full category list; deferred tiles are visibly labeled "Coming soon" and open a clearly-labeled placeholder page — they must never appear functional.~~ **Amended 2026-11-16 (human renegotiation — "Complete all feasible Settings features. No Coming Soon placeholders or fake functionality."):** the settings screen shows only fully functional categories — Theme & Appearance (persisted light/dark/system switch applied live), Security & Privacy (change password with current-password verification + sign out + privacy note), Storage & Data (real record counts, database file size, live image cache with a working clear action), Help & Support (real FAQ content) and About (real bundled version + real open-source licenses). Language and Notifications are omitted (not stubbed) until l10n work and the Epic 3 notification engine exist.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Edit name/phone, save | Valid new values | Row updated; header + session refresh immediately; persists after restart | Validation error, no write on empty/invalid input |
| Change email | New email + correct password | Password confirmed → email updated, session + AuthBloc state updated | Wrong password → rejected, no change; duplicate email → inline error |
| Change photo | `image_picker` selection | Resized base64 stored in `photo`, header shows it after restart | Oversize/corrupt image rejected with message; fallback initials avatar |
| Existing user (v5 DB) opens app | `phone`/`photo` NULL | Migration adds columns; all rows intact; header shows initials + "Add phone" hint | Migration guarded by `PRAGMA table_info`; failure aborts nothing destructive |
| Email uniqueness race | Email already registered | Save blocked with clear message | No partial session/DB update |

</frozen-after-approval>

## Code Map

- `lib/core/database/database_helper.dart` -- `_databaseVersion = 5` (L6), `_createUsersTable` (L170-182), `_onUpgrade` sequential blocks (L194-207); add guarded `oldVersion < 6` block: `ALTER TABLE users ADD COLUMN phone TEXT` / `photo TEXT`.
- `lib/features/auth/domain/entities/user_entity.dart` (+`data/models/user_model.dart`) -- 6 fields today; add `phone`, `photo` (nullable) to entity and both map converters.
- `lib/features/auth/data/datasources/user_local_data_source.dart` -- add `updateProfile(...)` (mirror `updatePassword` L98-107); keep `authenticateUser` legacy-hash path untouched (L84-94).
- `lib/features/auth/domain/repositories/user_repository.dart` + `data/repositories/user_repository_impl.dart` -- add `updateUserProfile` passthrough; no other changes.
- `lib/features/auth/domain/usecases/auth_usecases.dart` -- add `UpdateProfileUseCase` (name/email/phone validation, password check for email change via `PasswordHasher.verify` L14).
- `lib/features/auth/presentation/bloc/auth_{bloc,event,state}.dart` -- add `UpdateProfileEvent`; on success re-save session (`SessionManager.saveSession`, `lib/core/services/session_manager.dart` L28) and emit refreshed `AuthAuthenticatedState(email, fullName)`.
- `lib/app.dart` -- `onGenerateRoute` switch (L206): add `case '/settings':`; AuthBloc already provided (L155-166), no new providers needed.
- `lib/features/customers/presentation/pages/dashboard_page.dart` -- entry hooks: `AppBar.actions` settings IconButton (L30) + `_QuickActionCard` tile (L59-86).
- **New** `lib/features/settings/presentation/pages/{settings_page,edit_profile_page}.dart`, `lib/features/settings/presentation/widgets/{settings_section_header,settings_tile,profile_header}.dart` -- reuse `CreditBillBackground`, `CreditBillTextField`, `CreditBillPrimaryButton`, `CreditBillColors` from `lib/core/theme/widgets/`.
- **New** `test/features/settings/...` + migration/profile tests under `test/features/auth/...` -- mirror existing mocktail/bloc_test conventions in `test/features/cards/`.

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/database/database_helper.dart` -- bump to v6; guarded additive `phone`/`photo` columns; preserve v1–v5 blocks verbatim.
- [x] `lib/features/auth/domain/entities/user_entity.dart`, `data/models/user_model.dart` -- add nullable `phone`, `photo` across constructors/converters.
- [x] `lib/features/auth/data/datasources/user_local_data_source.dart` -- `updateProfile` (email uniqueness check inside transaction).
- [x] `lib/features/auth/domain/repositories/user_repository.dart`, `data/repositories/user_repository_impl.dart` -- expose `updateUserProfile`.
- [x] `lib/features/auth/domain/usecases/auth_usecases.dart` -- `UpdateProfileUseCase` with validation + password-gated email change.
- [x] `lib/features/auth/presentation/bloc/auth_{bloc,event,state}.dart` -- dispatch, persist session, emit updated state; failures surface typed error state.
- [x] `lib/features/settings/presentation/widgets/*` -- reusable section header, settings tile, profile header (image/initials fallback, name, email, phone).
- [x] `lib/features/settings/presentation/pages/settings_page.dart` -- profile header, Edit Profile, live search filter, category list per OQ2; dark/light-safe layout.
- [x] `lib/features/settings/presentation/pages/edit_profile_page.dart` -- view/edit name, email (password-confirm dialog), phone, photo via `image_picker`; account info section (id, email, created_at, verified).
- [x] `lib/app.dart` -- `/settings` route; `lib/features/customers/presentation/pages/dashboard_page.dart` -- AppBar + quick-action entry points.
- [x] `test/features/settings/` + `test/features/auth/` -- widget tests (search filter, validation errors, header rendering) and data tests (migration adds columns, `updateProfile` persists, duplicate email rejected, login still works post-migration).
- [x] `pubspec.yaml` -- add `image_picker` (approved dependency).

**Execution (renegotiated scope, 2026-11-16 — "no Coming Soon placeholders"):**
- [x] `lib/core/services/preferences_store.dart`, `lib/core/theme/theme_controller.dart` -- persisted theme-mode preference (SessionManager-style JSON file, in-memory fallback on web) + `ThemeScope` inherited notifier; `main.dart` preloads the controller, `app.dart` binds `MaterialApp.themeMode` to it.
- [x] `lib/core/theme/widgets/credit_bill_page_route.dart` -- shared fade + slide `PageRouteBuilder` (built-in Flutter animation APIs, honours `disableAnimations`) used for all settings navigation.
- [x] `lib/features/settings/presentation/pages/theme_settings_page.dart` -- System/Light/Dark selection applied live (Material `AnimatedTheme`) and persisted; reuses `SettingsOptionTile`.
- [x] `lib/features/auth/domain/usecases/auth_usecases.dart` -- `ChangePasswordUseCase`: verify current password with the legacy-aware hasher against the stored hash, enforce >=6 chars + different-from-current, then write a new bcrypt hash through the existing `resetPassword` repository path (no new repository surface, no schema change).
- [x] `lib/features/settings/presentation/pages/security_privacy_page.dart` -- change-password form (inline validation, success/failure snackbars, fields cleared only on success) + sign out with confirmation dialog (`LogoutRequestedEvent`, pop to root) + truthful on-device privacy note.
- [x] `lib/features/settings/presentation/pages/storage_data_page.dart` -- real record counts (COUNT queries over existing tables), database file size (new `DatabaseHelper.databaseFilePath`), live image-cache size, working "Clear image cache" action; web-safe fallbacks.
- [x] `lib/features/settings/presentation/pages/help_support_page.dart`, `about_page.dart` -- real FAQ with expandable answers; About shows the version parsed from the bundled `pubspec.yaml` asset (new asset entry) and opens the built-in `showLicensePage` listing.
- [x] `lib/features/settings/presentation/pages/settings_page.dart`, `widgets/settings_tile.dart` -- drop Language/Notifications tiles, the `comingSoon` badge and `_ComingSoonPage`; every tile carries a route to its real page.
- [x] `test/features/settings/` + `test/core/` + `test/features/auth/` -- replace placeholder expectations with real-behaviour tests (theme persistence, password-change success/rejection/no-op validation, storage figures + cache clear, FAQ expansion, version + license listing, theme controller unit tests, `ChangePasswordUseCase` unit tests).

**Acceptance Criteria:**
- Given a logged-in user, when they open Settings from the dashboard, then profile header shows their stored name/email/phone and a searchable category list.
- Given valid edits, when they save profile changes, then values persist across app restart and the session/header update immediately.
- Given an email change, when the password is wrong, then the change is rejected with no DB/session modification.
- Given a pre-existing v5 database, when the app upgrades, then all users/customers/transactions/payments/reports remain intact and login still succeeds.
- Given any settings category, when the user taps it, then a fully functional screen opens: the theme choice persists and applies live, change password verifies the current password against the stored (bcrypt/legacy) hash before writing a new bcrypt hash, storage figures are read from the real database and image cache, About shows the real bundled version and opens the real license listing — no placeholder, no inert control anywhere.

## Implementation Notes

**Original scope (12 tasks, checkboxes above) — shipped and verified 2026-11-16:** DB v6 migration adds nullable `phone`/`photo` via a `PRAGMA table_info`-guarded `oldVersion < 6` block (v1–v5 blocks untouched); entity/model carry the fields across both converters; `updateProfile` enforces email uniqueness inside a transaction; `updateUserProfile` + `UpdateProfileUseCase` (validation, `PasswordHasher.verifyWithLegacy` gate for email changes) feed `UpdateProfileEvent`, which re-saves the session and emits `AuthProfileUpdatedState`; Settings shell (profile header with initials/photo fallback, live search, category list) and Edit Profile (photo via `image_picker`, resized ≤300 KB base64, password-confirm dialog for email) reuse `CreditBillBackground`/`CreditBillTextField`/`CreditBillPrimaryButton`/`CreditBillTextTheme` throughout; `/settings` route + dashboard AppBar/quick-action entries; image_picker added as the only new dependency.

**Renegotiated scope (2026-11-16, "no Coming Soon placeholders") — shipped:**
- **Theme & Appearance (real):** `PreferencesStore` (JSON file beside session.json, in-memory web fallback — mirrors `SessionManager`) + `ThemeController` (loads in `main()` before the first frame; `setMode` notifies listeners first, persists after) + `ThemeScope` (`InheritedNotifier` directly above `MaterialApp`, which `app.dart` rebuilds via `ListenableBuilder` binding `themeMode`). Material's built-in `AnimatedTheme` eases every switch. The page offers System/Light/Dark through the new `SettingsOptionTile` (accent border, `AnimatedOpacity` check mark, semantics `selected` flag); selection survives restart.
- **Security & Privacy (real):** new `ChangePasswordUseCase` validates (current non-empty, ≥6 chars, differs from current), verifies the current password against the stored hash with `verifyWithLegacy` (bcrypt **and** legacy `fnv1a:` accounts), then writes through the existing `UserRepository.resetPassword` path (bcrypt re-hash) — zero new repository/schema surface. The page has inline field errors, a banner + colored SnackBars, fields cleared only on success, sign-out with a confirmation dialog (`LogoutRequestedEvent` → `popUntil(first)` so `AuthWrapper` shows the welcome screen), and a truthful on-device privacy note.
- **Storage & Data (real):** `COUNT(*)` queries over the five existing tables (Customers / Credit transactions / Payments / Cards / Statement bills), real on-disk DB size via the new `DatabaseHelper.databaseFilePath` (also reused by `_initDatabase`; `kIsWeb` guarded — "Not available on the web"), live `imageCache.currentSizeBytes`, and a working "Clear image cache" action with confirmation SnackBar; loading spinner + error/retry path.
- **Help & Support (real):** seven genuine FAQ entries (customers, bills, payments, data location, password recovery, profile edits, theme) as styled `ExpansionTile` cards + a data-handling note; no dead contact links.
- **About (real):** version parsed at runtime from the newly bundled `pubspec.yaml` asset (single source of truth, `version: 1.0.0+1` → "Version 1.0.0 (build 1)"), `showLicensePage` for the actual Flutter/package licenses, logo/description/copyright; ListTile sits on a `Material` (framework assertion caught by a test — fixed in the page, not the test).
- **Settings list:** Language and Notifications categories **removed, not stubbed** (no l10n infrastructure and no Epic 3 notification engine exist — both remain in `deferred-work.md`); `comingSoon` field/badge deleted from `SettingsTile`; `_ComingSoonPage` deleted; every tile carries a named route, and Edit profile keeps its inline dispatch so the header reloads on return. All settings navigation uses the new `CreditBillPageRoute` (240 ms easeOutCubic fade + 5% slide; no animation when `MediaQuery.disableAnimations`).

**Test results (actual, 2026-11-16):** `flutter analyze` → "No issues found"; `flutter test` → **123/123 passed** (99 before this scope, +24 new: theme page 3, settings page 5, security 6, storage 2, help/about 2, theme controller 4, ChangePasswordUseCase 7 — overlapping count includes re-runs of shared files); settings subset `flutter test test/features/settings` → 24/24; `flutter build web` → `√ Built build\web`; `flutter build apk --debug` → `√ Built build\app\outputs\flutter-apk\app-debug.apk`. Test mechanics stayed within the agreed constraints: `runAsync` only around real-I/O waits (storage/about loads, logout session clear) using **bounded condition loops that throw `StateError` on timeout — no fixed sleeps**; lazy lists driven with `scrollUntilVisible`; SnackBar dismiss timers flushed (`pump(5s)`) so no timer leaks; **no DB schema/record changes** were made for any test fix.

**Deferred overlap (left in `deferred-work.md` untouched):** entries still cover what was *not* feasible offline without new dependencies or epic work — font size/UI density display preferences, l10n (en/ta/si), notification engine + persisted notification prefs, biometric/PIN app lock and delete-account, backup/restore + exports, contact/report-a-problem/privacy-policy/terms pages. The feasible subsets of those entries (theme mode, change password, storage info + clear cache, FAQ/version/licenses) shipped here.

## Spec Change Log

- **2026-11-16 — human renegotiation (pre-review).** Trigger: user instruction "Complete all feasible Settings features. No Coming Soon placeholders or fake functionality." Amended inside `<frozen-after-approval>`: the "Never: Do not implement deferred goals" clause and Decision (2) (Coming-soon placeholders), plus AC5. New: execution block "renegotiated scope" with tasks for real Theme/Security/Storage/Help/About screens, persisted theme mode, change-password use case, animated settings routes, and their tests; Language and Notifications tiles are removed rather than stubbed (no l10n infra, no Epic 3 engine — both remain in `deferred-work.md`). Known-bad state avoided: inert controls / placeholder pages shipping as if they were features. KEEP: v6 migration + profile pipeline (entity/model/datasource/repository/usecase/bloc), edit-profile flow, profile header, search, dashboard entries — all must survive unchanged.

## Review Triage Log

## Design Notes

Profile updates extend `AuthBloc` rather than adding a second bloc: session + `AuthAuthenticatedState` must reflect new name/email anyway, and `app.dart` already wires `UserRepositoryImpl` into it — no new DI surface. Cross-feature rule (AD-1) is honored because settings presentation talks only to `AuthBloc`/auth domain, never `data/`.

## Verification

**Commands (run 2026-11-16 — actual results):**
- `flutter pub get` -- exit 0, no errors
- `flutter analyze` -- "No issues found" (exit 0)
- `flutter test` -- **123/123 passed** (exit 0)
- `flutter build web` -- "√ Built build\web" (exit 0)
- `flutter build apk --debug` -- "√ Built build\app\outputs\flutter-apk\app-debug.apk" (exit 0)

**Manual checks:**
- Edit profile → restart app → values persist; old customer/payment/report data untouched; login with old password still works.
