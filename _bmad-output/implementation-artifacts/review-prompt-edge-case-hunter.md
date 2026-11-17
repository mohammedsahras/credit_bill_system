# Edge Case Hunter Review

**Goal:** You are a pure path tracer. Never comment on whether code is good or bad; only list missing handling.
When a diff is provided, scan only the diff hunks and list boundaries that are directly reachable from the changed lines and lack an explicit guard in the diff.
When no diff is provided (full file or function), treat the entire provided content as the scope.
Ignore the rest of the codebase unless the provided content explicitly references external functions.
A brief secondary deletion check runs as Step 4 when the diff removes code.
A claims check runs as Step 5.

**Inputs:**
- **content** â€” Content to review, or a path to read it from: diff, full file, or function
- **also_consider** (optional) â€” Areas to keep in mind during review alongside normal edge-case analysis
- **claims_file** â€” Path to the spec this change was built from. Do NOT read it before Step 5: the path tracing in Steps 2â€“3 must finish before the claims are seen.

**MANDATORY: Execute steps in the Execution section IN EXACT ORDER. DO NOT skip steps or change the sequence. When a halt condition triggers, follow its specific instruction exactly. Each action within a step is a REQUIRED action to complete that step.**

**Your method is exhaustive path enumeration â€” mechanically walk every branch, not hunt by intuition. Report ONLY paths and conditions that lack handling â€” discard handled ones silently. Do NOT editorialize or add filler. Do not assign severity labels, rankings, or priority levels.**


## EXECUTION

### Step 1: Receive Content

- Take the content to review from the parent message that launched you â€” inline, or by reading the file it points to (never from this instruction file)
- If no content is supplied, or it is empty, unreadable, or cannot be decoded as text, return `[{"location":"N/A","trigger_condition":"Input empty or undecodable","guard_snippet":"Provide valid content to review","potential_consequence":"Review skipped â€” no analysis performed"}]` and stop
- Identify content type (diff, full file, or function) to determine scope rules

### Step 2: Exhaustive Path Analysis

**Walk every branching path and boundary condition within scope â€” report only unhandled ones.**

- If `also_consider` input was provided, incorporate those areas into the analysis
- Walk all branching paths: control flow (conditionals, loops, error handlers, early returns) and domain boundaries (where values, states, or conditions transition). Derive the relevant edge classes from the content itself â€” don't rely on a fixed checklist. Examples: missing else/default, unguarded inputs, off-by-one loops, arithmetic overflow, implicit type coercion, race conditions, timeout gaps
- Consider implicit branches: the diff special-cases or changes the handling of one or more members of a fixed set of values â€” enums, status codes, sentinels, type tags, flags, value ranges. The rest of the set is implicit branches (e.g. the diff changes the `RED` and `YELLOW` cases of a `RED`/`YELLOW`/`GREEN` enum; `GREEN` is the implicit branch)
- Consider handle lifetime: when the changed code re-checks, re-fetches, or re-validates something it already held â€” a handle, index, id, pointer â€” the re-check exists because an intervening call can invalidate it. Identify that call, what it does to the thing held, and what the changed code silently skips when the re-check fails
- For each call site the diff adds or changes â€” in test files as well as production code â€” read the callee's declaration and check the call against it: argument count, order, types, and defaults. Report any mismatch
- For each path: determine whether the content handles it
- Collect only the unhandled paths as findings â€” discard handled ones silently

### Step 3: Validate Completeness

- Revisit every edge class from Step 2 â€” e.g., missing else/default, null/empty inputs, off-by-one loops, arithmetic overflow, implicit type coercion, race conditions, timeout gaps
- Add any newly found unhandled paths to findings; discard confirmed-handled ones

### Step 4: Deletion Check

If the diff removed or replaced meaningful code (ignore pure renames and whitespace): load `references/deletion-check.md` and follow it.

### Step 5: Claims Check

Load `references/claims-check.md` and follow it.

### Step 6: Present Findings

Output all findings as a single JSON array following the Output Format specification exactly.


## OUTPUT FORMAT

Return ONLY a valid JSON array of objects. Each edge-case finding contains exactly these four fields:

```json
[{
  "location": "file:start-end (or file:line when single line, or file:hunk when exact line unavailable)",
  "trigger_condition": "one-line description (max 15 words)",
  "guard_snippet": "minimal code sketch that closes the gap (single-line escaped string, no raw newlines or unescaped quotes)",
  "potential_consequence": "what could actually go wrong (max 15 words)"
}]
```

No extra text, no explanations, no markdown wrapping. An empty array `[]` is valid when nothing is found. Deletion findings from Step 4 and claim findings from Step 5, if any, go in the same array with the extra fields defined in `references/deletion-check.md` and `references/claims-check.md`.


## HALT CONDITIONS

- If no content is supplied, or it is empty, unreadable, or cannot be decoded as text, return `[{"location":"N/A","trigger_condition":"Input empty or undecodable","guard_snippet":"Provide valid content to review","potential_consequence":"Review skipped â€” no analysis performed"}]` and stop
<reference path="references/deletion-check.md">
# Deletion Check

Secondary pass for the Edge Case Hunter â€” runs only when the diff removed meaningful code. Subordinate to the edge-case pass; findings are usually few or none.

For each chunk of removed or replaced code (ignore pure renames and whitespace), ask: did it carry behavior or a contract that the change neither re-established nor intentionally retired? Add a finding for any resulting regression, orphaned reference, or newly-dead code. Skip anything already covered by your edge-case findings.

Append each finding to the same JSON array as the edge-case findings, with the four standard fields plus:

- `kind`: `"deletion"`
- `confidence`: `"high"`, `"medium"`, or `"low"` â€” these are inferences; rate them

For a deletion finding the standard fields read as: `location` = the removed item; `trigger_condition` = the behavior or contract it enforced; `guard_snippet` = where or how to re-establish it; `potential_consequence` = the regression or orphan.

Add nothing if nothing qualifies.
</reference>
<reference path="references/claims-check.md">
# Claims Check

Final pass for the Edge Case Hunter. Read the claims file named in the message that launched you now, for the first time; the path tracing is finished and the claims cannot steer it retroactively.

It is the spec the change was built from. Read only its `## Intent` and `## Tasks & Acceptance` sections â€” the claims live there; ignore the rest of the file. The spec is the change's own account of itself: testimony, not evidence â€” a claim repeated in a code comment is still the same claim, not confirmation. Extract each checkable claim â€” what the change does, what it preserves, ordering, arithmetic, and parity with existing code ("exactly as X does") â€” then try to falsify each one against the code you have already traced. Where your trace is not enough to decide, read the code that decides it: the compared-to function, the actual callee, the state the claim assumes.

Append one finding per falsified claim to the same JSON array, with the four standard fields plus:

- `kind`: `"claim"`
- `confidence`: `"high"`, `"medium"`, or `"low"`

For a claim finding the standard fields read as: `location` = where the code contradicts the claim; `trigger_condition` = the claim, quoted or tightly paraphrased; `guard_snippet` = what the code actually does; `potential_consequence` = what goes wrong for someone who believed the claim.

Verified claims produce nothing. Add nothing if nothing is falsified.
</reference>

## CONTENT SOURCE

"Review content:" in the message that launched you gives the content itself or a path to read it from. Read the file when it is a path; either way that is the content under review, and this instruction file never is.


claims_file (leave unread until your instructions call for it — inlined below):

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

<frozen-after-approval reason="human-owned intent â€” do not modify unless human renegotiates">

## Intent

**Problem:** The app has no Settings section at all. Users cannot view or edit their profile (name, email, phone, photo) and there is nowhere to reach app configuration; the `users` table stores only name/email/password.

**Approach:** Add a WhatsApp-inspired Settings feature (feature-first Clean Architecture) with a main settings screen â€” profile header, edit-profile entry, search, and an icon category list â€” plus a Profile/Account editor that persists changes to the existing SQLite `users` table through an additive migration and refreshes the active session.

## Boundaries & Constraints

**Always:** Preserve the existing DB, migrations v1â€“v5, all users/customers/transactions/payments/reports, bcrypt + legacy hash login, and the current session flow. Schema change must be additive-only (nullable columns, guarded). Changing email requires current-password confirmation. Profile is DB-sourced and survives restart (`session.json` re-saved after updates). Follow AD-1/AD-3: UI â†’ Bloc â†’ UseCase â†’ Repository â†’ DataSource; presentation never imports `data/`. Reuse `CreditBill*` widgets and colors; every control has real behavior.

**Never:** No DB reset/recreate/overwrite, no drop/alter of existing columns, no plain-text password storage, no network calls, no WhatsApp branding. ~~Do not implement deferred goals (theme, l10n, notifications, security, backup, help).~~ **Amended 2026-11-16 (human renegotiation):** every visible settings category must be fully functional â€” no "Coming soon" labels, placeholder pages, or controls that do nothing. Categories whose feature cannot be built offline with existing dependencies and existing infra (language/l10n, notification scheduling, biometric app lock, backup/restore) are omitted from the list entirely until their epics (3, 7) or the deferred l10n work lands; they are never shown as stubs.

**Decisions (2026-11-16):** (1) Profile photo ships now: add `image_picker` and a nullable `photo` column storing resized base64. (2) ~~The settings screen shows the full category list; deferred tiles are visibly labeled "Coming soon" and open a clearly-labeled placeholder page â€” they must never appear functional.~~ **Amended 2026-11-16 (human renegotiation â€” "Complete all feasible Settings features. No Coming Soon placeholders or fake functionality."):** the settings screen shows only fully functional categories â€” Theme & Appearance (persisted light/dark/system switch applied live), Security & Privacy (change password with current-password verification + sign out + privacy note), Storage & Data (real record counts, database file size, live image cache with a working clear action), Help & Support (real FAQ content) and About (real bundled version + real open-source licenses). Language and Notifications are omitted (not stubbed) until l10n work and the Epic 3 notification engine exist.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Edit name/phone, save | Valid new values | Row updated; header + session refresh immediately; persists after restart | Validation error, no write on empty/invalid input |
| Change email | New email + correct password | Password confirmed â†’ email updated, session + AuthBloc state updated | Wrong password â†’ rejected, no change; duplicate email â†’ inline error |
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
- [x] `lib/core/database/database_helper.dart` -- bump to v6; guarded additive `phone`/`photo` columns; preserve v1â€“v5 blocks verbatim.
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

**Execution (renegotiated scope, 2026-11-16 â€” "no Coming Soon placeholders"):**
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
- Given any settings category, when the user taps it, then a fully functional screen opens: the theme choice persists and applies live, change password verifies the current password against the stored (bcrypt/legacy) hash before writing a new bcrypt hash, storage figures are read from the real database and image cache, About shows the real bundled version and opens the real license listing â€” no placeholder, no inert control anywhere.

## Implementation Notes

**Original scope (12 tasks, checkboxes above) â€” shipped and verified 2026-11-16:** DB v6 migration adds nullable `phone`/`photo` via a `PRAGMA table_info`-guarded `oldVersion < 6` block (v1â€“v5 blocks untouched); entity/model carry the fields across both converters; `updateProfile` enforces email uniqueness inside a transaction; `updateUserProfile` + `UpdateProfileUseCase` (validation, `PasswordHasher.verifyWithLegacy` gate for email changes) feed `UpdateProfileEvent`, which re-saves the session and emits `AuthProfileUpdatedState`; Settings shell (profile header with initials/photo fallback, live search, category list) and Edit Profile (photo via `image_picker`, resized â‰¤300 KB base64, password-confirm dialog for email) reuse `CreditBillBackground`/`CreditBillTextField`/`CreditBillPrimaryButton`/`CreditBillTextTheme` throughout; `/settings` route + dashboard AppBar/quick-action entries; image_picker added as the only new dependency.

**Renegotiated scope (2026-11-16, "no Coming Soon placeholders") â€” shipped:**
- **Theme & Appearance (real):** `PreferencesStore` (JSON file beside session.json, in-memory web fallback â€” mirrors `SessionManager`) + `ThemeController` (loads in `main()` before the first frame; `setMode` notifies listeners first, persists after) + `ThemeScope` (`InheritedNotifier` directly above `MaterialApp`, which `app.dart` rebuilds via `ListenableBuilder` binding `themeMode`). Material's built-in `AnimatedTheme` eases every switch. The page offers System/Light/Dark through the new `SettingsOptionTile` (accent border, `AnimatedOpacity` check mark, semantics `selected` flag); selection survives restart.
- **Security & Privacy (real):** new `ChangePasswordUseCase` validates (current non-empty, â‰¥6 chars, differs from current), verifies the current password against the stored hash with `verifyWithLegacy` (bcrypt **and** legacy `fnv1a:` accounts), then writes through the existing `UserRepository.resetPassword` path (bcrypt re-hash) â€” zero new repository/schema surface. The page has inline field errors, a banner + colored SnackBars, fields cleared only on success, sign-out with a confirmation dialog (`LogoutRequestedEvent` â†’ `popUntil(first)` so `AuthWrapper` shows the welcome screen), and a truthful on-device privacy note.
- **Storage & Data (real):** `COUNT(*)` queries over the five existing tables (Customers / Credit transactions / Payments / Cards / Statement bills), real on-disk DB size via the new `DatabaseHelper.databaseFilePath` (also reused by `_initDatabase`; `kIsWeb` guarded â€” "Not available on the web"), live `imageCache.currentSizeBytes`, and a working "Clear image cache" action with confirmation SnackBar; loading spinner + error/retry path.
- **Help & Support (real):** seven genuine FAQ entries (customers, bills, payments, data location, password recovery, profile edits, theme) as styled `ExpansionTile` cards + a data-handling note; no dead contact links.
- **About (real):** version parsed at runtime from the newly bundled `pubspec.yaml` asset (single source of truth, `version: 1.0.0+1` â†’ "Version 1.0.0 (build 1)"), `showLicensePage` for the actual Flutter/package licenses, logo/description/copyright; ListTile sits on a `Material` (framework assertion caught by a test â€” fixed in the page, not the test).
- **Settings list:** Language and Notifications categories **removed, not stubbed** (no l10n infrastructure and no Epic 3 notification engine exist â€” both remain in `deferred-work.md`); `comingSoon` field/badge deleted from `SettingsTile`; `_ComingSoonPage` deleted; every tile carries a named route, and Edit profile keeps its inline dispatch so the header reloads on return. All settings navigation uses the new `CreditBillPageRoute` (240 ms easeOutCubic fade + 5% slide; no animation when `MediaQuery.disableAnimations`).

**Test results (actual, 2026-11-16):** `flutter analyze` â†’ "No issues found"; `flutter test` â†’ **123/123 passed** (99 before this scope, +24 new: theme page 3, settings page 5, security 6, storage 2, help/about 2, theme controller 4, ChangePasswordUseCase 7 â€” overlapping count includes re-runs of shared files); settings subset `flutter test test/features/settings` â†’ 24/24; `flutter build web` â†’ `âˆš Built build\web`; `flutter build apk --debug` â†’ `âˆš Built build\app\outputs\flutter-apk\app-debug.apk`. Test mechanics stayed within the agreed constraints: `runAsync` only around real-I/O waits (storage/about loads, logout session clear) using **bounded condition loops that throw `StateError` on timeout â€” no fixed sleeps**; lazy lists driven with `scrollUntilVisible`; SnackBar dismiss timers flushed (`pump(5s)`) so no timer leaks; **no DB schema/record changes** were made for any test fix.

**Deferred overlap (left in `deferred-work.md` untouched):** entries still cover what was *not* feasible offline without new dependencies or epic work â€” font size/UI density display preferences, l10n (en/ta/si), notification engine + persisted notification prefs, biometric/PIN app lock and delete-account, backup/restore + exports, contact/report-a-problem/privacy-policy/terms pages. The feasible subsets of those entries (theme mode, change password, storage info + clear cache, FAQ/version/licenses) shipped here.

## Spec Change Log

- **2026-11-16 â€” human renegotiation (pre-review).** Trigger: user instruction "Complete all feasible Settings features. No Coming Soon placeholders or fake functionality." Amended inside `<frozen-after-approval>`: the "Never: Do not implement deferred goals" clause and Decision (2) (Coming-soon placeholders), plus AC5. New: execution block "renegotiated scope" with tasks for real Theme/Security/Storage/Help/About screens, persisted theme mode, change-password use case, animated settings routes, and their tests; Language and Notifications tiles are removed rather than stubbed (no l10n infra, no Epic 3 engine â€” both remain in `deferred-work.md`). Known-bad state avoided: inert controls / placeholder pages shipping as if they were features. KEEP: v6 migration + profile pipeline (entity/model/datasource/repository/usecase/bloc), edit-profile flow, profile header, search, dashboard entries â€” all must survive unchanged.

## Review Triage Log

## Design Notes

Profile updates extend `AuthBloc` rather than adding a second bloc: session + `AuthAuthenticatedState` must reflect new name/email anyway, and `app.dart` already wires `UserRepositoryImpl` into it â€” no new DI surface. Cross-feature rule (AD-1) is honored because settings presentation talks only to `AuthBloc`/auth domain, never `data/`.

## Verification

**Commands (run 2026-11-16 â€” actual results):**
- `flutter pub get` -- exit 0, no errors
- `flutter analyze` -- "No issues found" (exit 0)
- `flutter test` -- **123/123 passed** (exit 0)
- `flutter build web` -- "âˆš Built build\web" (exit 0)
- `flutter build apk --debug` -- "âˆš Built build\app\outputs\flutter-apk\app-debug.apk" (exit 0)

**Manual checks:**
- Edit profile â†’ restart app â†’ values persist; old customer/payment/report data untouched; login with old password still works.


Review content (the unified diff at C:\Users\RS COMPUTERS\AppData\Local\Temp\opencode\settings-review-diff.patch, inlined):

diff --git a/_bmad-output/implementation-artifacts/deferred-work.md b/_bmad-output/implementation-artifacts/deferred-work.md
new file mode 100644
index 0000000..5170250
--- /dev/null
+++ b/_bmad-output/implementation-artifacts/deferred-work.md
@@ -0,0 +1,18 @@
+- source_spec: none
+  summary: Implement theme, appearance and display settings (light/dark/system theme, theme preview, font size, UI density, compact/comfortable layout, table and dashboard display preferences) with app-wide persistence.
+  evidence: Split from the Settings module brief â€” independently shippable and mergeable as its own PR once the settings shell exists.
+- source_spec: none
+  summary: Add English/Tamil/Sinhala localization architecture via Flutter localization and wire existing screens to the selected language.
+  evidence: Split from the Settings module brief â€” a self-contained l10n deliverable that touches every screen and can ship separately from settings UI.
+- source_spec: none
+  summary: Build security and privacy settings (change password with bcrypt/legacy compatibility, current-password verification, app lock, PIN, biometric auth, auto-lock timeout, login sessions, secure logout, confirmed delete account).
+  evidence: Split from the Settings module brief â€” sensitive, independently testable work that overlaps Epic 7 and needs its own careful review.
+- source_spec: none
+  summary: Add persisted notification preferences (payment received/reminder, customer activity, new transaction, due payment, daily summary, sound, global enable/disable) without presenting them as functional until Epic 3 notification engine exists.
+  evidence: Split from the Settings module brief â€” depends on Epic 3 stories still in backlog, so must be scoped and verified separately.
+- source_spec: none
+  summary: Implement storage and data settings (database information, safe validated backup/restore with confirmation, customer/transaction/payment exports, storage info, clear cache, web-compatible download) â€” overlaps Epic 7 story 7-2.
+  evidence: Split from the Settings module brief â€” safety-critical, independently shippable, and needs reconciliation with the existing encrypted backup story.
+- source_spec: none
+  summary: Add help and support plus about screens (FAQ, user guide, contact support, report a problem, about CreditBill with logo, version, developer info, privacy policy, terms and conditions).
+  evidence: Split from the Settings module brief â€” mostly static content, independently shippable from the settings shell.
diff --git a/_bmad-output/implementation-artifacts/spec-settings-shell-profile-account.md b/_bmad-output/implementation-artifacts/spec-settings-shell-profile-account.md
new file mode 100644
index 0000000..3f1fe3a
--- /dev/null
+++ b/_bmad-output/implementation-artifacts/spec-settings-shell-profile-account.md
@@ -0,0 +1,123 @@
+---
+title: 'Settings Shell, Profile & Account'
+type: 'feature'
+created: '2026-11-16'
+status: 'in-review'
+baseline_commit: 'e4ee5865439b20f3817ca3f168c91820c28720c3'
+route: 'dispatch'
+review_loop_iteration: 0
+context: ['{project-root}/_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md']
+---
+
+<frozen-after-approval reason="human-owned intent â€” do not modify unless human renegotiates">
+
+## Intent
+
+**Problem:** The app has no Settings section at all. Users cannot view or edit their profile (name, email, phone, photo) and there is nowhere to reach app configuration; the `users` table stores only name/email/password.
+
+**Approach:** Add a WhatsApp-inspired Settings feature (feature-first Clean Architecture) with a main settings screen â€” profile header, edit-profile entry, search, and an icon category list â€” plus a Profile/Account editor that persists changes to the existing SQLite `users` table through an additive migration and refreshes the active session.
+
+## Boundaries & Constraints
+
+**Always:** Preserve the existing DB, migrations v1â€“v5, all users/customers/transactions/payments/reports, bcrypt + legacy hash login, and the current session flow. Schema change must be additive-only (nullable columns, guarded). Changing email requires current-password confirmation. Profile is DB-sourced and survives restart (`session.json` re-saved after updates). Follow AD-1/AD-3: UI â†’ Bloc â†’ UseCase â†’ Repository â†’ DataSource; presentation never imports `data/`. Reuse `CreditBill*` widgets and colors; every control has real behavior.
+
+**Never:** No DB reset/recreate/overwrite, no drop/alter of existing columns, no plain-text password storage, no network calls, no WhatsApp branding. ~~Do not implement deferred goals (theme, l10n, notifications, security, backup, help).~~ **Amended 2026-11-16 (human renegotiation):** every visible settings category must be fully functional â€” no "Coming soon" labels, placeholder pages, or controls that do nothing. Categories whose feature cannot be built offline with existing dependencies and existing infra (language/l10n, notification scheduling, biometric app lock, backup/restore) are omitted from the list entirely until their epics (3, 7) or the deferred l10n work lands; they are never shown as stubs.
+
+**Decisions (2026-11-16):** (1) Profile photo ships now: add `image_picker` and a nullable `photo` column storing resized base64. (2) ~~The settings screen shows the full category list; deferred tiles are visibly labeled "Coming soon" and open a clearly-labeled placeholder page â€” they must never appear functional.~~ **Amended 2026-11-16 (human renegotiation â€” "Complete all feasible Settings features. No Coming Soon placeholders or fake functionality."):** the settings screen shows only fully functional categories â€” Theme & Appearance (persisted light/dark/system switch applied live), Security & Privacy (change password with current-password verification + sign out + privacy note), Storage & Data (real record counts, database file size, live image cache with a working clear action), Help & Support (real FAQ content) and About (real bundled version + real open-source licenses). Language and Notifications are omitted (not stubbed) until l10n work and the Epic 3 notification engine exist.
+
+## I/O & Edge-Case Matrix
+
+| Scenario | Input / State | Expected Output / Behavior | Error Handling |
+|----------|--------------|---------------------------|----------------|
+| Edit name/phone, save | Valid new values | Row updated; header + session refresh immediately; persists after restart | Validation error, no write on empty/invalid input |
+| Change email | New email + correct password | Password confirmed â†’ email updated, session + AuthBloc state updated | Wrong password â†’ rejected, no change; duplicate email â†’ inline error |
+| Change photo | `image_picker` selection | Resized base64 stored in `photo`, header shows it after restart | Oversize/corrupt image rejected with message; fallback initials avatar |
+| Existing user (v5 DB) opens app | `phone`/`photo` NULL | Migration adds columns; all rows intact; header shows initials + "Add phone" hint | Migration guarded by `PRAGMA table_info`; failure aborts nothing destructive |
+| Email uniqueness race | Email already registered | Save blocked with clear message | No partial session/DB update |
+
+</frozen-after-approval>
+
+## Code Map
+
+- `lib/core/database/database_helper.dart` -- `_databaseVersion = 5` (L6), `_createUsersTable` (L170-182), `_onUpgrade` sequential blocks (L194-207); add guarded `oldVersion < 6` block: `ALTER TABLE users ADD COLUMN phone TEXT` / `photo TEXT`.
+- `lib/features/auth/domain/entities/user_entity.dart` (+`data/models/user_model.dart`) -- 6 fields today; add `phone`, `photo` (nullable) to entity and both map converters.
+- `lib/features/auth/data/datasources/user_local_data_source.dart` -- add `updateProfile(...)` (mirror `updatePassword` L98-107); keep `authenticateUser` legacy-hash path untouched (L84-94).
+- `lib/features/auth/domain/repositories/user_repository.dart` + `data/repositories/user_repository_impl.dart` -- add `updateUserProfile` passthrough; no other changes.
+- `lib/features/auth/domain/usecases/auth_usecases.dart` -- add `UpdateProfileUseCase` (name/email/phone validation, password check for email change via `PasswordHasher.verify` L14).
+- `lib/features/auth/presentation/bloc/auth_{bloc,event,state}.dart` -- add `UpdateProfileEvent`; on success re-save session (`SessionManager.saveSession`, `lib/core/services/session_manager.dart` L28) and emit refreshed `AuthAuthenticatedState(email, fullName)`.
+- `lib/app.dart` -- `onGenerateRoute` switch (L206): add `case '/settings':`; AuthBloc already provided (L155-166), no new providers needed.
+- `lib/features/customers/presentation/pages/dashboard_page.dart` -- entry hooks: `AppBar.actions` settings IconButton (L30) + `_QuickActionCard` tile (L59-86).
+- **New** `lib/features/settings/presentation/pages/{settings_page,edit_profile_page}.dart`, `lib/features/settings/presentation/widgets/{settings_section_header,settings_tile,profile_header}.dart` -- reuse `CreditBillBackground`, `CreditBillTextField`, `CreditBillPrimaryButton`, `CreditBillColors` from `lib/core/theme/widgets/`.
+- **New** `test/features/settings/...` + migration/profile tests under `test/features/auth/...` -- mirror existing mocktail/bloc_test conventions in `test/features/cards/`.
+
+## Tasks & Acceptance
+
+**Execution:**
+- [x] `lib/core/database/database_helper.dart` -- bump to v6; guarded additive `phone`/`photo` columns; preserve v1â€“v5 blocks verbatim.
+- [x] `lib/features/auth/domain/entities/user_entity.dart`, `data/models/user_model.dart` -- add nullable `phone`, `photo` across constructors/converters.
+- [x] `lib/features/auth/data/datasources/user_local_data_source.dart` -- `updateProfile` (email uniqueness check inside transaction).
+- [x] `lib/features/auth/domain/repositories/user_repository.dart`, `data/repositories/user_repository_impl.dart` -- expose `updateUserProfile`.
+- [x] `lib/features/auth/domain/usecases/auth_usecases.dart` -- `UpdateProfileUseCase` with validation + password-gated email change.
+- [x] `lib/features/auth/presentation/bloc/auth_{bloc,event,state}.dart` -- dispatch, persist session, emit updated state; failures surface typed error state.
+- [x] `lib/features/settings/presentation/widgets/*` -- reusable section header, settings tile, profile header (image/initials fallback, name, email, phone).
+- [x] `lib/features/settings/presentation/pages/settings_page.dart` -- profile header, Edit Profile, live search filter, category list per OQ2; dark/light-safe layout.
+- [x] `lib/features/settings/presentation/pages/edit_profile_page.dart` -- view/edit name, email (password-confirm dialog), phone, photo via `image_picker`; account info section (id, email, created_at, verified).
+- [x] `lib/app.dart` -- `/settings` route; `lib/features/customers/presentation/pages/dashboard_page.dart` -- AppBar + quick-action entry points.
+- [x] `test/features/settings/` + `test/features/auth/` -- widget tests (search filter, validation errors, header rendering) and data tests (migration adds columns, `updateProfile` persists, duplicate email rejected, login still works post-migration).
+- [x] `pubspec.yaml` -- add `image_picker` (approved dependency).
+
+**Execution (renegotiated scope, 2026-11-16 â€” "no Coming Soon placeholders"):**
+- [x] `lib/core/services/preferences_store.dart`, `lib/core/theme/theme_controller.dart` -- persisted theme-mode preference (SessionManager-style JSON file, in-memory fallback on web) + `ThemeScope` inherited notifier; `main.dart` preloads the controller, `app.dart` binds `MaterialApp.themeMode` to it.
+- [x] `lib/core/theme/widgets/credit_bill_page_route.dart` -- shared fade + slide `PageRouteBuilder` (built-in Flutter animation APIs, honours `disableAnimations`) used for all settings navigation.
+- [x] `lib/features/settings/presentation/pages/theme_settings_page.dart` -- System/Light/Dark selection applied live (Material `AnimatedTheme`) and persisted; reuses `SettingsOptionTile`.
+- [x] `lib/features/auth/domain/usecases/auth_usecases.dart` -- `ChangePasswordUseCase`: verify current password with the legacy-aware hasher against the stored hash, enforce >=6 chars + different-from-current, then write a new bcrypt hash through the existing `resetPassword` repository path (no new repository surface, no schema change).
+- [x] `lib/features/settings/presentation/pages/security_privacy_page.dart` -- change-password form (inline validation, success/failure snackbars, fields cleared only on success) + sign out with confirmation dialog (`LogoutRequestedEvent`, pop to root) + truthful on-device privacy note.
+- [x] `lib/features/settings/presentation/pages/storage_data_page.dart` -- real record counts (COUNT queries over existing tables), database file size (new `DatabaseHelper.databaseFilePath`), live image-cache size, working "Clear image cache" action; web-safe fallbacks.
+- [x] `lib/features/settings/presentation/pages/help_support_page.dart`, `about_page.dart` -- real FAQ with expandable answers; About shows the version parsed from the bundled `pubspec.yaml` asset (new asset entry) and opens the built-in `showLicensePage` listing.
+- [x] `lib/features/settings/presentation/pages/settings_page.dart`, `widgets/settings_tile.dart` -- drop Language/Notifications tiles, the `comingSoon` badge and `_ComingSoonPage`; every tile carries a route to its real page.
+- [x] `test/features/settings/` + `test/core/` + `test/features/auth/` -- replace placeholder expectations with real-behaviour tests (theme persistence, password-change success/rejection/no-op validation, storage figures + cache clear, FAQ expansion, version + license listing, theme controller unit tests, `ChangePasswordUseCase` unit tests).
+
+**Acceptance Criteria:**
+- Given a logged-in user, when they open Settings from the dashboard, then profile header shows their stored name/email/phone and a searchable category list.
+- Given valid edits, when they save profile changes, then values persist across app restart and the session/header update immediately.
+- Given an email change, when the password is wrong, then the change is rejected with no DB/session modification.
+- Given a pre-existing v5 database, when the app upgrades, then all users/customers/transactions/payments/reports remain intact and login still succeeds.
+- Given any settings category, when the user taps it, then a fully functional screen opens: the theme choice persists and applies live, change password verifies the current password against the stored (bcrypt/legacy) hash before writing a new bcrypt hash, storage figures are read from the real database and image cache, About shows the real bundled version and opens the real license listing â€” no placeholder, no inert control anywhere.
+
+## Implementation Notes
+
+**Original scope (12 tasks, checkboxes above) â€” shipped and verified 2026-11-16:** DB v6 migration adds nullable `phone`/`photo` via a `PRAGMA table_info`-guarded `oldVersion < 6` block (v1â€“v5 blocks untouched); entity/model carry the fields across both converters; `updateProfile` enforces email uniqueness inside a transaction; `updateUserProfile` + `UpdateProfileUseCase` (validation, `PasswordHasher.verifyWithLegacy` gate for email changes) feed `UpdateProfileEvent`, which re-saves the session and emits `AuthProfileUpdatedState`; Settings shell (profile header with initials/photo fallback, live search, category list) and Edit Profile (photo via `image_picker`, resized â‰¤300 KB base64, password-confirm dialog for email) reuse `CreditBillBackground`/`CreditBillTextField`/`CreditBillPrimaryButton`/`CreditBillTextTheme` throughout; `/settings` route + dashboard AppBar/quick-action entries; image_picker added as the only new dependency.
+
+**Renegotiated scope (2026-11-16, "no Coming Soon placeholders") â€” shipped:**
+- **Theme & Appearance (real):** `PreferencesStore` (JSON file beside session.json, in-memory web fallback â€” mirrors `SessionManager`) + `ThemeController` (loads in `main()` before the first frame; `setMode` notifies listeners first, persists after) + `ThemeScope` (`InheritedNotifier` directly above `MaterialApp`, which `app.dart` rebuilds via `ListenableBuilder` binding `themeMode`). Material's built-in `AnimatedTheme` eases every switch. The page offers System/Light/Dark through the new `SettingsOptionTile` (accent border, `AnimatedOpacity` check mark, semantics `selected` flag); selection survives restart.
+- **Security & Privacy (real):** new `ChangePasswordUseCase` validates (current non-empty, â‰¥6 chars, differs from current), verifies the current password against the stored hash with `verifyWithLegacy` (bcrypt **and** legacy `fnv1a:` accounts), then writes through the existing `UserRepository.resetPassword` path (bcrypt re-hash) â€” zero new repository/schema surface. The page has inline field errors, a banner + colored SnackBars, fields cleared only on success, sign-out with a confirmation dialog (`LogoutRequestedEvent` â†’ `popUntil(first)` so `AuthWrapper` shows the welcome screen), and a truthful on-device privacy note.
+- **Storage & Data (real):** `COUNT(*)` queries over the five existing tables (Customers / Credit transactions / Payments / Cards / Statement bills), real on-disk DB size via the new `DatabaseHelper.databaseFilePath` (also reused by `_initDatabase`; `kIsWeb` guarded â€” "Not available on the web"), live `imageCache.currentSizeBytes`, and a working "Clear image cache" action with confirmation SnackBar; loading spinner + error/retry path.
+- **Help & Support (real):** seven genuine FAQ entries (customers, bills, payments, data location, password recovery, profile edits, theme) as styled `ExpansionTile` cards + a data-handling note; no dead contact links.
+- **About (real):** version parsed at runtime from the newly bundled `pubspec.yaml` asset (single source of truth, `version: 1.0.0+1` â†’ "Version 1.0.0 (build 1)"), `showLicensePage` for the actual Flutter/package licenses, logo/description/copyright; ListTile sits on a `Material` (framework assertion caught by a test â€” fixed in the page, not the test).
+- **Settings list:** Language and Notifications categories **removed, not stubbed** (no l10n infrastructure and no Epic 3 notification engine exist â€” both remain in `deferred-work.md`); `comingSoon` field/badge deleted from `SettingsTile`; `_ComingSoonPage` deleted; every tile carries a named route, and Edit profile keeps its inline dispatch so the header reloads on return. All settings navigation uses the new `CreditBillPageRoute` (240 ms easeOutCubic fade + 5% slide; no animation when `MediaQuery.disableAnimations`).
+
+**Test results (actual, 2026-11-16):** `flutter analyze` â†’ "No issues found"; `flutter test` â†’ **123/123 passed** (99 before this scope, +24 new: theme page 3, settings page 5, security 6, storage 2, help/about 2, theme controller 4, ChangePasswordUseCase 7 â€” overlapping count includes re-runs of shared files); settings subset `flutter test test/features/settings` â†’ 24/24; `flutter build web` â†’ `âˆš Built build\web`; `flutter build apk --debug` â†’ `âˆš Built build\app\outputs\flutter-apk\app-debug.apk`. Test mechanics stayed within the agreed constraints: `runAsync` only around real-I/O waits (storage/about loads, logout session clear) using **bounded condition loops that throw `StateError` on timeout â€” no fixed sleeps**; lazy lists driven with `scrollUntilVisible`; SnackBar dismiss timers flushed (`pump(5s)`) so no timer leaks; **no DB schema/record changes** were made for any test fix.
+
+**Deferred overlap (left in `deferred-work.md` untouched):** entries still cover what was *not* feasible offline without new dependencies or epic work â€” font size/UI density display preferences, l10n (en/ta/si), notification engine + persisted notification prefs, biometric/PIN app lock and delete-account, backup/restore + exports, contact/report-a-problem/privacy-policy/terms pages. The feasible subsets of those entries (theme mode, change password, storage info + clear cache, FAQ/version/licenses) shipped here.
+
+## Spec Change Log
+
+- **2026-11-16 â€” human renegotiation (pre-review).** Trigger: user instruction "Complete all feasible Settings features. No Coming Soon placeholders or fake functionality." Amended inside `<frozen-after-approval>`: the "Never: Do not implement deferred goals" clause and Decision (2) (Coming-soon placeholders), plus AC5. New: execution block "renegotiated scope" with tasks for real Theme/Security/Storage/Help/About screens, persisted theme mode, change-password use case, animated settings routes, and their tests; Language and Notifications tiles are removed rather than stubbed (no l10n infra, no Epic 3 engine â€” both remain in `deferred-work.md`). Known-bad state avoided: inert controls / placeholder pages shipping as if they were features. KEEP: v6 migration + profile pipeline (entity/model/datasource/repository/usecase/bloc), edit-profile flow, profile header, search, dashboard entries â€” all must survive unchanged.
+
+## Review Triage Log
+
+## Design Notes
+
+Profile updates extend `AuthBloc` rather than adding a second bloc: session + `AuthAuthenticatedState` must reflect new name/email anyway, and `app.dart` already wires `UserRepositoryImpl` into it â€” no new DI surface. Cross-feature rule (AD-1) is honored because settings presentation talks only to `AuthBloc`/auth domain, never `data/`.
+
+## Verification
+
+**Commands (run 2026-11-16 â€” actual results):**
+- `flutter pub get` -- exit 0, no errors
+- `flutter analyze` -- "No issues found" (exit 0)
+- `flutter test` -- **123/123 passed** (exit 0)
+- `flutter build web` -- "âˆš Built build\web" (exit 0)
+- `flutter build apk --debug` -- "âˆš Built build\app\outputs\flutter-apk\app-debug.apk" (exit 0)
+
+**Manual checks:**
+- Edit profile â†’ restart app â†’ values persist; old customer/payment/report data untouched; login with old password still works.
diff --git a/android/gradle.properties b/android/gradle.properties
index e96108c..64042b2 100644
--- a/android/gradle.properties
+++ b/android/gradle.properties
@@ -4,3 +4,10 @@ android.useAndroidX=true
 android.newDsl=false
 # This builtInKotlin flag was added by the Flutter template
 android.builtInKotlin=false
+# Plugin sources live in the pub cache (C:) while the project is on D:;
+# Kotlin incremental compilation's RelocatableFileToPathConverter cannot
+# compute cross-drive relative paths and fails image_picker_android's
+# compileDebugKotlin with "Storage ... already registered". Full (non-
+# incremental) Kotlin compilation sidesteps it at the cost of slower
+# rebuilds only.
+kotlin.incremental=false
diff --git a/lib/app.dart b/lib/app.dart
index cb3e477..11a40c4 100644
--- a/lib/app.dart
+++ b/lib/app.dart
@@ -2,6 +2,8 @@ import 'package:flutter/material.dart';
 import 'package:flutter_bloc/flutter_bloc.dart';
 
 import 'core/database/database_helper.dart';
+import 'core/theme/theme_controller.dart';
+import 'core/theme/widgets/credit_bill_page_route.dart';
 import 'app/presentation/wallet_composition_page.dart';
 import 'features/auth/data/datasources/user_local_data_source.dart';
 import 'features/auth/data/repositories/user_repository_impl.dart';
@@ -23,6 +25,13 @@ import 'features/customers/presentation/pages/customer_detail_page.dart';
 import 'features/customers/presentation/pages/customer_list_page.dart';
 import 'features/reports/presentation/pages/reports_page.dart';
 import 'features/reports/presentation/bloc/reports_bloc.dart';
+import 'features/settings/presentation/pages/about_page.dart';
+import 'features/settings/presentation/pages/edit_profile_page.dart';
+import 'features/settings/presentation/pages/help_support_page.dart';
+import 'features/settings/presentation/pages/security_privacy_page.dart';
+import 'features/settings/presentation/pages/settings_page.dart';
+import 'features/settings/presentation/pages/storage_data_page.dart';
+import 'features/settings/presentation/pages/theme_settings_page.dart';
 import 'features/customers/presentation/pages/dashboard_page.dart';
 import 'features/customers/presentation/pages/edit_customer_page.dart';
 import 'features/customers/presentation/pages/record_payment_page.dart';
@@ -51,11 +60,21 @@ class CreditBillApp extends StatelessWidget {
   final DatabaseHelper? databaseHelper;
   final Widget? home;
 
-  const CreditBillApp({super.key, this.databaseHelper, this.home});
+  /// App-wide theme-mode control. `main()` loads the persisted value
+  /// before the first frame; tests may inject one backed by a fake store.
+  final ThemeController? themeController;
+
+  const CreditBillApp({
+    super.key,
+    this.databaseHelper,
+    this.home,
+    this.themeController,
+  });
 
   @override
   Widget build(BuildContext context) {
     final dbHelper = databaseHelper ?? DatabaseHelper();
+    final themeController = this.themeController ?? ThemeController();
     final cardLocalDataSource = CardLocalDataSourceImpl(
       databaseHelper: dbHelper,
     );
@@ -134,6 +153,13 @@ class CreditBillApp extends StatelessWidget {
     final seedDevAccountUseCase = SeedDevAccountUseCase(
       repository: userRepository,
     );
+    final getProfileUseCase = GetProfileUseCase(repository: userRepository);
+    final updateProfileUseCase = UpdateProfileUseCase(
+      repository: userRepository,
+    );
+    final changePasswordUseCase = ChangePasswordUseCase(
+      repository: userRepository,
+    );
 
     return MultiBlocProvider(
       providers: [
@@ -159,6 +185,7 @@ class CreditBillApp extends StatelessWidget {
             resetPasswordUseCase: resetPasswordUseCase,
             seedDefaultUserUseCase: seedDefaultUserUseCase,
             seedDevAccountUseCase: seedDevAccountUseCase,
+            updateProfileUseCase: updateProfileUseCase,
             recoveryCodeDataSource: RecoveryCodeLocalDataSourceImpl(
               databaseHelper: DatabaseHelper(),
             ),
@@ -175,7 +202,9 @@ class CreditBillApp extends StatelessWidget {
         ),
         BlocProvider<CustomerDetailBloc>(
           create: (_) => CustomerDetailBloc(
-            getCustomerByIdUseCase: GetCustomerByIdUseCase(repository: customerRepository),
+            getCustomerByIdUseCase: GetCustomerByIdUseCase(
+              repository: customerRepository,
+            ),
             creditTransactionRepository: creditTransactionRepository,
             paymentRepository: paymentRepository,
           ),
@@ -184,99 +213,139 @@ class CreditBillApp extends StatelessWidget {
           create: (_) => ReportsBloc(databaseHelper: dbHelper),
         ),
       ],
-      child: MaterialApp(
-        title: 'Credit Bill System',
-        debugShowCheckedModeBanner: false,
-        themeMode: ThemeMode.system,
-        theme: ThemeData(
-          useMaterial3: true,
-          colorScheme: ColorScheme.fromSeed(
-            seedColor: const Color(0xFF087DB5),
-            brightness: Brightness.light,
-          ),
-        ),
-        darkTheme: ThemeData(
-          useMaterial3: true,
-          colorScheme: ColorScheme.fromSeed(
-            seedColor: const Color(0xFF087DB5),
-            brightness: Brightness.dark,
+      child: ThemeScope(
+        controller: themeController,
+        child: ListenableBuilder(
+          listenable: themeController,
+          builder: (context, _) => MaterialApp(
+            title: 'Credit Bill System',
+            debugShowCheckedModeBanner: false,
+            themeMode: themeController.mode,
+            theme: ThemeData(
+              useMaterial3: true,
+              colorScheme: ColorScheme.fromSeed(
+                seedColor: const Color(0xFF087DB5),
+                brightness: Brightness.light,
+              ),
+            ),
+            darkTheme: ThemeData(
+              useMaterial3: true,
+              colorScheme: ColorScheme.fromSeed(
+                seedColor: const Color(0xFF087DB5),
+                brightness: Brightness.dark,
+              ),
+            ),
+            home: home ?? const WalletCompositionPage(),
+            onGenerateRoute: (settings) {
+              switch (settings.name) {
+                case '/welcome':
+                  return MaterialPageRoute(builder: (_) => const WelcomePage());
+                case '/login':
+                  return MaterialPageRoute(builder: (_) => const LoginPage());
+                case '/forgot-password':
+                  return MaterialPageRoute(
+                    builder: (_) => const ForgotPasswordPage(),
+                  );
+                case '/verify-recovery-code':
+                  final email = settings.arguments as String? ?? '';
+                  return MaterialPageRoute(
+                    builder: (_) => VerifyRecoveryCodePage(email: email),
+                  );
+                case '/create-new-password':
+                  final args = settings.arguments;
+                  String email = 'demo@creditbill.com';
+                  if (args is Map) {
+                    email = args['email'] as String? ?? email;
+                  } else if (args is String) {
+                    email = args;
+                  }
+                  return MaterialPageRoute(
+                    builder: (_) => CreateNewPasswordPage(email: email),
+                  );
+                case '/password-changed':
+                  return MaterialPageRoute(
+                    builder: (_) => const PasswordChangedPage(),
+                  );
+                case '/home':
+                  return MaterialPageRoute(
+                    builder: (_) => const WalletCompositionPage(),
+                  );
+                case '/customers':
+                  return MaterialPageRoute(
+                    builder: (_) => const CustomerListPage(),
+                  );
+                case '/add-customer':
+                  return MaterialPageRoute(
+                    builder: (_) => const AddCustomerPage(),
+                  );
+                case '/customer-detail':
+                  final customer = settings.arguments as CustomerEntity?;
+                  if (customer == null) return null;
+                  return MaterialPageRoute(
+                    builder: (_) => CustomerDetailPage(customer: customer),
+                  );
+                case '/edit-customer':
+                  final customer = settings.arguments as CustomerEntity?;
+                  if (customer == null) return null;
+                  return MaterialPageRoute(
+                    builder: (_) => EditCustomerPage(customer: customer),
+                  );
+                case '/add-credit-bill':
+                  final customer = settings.arguments as CustomerEntity?;
+                  return MaterialPageRoute(
+                    builder: (_) => AddCreditBillPage(customer: customer),
+                  );
+                case '/record-payment':
+                  final customer = settings.arguments as CustomerEntity?;
+                  return MaterialPageRoute(
+                    builder: (_) => RecordPaymentPage(
+                      customer: customer,
+                      paymentRepository: paymentRepository,
+                      creditTransactionRepository: creditTransactionRepository,
+                    ),
+                  );
+                case '/dashboard':
+                  return MaterialPageRoute(
+                    builder: (_) => const DashboardPage(),
+                  );
+                case '/reports':
+                  return MaterialPageRoute(builder: (_) => const ReportsPage());
+                case '/settings':
+                  return CreditBillPageRoute(
+                    builder: (_) =>
+                        SettingsPage(getProfileUseCase: getProfileUseCase),
+                  );
+                case '/edit-profile':
+                  return CreditBillPageRoute(
+                    builder: (_) =>
+                        EditProfilePage(getProfileUseCase: getProfileUseCase),
+                  );
+                case '/settings/theme':
+                  return CreditBillPageRoute(
+                    builder: (_) => const ThemeSettingsPage(),
+                  );
+                case '/settings/security':
+                  return CreditBillPageRoute(
+                    builder: (_) => SecurityPrivacyPage(
+                      changePasswordUseCase: changePasswordUseCase,
+                    ),
+                  );
+                case '/settings/storage':
+                  return CreditBillPageRoute(
+                    builder: (_) => StorageDataPage(databaseHelper: dbHelper),
+                  );
+                case '/settings/help':
+                  return CreditBillPageRoute(
+                    builder: (_) => const HelpSupportPage(),
+                  );
+                case '/settings/about':
+                  return CreditBillPageRoute(builder: (_) => const AboutPage());
+                default:
+                  return null;
+              }
+            },
           ),
         ),
-        home: home ?? const WalletCompositionPage(),
-        onGenerateRoute: (settings) {
-          switch (settings.name) {
-            case '/welcome':
-              return MaterialPageRoute(builder: (_) => const WelcomePage());
-            case '/login':
-              return MaterialPageRoute(builder: (_) => const LoginPage());
-            case '/forgot-password':
-              return MaterialPageRoute(
-                builder: (_) => const ForgotPasswordPage(),
-              );
-            case '/verify-recovery-code':
-              final email = settings.arguments as String? ?? '';
-              return MaterialPageRoute(
-                builder: (_) => VerifyRecoveryCodePage(email: email),
-              );
-            case '/create-new-password':
-              final args = settings.arguments;
-              String email = 'demo@creditbill.com';
-              if (args is Map) {
-                email = args['email'] as String? ?? email;
-              } else if (args is String) {
-                email = args;
-              }
-              return MaterialPageRoute(
-                builder: (_) => CreateNewPasswordPage(email: email),
-              );
-            case '/password-changed':
-              return MaterialPageRoute(
-                builder: (_) => const PasswordChangedPage(),
-              );
-            case '/home':
-              return MaterialPageRoute(
-                builder: (_) => const WalletCompositionPage(),
-              );
-            case '/customers':
-              return MaterialPageRoute(
-                builder: (_) => const CustomerListPage(),
-              );
-            case '/add-customer':
-              return MaterialPageRoute(builder: (_) => const AddCustomerPage());
-            case '/customer-detail':
-              final customer = settings.arguments as CustomerEntity?;
-              if (customer == null) return null;
-              return MaterialPageRoute(
-                builder: (_) => CustomerDetailPage(customer: customer),
-              );
-            case '/edit-customer':
-              final customer = settings.arguments as CustomerEntity?;
-              if (customer == null) return null;
-              return MaterialPageRoute(
-                builder: (_) => EditCustomerPage(customer: customer),
-              );
-            case '/add-credit-bill':
-              final customer = settings.arguments as CustomerEntity?;
-              return MaterialPageRoute(
-                builder: (_) => AddCreditBillPage(customer: customer),
-              );
-            case '/record-payment':
-              final customer = settings.arguments as CustomerEntity?;
-              return MaterialPageRoute(
-                builder: (_) => RecordPaymentPage(
-                  customer: customer,
-                  paymentRepository: paymentRepository,
-                  creditTransactionRepository: creditTransactionRepository,
-                ),
-              );
-            case '/dashboard':
-              return MaterialPageRoute(builder: (_) => const DashboardPage());
-            case '/reports':
-              return MaterialPageRoute(builder: (_) => const ReportsPage());
-            default:
-              return null;
-          }
-        },
       ),
     );
   }
diff --git a/lib/core/database/database_helper.dart b/lib/core/database/database_helper.dart
index 4d7eaa2..56c5bcd 100644
--- a/lib/core/database/database_helper.dart
+++ b/lib/core/database/database_helper.dart
@@ -3,7 +3,7 @@ import 'package:sqflite/sqflite.dart';
 
 class DatabaseHelper {
   static const String _databaseName = 'credit_bill_system.db';
-  static const int _databaseVersion = 5;
+  static const int _databaseVersion = 6;
 
   static const String tableCards = 'cards';
   static const String tableBills = 'bills';
@@ -15,6 +15,10 @@ class DatabaseHelper {
   static const String columnUserCreatedAt = 'created_at';
   static const String columnUserIsEmailVerified = 'is_email_verified';
 
+  // --- Profile (v6, additive-only) ---
+  static const String columnUserPhone = 'phone';
+  static const String columnUserPhoto = 'photo';
+
   // --- Customer tables (v4) ---
   static const String tableCustomers = 'customers';
   static const String columnCustomerId = 'id';
@@ -100,9 +104,16 @@ class DatabaseHelper {
     return _database!;
   }
 
-  Future<Database> _initDatabase() async {
+  /// Absolute path of the app database file â€” used by Storage & Data to
+  /// report the real on-disk size. Callers must guard `kIsWeb` first:
+  /// there is no file system on the web.
+  static Future<String> get databaseFilePath async {
     final dbPath = await getDatabasesPath();
-    final path = p.join(dbPath, _databaseName);
+    return p.join(dbPath, _databaseName);
+  }
+
+  Future<Database> _initDatabase() async {
+    final path = await databaseFilePath;
 
     return await openDatabase(
       path,
@@ -174,7 +185,9 @@ class DatabaseHelper {
         $columnUserFullName TEXT NOT NULL,
         $columnUserPasswordHash TEXT NOT NULL,
         $columnUserCreatedAt TEXT NOT NULL,
-        $columnUserIsEmailVerified INTEGER NOT NULL DEFAULT 1
+        $columnUserIsEmailVerified INTEGER NOT NULL DEFAULT 1,
+        $columnUserPhone TEXT,
+        $columnUserPhoto TEXT
       )
     ''');
     await db.execute('''      CREATE INDEX IF NOT EXISTS idx_users_email ON $tableUsers($columnUserEmail)
@@ -204,6 +217,35 @@ class DatabaseHelper {
     if (oldVersion < 5) {
       await _migrateToRecoveryCodesTable(db);
     }
+    if (oldVersion < 6) {
+      await _addUserProfileColumns(db);
+    }
+  }
+
+  /// v6 migration: adds the nullable `phone` / `photo` profile columns.
+  ///
+  /// Guarded by `PRAGMA table_info` so it is strictly additive â€” it never
+  /// drops, rewrites or recreates anything, and a database without a `users`
+  /// table (or that already has the columns) is left untouched.
+  Future<void> _addUserProfileColumns(Database db) async {
+    final tables = await db.rawQuery(
+      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
+      [tableUsers],
+    );
+    if (tables.isEmpty) return;
+
+    final columns = await db.rawQuery('PRAGMA table_info($tableUsers);');
+    final existing = columns.map((row) => row['name'] as String?).toSet();
+    if (!existing.contains(columnUserPhone)) {
+      await db.execute(
+        'ALTER TABLE $tableUsers ADD COLUMN $columnUserPhone TEXT',
+      );
+    }
+    if (!existing.contains(columnUserPhoto)) {
+      await db.execute(
+        'ALTER TABLE $tableUsers ADD COLUMN $columnUserPhoto TEXT',
+      );
+    }
   }
 
   Future<void> _createCustomerTables(Database db) async {
diff --git a/lib/core/utils/password_hasher.dart b/lib/core/utils/password_hasher.dart
index 98cb393..b5c9480 100644
--- a/lib/core/utils/password_hasher.dart
+++ b/lib/core/utils/password_hasher.dart
@@ -18,4 +18,25 @@ class PasswordHasher {
       return false;
     }
   }
+
+  /// Verifies a password against both modern bcrypt hashes and the legacy
+  /// FNV-1a format (`fnv1a:<hash>`), so pre-bcrypt accounts can confirm
+  /// sensitive profile changes (e.g. an email change) with the password
+  /// they actually log in with.
+  static bool verifyWithLegacy(String password, String hash) {
+    if (hash.startsWith(r'$2')) {
+      return verify(password, hash);
+    }
+    return hash == legacyHash(password);
+  }
+
+  /// Legacy FNV-1a hash used before bcrypt was introduced.
+  static String legacyHash(String password) {
+    var hash = 0x811c9dc5;
+    for (final unit in password.codeUnits) {
+      hash ^= unit;
+      hash = (hash * 0x01000193) & 0xFFFFFFFF;
+    }
+    return 'fnv1a:$hash';
+  }
 }
diff --git a/lib/features/auth/data/datasources/user_local_data_source.dart b/lib/features/auth/data/datasources/user_local_data_source.dart
index f9767a6..39f0875 100644
--- a/lib/features/auth/data/datasources/user_local_data_source.dart
+++ b/lib/features/auth/data/datasources/user_local_data_source.dart
@@ -4,6 +4,18 @@ import '../../../../core/database/database_helper.dart';
 import '../../../../core/utils/password_hasher.dart';
 import '../models/user_model.dart';
 
+/// Thrown inside [UserLocalDataSourceImpl.updateProfile] when the requested
+/// email is already owned by another account. The surrounding transaction is
+/// rolled back, so no partial write can happen.
+class DuplicateEmailException implements Exception {
+  final String email;
+
+  const DuplicateEmailException(this.email);
+
+  @override
+  String toString() => 'DuplicateEmailException($email)';
+}
+
 abstract class UserLocalDataSource {
   /// Returns true when at least one user is registered.
   Future<bool> hasRegisteredUser();
@@ -20,6 +32,20 @@ abstract class UserLocalDataSource {
   /// Updates a user's password hash.
   Future<int> updatePassword(String email, String newPasswordHash);
 
+  /// Updates the profile fields of the user identified by [currentEmail].
+  ///
+  /// Returns the refreshed model, or null when no matching row exists.
+  /// Throws [DuplicateEmailException] when [email] is already taken by a
+  /// different account. The uniqueness check and the update run inside one
+  /// transaction so a rejected save can never partially modify the row.
+  Future<UserModel?> updateProfile({
+    required String currentEmail,
+    required String fullName,
+    required String email,
+    String? phone,
+    String? photo,
+  });
+
   /// Seeds a default demo user when none exist.
   Future<bool> seedDefaultUser();
 }
@@ -33,6 +59,9 @@ class UserLocalDataSourceImpl implements UserLocalDataSource {
 
   static const String _columnId = 'id';
   static const String _columnEmail = 'email';
+  static const String _columnFullName = 'full_name';
+  static const String _columnPhone = 'phone';
+  static const String _columnPhoto = 'photo';
   static const String _columnPasswordHash = 'password_hash';
 
   @override
@@ -88,7 +117,7 @@ class UserLocalDataSourceImpl implements UserLocalDataSource {
       }
     } else {
       // Legacy FNV-1a hash
-      if (user.passwordHash == _legacyHash(plainPassword)) {
+      if (user.passwordHash == PasswordHasher.legacyHash(plainPassword)) {
         return user;
       }
     }
@@ -106,6 +135,58 @@ class UserLocalDataSourceImpl implements UserLocalDataSource {
     );
   }
 
+  @override
+  Future<UserModel?> updateProfile({
+    required String currentEmail,
+    required String fullName,
+    required String email,
+    String? phone,
+    String? photo,
+  }) async {
+    final db = await databaseHelper.database;
+    final currentKey = currentEmail.toLowerCase().trim();
+    final newKey = email.toLowerCase().trim();
+
+    return db.transaction<UserModel?>((txn) async {
+      // Uniqueness check inside the same transaction as the write, so a
+      // concurrent registration can never produce a partial profile update.
+      if (newKey != currentKey) {
+        final existing = await txn.query(
+          tableUsers,
+          columns: [_columnId],
+          where: 'LOWER($_columnEmail) = ?',
+          whereArgs: [newKey],
+          limit: 1,
+        );
+        if (existing.isNotEmpty) {
+          throw DuplicateEmailException(email.trim());
+        }
+      }
+
+      final updated = await txn.update(
+        tableUsers,
+        {
+          _columnFullName: fullName.trim(),
+          _columnEmail: email.trim(),
+          _columnPhone: phone,
+          _columnPhoto: photo,
+        },
+        where: 'LOWER($_columnEmail) = ?',
+        whereArgs: [currentKey],
+      );
+      if (updated == 0) return null;
+
+      final rows = await txn.query(
+        tableUsers,
+        where: 'LOWER($_columnEmail) = ?',
+        whereArgs: [newKey],
+        limit: 1,
+      );
+      if (rows.isEmpty) return null;
+      return UserModel.fromMap(rows.first);
+    });
+  }
+
   @override
   Future<bool> seedDefaultUser() async {
     final hasUser = await hasRegisteredUser();
@@ -124,13 +205,4 @@ class UserLocalDataSourceImpl implements UserLocalDataSource {
     ); //fnv1a:1773485738
     return true;
   }
-
-  static String _legacyHash(String password) {
-    var hash = 0x811c9dc5;
-    for (final unit in password.codeUnits) {
-      hash ^= unit;
-      hash = (hash * 0x01000193) & 0xFFFFFFFF;
-    }
-    return 'fnv1a:$hash';
-  }
 }
diff --git a/lib/features/auth/data/models/user_model.dart b/lib/features/auth/data/models/user_model.dart
index 8c48514..2fc2fbe 100644
--- a/lib/features/auth/data/models/user_model.dart
+++ b/lib/features/auth/data/models/user_model.dart
@@ -9,6 +9,8 @@ class UserModel extends UserEntity {
     required super.passwordHash,
     required super.createdAt,
     super.isEmailVerified = false,
+    super.phone,
+    super.photo,
   });
 
   factory UserModel.fromMap(Map<String, dynamic> map) {
@@ -19,6 +21,8 @@ class UserModel extends UserEntity {
       passwordHash: map['password_hash'] as String,
       createdAt: DateTime.parse(map['created_at'] as String),
       isEmailVerified: (map['is_email_verified'] as int? ?? 0) == 1,
+      phone: map['phone'] as String?,
+      photo: map['photo'] as String?,
     );
   }
 
@@ -30,6 +34,8 @@ class UserModel extends UserEntity {
       'password_hash': passwordHash,
       'created_at': createdAt.toIso8601String(),
       'is_email_verified': isEmailVerified ? 1 : 0,
+      'phone': phone,
+      'photo': photo,
     };
   }
 
@@ -41,6 +47,8 @@ class UserModel extends UserEntity {
       passwordHash: entity.passwordHash,
       createdAt: entity.createdAt,
       isEmailVerified: entity.isEmailVerified,
+      phone: entity.phone,
+      photo: entity.photo,
     );
   }
 }
diff --git a/lib/features/auth/data/repositories/user_repository_impl.dart b/lib/features/auth/data/repositories/user_repository_impl.dart
index 5e09908..cbdc3a9 100644
--- a/lib/features/auth/data/repositories/user_repository_impl.dart
+++ b/lib/features/auth/data/repositories/user_repository_impl.dart
@@ -94,6 +94,37 @@ class UserRepositoryImpl implements UserRepository {
       return DatabaseFailure('Failed to reset password: $e').asLeft();
     }
   }
+
+  @override
+  Future<Either<Failure, UserEntity>> updateUserProfile({
+    required String currentEmail,
+    required String fullName,
+    required String email,
+    String? phone,
+    String? photo,
+  }) async {
+    try {
+      final updated = await localDataSource.updateProfile(
+        currentEmail: currentEmail,
+        fullName: fullName,
+        email: email,
+        phone: phone,
+        photo: photo,
+      );
+      if (updated == null) {
+        return const NotFoundFailure(
+          'No account found with this email.',
+        ).asLeft();
+      }
+      return Right(updated);
+    } on DuplicateEmailException {
+      return const ConflictFailure(
+        'That email address is already in use by another account.',
+      ).asLeft();
+    } catch (e) {
+      return DatabaseFailure('Failed to update profile: $e').asLeft();
+    }
+  }
 }
 
 extension FailureLeftExt on Failure {
diff --git a/lib/features/auth/domain/entities/user_entity.dart b/lib/features/auth/domain/entities/user_entity.dart
index a379937..81a3c02 100644
--- a/lib/features/auth/domain/entities/user_entity.dart
+++ b/lib/features/auth/domain/entities/user_entity.dart
@@ -9,6 +9,14 @@ class UserEntity extends Equatable {
   final DateTime createdAt;
   final bool isEmailVerified;
 
+  /// Optional mobile number. Nullable â€” added by the v6 profile migration,
+  /// so pre-existing accounts simply have no phone yet.
+  final String? phone;
+
+  /// Optional profile photo stored as a resized base64 string.
+  /// Nullable for the same reason as [phone].
+  final String? photo;
+
   const UserEntity({
     required this.id,
     required this.email,
@@ -16,6 +24,8 @@ class UserEntity extends Equatable {
     required this.passwordHash,
     required this.createdAt,
     this.isEmailVerified = false,
+    this.phone,
+    this.photo,
   });
 
   @override
@@ -26,5 +36,7 @@ class UserEntity extends Equatable {
     passwordHash,
     createdAt,
     isEmailVerified,
+    phone,
+    photo,
   ];
 }
diff --git a/lib/features/auth/domain/repositories/user_repository.dart b/lib/features/auth/domain/repositories/user_repository.dart
index 58d411c..5ff5552 100644
--- a/lib/features/auth/domain/repositories/user_repository.dart
+++ b/lib/features/auth/domain/repositories/user_repository.dart
@@ -21,4 +21,17 @@ abstract class UserRepository {
     String email,
     String newPassword,
   );
+
+  /// Updates the profile fields (name, email, phone, photo) of the user
+  /// identified by [currentEmail] and returns the refreshed entity.
+  ///
+  /// Returns a [ConflictFailure] when the new email is already taken, and a
+  /// [NotFoundFailure] when no account matches [currentEmail].
+  Future<Either<Failure, UserEntity>> updateUserProfile({
+    required String currentEmail,
+    required String fullName,
+    required String email,
+    String? phone,
+    String? photo,
+  });
 }
diff --git a/lib/features/auth/domain/usecases/auth_usecases.dart b/lib/features/auth/domain/usecases/auth_usecases.dart
index d41d8be..f8bf62d 100644
--- a/lib/features/auth/domain/usecases/auth_usecases.dart
+++ b/lib/features/auth/domain/usecases/auth_usecases.dart
@@ -1,3 +1,5 @@
+import 'dart:convert';
+
 import 'package:uuid/uuid.dart';
 import 'package:credit_bill_system/core/errors/either.dart';
 import 'package:credit_bill_system/core/errors/failures.dart';
@@ -62,6 +64,157 @@ class SeedDefaultUserUseCase {
   }
 }
 
+/// Loads the stored profile of a registered user for the settings and
+/// edit-profile screens.
+class GetProfileUseCase {
+  final UserRepository repository;
+  GetProfileUseCase({required this.repository});
+
+  /// Returns the user matching [email], or `Right(null)` when no account
+  /// exists for that address.
+  Future<Either<Failure, UserEntity?>> execute({required String email}) {
+    return repository.findUserByEmail(email);
+  }
+}
+
+/// Updates the signed-in user's profile (name, email, phone, photo).
+///
+/// Validation happens before any write, and changing the email address
+/// additionally requires the account's current password â€” verified against
+/// the stored hash â€” so an unattended device cannot re-point the account.
+class UpdateProfileUseCase {
+  final UserRepository repository;
+  UpdateProfileUseCase({required this.repository});
+
+  static final RegExp _emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
+  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9()\-\s]{6,20}$');
+
+  /// Upper bound for the stored base64 photo (~300 KB of binary data).
+  static const int _maxPhotoLength = 400 * 1024;
+
+  Future<Either<Failure, UserEntity>> execute({
+    required String currentEmail,
+    required String fullName,
+    required String email,
+    String? phone,
+    String? photo,
+    String? currentPassword,
+  }) async {
+    final name = fullName.trim();
+    final newEmail = email.trim();
+    final newPhone = (phone ?? '').trim();
+    final newPhoto = (photo == null || photo.isEmpty) ? null : photo;
+
+    if (name.isEmpty) {
+      return Left(const ValidationFailure('Name cannot be empty.'));
+    }
+    if (!_emailRegex.hasMatch(newEmail)) {
+      return Left(const ValidationFailure('Enter a valid email address.'));
+    }
+    if (newPhone.isNotEmpty && !_phoneRegex.hasMatch(newPhone)) {
+      return Left(const ValidationFailure('Enter a valid phone number.'));
+    }
+    if (newPhoto != null) {
+      if (newPhoto.length > _maxPhotoLength) {
+        return Left(
+          const ValidationFailure(
+            'Please choose a smaller photo (max 300 KB).',
+          ),
+        );
+      }
+      try {
+        base64Decode(newPhoto);
+      } catch (_) {
+        return Left(
+          const ValidationFailure(
+            'The selected photo could not be read. Please choose another image.',
+          ),
+        );
+      }
+    }
+
+    final emailChanged =
+        newEmail.toLowerCase() != currentEmail.trim().toLowerCase();
+    if (emailChanged) {
+      if (currentPassword == null || currentPassword.isEmpty) {
+        return Left(
+          const ValidationFailure(
+            'Enter your current password to change your email address.',
+          ),
+        );
+      }
+      final existing = await repository.findUserByEmail(currentEmail.trim());
+      if (existing.isLeft) return Left(existing.leftOrNull!);
+      final user = existing.rightOrNull;
+      if (user == null) {
+        return Left(
+          const NotFoundFailure('No account found with this email.'),
+        );
+      }
+      if (!PasswordHasher.verifyWithLegacy(
+        currentPassword,
+        user.passwordHash,
+      )) {
+        return Left(const ValidationFailure('Current password is incorrect.'));
+      }
+    }
+
+    return repository.updateUserProfile(
+      currentEmail: currentEmail.trim(),
+      fullName: name,
+      email: newEmail,
+      phone: newPhone.isEmpty ? null : newPhone,
+      photo: newPhoto,
+    );
+  }
+}
+
+/// Changes the signed-in user's password after verifying the current one.
+///
+/// The current password is checked against the stored hash with the
+/// legacy-aware hasher (the same code path login and the email-change
+/// confirmation use), and the new value is re-hashed with bcrypt by the
+/// existing [UserRepository.resetPassword] â€” no plain-text password ever
+/// reaches the database, and no new repository/schema surface is added.
+class ChangePasswordUseCase {
+  final UserRepository repository;
+  ChangePasswordUseCase({required this.repository});
+
+  Future<Either<Failure, UserEntity>> execute({
+    required String email,
+    required String currentPassword,
+    required String newPassword,
+  }) async {
+    final address = email.trim();
+    if (currentPassword.isEmpty) {
+      return Left(const ValidationFailure('Enter your current password.'));
+    }
+    if (newPassword.length < 6) {
+      return Left(
+        const ValidationFailure('Password must be at least 6 characters.'),
+      );
+    }
+    if (newPassword == currentPassword) {
+      return Left(
+        const ValidationFailure(
+          'New password must be different from your current password.',
+        ),
+      );
+    }
+
+    final existing = await repository.findUserByEmail(address);
+    if (existing.isLeft) return Left(existing.leftOrNull!);
+    final user = existing.rightOrNull;
+    if (user == null) {
+      return Left(const NotFoundFailure('No account found with this email.'));
+    }
+    if (!PasswordHasher.verifyWithLegacy(currentPassword, user.passwordHash)) {
+      return Left(const ValidationFailure('Current password is incorrect.'));
+    }
+    return repository.resetPassword(address, newPassword);
+  }
+}
+
 /// Seeds the development account from local credentials.
 /// Reads from lib/core/config/dev_credentials.dart (gitignored).
 /// If credentials are placeholders, skips seeding.
diff --git a/lib/features/auth/presentation/bloc/auth_bloc.dart b/lib/features/auth/presentation/bloc/auth_bloc.dart
index 3686380..310e8a7 100644
--- a/lib/features/auth/presentation/bloc/auth_bloc.dart
+++ b/lib/features/auth/presentation/bloc/auth_bloc.dart
@@ -16,6 +16,7 @@ class AuthBloc extends Bloc<AuthEvent, AuthState> {
   final ResetPasswordUseCase resetPasswordUseCase;
   final SeedDefaultUserUseCase seedDefaultUserUseCase;
   final SeedDevAccountUseCase seedDevAccountUseCase;
+  final UpdateProfileUseCase updateProfileUseCase;
   final RecoveryCodeLocalDataSource recoveryCodeDataSource;
 
   AuthBloc({
@@ -24,12 +25,14 @@ class AuthBloc extends Bloc<AuthEvent, AuthState> {
     required this.resetPasswordUseCase,
     required this.seedDefaultUserUseCase,
     required this.seedDevAccountUseCase,
+    required this.updateProfileUseCase,
     required this.recoveryCodeDataSource,
   }) : super(AuthInitialState()) {
     on<CheckAuthStatusEvent>(_onCheckAuthStatus);
     on<LoginRequestedEvent>(_onLoginRequested);
     on<ForgotPasswordRequestedEvent>(_onForgotPasswordRequested);
     on<ResetPasswordRequestedEvent>(_onResetPasswordRequested);
+    on<UpdateProfileEvent>(_onUpdateProfile);
     on<LogoutRequestedEvent>(_onLogoutRequested);
   }
 
@@ -145,6 +148,79 @@ class AuthBloc extends Bloc<AuthEvent, AuthState> {
     }
   }
 
+  Future<void> _onUpdateProfile(
+    UpdateProfileEvent event,
+    Emitter<AuthState> emit,
+  ) async {
+    // Note: no AuthLoadingState here. The edit screen manages its own
+    // saving indicator, and a transient non-authenticated state would make
+    // the app root (AuthWrapper) drop back to the welcome screen.
+    try {
+      final result = await updateProfileUseCase.execute(
+        currentEmail: event.currentEmail,
+        fullName: event.fullName,
+        email: event.email,
+        phone: event.phone,
+        photo: event.photo,
+        currentPassword: event.currentPassword,
+      );
+      if (result.isLeft) {
+        final identity = _identityAfterFailure(event);
+        emit(
+          AuthProfileUpdateFailedState(
+            email: identity.email,
+            fullName: identity.fullName,
+            message: result.leftOrNull!.message,
+            failedAt: DateTime.now(),
+          ),
+        );
+        return;
+      }
+
+      final user = result.rightOrNull!;
+      // Session save may fail on Web; it must never block the update.
+      try {
+        await SessionManager.saveSession(
+          email: user.email,
+          fullName: user.fullName,
+        );
+      } catch (e) {
+        debugPrint('Session save failed (non-blocking): $e');
+      }
+      emit(
+        AuthProfileUpdatedState(
+          email: user.email,
+          fullName: user.fullName,
+          message: 'Your profile has been updated.',
+          updatedAt: DateTime.now(),
+        ),
+      );
+    } catch (e) {
+      final identity = _identityAfterFailure(event);
+      emit(
+        AuthProfileUpdateFailedState(
+          email: identity.email,
+          fullName: identity.fullName,
+          message: 'Profile update failed: $e',
+          failedAt: DateTime.now(),
+        ),
+      );
+    }
+  }
+
+  /// Identity to report on a failed update: the last confirmed session
+  /// values (a failed save never changes them), falling back to the values
+  /// the event was built from when nothing has been confirmed yet.
+  ({String email, String fullName}) _identityAfterFailure(
+    UpdateProfileEvent event,
+  ) {
+    final current = state;
+    if (current is AuthAuthenticatedState) {
+      return (email: current.email, fullName: current.fullName);
+    }
+    return (email: event.currentEmail, fullName: event.fullName);
+  }
+
   Future<void> _onLogoutRequested(
     LogoutRequestedEvent event,
     Emitter<AuthState> emit,
diff --git a/lib/features/auth/presentation/bloc/auth_event.dart b/lib/features/auth/presentation/bloc/auth_event.dart
index 01b36d2..9b9b397 100644
--- a/lib/features/auth/presentation/bloc/auth_event.dart
+++ b/lib/features/auth/presentation/bloc/auth_event.dart
@@ -42,3 +42,36 @@ class ResetPasswordRequestedEvent extends AuthEvent {
 }
 
 class LogoutRequestedEvent extends AuthEvent {}
+
+class UpdateProfileEvent extends AuthEvent {
+  /// Email the profile row is currently stored under.
+  final String currentEmail;
+
+  final String fullName;
+  final String email;
+  final String? phone;
+  final String? photo;
+
+  /// Required only when [email] differs from [currentEmail]; verified
+  /// against the stored password hash before anything is written.
+  final String? currentPassword;
+
+  const UpdateProfileEvent({
+    required this.currentEmail,
+    required this.fullName,
+    required this.email,
+    this.phone,
+    this.photo,
+    this.currentPassword,
+  });
+
+  @override
+  List<Object?> get props => [
+    currentEmail,
+    fullName,
+    email,
+    phone,
+    photo,
+    currentPassword,
+  ];
+}
diff --git a/lib/features/auth/presentation/bloc/auth_state.dart b/lib/features/auth/presentation/bloc/auth_state.dart
index b21935c..9c4b8ee 100644
--- a/lib/features/auth/presentation/bloc/auth_state.dart
+++ b/lib/features/auth/presentation/bloc/auth_state.dart
@@ -40,3 +40,46 @@ class AuthSuccessState extends AuthState {
   @override
   List<Object?> get props => [message];
 }
+
+/// A profile update succeeded: the session was re-saved and the identity
+/// below reflects the persisted values.
+///
+/// Extends [AuthAuthenticatedState] so the app root (AuthWrapper) keeps the
+/// dashboard mounted instead of falling back to the welcome screen, and
+/// carries [updatedAt] so every save surfaces as a distinct emission even
+/// when name/email happen to be unchanged (e.g. a phone-only edit).
+class AuthProfileUpdatedState extends AuthAuthenticatedState {
+  final String message;
+  final DateTime updatedAt;
+
+  const AuthProfileUpdatedState({
+    required super.email,
+    required super.fullName,
+    required this.message,
+    required this.updatedAt,
+  });
+
+  @override
+  List<Object?> get props => [email, fullName, message, updatedAt];
+}
+
+/// A profile update was rejected (validation, wrong password, duplicate
+/// email, storage error).
+///
+/// Typed error state that intentionally still extends
+/// [AuthAuthenticatedState]: the signed-in session and database row are
+/// untouched, so the user must stay signed in on the screen they are on.
+class AuthProfileUpdateFailedState extends AuthAuthenticatedState {
+  final String message;
+  final DateTime failedAt;
+
+  const AuthProfileUpdateFailedState({
+    required super.email,
+    required super.fullName,
+    required this.message,
+    required this.failedAt,
+  });
+
+  @override
+  List<Object?> get props => [email, fullName, message, failedAt];
+}
diff --git a/lib/features/customers/presentation/pages/dashboard_page.dart b/lib/features/customers/presentation/pages/dashboard_page.dart
index 17dbef9..4767783 100644
--- a/lib/features/customers/presentation/pages/dashboard_page.dart
+++ b/lib/features/customers/presentation/pages/dashboard_page.dart
@@ -28,6 +28,14 @@ class _DashboardPageState extends State<DashboardPage> {
         backgroundColor: CreditBillColors.primaryBlue,
         foregroundColor: CreditBillColors.white,
         actions: [
+          IconButton(
+            key: const Key('dashboardSettingsAction'),
+            icon: const Icon(Icons.settings),
+            tooltip: 'Settings',
+            onPressed: () {
+              Navigator.of(context).pushNamed('/settings');
+            },
+          ),
           IconButton(
             icon: const Icon(Icons.logout),
             onPressed: () {
@@ -84,6 +92,11 @@ class _DashboardPageState extends State<DashboardPage> {
                       onTap: () =>
                           Navigator.of(context).pushNamed('/customers'),
                     ),
+                    _QuickActionCard(
+                      icon: Icons.settings,
+                      label: 'Settings',
+                      onTap: () => Navigator.of(context).pushNamed('/settings'),
+                    ),
                   ],
                 ),
                 const SizedBox(height: 24),
diff --git a/lib/features/settings/presentation/pages/edit_profile_page.dart b/lib/features/settings/presentation/pages/edit_profile_page.dart
new file mode 100644
index 0000000..ccfd318
--- /dev/null
+++ b/lib/features/settings/presentation/pages/edit_profile_page.dart
@@ -0,0 +1,652 @@
+import 'dart:convert';
+
+import 'package:flutter/material.dart';
+import 'package:flutter_bloc/flutter_bloc.dart';
+import 'package:image_picker/image_picker.dart';
+import 'package:intl/intl.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+import '../../../../core/theme/widgets/credit_bill_background.dart';
+import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
+import '../../../../core/theme/widgets/credit_bill_text_field.dart';
+import '../../../auth/domain/entities/user_entity.dart';
+import '../../../auth/domain/usecases/auth_usecases.dart';
+import '../../../auth/presentation/bloc/auth_bloc.dart';
+import '../widgets/profile_header.dart';
+import '../widgets/settings_section_header.dart';
+
+/// Profile / Account editor.
+///
+/// Loads the stored profile through [GetProfileUseCase] (auth domain), lets
+/// the user edit name, email, phone and photo, and persists through
+/// [AuthBloc] â€” which validates, re-saves the session and refreshes the
+/// authenticated state. Changing the email address always requires the
+/// current password first.
+class EditProfilePage extends StatefulWidget {
+  final GetProfileUseCase getProfileUseCase;
+
+  const EditProfilePage({super.key, required this.getProfileUseCase});
+
+  @override
+  State<EditProfilePage> createState() => _EditProfilePageState();
+}
+
+class _EditProfilePageState extends State<EditProfilePage> {
+  /// Binary cap for a picked photo (~300 KB before base64 encoding).
+  static const int _maxPhotoBytes = 300 * 1024;
+
+  static final RegExp _emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
+  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9()\-\s]{6,20}$');
+
+  final _nameController = TextEditingController();
+  final _emailController = TextEditingController();
+  final _phoneController = TextEditingController();
+
+  UserEntity? _profile;
+  bool _loading = true;
+  bool _initialized = false;
+  bool _isSaving = false;
+  String? _loadError;
+  String? _photo;
+  String? _nameError;
+  String? _emailError;
+  String? _phoneError;
+  String? _formError;
+
+  final ScrollController _scrollController = ScrollController();
+
+  /// Anchors used to scroll a field back into view after a failed save: the
+  /// form list is lazy, so a field above the fold may not even be mounted.
+  final GlobalKey _nameAnchor = GlobalKey();
+  final GlobalKey _emailAnchor = GlobalKey();
+  final GlobalKey _phoneAnchor = GlobalKey();
+
+  @override
+  void initState() {
+    super.initState();
+    _loadProfile();
+  }
+
+  @override
+  void dispose() {
+    _nameController.dispose();
+    _emailController.dispose();
+    _phoneController.dispose();
+    _scrollController.dispose();
+    super.dispose();
+  }
+
+  String? get _signedInEmail {
+    final state = context.read<AuthBloc>().state;
+    return state is AuthAuthenticatedState ? state.email : null;
+  }
+
+  Future<void> _loadProfile() async {
+    final email = _signedInEmail;
+    if (email == null) {
+      setState(() {
+        _loading = false;
+        _loadError = 'Please sign in again to edit your profile.';
+      });
+      return;
+    }
+    setState(() {
+      _loading = true;
+      _loadError = null;
+    });
+    try {
+      final result = await widget.getProfileUseCase.execute(email: email);
+      if (!mounted) return;
+      if (result.isLeft) {
+        setState(() {
+          _loading = false;
+          _loadError = result.leftOrNull!.message;
+        });
+        return;
+      }
+      final profile = result.rightOrNull;
+      if (profile == null) {
+        setState(() {
+          _loading = false;
+          _loadError = 'No profile found for this account.';
+        });
+        return;
+      }
+      // Only seed the form on the first successful load so a retry never
+      // discards in-progress edits.
+      if (!_initialized) {
+        _nameController.text = profile.fullName;
+        _emailController.text = profile.email;
+        _phoneController.text = profile.phone ?? '';
+        _photo = profile.photo;
+        _initialized = true;
+      }
+      setState(() {
+        _profile = profile;
+        _loading = false;
+      });
+    } catch (e) {
+      if (!mounted) return;
+      setState(() {
+        _loading = false;
+        _loadError = 'Failed to load profile: $e';
+      });
+    }
+  }
+
+  Future<void> _onSave() async {
+    setState(() {
+      _nameError = null;
+      _emailError = null;
+      _phoneError = null;
+      _formError = null;
+    });
+
+    final name = _nameController.text.trim();
+    final email = _emailController.text.trim();
+    final phone = _phoneController.text.trim();
+
+    var invalid = false;
+    if (name.isEmpty) {
+      setState(() => _nameError = 'Name cannot be empty.');
+      invalid = true;
+    }
+    if (!_emailRegex.hasMatch(email)) {
+      setState(() => _emailError = 'Enter a valid email address.');
+      invalid = true;
+    }
+    if (phone.isNotEmpty && !_phoneRegex.hasMatch(phone)) {
+      setState(() => _phoneError = 'Enter a valid phone number.');
+      invalid = true;
+    }
+    if (invalid) {
+      _revealFirstInvalidError();
+      return;
+    }
+
+    final originalEmail =
+        _profile?.email ?? _signedInEmail ?? '';
+    final emailChanged = email.toLowerCase() != originalEmail.toLowerCase();
+
+    String? currentPassword;
+    if (emailChanged) {
+      currentPassword = await _askCurrentPassword();
+      if (currentPassword == null) return; // User cancelled the confirmation.
+    }
+    if (!mounted) return;
+
+    setState(() => _isSaving = true);
+    context.read<AuthBloc>().add(
+      UpdateProfileEvent(
+        currentEmail: originalEmail,
+        fullName: name,
+        email: email,
+        phone: phone.isEmpty ? null : phone,
+        photo: _photo,
+        currentPassword: currentPassword,
+      ),
+    );
+  }
+
+  /// Brings the first invalid field into view after a failed save so the
+  /// validation error is actually visible. The form list is lazy: a field
+  /// above the current scroll position may not even be mounted yet, so in
+  /// that case snap to the top first and reveal it on the next frame.
+  void _revealFirstInvalidError() {
+    final anchor =
+        _nameError != null
+        ? _nameAnchor
+        : _emailError != null
+        ? _emailAnchor
+        : _phoneAnchor;
+    final fieldContext = anchor.currentContext;
+    if (fieldContext != null) {
+      Scrollable.ensureVisible(fieldContext);
+      return;
+    }
+    if (_scrollController.hasClients) {
+      _scrollController.jumpTo(0);
+    }
+    WidgetsBinding.instance.addPostFrameCallback((_) {
+      final ctx = anchor.currentContext;
+      if (ctx != null && mounted) Scrollable.ensureVisible(ctx);
+    });
+  }
+
+  /// Password confirmation dialog shown only for an email change.
+  /// Returns the entered password, or null when the user cancels.
+  Future<String?> _askCurrentPassword() {
+    return showDialog<String>(
+      context: context,
+      builder: (_) => const _PasswordConfirmDialog(),
+    );
+  }
+
+  Future<void> _pickPhoto() async {
+    if (_isSaving) return;
+    try {
+      final picked = await ImagePicker().pickImage(
+        source: ImageSource.gallery,
+        maxWidth: 512,
+        maxHeight: 512,
+        imageQuality: 85,
+      );
+      if (picked == null) return; // Selection cancelled â€” keep current photo.
+
+      final bytes = await picked.readAsBytes();
+      String? error;
+      if (bytes.isEmpty) {
+        error = 'The selected image could not be read.';
+      } else if (bytes.lengthInBytes > _maxPhotoBytes) {
+        error = 'Please choose a smaller photo (max 300 KB).';
+      } else {
+        // Reject corrupt files outright so a broken image never reaches
+        // the database; `Image.memory` still guards the rendering side.
+        try {
+          final image = await decodeImageFromList(bytes);
+          image.dispose();
+        } catch (_) {
+          error = 'This file is not a valid image. Please choose another one.';
+        }
+      }
+      if (!mounted) return;
+      if (error != null) {
+        setState(() => _formError = error);
+        return;
+      }
+      setState(() {
+        _photo = base64Encode(bytes);
+        _formError = null;
+      });
+    } catch (e) {
+      if (!mounted) return;
+      setState(() => _formError = 'Could not open the photo picker: $e');
+    }
+  }
+
+  void _removePhoto() {
+    setState(() {
+      _photo = null;
+      _formError = null;
+    });
+  }
+
+  void _onAuthState(BuildContext context, AuthState state) {
+    if (state is AuthProfileUpdatedState) {
+      setState(() => _isSaving = false);
+      ScaffoldMessenger.of(context).showSnackBar(
+        SnackBar(
+          content: Text(state.message),
+          backgroundColor: CreditBillColors.successGreen,
+          behavior: SnackBarBehavior.floating,
+          shape: RoundedRectangleBorder(
+            borderRadius: BorderRadius.circular(12),
+          ),
+        ),
+      );
+      Navigator.of(context).pop(true);
+    } else if (state is AuthProfileUpdateFailedState) {
+      setState(() {
+        _isSaving = false;
+        _formError = state.message;
+      });
+      ScaffoldMessenger.of(context).showSnackBar(
+        SnackBar(
+          content: Text(state.message),
+          backgroundColor: CreditBillColors.errorRed,
+          behavior: SnackBarBehavior.floating,
+          shape: RoundedRectangleBorder(
+            borderRadius: BorderRadius.circular(12),
+          ),
+        ),
+      );
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return BlocListener<AuthBloc, AuthState>(
+      listenWhen: (previous, next) =>
+          next is AuthProfileUpdatedState ||
+          next is AuthProfileUpdateFailedState,
+      listener: _onAuthState,
+      child: Scaffold(
+        appBar: AppBar(
+          title: const Text('Edit Profile'),
+          backgroundColor: CreditBillColors.primaryBlue,
+          foregroundColor: CreditBillColors.white,
+        ),
+        body: CreditBillBackground(
+          child: _loading
+              ? const Center(child: CircularProgressIndicator())
+              : _loadError != null
+              ? Center(
+                  child: Padding(
+                    padding: const EdgeInsets.all(24),
+                    child: Column(
+                      mainAxisSize: MainAxisSize.min,
+                      children: [
+                        Text(
+                          _loadError!,
+                          textAlign: TextAlign.center,
+                          style: CreditBillTextTheme.screenSubheading,
+                        ),
+                        const SizedBox(height: 12),
+                        TextButton(
+                          onPressed: _loadProfile,
+                          child: const Text('Retry'),
+                        ),
+                      ],
+                    ),
+                  ),
+                )
+              : _buildForm(),
+        ),
+      ),
+    );
+  }
+
+  Widget _buildForm() {
+    return ListView(
+      controller: _scrollController,
+      padding: const EdgeInsets.all(16),
+      children: [
+        if (_formError != null) ...[
+          Container(
+            padding: const EdgeInsets.all(12),
+            decoration: BoxDecoration(
+              color: CreditBillColors.errorRed.withValues(alpha: 0.1),
+              borderRadius: BorderRadius.circular(12),
+              border: Border.all(color: CreditBillColors.errorRed, width: 1),
+            ),
+            child: Row(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                const Icon(
+                  Icons.error_outline,
+                  size: 18,
+                  color: CreditBillColors.errorRed,
+                ),
+                const SizedBox(width: 8),
+                Expanded(
+                  child: Text(
+                    _formError!,
+                    style: CreditBillTextTheme.errorText.copyWith(fontSize: 13),
+                  ),
+                ),
+              ],
+            ),
+          ),
+          const SizedBox(height: 16),
+        ],
+        _buildPhotoSection(),
+        const SizedBox(height: 20),
+        const SettingsSectionHeader(title: 'Personal details'),
+        KeyedSubtree(
+          key: _nameAnchor,
+          child: CreditBillTextField(
+            key: const Key('profileNameField'),
+            label: 'Full name',
+            hint: 'Your name',
+            controller: _nameController,
+            errorText: _nameError,
+            onChanged: (_) {
+              if (_nameError != null) setState(() => _nameError = null);
+            },
+          ),
+        ),
+        const SizedBox(height: 14),
+        KeyedSubtree(
+          key: _emailAnchor,
+          child: CreditBillTextField(
+            key: const Key('profileEmailField'),
+            label: 'Email',
+            hint: 'you@example.com',
+            controller: _emailController,
+            keyboardType: TextInputType.emailAddress,
+            textInputAction: TextInputAction.next,
+            errorText: _emailError,
+            onChanged: (_) {
+              if (_emailError != null) setState(() => _emailError = null);
+            },
+          ),
+        ),
+        const SizedBox(height: 14),
+        KeyedSubtree(
+          key: _phoneAnchor,
+          child: CreditBillTextField(
+            key: const Key('profilePhoneField'),
+            label: 'Phone',
+            hint: 'Optional mobile number',
+            controller: _phoneController,
+            keyboardType: TextInputType.phone,
+            textInputAction: TextInputAction.done,
+            errorText: _phoneError,
+            onChanged: (_) {
+              if (_phoneError != null) setState(() => _phoneError = null);
+            },
+          ),
+        ),
+        const SizedBox(height: 20),
+        const SettingsSectionHeader(title: 'Account info'),
+        _buildAccountInfo(),
+        const SizedBox(height: 24),
+        CreditBillPrimaryButton(
+          key: const Key('saveProfileButton'),
+          text: 'Save changes',
+          isLoading: _isSaving,
+          onPressed: _isSaving ? null : _onSave,
+        ),
+        const SizedBox(height: 8),
+      ],
+    );
+  }
+
+  Widget _buildPhotoSection() {
+    return Column(
+      children: [
+        const SizedBox(height: 4),
+        ProfileAvatar(
+          key: const Key('profilePhotoAvatar'),
+          name: _nameController.text,
+          photo: _photo,
+          size: 72,
+        ),
+        const SizedBox(height: 10),
+        // Wrap (not Row): the panel's content column is only ~252px wide,
+        // so the two buttons must stack instead of overflowing sideways
+        // (which pushed "Remove photo" outside the viewport's hit area).
+        Wrap(
+          alignment: WrapAlignment.center,
+          spacing: 8,
+          runSpacing: 8,
+          children: [
+            CreditBillTextButton(
+              key: const Key('changePhotoButton'),
+              text: 'Change photo',
+              onPressed: _isSaving ? null : _pickPhoto,
+            ),
+            if (_photo != null)
+              CreditBillTextButton(
+                key: const Key('removePhotoButton'),
+                text: 'Remove photo',
+                color: CreditBillColors.errorRed,
+                onPressed: _isSaving ? null : _removePhoto,
+              ),
+          ],
+        ),
+      ],
+    );
+  }
+
+  Widget _buildAccountInfo() {
+    final profile = _profile;
+    final created = profile?.createdAt;
+    return Container(
+      width: double.infinity,
+      padding: const EdgeInsets.all(14),
+      decoration: BoxDecoration(
+        color: CreditBillColors.white,
+        borderRadius: BorderRadius.circular(12),
+        boxShadow: [
+          BoxShadow(
+            color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+            blurRadius: 6,
+            offset: const Offset(0, 3),
+          ),
+        ],
+      ),
+      child: Column(
+        children: [
+          _infoRow('User ID', profile?.id ?? 'â€”'),
+          _infoRow('Email', profile?.email ?? _signedInEmail ?? 'â€”'),
+          _infoRow(
+            'Member since',
+            created == null ? 'â€”' : DateFormat('d MMM yyyy').format(created),
+          ),
+          _infoRow(
+            'Email verified',
+            profile == null
+                ? 'â€”'
+                : (profile.isEmailVerified ? 'Verified' : 'Not verified'),
+            isStatus: true,
+            verified: profile?.isEmailVerified ?? false,
+          ),
+        ],
+      ),
+    );
+  }
+
+  Widget _infoRow(
+    String label,
+    String value, {
+    bool isStatus = false,
+    bool verified = false,
+  }) {
+    return Padding(
+      padding: const EdgeInsets.symmetric(vertical: 6),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          SizedBox(
+            width: 110,
+            child: Text(label, style: CreditBillTextTheme.inputLabel),
+          ),
+          Expanded(
+            child: isStatus
+                ? Align(
+                    alignment: Alignment.centerRight,
+                    child: Container(
+                      padding: const EdgeInsets.symmetric(
+                        horizontal: 10,
+                        vertical: 3,
+                      ),
+                      decoration: BoxDecoration(
+                        color: (verified
+                                ? CreditBillColors.successGreen
+                                : CreditBillColors.secondaryText)
+                            .withValues(alpha: 0.12),
+                        borderRadius: BorderRadius.circular(999),
+                      ),
+                      child: Text(
+                        value,
+                        style: CreditBillTextTheme.inputLabel.copyWith(
+                          color: verified
+                              ? CreditBillColors.successGreen
+                              : CreditBillColors.secondaryText,
+                        ),
+                      ),
+                    ),
+                  )
+                : Text(
+                    value,
+                    textAlign: TextAlign.right,
+                    style: CreditBillTextTheme.inputLabel.copyWith(
+                      color: CreditBillColors.textDark,
+                    ),
+                  ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+/// Asks for the current password before allowing an email change.
+///
+/// The dialog owns its [TextEditingController] and disposes it in
+/// [State.dispose], i.e. only after the dialog route's exit animation has
+/// finished and the route's widgets are unmounted. Disposing from a
+/// `showDialog(...).whenComplete` callback instead would release the
+/// controller while the closing dialog is still rebuilding against it
+/// ("A TextEditingController was used after being disposed").
+class _PasswordConfirmDialog extends StatefulWidget {
+  const _PasswordConfirmDialog();
+
+  @override
+  State<_PasswordConfirmDialog> createState() =>
+      _PasswordConfirmDialogState();
+}
+
+class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
+  final TextEditingController _controller = TextEditingController();
+  bool _obscure = true;
+  String? _error;
+
+  @override
+  void dispose() {
+    _controller.dispose();
+    super.dispose();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return AlertDialog(
+      title: const Text('Confirm your current password'),
+      content: Column(
+        mainAxisSize: MainAxisSize.min,
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            'Changing your email address needs your current '
+            'password to confirm it is you.',
+            style: CreditBillTextTheme.inputLabel,
+          ),
+          const SizedBox(height: 14),
+          CreditBillTextField(
+            key: const Key('currentPasswordField'),
+            label: 'Current password',
+            hint: 'Enter your password',
+            controller: _controller,
+            obscureText: _obscure,
+            autofocus: true,
+            textInputAction: TextInputAction.done,
+            onToggleVisibility: () => setState(() => _obscure = !_obscure),
+          ),
+          if (_error != null) ...[
+            const SizedBox(height: 8),
+            Text(_error!, style: CreditBillTextTheme.errorText),
+          ],
+        ],
+      ),
+      actions: [
+        CreditBillTextButton(
+          text: 'Cancel',
+          onPressed: () => Navigator.of(context).pop(),
+        ),
+        CreditBillTextButton(
+          text: 'Confirm',
+          onPressed: () {
+            if (_controller.text.isEmpty) {
+              setState(() => _error = 'Password is required.');
+              return;
+            }
+            Navigator.of(context).pop(_controller.text);
+          },
+        ),
+      ],
+    );
+  }
+}
+
diff --git a/lib/features/settings/presentation/pages/settings_page.dart b/lib/features/settings/presentation/pages/settings_page.dart
new file mode 100644
index 0000000..31763e8
--- /dev/null
+++ b/lib/features/settings/presentation/pages/settings_page.dart
@@ -0,0 +1,336 @@
+import 'package:flutter/material.dart';
+import 'package:flutter_bloc/flutter_bloc.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+import '../../../../core/theme/widgets/credit_bill_background.dart';
+import '../../../auth/domain/entities/user_entity.dart';
+import '../../../auth/domain/usecases/auth_usecases.dart';
+import '../../../auth/presentation/bloc/auth_bloc.dart';
+import '../widgets/profile_header.dart';
+import '../widgets/settings_section_header.dart';
+import '../widgets/settings_tile.dart';
+
+/// Main Settings screen: profile header, Edit Profile entry, live search
+/// and the full settings category list.
+///
+/// Every category leads to a fully functional screen (theme, security,
+/// storage, help, about) â€” there are no placeholders and no inert
+/// controls. Categories whose feature does not exist yet (language,
+/// notifications) are omitted entirely rather than shown as stubs.
+class SettingsPage extends StatefulWidget {
+  final GetProfileUseCase getProfileUseCase;
+
+  const SettingsPage({super.key, required this.getProfileUseCase});
+
+  @override
+  State<SettingsPage> createState() => _SettingsPageState();
+}
+
+class _SettingsSection {
+  final String title;
+  final List<_SettingsCategory> items;
+
+  const _SettingsSection(this.title, this.items);
+}
+
+class _SettingsCategory {
+  final String title;
+  final String subtitle;
+  final IconData icon;
+
+  /// Named route of the destination screen. "Edit profile" is dispatched
+  /// inline first so it can reload the header on return.
+  final String route;
+
+  const _SettingsCategory({
+    required this.title,
+    required this.subtitle,
+    required this.icon,
+    required this.route,
+  });
+}
+
+class _SettingsPageState extends State<SettingsPage> {
+  static const _categories = <_SettingsSection>[
+    _SettingsSection('Account', [
+      _SettingsCategory(
+        title: 'Edit profile',
+        subtitle: 'Name, email, phone and photo',
+        icon: Icons.person_outline,
+        route: '/edit-profile',
+      ),
+    ]),
+    _SettingsSection('Preferences', [
+      _SettingsCategory(
+        title: 'Theme & Appearance',
+        subtitle: 'Light, dark and system theme',
+        icon: Icons.palette_outlined,
+        route: '/settings/theme',
+      ),
+    ]),
+    _SettingsSection('Privacy', [
+      _SettingsCategory(
+        title: 'Security & Privacy',
+        subtitle: 'Change password and sign out',
+        icon: Icons.lock_outline,
+        route: '/settings/security',
+      ),
+    ]),
+    _SettingsSection('Data', [
+      _SettingsCategory(
+        title: 'Storage & Data',
+        subtitle: 'Storage usage and cache',
+        icon: Icons.storage_outlined,
+        route: '/settings/storage',
+      ),
+    ]),
+    _SettingsSection('Support', [
+      _SettingsCategory(
+        title: 'Help & Support',
+        subtitle: 'FAQs and app guide',
+        icon: Icons.help_outline,
+        route: '/settings/help',
+      ),
+      _SettingsCategory(
+        title: 'About',
+        subtitle: 'Version and legal information',
+        icon: Icons.info_outline,
+        route: '/settings/about',
+      ),
+    ]),
+  ];
+
+  final _searchController = TextEditingController();
+
+  UserEntity? _profile;
+  bool _loading = true;
+  String? _error;
+  String _query = '';
+
+  @override
+  void initState() {
+    super.initState();
+    _loadProfile();
+  }
+
+  @override
+  void dispose() {
+    _searchController.dispose();
+    super.dispose();
+  }
+
+  String? get _accountEmail {
+    final state = context.read<AuthBloc>().state;
+    return state is AuthAuthenticatedState ? state.email : null;
+  }
+
+  Future<void> _loadProfile() async {
+    final email = _accountEmail;
+    if (email == null) {
+      setState(() {
+        _loading = false;
+        _error = 'Please sign in to view your profile.';
+        _profile = null;
+      });
+      return;
+    }
+    setState(() {
+      _loading = true;
+      _error = null;
+    });
+    try {
+      final result = await widget.getProfileUseCase.execute(email: email);
+      if (!mounted) return;
+      setState(() {
+        _loading = false;
+        if (result.isLeft) {
+          _profile = null;
+          _error = result.leftOrNull!.message;
+        } else {
+          _profile = result.rightOrNull;
+          _error = _profile == null ? 'No profile found for this account.' : null;
+        }
+      });
+    } catch (e) {
+      if (!mounted) return;
+      setState(() {
+        _loading = false;
+        _profile = null;
+        _error = 'Failed to load profile: $e';
+      });
+    }
+  }
+
+  Future<void> _openEditProfile() async {
+    // Deliberately not `pushNamed<bool>`: named routes are registered as
+    // `MaterialPageRoute<dynamic>`, and `pushNamed<bool>` casts the created
+    // route to `Route<bool?>`, which throws a TypeError at runtime. The
+    // popped result is still compared against `true` below.
+    final updated = await Navigator.of(context).pushNamed('/edit-profile');
+    if (updated == true && mounted) {
+      await _loadProfile();
+    }
+  }
+
+  void _openCategory(_SettingsCategory category) {
+    if (category.title == 'Edit profile') {
+      _openEditProfile();
+      return;
+    }
+    Navigator.of(context).pushNamed(category.route);
+  }
+
+  List<_SettingsSection> get _visibleSections {
+    final query = _query.trim().toLowerCase();
+    if (query.isEmpty) return _categories;
+    return _categories
+        .map(
+          (section) => _SettingsSection(
+            section.title,
+            section.items
+                .where(
+                  (item) =>
+                      item.title.toLowerCase().contains(query) ||
+                      item.subtitle.toLowerCase().contains(query),
+                )
+                .toList(),
+          ),
+        )
+        .where((section) => section.items.isNotEmpty)
+        .toList();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final sections = _visibleSections;
+
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text('Settings'),
+        backgroundColor: CreditBillColors.primaryBlue,
+        foregroundColor: CreditBillColors.white,
+      ),
+      body: CreditBillBackground(
+        child: _loading
+            ? const Center(child: CircularProgressIndicator())
+            : _error != null
+            ? Center(
+                child: Padding(
+                  padding: const EdgeInsets.all(24),
+                  child: Column(
+                    mainAxisSize: MainAxisSize.min,
+                    children: [
+                      Text(
+                        _error!,
+                        textAlign: TextAlign.center,
+                        style: CreditBillTextTheme.screenSubheading,
+                      ),
+                      const SizedBox(height: 12),
+                      TextButton(
+                        onPressed: _loadProfile,
+                        child: const Text('Retry'),
+                      ),
+                    ],
+                  ),
+                ),
+              )
+            : ListView(
+                padding: const EdgeInsets.all(16),
+                children: [
+                  if (_query.trim().isEmpty) ...[
+                    ProfileHeader(
+                      name: _profile?.fullName ?? '',
+                      email: _profile?.email,
+                      phone: _profile?.phone,
+                      photo: _profile?.photo,
+                      onTap: _openEditProfile,
+                    ),
+                    const SizedBox(height: 8),
+                  ],
+                  _SearchField(
+                    controller: _searchController,
+                    onChanged: (value) => setState(() => _query = value),
+                  ),
+                  if (sections.isEmpty) ...[
+                    const SizedBox(height: 32),
+                    Center(
+                      child: Text(
+                        'No settings match "${_query.trim()}".',
+                        textAlign: TextAlign.center,
+                        style: CreditBillTextTheme.screenSubheading,
+                      ),
+                    ),
+                  ],
+                  for (final section in sections) ...[
+                    SettingsSectionHeader(title: section.title),
+                    for (final category in section.items)
+                      SettingsTile(
+                        icon: category.icon,
+                        title: category.title,
+                        subtitle: category.subtitle,
+                        onTap: () => _openCategory(category),
+                      ),
+                  ],
+                ],
+              ),
+      ),
+    );
+  }
+}
+
+class _SearchField extends StatelessWidget {
+  final TextEditingController controller;
+  final ValueChanged<String> onChanged;
+
+  const _SearchField({required this.controller, required this.onChanged});
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(top: 4, bottom: 4),
+      child: SizedBox(
+        height: 48,
+        child: TextField(
+          key: const Key('settingsSearchField'),
+          controller: controller,
+          onChanged: onChanged,
+          style: const TextStyle(
+            fontSize: 15,
+            color: CreditBillColors.textDark,
+          ),
+          cursorColor: CreditBillColors.primaryBlue,
+          decoration: InputDecoration(
+            hintText: 'Search settings',
+            hintStyle: const TextStyle(
+              fontSize: 15,
+              color: CreditBillColors.secondaryText,
+            ),
+            prefixIcon: const Icon(
+              Icons.search,
+              size: 20,
+              color: CreditBillColors.secondaryText,
+            ),
+            filled: true,
+            fillColor: CreditBillColors.inputBackground,
+            contentPadding: const EdgeInsets.symmetric(vertical: 14),
+            enabledBorder: OutlineInputBorder(
+              borderRadius: BorderRadius.circular(16),
+              borderSide: const BorderSide(
+                color: CreditBillColors.inputBorder,
+                width: 1.5,
+              ),
+            ),
+            focusedBorder: OutlineInputBorder(
+              borderRadius: BorderRadius.circular(16),
+              borderSide: const BorderSide(
+                color: CreditBillColors.primaryBlue,
+                width: 1.8,
+              ),
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/lib/features/settings/presentation/widgets/profile_header.dart b/lib/features/settings/presentation/widgets/profile_header.dart
new file mode 100644
index 0000000..5804ff6
--- /dev/null
+++ b/lib/features/settings/presentation/widgets/profile_header.dart
@@ -0,0 +1,201 @@
+import 'dart:convert';
+import 'dart:typed_data';
+
+import 'package:flutter/material.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+
+/// Settings profile header: avatar (photo or initials fallback), name,
+/// email and phone â€” or an "Add phone" hint when no number is stored yet.
+/// Tapping it opens the profile editor.
+class ProfileHeader extends StatelessWidget {
+  final String name;
+  final String? email;
+  final String? phone;
+  final String? photo;
+  final VoidCallback? onTap;
+
+  const ProfileHeader({
+    super.key,
+    required this.name,
+    this.email,
+    this.phone,
+    this.photo,
+    this.onTap,
+  });
+
+  /// Up to two uppercase initials, e.g. "Ada Lovelace" -> "AL".
+  static String initialsOf(String name) {
+    final parts =
+        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
+    if (parts.isEmpty) return '?';
+    if (parts.length == 1) {
+      return parts.first.substring(0, 1).toUpperCase();
+    }
+    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
+        .toUpperCase();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final hasPhone = phone != null && phone!.trim().isNotEmpty;
+
+    return Padding(
+      padding: const EdgeInsets.only(top: 4, bottom: 4),
+      child: InkWell(
+        onTap: onTap,
+        borderRadius: BorderRadius.circular(16),
+        child: Container(
+          padding: const EdgeInsets.all(16),
+          decoration: BoxDecoration(
+            color: CreditBillColors.white,
+            borderRadius: BorderRadius.circular(16),
+            boxShadow: [
+              BoxShadow(
+                color: CreditBillColors.deepBlue.withValues(alpha: 0.12),
+                blurRadius: 10,
+                offset: const Offset(0, 4),
+              ),
+            ],
+          ),
+          child: Row(
+            children: [
+              ProfileAvatar(name: name, photo: photo),
+              const SizedBox(width: 14),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      name,
+                      maxLines: 1,
+                      overflow: TextOverflow.ellipsis,
+                      style: CreditBillTextTheme.sectionLabel.copyWith(
+                        fontSize: 16,
+                      ),
+                    ),
+                    const SizedBox(height: 2),
+                    if (email != null && email!.isNotEmpty)
+                      Text(
+                        email!,
+                        maxLines: 1,
+                        overflow: TextOverflow.ellipsis,
+                        style: CreditBillTextTheme.inputLabel,
+                      ),
+                    const SizedBox(height: 4),
+                    if (hasPhone)
+                      Row(
+                        children: [
+                          const Icon(
+                            Icons.phone_outlined,
+                            size: 14,
+                            color: CreditBillColors.secondaryText,
+                          ),
+                          const SizedBox(width: 4),
+                          Expanded(
+                            child: Text(
+                              phone!.trim(),
+                              maxLines: 1,
+                              overflow: TextOverflow.ellipsis,
+                              style: CreditBillTextTheme.inputLabel.copyWith(
+                                color: CreditBillColors.textDark,
+                              ),
+                            ),
+                          ),
+                        ],
+                      )
+                    else
+                      Row(
+                        children: [
+                          const Icon(
+                            Icons.add_circle_outline,
+                            size: 14,
+                            color: CreditBillColors.primaryBlue,
+                          ),
+                          const SizedBox(width: 4),
+                          Expanded(
+                            child: Text(
+                              'Add phone',
+                              maxLines: 1,
+                              overflow: TextOverflow.ellipsis,
+                              style: CreditBillTextTheme.linkText.copyWith(
+                                fontSize: 13,
+                              ),
+                            ),
+                          ),
+                        ],
+                      ),
+                  ],
+                ),
+              ),
+              const Icon(
+                Icons.chevron_right,
+                color: CreditBillColors.secondaryText,
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class ProfileAvatar extends StatelessWidget {
+  final String name;
+  final String? photo;
+  final double size;
+
+  const ProfileAvatar({
+    super.key,
+    required this.name,
+    this.photo,
+    this.size = 56,
+  });
+
+  @override
+  Widget build(BuildContext context) {
+    Uint8List? bytes;
+    final encoded = photo?.trim();
+    if (encoded != null && encoded.isNotEmpty) {
+      try {
+        bytes = base64Decode(encoded);
+      } catch (_) {
+        bytes = null; // Corrupt payload -> initials fallback below.
+      }
+    }
+
+    final fallback = Container(
+      width: size,
+      height: size,
+      alignment: Alignment.center,
+      decoration: const BoxDecoration(
+        color: CreditBillColors.primaryBlue,
+        shape: BoxShape.circle,
+      ),
+      child: Text(
+        ProfileHeader.initialsOf(name),
+        style: TextStyle(
+          color: CreditBillColors.white,
+          fontSize: size * 0.34,
+          fontWeight: FontWeight.w700,
+        ),
+      ),
+    );
+
+    if (bytes == null) return fallback;
+
+    return ClipOval(
+      child: SizedBox(
+        width: size,
+        height: size,
+        child: Image.memory(
+          bytes,
+          fit: BoxFit.cover,
+          // A corrupt/undecodable image falls back to the initials avatar.
+          errorBuilder: (_, _, _) => fallback,
+        ),
+      ),
+    );
+  }
+}
diff --git a/lib/features/settings/presentation/widgets/settings_section_header.dart b/lib/features/settings/presentation/widgets/settings_section_header.dart
new file mode 100644
index 0000000..7ade146
--- /dev/null
+++ b/lib/features/settings/presentation/widgets/settings_section_header.dart
@@ -0,0 +1,27 @@
+import 'package:flutter/material.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+
+/// Small uppercase-ish heading used to group settings categories
+/// (WhatsApp-style section labels).
+class SettingsSectionHeader extends StatelessWidget {
+  final String title;
+
+  const SettingsSectionHeader({super.key, required this.title});
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(top: 20, bottom: 8),
+      child: Text(
+        title,
+        style: const TextStyle(
+          fontSize: 13,
+          fontWeight: FontWeight.w700,
+          color: CreditBillColors.primaryBlue,
+          letterSpacing: 0.4,
+        ),
+      ),
+    );
+  }
+}
diff --git a/lib/features/settings/presentation/widgets/settings_tile.dart b/lib/features/settings/presentation/widgets/settings_tile.dart
new file mode 100644
index 0000000..cfd0a27
--- /dev/null
+++ b/lib/features/settings/presentation/widgets/settings_tile.dart
@@ -0,0 +1,83 @@
+import 'package:flutter/material.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+
+/// A single settings row: icon, title, optional subtitle and trailing
+/// chevron. Every tile on the settings screen leads to a fully
+/// functional destination â€” there are no "coming soon" badges.
+class SettingsTile extends StatelessWidget {
+  final IconData icon;
+  final String title;
+  final String? subtitle;
+  final VoidCallback? onTap;
+
+  const SettingsTile({
+    super.key,
+    required this.icon,
+    required this.title,
+    this.subtitle,
+    this.onTap,
+  });
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 10),
+      child: InkWell(
+        onTap: onTap,
+        borderRadius: BorderRadius.circular(12),
+        child: Container(
+          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
+          decoration: BoxDecoration(
+            color: CreditBillColors.white,
+            borderRadius: BorderRadius.circular(12),
+            boxShadow: [
+              BoxShadow(
+                color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+                blurRadius: 6,
+                offset: const Offset(0, 3),
+              ),
+            ],
+          ),
+          child: Row(
+            children: [
+              Container(
+                padding: const EdgeInsets.all(8),
+                decoration: BoxDecoration(
+                  color: CreditBillColors.primaryBlue.withValues(alpha: 0.12),
+                  shape: BoxShape.circle,
+                ),
+                child: Icon(icon, size: 20, color: CreditBillColors.primaryBlue),
+              ),
+              const SizedBox(width: 12),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(title, style: CreditBillTextTheme.sectionLabel),
+                    if (subtitle != null && subtitle!.isNotEmpty) ...[
+                      const SizedBox(height: 2),
+                      Text(
+                        subtitle!,
+                        maxLines: 1,
+                        overflow: TextOverflow.ellipsis,
+                        style: CreditBillTextTheme.inputLabel,
+                      ),
+                    ],
+                  ],
+                ),
+              ),
+              const SizedBox(width: 4),
+              const Icon(
+                Icons.chevron_right,
+                size: 20,
+                color: CreditBillColors.secondaryText,
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/lib/main.dart b/lib/main.dart
index 08e1ac6..e379e94 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -3,6 +3,8 @@ import 'package:flutter/foundation.dart' show kIsWeb;
 import 'package:sqflite/sqflite.dart';
 import 'package:sqflite_common_ffi/sqflite_common_ffi.dart' as ffi;
 import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi_web;
+
+import 'core/theme/theme_controller.dart';
 import 'app.dart';
 import 'app/presentation/auth_wrapper.dart';
 
@@ -29,5 +31,10 @@ void main() async {
     databaseFactory = ffi.databaseFactoryFfi;
   }
 
-  runApp(const CreditBillApp(home: AuthWrapper()));
-}
\ No newline at end of file
+  // Load the persisted theme mode before the first frame so the app
+  // opens in the chosen theme without a light/dark flash.
+  final themeController = ThemeController();
+  await themeController.load();
+
+  runApp(CreditBillApp(home: AuthWrapper(), themeController: themeController));
+}
diff --git a/pubspec.lock b/pubspec.lock
index afb24c2..e4fc042 100644
--- a/pubspec.lock
+++ b/pubspec.lock
@@ -121,6 +121,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "1.15.1"
+  cross_file:
+    dependency: transitive
+    description:
+      name: cross_file
+      sha256: f141ea4f277af142a0356955707f6556f37b03947d39d55585981a06ca437bd6
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.3.5+5"
   crypto:
     dependency: transitive
     description:
@@ -185,6 +193,38 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "7.0.1"
+  file_selector_linux:
+    dependency: transitive
+    description:
+      name: file_selector_linux
+      sha256: da76400e7872ce7637ffdce12749ec24169c25f6195c28372208e65a24bcd2ab
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.9.4+1"
+  file_selector_macos:
+    dependency: transitive
+    description:
+      name: file_selector_macos
+      sha256: d785431f1910aac8a50e5c492cae912320158030a88703c67b9ef7f1f96fd7ba
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.9.5+2"
+  file_selector_platform_interface:
+    dependency: transitive
+    description:
+      name: file_selector_platform_interface
+      sha256: "35e0bd61ebcdb91a3505813b055b09b79dfdc7d0aee9c09a7ba59ae4bb13dc85"
+      url: "https://pub.dev"
+    source: hosted
+    version: "2.7.0"
+  file_selector_windows:
+    dependency: transitive
+    description:
+      name: file_selector_windows
+      sha256: fbefc5fb92c6d3cbe8d284a2cd971b593bb07d2cd6da8557b81a862250b4acec
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.9.3+6"
   fixnum:
     dependency: transitive
     description:
@@ -214,11 +254,24 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "6.0.0"
+  flutter_plugin_android_lifecycle:
+    dependency: transitive
+    description:
+      name: flutter_plugin_android_lifecycle
+      sha256: "3854fe5e3bff0b113c658f260b90c95dea17c92db0f2addeac2e343dd9969785"
+      url: "https://pub.dev"
+    source: hosted
+    version: "2.0.35"
   flutter_test:
     dependency: "direct dev"
     description: flutter
     source: sdk
     version: "0.0.0"
+  flutter_web_plugins:
+    dependency: transitive
+    description: flutter
+    source: sdk
+    version: "0.0.0"
   frontend_server_client:
     dependency: transitive
     description:
@@ -267,6 +320,70 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "4.1.2"
+  image_picker:
+    dependency: "direct main"
+    description:
+      name: image_picker
+      sha256: e71b1bd9e40124041128d60fc3034c7b1598e1bba4e570bba0c70301c817013a
+      url: "https://pub.dev"
+    source: hosted
+    version: "1.2.4"
+  image_picker_android:
+    dependency: transitive
+    description:
+      name: image_picker_android
+      sha256: "8a7823d5d3e884f7780829d85d92110d072bdcd9ed48e2be158d2abe91a912d4"
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.8.13+25"
+  image_picker_for_web:
+    dependency: transitive
+    description:
+      name: image_picker_for_web
+      sha256: "66257a3191ab360d23a55c8241c91a6e329d31e94efa7be9cf7a212e65850214"
+      url: "https://pub.dev"
+    source: hosted
+    version: "3.1.1"
+  image_picker_ios:
+    dependency: transitive
+    description:
+      name: image_picker_ios
+      sha256: f4e5650a81b268af3886bc789216ff6d56bdfa79934f93f1a5a8a303b8f60f77
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.8.13+15"
+  image_picker_linux:
+    dependency: transitive
+    description:
+      name: image_picker_linux
+      sha256: "1f81c5f2046b9ab724f85523e4af65be1d47b038160a8c8deed909762c308ed4"
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.2.2"
+  image_picker_macos:
+    dependency: transitive
+    description:
+      name: image_picker_macos
+      sha256: "86f0f15a309de7e1a552c12df9ce5b59fe927e71385329355aec4776c6a8ec91"
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.2.2+1"
+  image_picker_platform_interface:
+    dependency: transitive
+    description:
+      name: image_picker_platform_interface
+      sha256: "2dee4b4e3be429db71472c9c559c981498070a61af1ba82e0e4986fc5dadc042"
+      url: "https://pub.dev"
+    source: hosted
+    version: "2.11.2"
+  image_picker_windows:
+    dependency: transitive
+    description:
+      name: image_picker_windows
+      sha256: d248c86554a72b5495a31c56f060cf73a41c7ff541689327b1a7dbccc33adfae
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.2.2"
   intl:
     dependency: "direct main"
     description:
@@ -818,4 +935,4 @@ packages:
     version: "3.1.4"
 sdks:
   dart: ">=3.13.4 <4.0.0"
-  flutter: ">=3.44.0"
+  flutter: ">=3.47.0"
diff --git a/pubspec.yaml b/pubspec.yaml
index 7c48020..91fbbc3 100644
--- a/pubspec.yaml
+++ b/pubspec.yaml
@@ -38,6 +38,7 @@ dependencies:
   uuid: ^4.4.0
   intl: ^0.19.0
   bcrypt: ^1.2.0
+  image_picker: ^1.2.4
   sqflite_common: ^2.5.13
   sqflite_common_ffi: ^2.4.4
   sqflite_common_ffi_web: 1.2.0
@@ -54,6 +55,11 @@ flutter:
   # the material Icons class.
   uses-material-design: true
 
+  assets:
+    # Parsed at runtime by the About screen so the displayed app version
+    # always matches the build.
+    - pubspec.yaml
+
   # To add assets to your application, add an assets section, like this:
   # assets:
   #   - images/a_dot_burr.jpeg
diff --git a/test/features/auth/data/profile_migration_test.dart b/test/features/auth/data/profile_migration_test.dart
new file mode 100644
index 0000000..3fca726
--- /dev/null
+++ b/test/features/auth/data/profile_migration_test.dart
@@ -0,0 +1,453 @@
+import 'package:credit_bill_system/core/database/database_helper.dart';
+import 'package:credit_bill_system/core/errors/failures.dart';
+import 'package:credit_bill_system/core/utils/password_hasher.dart';
+import 'package:credit_bill_system/features/auth/data/datasources/user_local_data_source.dart';
+import 'package:credit_bill_system/features/auth/data/models/user_model.dart';
+import 'package:credit_bill_system/features/auth/data/repositories/user_repository_impl.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:path/path.dart' as p;
+import 'package:sqflite_common_ffi/sqflite_ffi.dart';
+
+/// v5 schema (everything that existed before the profile columns), used to
+/// prove the v6 upgrade is strictly additive.
+Future<void> createV5Schema(Database db) async {
+  await db.execute('''
+    CREATE TABLE cards (
+      id TEXT PRIMARY KEY,
+      bank_name TEXT NOT NULL,
+      nickname TEXT NOT NULL,
+      last_four TEXT NOT NULL
+        CHECK(last_four GLOB '[0-9][0-9][0-9][0-9]'),
+      network TEXT NOT NULL,
+      total_limit REAL NOT NULL CHECK(total_limit > 0),
+      billing_day INTEGER NOT NULL CHECK(billing_day BETWEEN 1 AND 31),
+      due_day INTEGER NOT NULL CHECK(due_day BETWEEN 1 AND 31),
+      color_gradient_idx INTEGER NOT NULL DEFAULT 0,
+      is_archived INTEGER NOT NULL DEFAULT 0,
+      created_at TEXT NOT NULL
+    )
+  ''');
+  await db.execute(
+    'CREATE INDEX IF NOT EXISTS idx_cards_archived ON cards(is_archived)',
+  );
+  await db.execute('''
+    CREATE TABLE bills (
+      id TEXT PRIMARY KEY NOT NULL,
+      card_id TEXT NOT NULL,
+      cycle_month TEXT NOT NULL,
+      statement_date TEXT NOT NULL,
+      due_date TEXT NOT NULL,
+      total_amount_due REAL NOT NULL CHECK(total_amount_due >= 0),
+      minimum_amount_due REAL NOT NULL DEFAULT 0,
+      amount_paid REAL NOT NULL DEFAULT 0 CHECK(amount_paid >= 0),
+      status TEXT NOT NULL CHECK(status IN ('unpaid', 'partially_paid', 'paid')),
+      updated_at TEXT NOT NULL,
+      FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE,
+      UNIQUE (card_id, cycle_month)
+    )
+  ''');
+  await db.execute(
+    'CREATE INDEX IF NOT EXISTS idx_bills_card_due ON bills(card_id, due_date)',
+  );
+  // v5 users table: no phone / photo yet.
+  await db.execute('''
+    CREATE TABLE users (
+      id TEXT PRIMARY KEY,
+      email TEXT NOT NULL UNIQUE,
+      full_name TEXT NOT NULL,
+      password_hash TEXT NOT NULL,
+      created_at TEXT NOT NULL,
+      is_email_verified INTEGER NOT NULL DEFAULT 1
+    )
+  ''');
+  await db.execute(
+    'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
+  );
+  await db.execute('''
+    CREATE TABLE customers (
+      id TEXT PRIMARY KEY,
+      name TEXT NOT NULL,
+      phone TEXT NOT NULL UNIQUE,
+      address,
+      created_at TEXT NOT NULL,
+      is_active INTEGER NOT NULL DEFAULT 1
+    )
+  ''');
+  await db.execute(
+    'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)',
+  );
+  await db.execute(
+    'CREATE INDEX IF NOT EXISTS idx_customers_active ON customers(is_active)',
+  );
+  await db.execute('''
+    CREATE TABLE credit_transactions (
+      id TEXT PRIMARY KEY,
+      customer_id TEXT NOT NULL,
+      amount_minor INTEGER NOT NULL CHECK(amount_minor > 0),
+      description,
+      due_date TEXT NOT NULL,
+      created_at TEXT NOT NULL,
+      FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
+    )
+  ''');
+  await db.execute(
+    'CREATE INDEX IF NOT EXISTS idx_credit_transactions_customer '
+    'ON credit_transactions(customer_id)',
+  );
+  await db.execute('''
+    CREATE TABLE payments (
+      id TEXT PRIMARY KEY,
+      customer_id TEXT NOT NULL,
+      amount_minor INTEGER NOT NULL CHECK(amount_minor > 0),
+      payment_date TEXT NOT NULL,
+      payment_type TEXT NOT NULL CHECK(payment_type IN ('full', 'partial')),
+      created_at TEXT NOT NULL,
+      FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
+    )
+  ''');
+  await db.execute(
+    'CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id)',
+  );
+  await db.execute('''
+    CREATE TABLE payment_allocations (
+      id TEXT PRIMARY KEY,
+      payment_id TEXT NOT NULL,
+      credit_transaction_id TEXT NOT NULL,
+      allocated_amount_minor INTEGER NOT NULL CHECK(allocated_amount_minor > 0),
+      created_at TEXT NOT NULL,
+      FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
+      FOREIGN KEY (credit_transaction_id) REFERENCES credit_transactions(id)
+        ON DELETE CASCADE,
+      UNIQUE (payment_id, credit_transaction_id)
+    )
+  ''');
+  await db.execute('''
+    CREATE TABLE recovery_codes (
+      id TEXT PRIMARY KEY,
+      email TEXT NOT NULL,
+      code_hash TEXT NOT NULL,
+      expires_at TEXT NOT NULL,
+      attempts INTEGER NOT NULL DEFAULT 0,
+      max_attempts INTEGER NOT NULL DEFAULT 5,
+      used INTEGER NOT NULL DEFAULT 0,
+      created_at TEXT NOT NULL
+    )
+  ''');
+  await db.execute(
+    'CREATE INDEX IF NOT EXISTS idx_recovery_email ON recovery_codes(email)',
+  );
+}
+
+Future<void> seedV5Data(Database db) async {
+  final now = DateTime.utc(2026, 10, 1).toIso8601String();
+
+  await db.insert('cards', {
+    'id': 'card-1',
+    'bank_name': 'HDFC',
+    'nickname': 'Millennia',
+    'last_four': '4821',
+    'network': 'Visa',
+    'total_limit': 150000,
+    'billing_day': 12,
+    'due_day': 2,
+    'color_gradient_idx': 3,
+    'is_archived': 0,
+    'created_at': now,
+  });
+  await db.insert('bills', {
+    'id': 'bill-1',
+    'card_id': 'card-1',
+    'cycle_month': '2026-10',
+    'statement_date': now,
+    'due_date': now,
+    'total_amount_due': 1250,
+    'minimum_amount_due': 100,
+    'amount_paid': 0,
+    'status': 'unpaid',
+    'updated_at': now,
+  });
+  await db.insert('users', {
+    'id': 'user-bcrypt',
+    'email': 'ada@example.com',
+    'full_name': 'Ada Lovelace',
+    'password_hash': PasswordHasher.hash('Secret123!'),
+    'created_at': now,
+    'is_email_verified': 1,
+  });
+  await db.insert('users', {
+    'id': 'user-legacy',
+    'email': 'legacy@example.com',
+    'full_name': 'Legacy User',
+    'password_hash': PasswordHasher.legacyHash('old-password'),
+    'created_at': now,
+    'is_email_verified': 1,
+  });
+  await db.insert('customers', {
+    'id': 'customer-1',
+    'name': 'Ravi',
+    'phone': '+94 77 000 1111',
+    'address': 'Colombo',
+    'created_at': now,
+    'is_active': 1,
+  });
+  await db.insert('credit_transactions', {
+    'id': 'txn-1',
+    'customer_id': 'customer-1',
+    'amount_minor': 50000,
+    'description': 'Stock',
+    'due_date': now,
+    'created_at': now,
+  });
+  await db.insert('payments', {
+    'id': 'payment-1',
+    'customer_id': 'customer-1',
+    'amount_minor': 25000,
+    'payment_date': now,
+    'payment_type': 'partial',
+    'created_at': now,
+  });
+  await db.insert('payment_allocations', {
+    'id': 'alloc-1',
+    'payment_id': 'payment-1',
+    'credit_transaction_id': 'txn-1',
+    'allocated_amount_minor': 25000,
+    'created_at': now,
+  });
+  await db.insert('recovery_codes', {
+    'id': 'recovery-1',
+    'email': 'ada@example.com',
+    'code_hash': 'hash',
+    'expires_at': now,
+    'attempts': 0,
+    'max_attempts': 5,
+    'used': 0,
+    'created_at': now,
+  });
+}
+
+void main() {
+  late DatabaseHelper databaseHelper;
+
+  setUpAll(() {
+    sqfliteFfiInit();
+    databaseFactory = databaseFactoryFfi;
+    databaseHelper = DatabaseHelper();
+  });
+
+  Future<String> databaseFilePath() async {
+    return p.join(await getDatabasesPath(), 'credit_bill_system.db');
+  }
+
+  setUp(() async {
+    await databaseHelper.close();
+    await deleteDatabase(await databaseFilePath());
+  });
+
+  tearDownAll(() async {
+    await databaseHelper.close();
+  });
+
+  test(
+    'v5 database upgrades to v6 with additive profile columns and intact data',
+    () async {
+      // Build a genuine v5 database with rows in every business table.
+      final path = await databaseFilePath();
+      final legacyDb = await databaseFactory.openDatabase(
+        path,
+        options: OpenDatabaseOptions(
+          version: 5,
+          onCreate: (db, version) async {
+            await createV5Schema(db);
+            await seedV5Data(db);
+          },
+        ),
+      );
+      expect(await legacyDb.getVersion(), 5);
+      await legacyDb.close();
+
+      // Opening through DatabaseHelper triggers the 5 -> 6 upgrade.
+      final db = await databaseHelper.database;
+
+      final version = await db.rawQuery('PRAGMA user_version;');
+      expect(version.single.values.single, 6);
+
+      // Profile columns exist, are nullable, and nothing else changed.
+      final columns = await db.rawQuery('PRAGMA table_info(users);');
+      final phone = columns.singleWhere((row) => row['name'] == 'phone');
+      final photo = columns.singleWhere((row) => row['name'] == 'photo');
+      expect(phone['notnull'], 0);
+      expect(photo['notnull'], 0);
+      expect(phone['type'], 'TEXT');
+      expect(photo['type'], 'TEXT');
+
+      // Every pre-existing row survived the migration untouched.
+      expect(
+        (await db.query('users')).map((row) => row['id']).toSet(),
+        {'user-bcrypt', 'user-legacy'},
+      );
+      final ada = (await db.query('users', where: 'email = ?', whereArgs: [
+        'ada@example.com',
+      ])).single;
+      expect(ada['full_name'], 'Ada Lovelace');
+      expect(ada['phone'], isNull);
+      expect(ada['photo'], isNull);
+      expect(await db.query('cards'), hasLength(1));
+      expect(await db.query('bills'), hasLength(1));
+      expect(await db.query('customers'), hasLength(1));
+      expect(await db.query('credit_transactions'), hasLength(1));
+      expect(await db.query('payments'), hasLength(1));
+      expect(await db.query('payment_allocations'), hasLength(1));
+      expect(await db.query('recovery_codes'), hasLength(1));
+
+      // Login still works for both modern (bcrypt) and legacy hashes.
+      final dataSource = UserLocalDataSourceImpl(
+        databaseHelper: databaseHelper,
+      );
+      final bcryptLogin = await dataSource.authenticateUser(
+        'ada@example.com',
+        'Secret123!',
+      );
+      expect(bcryptLogin, isNotNull);
+      expect(bcryptLogin!.id, 'user-bcrypt');
+
+      final legacyLogin = await dataSource.authenticateUser(
+        'legacy@example.com',
+        'old-password',
+      );
+      expect(legacyLogin, isNotNull);
+      expect(legacyLogin!.id, 'user-legacy');
+
+      expect(
+        await dataSource.authenticateUser('ada@example.com', 'wrong'),
+        isNull,
+      );
+    },
+  );
+
+  test('fresh install at v6 creates the profile columns too', () async {
+    final db = await databaseHelper.database;
+    final columns = await db.rawQuery('PRAGMA table_info(users);');
+    final names = columns.map((row) => row['name']).toSet();
+    expect(names, containsAll(['phone', 'photo']));
+    expect(await db.getVersion(), 6);
+  });
+
+  test('updateProfile persists edits across a reopen', () async {
+    final dataSource = UserLocalDataSourceImpl(
+      databaseHelper: databaseHelper,
+    );
+    await dataSource.insertUser(
+      UserModel(
+        id: 'user-1',
+        email: 'ada@example.com',
+        fullName: 'Ada',
+        passwordHash: PasswordHasher.hash('Secret123!'),
+        createdAt: DateTime(2026, 1, 1),
+      ),
+    );
+
+    const resizedPhoto = 'aGVsbG8gd29ybGQ='; // "hello world"
+    final updated = await dataSource.updateProfile(
+      currentEmail: 'ada@example.com',
+      fullName: 'Ada Lovelace',
+      email: 'ada.lovelace@example.com',
+      phone: '+94 77 123 4567',
+      photo: resizedPhoto,
+    );
+
+    expect(updated, isNotNull);
+    expect(updated!.fullName, 'Ada Lovelace');
+    expect(updated.email, 'ada.lovelace@example.com');
+    expect(updated.phone, '+94 77 123 4567');
+    expect(updated.photo, resizedPhoto);
+
+    // Reopen the database (fresh read) to prove the values persisted.
+    await databaseHelper.close();
+    final reopened = await databaseHelper.database;
+    final rows = await reopened.query('users');
+    expect(rows, hasLength(1));
+    expect(rows.single['full_name'], 'Ada Lovelace');
+    expect(rows.single['email'], 'ada.lovelace@example.com');
+    expect(rows.single['phone'], '+94 77 123 4567');
+    expect(rows.single['photo'], resizedPhoto);
+
+    // Login with the untouched password still works after the edit.
+    final login = await dataSource.authenticateUser(
+      'ada.lovelace@example.com',
+      'Secret123!',
+    );
+    expect(login, isNotNull);
+  });
+
+  test('updateProfile rejects a duplicate email without any partial write',
+      () async {
+    final dataSource = UserLocalDataSourceImpl(
+      databaseHelper: databaseHelper,
+    );
+    await dataSource.insertUser(
+      UserModel(
+        id: 'user-ada',
+        email: 'ada@example.com',
+        fullName: 'Ada',
+        passwordHash: PasswordHasher.hash('Secret123!'),
+        createdAt: DateTime(2026, 1, 1),
+      ),
+    );
+    await dataSource.insertUser(
+      UserModel(
+        id: 'user-grace',
+        email: 'grace@example.com',
+        fullName: 'Grace',
+        passwordHash: PasswordHasher.hash('Secret123!'),
+        createdAt: DateTime(2026, 1, 1),
+      ),
+    );
+
+    await expectLater(
+      dataSource.updateProfile(
+        currentEmail: 'ada@example.com',
+        fullName: 'Hijacked Name',
+        email: 'grace@example.com',
+        phone: '+1 000 000 0000',
+      ),
+      throwsA(isA<DuplicateEmailException>()),
+    );
+
+    // Neither account was modified by the rejected attempt.
+    final ada = await dataSource.getUserByEmail('ada@example.com');
+    expect(ada!.fullName, 'Ada');
+    expect(ada.email, 'ada@example.com');
+    expect(ada.phone, isNull);
+    final grace = await dataSource.getUserByEmail('grace@example.com');
+    expect(grace!.fullName, 'Grace');
+    expect(grace.email, 'grace@example.com');
+
+    // Repository surfaces the conflict as a typed Failure.
+    final repository = UserRepositoryImpl(localDataSource: dataSource);
+    final result = await repository.updateUserProfile(
+      currentEmail: 'ada@example.com',
+      fullName: 'Ada',
+      email: 'grace@example.com',
+    );
+    expect(result.isLeft, isTrue);
+    expect(result.leftOrNull, isA<ConflictFailure>());
+    expect(
+      (await repository.findUserByEmail('grace@example.com')).rightOrNull!.id,
+      'user-grace',
+    );
+  });
+
+  test('updateProfile on an unknown account reports NotFound', () async {
+    final repository = UserRepositoryImpl(
+      localDataSource: UserLocalDataSourceImpl(
+        databaseHelper: databaseHelper,
+      ),
+    );
+    final result = await repository.updateUserProfile(
+      currentEmail: 'ghost@example.com',
+      fullName: 'Ghost',
+      email: 'ghost@example.com',
+    );
+    expect(result.leftOrNull, isA<NotFoundFailure>());
+  });
+}
diff --git a/test/features/auth/domain/update_profile_usecase_test.dart b/test/features/auth/domain/update_profile_usecase_test.dart
new file mode 100644
index 0000000..6a081b0
--- /dev/null
+++ b/test/features/auth/domain/update_profile_usecase_test.dart
@@ -0,0 +1,333 @@
+import 'package:credit_bill_system/core/errors/either.dart';
+import 'package:credit_bill_system/core/errors/failures.dart';
+import 'package:credit_bill_system/core/utils/password_hasher.dart';
+import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
+import 'package:credit_bill_system/features/auth/domain/repositories/user_repository.dart';
+import 'package:credit_bill_system/features/auth/domain/usecases/auth_usecases.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mocktail/mocktail.dart';
+
+class MockUserRepository extends Mock implements UserRepository {}
+
+void main() {
+  late MockUserRepository repository;
+  late UpdateProfileUseCase useCase;
+
+  UserEntity storedUser({
+    String email = 'ada@example.com',
+    String? passwordHash,
+  }) {
+    return UserEntity(
+      id: 'user-1',
+      email: email,
+      fullName: 'Ada Lovelace',
+      passwordHash: passwordHash ?? PasswordHasher.hash('Secret123!'),
+      createdAt: DateTime(2026, 1, 1),
+      isEmailVerified: true,
+      phone: '+94 77 123 4567',
+    );
+  }
+
+  void stubProfileUpdate({Either<Failure, UserEntity>? result}) {
+    when(
+      () => repository.updateUserProfile(
+        currentEmail: any(named: 'currentEmail'),
+        fullName: any(named: 'fullName'),
+        email: any(named: 'email'),
+        phone: any(named: 'phone'),
+        photo: any(named: 'photo'),
+      ),
+    ).thenAnswer(
+      (_) async =>
+          result ??
+          Right<Failure, UserEntity>(storedUser(email: 'ada@example.com')),
+    );
+  }
+
+  setUp(() {
+    repository = MockUserRepository();
+    useCase = UpdateProfileUseCase(repository: repository);
+  });
+
+  group('validation runs before any write', () {
+    test('rejects an empty name', () async {
+      final result = await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: '   ',
+        email: 'ada@example.com',
+      );
+
+      expect(result.leftOrNull, isA<ValidationFailure>());
+      expect(
+        (result.leftOrNull! as ValidationFailure).message,
+        'Name cannot be empty.',
+      );
+      verifyNever(
+        () => repository.updateUserProfile(
+          currentEmail: any(named: 'currentEmail'),
+          fullName: any(named: 'fullName'),
+          email: any(named: 'email'),
+          phone: any(named: 'phone'),
+          photo: any(named: 'photo'),
+        ),
+      );
+    });
+
+    test('rejects a malformed email', () async {
+      final result = await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada',
+        email: 'not-an-email',
+      );
+
+      expect(result.leftOrNull, isA<ValidationFailure>());
+      expect(
+        (result.leftOrNull! as ValidationFailure).message,
+        'Enter a valid email address.',
+      );
+    });
+
+    test('rejects a malformed phone number', () async {
+      final result = await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada',
+        email: 'ada@example.com',
+        phone: 'call-me',
+      );
+
+      expect(result.leftOrNull, isA<ValidationFailure>());
+      expect(
+        (result.leftOrNull! as ValidationFailure).message,
+        'Enter a valid phone number.',
+      );
+    });
+
+    test('rejects a photo that is not valid base64', () async {
+      final result = await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada',
+        email: 'ada@example.com',
+        photo: '!!!not-base64!!!',
+      );
+
+      expect(result.leftOrNull, isA<ValidationFailure>());
+      expect(
+        (result.leftOrNull! as ValidationFailure).message,
+        contains('photo could not be read'),
+      );
+    });
+
+    test('rejects an oversized photo', () async {
+      final result = await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada',
+        email: 'ada@example.com',
+        photo: 'A' * (400 * 1024 + 1),
+      );
+
+      expect(result.leftOrNull, isA<ValidationFailure>());
+      expect(
+        (result.leftOrNull! as ValidationFailure).message,
+        contains('smaller photo'),
+      );
+    });
+  });
+
+  group('successful updates', () {
+    test('normalises the values and passes them to the repository', () async {
+      stubProfileUpdate();
+
+      final result = await useCase.execute(
+        currentEmail: '  ada@example.com ',
+        fullName: '  Ada Lovelace  ',
+        email: 'ada@example.com',
+        phone: '',
+      );
+
+      expect(result.isRight, isTrue);
+      verify(
+        () => repository.updateUserProfile(
+          currentEmail: 'ada@example.com',
+          fullName: 'Ada Lovelace',
+          email: 'ada@example.com',
+          phone: null,
+          photo: null,
+        ),
+      ).called(1);
+    });
+
+    test('keeps an empty phone as null instead of an empty string', () async {
+      stubProfileUpdate();
+
+      await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada Lovelace',
+        email: 'ada@example.com',
+        phone: '   ',
+      );
+
+      verify(
+        () => repository.updateUserProfile(
+          currentEmail: any(named: 'currentEmail'),
+          fullName: any(named: 'fullName'),
+          email: any(named: 'email'),
+          phone: null,
+          photo: null,
+        ),
+      ).called(1);
+    });
+  });
+
+  group('email changes require the current password', () {
+    test('are blocked without a password', () async {
+      final result = await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada Lovelace',
+        email: 'new@example.com',
+      );
+
+      expect(result.leftOrNull, isA<ValidationFailure>());
+      expect(
+        (result.leftOrNull! as ValidationFailure).message,
+        contains('current password'),
+      );
+      verifyNever(() => repository.findUserByEmail(any()));
+      verifyNever(
+        () => repository.updateUserProfile(
+          currentEmail: any(named: 'currentEmail'),
+          fullName: any(named: 'fullName'),
+          email: any(named: 'email'),
+          phone: any(named: 'phone'),
+          photo: any(named: 'photo'),
+        ),
+      );
+    });
+
+    test('are rejected when the password is wrong', () async {
+      when(() => repository.findUserByEmail('ada@example.com'))
+          .thenAnswer((_) async => Right<Failure, UserEntity?>(storedUser()));
+
+      final result = await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada Lovelace',
+        email: 'new@example.com',
+        currentPassword: 'wrong-password',
+      );
+
+      expect(result.leftOrNull, isA<ValidationFailure>());
+      expect(
+        (result.leftOrNull! as ValidationFailure).message,
+        'Current password is incorrect.',
+      );
+      // No database write happened for the rejected change.
+      verifyNever(
+        () => repository.updateUserProfile(
+          currentEmail: any(named: 'currentEmail'),
+          fullName: any(named: 'fullName'),
+          email: any(named: 'email'),
+          phone: any(named: 'phone'),
+          photo: any(named: 'photo'),
+        ),
+      );
+    });
+
+    test('are accepted when the password is correct', () async {
+      when(() => repository.findUserByEmail('ada@example.com'))
+          .thenAnswer((_) async => Right<Failure, UserEntity?>(storedUser()));
+      stubProfileUpdate(
+        result: Right<Failure, UserEntity>(
+          storedUser(email: 'new@example.com'),
+        ),
+      );
+
+      final result = await useCase.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada Lovelace',
+        email: 'new@example.com',
+        currentPassword: 'Secret123!',
+      );
+
+      expect(result.isRight, isTrue);
+      verify(
+        () => repository.updateUserProfile(
+          currentEmail: 'ada@example.com',
+          fullName: 'Ada Lovelace',
+          email: 'new@example.com',
+          phone: any(named: 'phone'),
+          photo: any(named: 'photo'),
+        ),
+      ).called(1);
+    });
+
+    test('still work for legacy FNV-1a accounts', () async {
+      when(() => repository.findUserByEmail('legacy@example.com')).thenAnswer(
+        (_) async => Right<Failure, UserEntity?>(
+          storedUser(
+            email: 'legacy@example.com',
+            passwordHash: PasswordHasher.legacyHash('old-password'),
+          ),
+        ),
+      );
+      stubProfileUpdate();
+
+      final result = await useCase.execute(
+        currentEmail: 'legacy@example.com',
+        fullName: 'Legacy User',
+        email: 'legacy2@example.com',
+        currentPassword: 'old-password',
+      );
+
+      expect(result.isRight, isTrue);
+    });
+
+    test('surface a missing account as NotFound', () async {
+      when(() => repository.findUserByEmail('ghost@example.com'))
+          .thenAnswer((_) async => const Right<Failure, UserEntity?>(null));
+
+      final result = await useCase.execute(
+        currentEmail: 'ghost@example.com',
+        fullName: 'Ghost',
+        email: 'ghost2@example.com',
+        currentPassword: 'whatever',
+      );
+
+      expect(result.leftOrNull, isA<NotFoundFailure>());
+      verifyNever(
+        () => repository.updateUserProfile(
+          currentEmail: any(named: 'currentEmail'),
+          fullName: any(named: 'fullName'),
+          email: any(named: 'email'),
+          phone: any(named: 'phone'),
+          photo: any(named: 'photo'),
+        ),
+      );
+    });
+  });
+
+  test('propagates repository failures such as a duplicate email', () async {
+    when(
+      () => repository.updateUserProfile(
+        currentEmail: any(named: 'currentEmail'),
+        fullName: any(named: 'fullName'),
+        email: any(named: 'email'),
+        phone: any(named: 'phone'),
+        photo: any(named: 'photo'),
+      ),
+    ).thenAnswer(
+      (_) async => const Left<Failure, UserEntity>(
+        ConflictFailure('That email address is already in use.'),
+      ),
+    );
+    when(() => repository.findUserByEmail('ada@example.com'))
+        .thenAnswer((_) async => Right(storedUser()));
+
+    final result = await useCase.execute(
+      currentEmail: 'ada@example.com',
+      fullName: 'Ada Lovelace',
+      email: 'taken@example.com',
+      currentPassword: 'Secret123!',
+    );
+
+    expect(result.leftOrNull, isA<ConflictFailure>());
+  });
+}
diff --git a/test/features/settings/presentation/edit_profile_page_test.dart b/test/features/settings/presentation/edit_profile_page_test.dart
new file mode 100644
index 0000000..f353a94
--- /dev/null
+++ b/test/features/settings/presentation/edit_profile_page_test.dart
@@ -0,0 +1,310 @@
+import 'package:credit_bill_system/core/errors/either.dart';
+import 'package:credit_bill_system/core/errors/failures.dart';
+import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
+import 'package:credit_bill_system/features/auth/presentation/bloc/auth_bloc.dart';
+import 'package:credit_bill_system/features/settings/presentation/pages/edit_profile_page.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_bloc/flutter_bloc.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mocktail/mocktail.dart';
+
+import '../settings_test_harness.dart';
+
+/// 1x1 transparent PNG â€” small enough for the photo size guard and valid
+/// enough to pass the picker's decode check.
+const _tinyPngBase64 =
+    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
+
+void main() {
+  const nameField = Key('profileNameField');
+  const emailField = Key('profileEmailField');
+  const phoneField = Key('profilePhoneField');
+  const saveButton = Key('saveProfileButton');
+
+  late AuthBloc bloc;
+  late MockUpdateProfileUseCase updateProfile;
+  late MockGetProfileUseCase getProfile;
+
+  String textOf(WidgetTester tester, Key key) {
+    final field = tester.widget<TextFormField>(
+      find.descendant(of: find.byKey(key), matching: find.byType(TextFormField)),
+    );
+    return field.controller!.text;
+  }
+
+  void stubUpdate(
+    Future<Either<Failure, UserEntity>> Function() answer,
+  ) {
+    when(
+      () => updateProfile.execute(
+        currentEmail: any(named: 'currentEmail'),
+        fullName: any(named: 'fullName'),
+        email: any(named: 'email'),
+        phone: any(named: 'phone'),
+        photo: any(named: 'photo'),
+        currentPassword: any(named: 'currentPassword'),
+      ),
+    ).thenAnswer((_) => answer());
+  }
+
+  Future<void> pumpEditor(
+    WidgetTester tester,
+    UserEntity storedUser,
+  ) async {
+    getProfile = MockGetProfileUseCase();
+    when(() => getProfile.execute(email: any(named: 'email'))).thenAnswer(
+      (_) async => Right<Failure, UserEntity?>(storedUser),
+    );
+
+    await tester.pumpWidget(
+      BlocProvider<AuthBloc>.value(
+        value: bloc,
+        child: MaterialApp(
+          home: Builder(
+            builder: (context) {
+              return Scaffold(
+                body: Center(
+                  child: TextButton(
+                    key: const Key('openEditorAction'),
+                    onPressed: () => Navigator.of(context).push(
+                      MaterialPageRoute<void>(
+                        builder: (_) => EditProfilePage(
+                          getProfileUseCase: getProfile,
+                        ),
+                      ),
+                    ),
+                    child: const Text('Open editor'),
+                  ),
+                ),
+              );
+            },
+          ),
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(const Key('openEditorAction')));
+    await tester.pumpAndSettle();
+    expect(find.byType(EditProfilePage), findsOneWidget);
+  }
+
+  /// The auth bloc is constructed in `setUp`, i.e. outside the fake-async
+  /// zone, so its update handler's async work â€” mock reply, session file
+  /// write, state emit, listener â€” only progresses on the real event loop,
+  /// which plain `pump`s never turn. Turn that loop inside `runAsync` and
+  /// wait for the actual update state (no fixed delay): if the bloc never
+  /// emits, the bounded timeout fails the test loudly instead of masking it.
+  Future<void> settleBlocDispatch(WidgetTester tester) async {
+    await tester.runAsync(() async {
+      if (bloc.state is! AuthProfileUpdatedState &&
+          bloc.state is! AuthProfileUpdateFailedState) {
+        await bloc.stream
+            .firstWhere(
+              (state) =>
+                  state is AuthProfileUpdatedState ||
+                  state is AuthProfileUpdateFailedState,
+            )
+            .timeout(
+              const Duration(seconds: 5),
+              onTimeout: () => throw StateError(
+                'AuthBloc never emitted a profile update state',
+              ),
+            );
+      }
+    });
+  }
+
+  setUp(() async {
+    final auth = await signedInAuthBloc(sampleUser());
+    bloc = auth.bloc;
+    addTearDown(bloc.close);
+    updateProfile = auth.updateProfileUseCase;
+    stubUpdate(() async => Right(sampleUser()));
+  });
+
+  testWidgets('seeds the form and account info from the stored profile', (
+    tester,
+  ) async {
+    await pumpEditor(tester, sampleUser());
+
+    expect(textOf(tester, nameField), 'Ada Lovelace');
+    expect(textOf(tester, emailField), 'ada@example.com');
+    expect(textOf(tester, phoneField), '+94 77 123 4567');
+    expect(find.text('AL'), findsOneWidget); // no photo -> initials avatar
+    expect(find.text('Change photo'), findsOneWidget);
+    expect(find.text('Remove photo'), findsNothing);
+
+    // The account-info card sits below the fold: scroll the page list so it
+    // is built and revealed before asserting on its rows.
+    await tester.scrollUntilVisible(
+      find.text('user-0001'),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    expect(find.text('User ID'), findsOneWidget);
+    expect(find.text('user-0001'), findsOneWidget);
+    expect(find.text('15 Jan 2026'), findsOneWidget);
+    expect(find.text('Verified'), findsOneWidget);
+  });
+
+  testWidgets('validates name, email and phone before dispatching anything', (
+    tester,
+  ) async {
+    await pumpEditor(tester, sampleUser());
+
+    await tester.enterText(find.byKey(nameField), '');
+    await tester.enterText(find.byKey(emailField), 'not-an-email');
+    await tester.enterText(find.byKey(phoneField), 'call-me');
+
+    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(saveButton));
+    await tester.pump();
+
+    expect(find.text('Name cannot be empty.'), findsOneWidget);
+    expect(find.text('Enter a valid email address.'), findsOneWidget);
+    expect(find.text('Enter a valid phone number.'), findsOneWidget);
+    expect(find.byType(EditProfilePage), findsOneWidget);
+    verifyNever(
+      () => updateProfile.execute(
+        currentEmail: any(named: 'currentEmail'),
+        fullName: any(named: 'fullName'),
+        email: any(named: 'email'),
+        phone: any(named: 'phone'),
+        photo: any(named: 'photo'),
+        currentPassword: any(named: 'currentPassword'),
+      ),
+    );
+  });
+
+  testWidgets('an email change asks for the current password first', (
+    tester,
+  ) async {
+    await pumpEditor(tester, sampleUser());
+
+    await tester.enterText(find.byKey(emailField), 'ada@newdomain.com');
+    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(saveButton));
+    await tester.pumpAndSettle();
+
+    expect(find.byType(AlertDialog), findsOneWidget);
+    expect(find.text('Confirm your current password'), findsOneWidget);
+    expect(find.text('Password is required.'), findsNothing);
+
+    // Confirming an empty password keeps the dialog open with an explanation.
+    await tester.tap(find.text('Confirm'));
+    await tester.pump();
+    expect(find.text('Password is required.'), findsOneWidget);
+    expect(find.byType(AlertDialog), findsOneWidget);
+
+    // Cancelling abandons the change: nothing is dispatched.
+    await tester.tap(find.text('Cancel'));
+    await tester.pumpAndSettle();
+    expect(find.byType(AlertDialog), findsNothing);
+    expect(find.byType(EditProfilePage), findsOneWidget);
+    expect(textOf(tester, emailField), 'ada@newdomain.com'); // edit kept
+    verifyNever(
+      () => updateProfile.execute(
+        currentEmail: any(named: 'currentEmail'),
+        fullName: any(named: 'fullName'),
+        email: any(named: 'email'),
+        phone: any(named: 'phone'),
+        photo: any(named: 'photo'),
+        currentPassword: any(named: 'currentPassword'),
+      ),
+    );
+  });
+
+  testWidgets('a wrong password keeps the user signed in with a clear message', (
+    tester,
+  ) async {
+    stubUpdate(
+      () async => const Left<Failure, UserEntity>(
+        ValidationFailure('Current password is incorrect.'),
+      ),
+    );
+    await pumpEditor(tester, sampleUser());
+
+    await tester.enterText(find.byKey(emailField), 'ada@newdomain.com');
+    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(saveButton));
+    await tester.pumpAndSettle();
+
+    await tester.enterText(
+      find.byKey(const Key('currentPasswordField')),
+      'wrong-password',
+    );
+    await tester.tap(find.text('Confirm'));
+    await settleBlocDispatch(tester);
+    await tester.pumpAndSettle();
+
+    // The rejection is surfaced and the editor (and session) stay put.
+    expect(find.text('Current password is incorrect.'), findsWidgets);
+    expect(find.byType(EditProfilePage), findsOneWidget);
+    expect(bloc.state, isA<AuthProfileUpdateFailedState>());
+    expect(bloc.state, isA<AuthAuthenticatedState>());
+
+    // Let the error SnackBar finish its timer so no timer outlives the test.
+    await tester.pump(const Duration(seconds: 5));
+    await tester.pumpAndSettle();
+  });
+
+  testWidgets('a successful save pops the editor with a confirmation', (
+    tester,
+  ) async {
+    stubUpdate(() async => Right(sampleUser(fullName: 'Augusta Ada King')));
+    await pumpEditor(tester, sampleUser());
+
+    await tester.enterText(find.byKey(nameField), 'Augusta Ada King');
+    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(saveButton));
+    await settleBlocDispatch(tester);
+    await tester.pumpAndSettle();
+
+    expect(find.byType(EditProfilePage), findsNothing);
+    expect(bloc.state, isA<AuthProfileUpdatedState>());
+    expect(
+      (bloc.state as AuthProfileUpdatedState).fullName,
+      'Augusta Ada King',
+    );
+    expect(find.text('Your profile has been updated.'), findsWidgets);
+
+    // Flush the success SnackBar timer before the test ends.
+    await tester.pump(const Duration(seconds: 5));
+    await tester.pumpAndSettle();
+  });
+
+  testWidgets('removing the photo sends a null photo on save', (tester) async {
+    await pumpEditor(tester, sampleUser(photo: _tinyPngBase64));
+
+    expect(find.text('Remove photo'), findsOneWidget);
+    await tester.tap(find.text('Remove photo'));
+    await tester.pump();
+    expect(find.text('Remove photo'), findsNothing);
+    expect(find.text('AL'), findsOneWidget); // back to initials
+
+    await tester.scrollUntilVisible(find.byKey(saveButton), 200, scrollable: pageScrollable);
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(saveButton));
+    await settleBlocDispatch(tester);
+    await tester.pumpAndSettle();
+
+    verify(
+      () => updateProfile.execute(
+        currentEmail: 'ada@example.com',
+        fullName: 'Ada Lovelace',
+        email: 'ada@example.com',
+        phone: '+94 77 123 4567',
+        photo: null,
+        currentPassword: null,
+      ),
+    ).called(1);
+
+    await tester.pump(const Duration(seconds: 5));
+    await tester.pumpAndSettle();
+  });
+}
diff --git a/test/features/settings/presentation/settings_page_test.dart b/test/features/settings/presentation/settings_page_test.dart
new file mode 100644
index 0000000..55bbbd3
--- /dev/null
+++ b/test/features/settings/presentation/settings_page_test.dart
@@ -0,0 +1,280 @@
+import 'package:credit_bill_system/core/errors/either.dart';
+import 'package:credit_bill_system/core/errors/failures.dart';
+import 'package:credit_bill_system/core/theme/theme_controller.dart';
+import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
+import 'package:credit_bill_system/features/auth/presentation/bloc/auth_bloc.dart';
+import 'package:credit_bill_system/features/settings/presentation/pages/settings_page.dart';
+import 'package:credit_bill_system/features/settings/presentation/pages/theme_settings_page.dart';
+import 'package:credit_bill_system/features/settings/presentation/widgets/profile_header.dart';
+import 'package:credit_bill_system/features/settings/presentation/widgets/settings_option_tile.dart';
+import 'package:credit_bill_system/features/settings/presentation/widgets/settings_tile.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_bloc/flutter_bloc.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mocktail/mocktail.dart';
+
+import '../settings_test_harness.dart';
+
+void main() {
+  late AuthBloc bloc;
+  late MockGetProfileUseCase getProfile;
+  late ThemeController themeController;
+  late FakePreferencesStore prefs;
+
+  /// Builds a [GetProfileUseCase] stub that answers from [answers] in order,
+  /// repeating the last entry when it runs out.
+  MockGetProfileUseCase profileStub(List<Either<Failure, UserEntity?>> answers) {
+    var calls = 0;
+    final stub = MockGetProfileUseCase();
+    when(() => stub.execute(email: any(named: 'email'))).thenAnswer((_) async {
+      final index = calls < answers.length ? calls : answers.length - 1;
+      calls += 1;
+      return answers[index];
+    });
+    return stub;
+  }
+
+  Future<void> pumpSettings(WidgetTester tester) async {
+    await tester.pumpWidget(
+      ThemeScope(
+        controller: themeController,
+        child: BlocProvider<AuthBloc>.value(
+          value: bloc,
+          child: MaterialApp(
+            home: SettingsPage(getProfileUseCase: getProfile),
+            onGenerateRoute: (settings) {
+              switch (settings.name) {
+                case '/edit-profile':
+                  return MaterialPageRoute<void>(
+                    builder: (context) => Scaffold(
+                      body: Center(
+                        child: TextButton(
+                          key: const Key('finishEditAction'),
+                          onPressed: () => Navigator.of(context).pop(true),
+                          child: const Text('Finish editing'),
+                        ),
+                      ),
+                    ),
+                  );
+                case '/settings/theme':
+                  return MaterialPageRoute<void>(
+                    builder: (context) => const ThemeSettingsPage(),
+                  );
+                default:
+                  return null;
+              }
+            },
+          ),
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+  }
+
+  setUp(() async {
+    final auth = await signedInAuthBloc(sampleUser());
+    bloc = auth.bloc;
+    addTearDown(bloc.close);
+    getProfile = profileStub([Right(sampleUser())]);
+    prefs = FakePreferencesStore();
+    themeController = ThemeController(store: prefs);
+    addTearDown(themeController.dispose);
+  });
+
+  testWidgets('renders the stored profile header and the full category list', (
+    tester,
+  ) async {
+    await pumpSettings(tester);
+
+    // Profile comes from the database, not from hard-coded text.
+    expect(find.byType(ProfileHeader), findsOneWidget);
+    expect(find.text('Ada Lovelace'), findsOneWidget);
+    expect(find.text('ada@example.com'), findsOneWidget);
+    expect(find.text('+94 77 123 4567'), findsOneWidget);
+    expect(find.text('AL'), findsOneWidget); // initials avatar fallback
+
+    expect(
+      find.ancestor(
+        of: find.text('Edit profile'),
+        matching: find.byType(SettingsTile),
+      ),
+      findsOneWidget,
+    );
+
+    // Nothing on the screen pretends to be on the way: there is no
+    // "Coming soon" label anywhere, and the categories whose features
+    // do not exist yet (language, notifications) are omitted entirely â€”
+    // not shown as stubs.
+    expect(find.text('Coming soon'), findsNothing);
+
+    // The whole list ships, all the way to the last entry. The list is
+    // lazy: bring each entry into view (in list order) before asserting
+    // on it, or the ones scrolled past are unmounted.
+    for (final label in [
+      'Theme & Appearance',
+      'Security & Privacy',
+      'Storage & Data',
+      'Help & Support',
+      'About',
+    ]) {
+      await tester.scrollUntilVisible(
+        find.text(label),
+        200,
+        scrollable: pageScrollable,
+      );
+      await tester.pumpAndSettle();
+      expect(find.text(label), findsOneWidget);
+      expect(
+        find.ancestor(of: find.text(label), matching: find.byType(SettingsTile)),
+        findsOneWidget,
+      );
+    }
+    expect(find.text('Coming soon'), findsNothing);
+  });
+
+  testWidgets('a category opens its real screen, applies and returns', (
+    tester,
+  ) async {
+    await pumpSettings(tester);
+
+    await tester.scrollUntilVisible(
+      find.text('Theme & Appearance'),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(find.text('Theme & Appearance'));
+    await tester.pumpAndSettle();
+
+    // A fully functional theme picker â€” not a placeholder.
+    expect(find.byType(ThemeSettingsPage), findsOneWidget);
+    expect(find.text('System default'), findsOneWidget);
+    expect(find.text('Light'), findsOneWidget);
+    expect(find.text('Dark'), findsOneWidget);
+
+    // Choosing Dark applies to the controller and is persisted.
+    await tester.tap(find.byKey(const Key('themeDarkOption')));
+    await tester.pumpAndSettle();
+    expect(prefs.savedMode, ThemeMode.dark);
+    expect(
+      tester.widget<SettingsOptionTile>(
+        find.byKey(const Key('themeDarkOption')),
+      ).selected,
+      isTrue,
+    );
+
+    // Back returns to the settings list untouched.
+    Navigator.of(tester.element(find.byType(AppBar))).pop();
+    await tester.pumpAndSettle();
+    expect(find.byType(SettingsPage), findsOneWidget);
+    // The lazy list restores at its previous offset, leaving the first
+    // entry unmounted; snap back to the top before asserting on it.
+    tester.state<ScrollableState>(pageScrollable).position.jumpTo(0);
+    await tester.pumpAndSettle();
+    expect(find.text('Edit profile'), findsOneWidget);
+  });
+
+  testWidgets('live search filters the category list', (tester) async {
+    await pumpSettings(tester);
+
+    await tester.enterText(
+      find.byKey(const Key('settingsSearchField')),
+      'storage',
+    );
+    await tester.pump();
+
+    expect(find.text('Storage & Data'), findsOneWidget);
+    expect(find.text('Data'), findsOneWidget);
+    expect(find.text('Edit profile'), findsNothing);
+    expect(find.text('Account'), findsNothing);
+    expect(find.byType(ProfileHeader), findsNothing); // search-only mode
+
+    await tester.enterText(
+      find.byKey(const Key('settingsSearchField')),
+      'zzzz',
+    );
+    await tester.pump();
+    expect(find.text('No settings match "zzzz".'), findsOneWidget);
+    expect(find.byType(SettingsTile), findsNothing);
+
+    // Categories whose features are not built (yet) are absent from the
+    // searchable list instead of advertising themselves.
+    await tester.enterText(
+      find.byKey(const Key('settingsSearchField')),
+      'language',
+    );
+    await tester.pump();
+    expect(find.text('No settings match "language".'), findsOneWidget);
+
+    await tester.enterText(
+      find.byKey(const Key('settingsSearchField')),
+      'notifications',
+    );
+    await tester.pump();
+    expect(find.text('No settings match "notifications".'), findsOneWidget);
+
+    await tester.enterText(find.byKey(const Key('settingsSearchField')), '');
+    await tester.pump();
+    expect(find.byType(ProfileHeader), findsOneWidget);
+    expect(find.text('Edit profile'), findsOneWidget);
+    expect(find.text('No settings match "zzzz".'), findsNothing);
+  });
+
+  testWidgets('opening Edit profile reloads the profile on return', (
+    tester,
+  ) async {
+    var calls = 0;
+    getProfile = MockGetProfileUseCase();
+    when(() => getProfile.execute(email: any(named: 'email'))).thenAnswer((
+      _,
+    ) async {
+      calls += 1;
+      return Right<Failure, UserEntity?>(
+        calls == 1
+            ? sampleUser()
+            : sampleUser(fullName: 'Grace Hopper', phone: null),
+      );
+    });
+
+    await pumpSettings(tester);
+    expect(calls, 1);
+    expect(find.text('Ada Lovelace'), findsOneWidget);
+
+    await tester.tap(find.text('Edit profile'));
+    await tester.pumpAndSettle();
+    expect(find.byKey(const Key('finishEditAction')), findsOneWidget);
+
+    await tester.tap(find.byKey(const Key('finishEditAction')));
+    await tester.pumpAndSettle();
+
+    // Returning with `true` refreshes the header from the database.
+    expect(calls, 2);
+    expect(find.text('Grace Hopper'), findsOneWidget);
+    expect(find.text('Ada Lovelace'), findsNothing);
+    expect(find.text('Add phone'), findsOneWidget); // no number stored yet
+  });
+
+  testWidgets('profile load failures show a message and a working Retry', (
+    tester,
+  ) async {
+    getProfile = profileStub([
+      const Left<Failure, UserEntity?>(
+        NotFoundFailure('No account found with this email.'),
+      ),
+      Right(sampleUser()),
+    ]);
+
+    await pumpSettings(tester);
+
+    expect(find.text('No account found with this email.'), findsOneWidget);
+    expect(find.text('Retry'), findsOneWidget);
+    expect(find.byType(ProfileHeader), findsNothing);
+
+    await tester.tap(find.text('Retry'));
+    await tester.pumpAndSettle();
+
+    expect(find.byType(ProfileHeader), findsOneWidget);
+    expect(find.text('Ada Lovelace'), findsOneWidget);
+    expect(find.text('No account found with this email.'), findsNothing);
+  });
+}
diff --git a/test/features/settings/settings_test_harness.dart b/test/features/settings/settings_test_harness.dart
new file mode 100644
index 0000000..70e6099
--- /dev/null
+++ b/test/features/settings/settings_test_harness.dart
@@ -0,0 +1,131 @@
+import 'dart:io';
+
+import 'package:credit_bill_system/core/errors/either.dart';
+import 'package:credit_bill_system/core/errors/failures.dart';
+import 'package:credit_bill_system/core/services/preferences_store.dart';
+import 'package:credit_bill_system/core/utils/password_hasher.dart';
+import 'package:credit_bill_system/features/auth/data/datasources/recovery_code_local_data_source.dart';
+import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
+import 'package:credit_bill_system/features/auth/domain/usecases/auth_usecases.dart';
+import 'package:credit_bill_system/features/auth/presentation/bloc/auth_bloc.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter/services.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mocktail/mocktail.dart';
+
+class MockLoginUseCase extends Mock implements LoginUseCase {}
+
+class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
+
+class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
+
+class MockSeedDefaultUserUseCase extends Mock
+    implements SeedDefaultUserUseCase {}
+
+class MockSeedDevAccountUseCase extends Mock implements SeedDevAccountUseCase {}
+
+class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}
+
+class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}
+
+class MockChangePasswordUseCase extends Mock implements ChangePasswordUseCase {}
+
+/// In-memory [PreferencesStore] for widget tests: the pages only need the
+/// read/write round trip, while real file persistence is covered by the
+/// theme-controller unit tests.
+class FakePreferencesStore extends Fake implements PreferencesStore {
+  ThemeMode? savedMode;
+
+  @override
+  Future<ThemeMode> loadThemeMode() async => savedMode ?? ThemeMode.system;
+
+  @override
+  Future<void> saveThemeMode(ThemeMode mode) async => savedMode = mode;
+}
+
+class MockRecoveryCodeLocalDataSource extends Mock
+    implements RecoveryCodeLocalDataSource {}
+
+/// The settings pages' vertical list [Scrollable].
+///
+/// Pass this as `scrollable:` to `scrollUntilVisible`. The default
+/// `find.byType(Scrollable)` matches every single-line [TextField] as well
+/// (each hosts its own horizontal scrollable), which makes
+/// `scrollUntilVisible` throw `Bad state: Too many elements`.
+final Finder pageScrollable = find.byWidgetPredicate(
+  (widget) => widget is Scrollable && widget.axis == Axis.vertical,
+);
+
+/// path_provider's method channel is unanswered inside widget tests, so an
+/// unmocked [SessionManager.saveSession] (the auth bloc awaits it before
+/// emitting any post-login/profile state) would hang forever and stall every
+/// `pumpAndSettle`. Answer it with the system temp directory instead.
+const MethodChannel _pathProviderChannel = MethodChannel(
+  'plugins.flutter.io/path_provider',
+);
+
+void mockPathProvider() {
+  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
+      .setMockMethodCallHandler(_pathProviderChannel, (call) async {
+    return Directory.systemTemp.path;
+  });
+}
+
+/// A stored profile used across the settings widget tests.
+UserEntity sampleUser({
+  String id = 'user-0001',
+  String email = 'ada@example.com',
+  String fullName = 'Ada Lovelace',
+  String? phone = '+94 77 123 4567',
+  String? photo,
+  bool isEmailVerified = true,
+  DateTime? createdAt,
+}) {
+  return UserEntity(
+    id: id,
+    email: email,
+    fullName: fullName,
+    passwordHash: PasswordHasher.hash('Secret123!'),
+    createdAt: createdAt ?? DateTime(2026, 1, 15),
+    isEmailVerified: isEmailVerified,
+    phone: phone,
+    photo: photo,
+  );
+}
+
+/// Builds an [AuthBloc] that has already completed a sign-in as [user], so
+/// the settings screens can resolve the signed-in email from its state.
+///
+/// Returns the bloc together with its (mocked) update use case so tests can
+/// stub profile saves.
+Future<
+  ({AuthBloc bloc, MockUpdateProfileUseCase updateProfileUseCase})
+>
+signedInAuthBloc(UserEntity user) async {
+  mockPathProvider();
+  final login = MockLoginUseCase();
+  when(
+    () => login.execute(
+      email: any(named: 'email'),
+      password: any(named: 'password'),
+    ),
+  ).thenAnswer((_) async => Right<Failure, UserEntity>(user));
+
+  final updateProfile = MockUpdateProfileUseCase();
+  final bloc = AuthBloc(
+    loginUseCase: login,
+    forgotPasswordUseCase: MockForgotPasswordUseCase(),
+    resetPasswordUseCase: MockResetPasswordUseCase(),
+    seedDefaultUserUseCase: MockSeedDefaultUserUseCase(),
+    seedDevAccountUseCase: MockSeedDevAccountUseCase(),
+    updateProfileUseCase: updateProfile,
+    recoveryCodeDataSource: MockRecoveryCodeLocalDataSource(),
+  );
+
+  final signedIn = bloc.stream.firstWhere(
+    (state) => state is AuthAuthenticatedState,
+  );
+  bloc.add(LoginRequestedEvent(email: user.email, password: 'not-checked'));
+  await signedIn;
+  return (bloc: bloc, updateProfileUseCase: updateProfile);
+}
diff --git a/lib/core/services/preferences_store.dart b/lib/core/services/preferences_store.dart
new file mode 100644
index 0000000..389e83a
--- /dev/null
+++ b/lib/core/services/preferences_store.dart
@@ -0,0 +1,89 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:flutter/foundation.dart';
+import 'package:flutter/material.dart' show ThemeMode;
+import 'package:path_provider/path_provider.dart';
+
+/// Local, offline key/value store for app preferences (theme mode today;
+/// further settings as they land).
+///
+/// Follows the [SessionManager] pattern: a JSON file in the app documents
+/// directory on native platforms, an in-memory fallback on web where
+/// `dart:io` is unavailable. Nothing here ever leaves the device.
+class PreferencesStore {
+  PreferencesStore({this.fileName = defaultFileName});
+
+  static const String defaultFileName = 'preferences.json';
+
+  /// Shared instance used by the app.
+  static final PreferencesStore instance = PreferencesStore();
+
+  final String fileName;
+
+  // In-memory fallback for Web where dart:io File is unavailable.
+  Map<String, dynamic>? _memory;
+
+  Future<File?> _prefsFile() async {
+    if (kIsWeb) return null;
+    try {
+      final dir = await getApplicationDocumentsDirectory();
+      return File('${dir.path}/$fileName');
+    } catch (_) {
+      return null;
+    }
+  }
+
+  Future<Map<String, dynamic>> _read() async {
+    if (kIsWeb) return _memory ??= <String, dynamic>{};
+    try {
+      final file = await _prefsFile();
+      if (file == null || !await file.exists()) return <String, dynamic>{};
+      final decoded = jsonDecode(await file.readAsString());
+      if (decoded is Map<String, dynamic>) return decoded;
+      return <String, dynamic>{};
+    } catch (_) {
+      // A corrupt/unreadable file behaves like "nothing stored yet".
+      return <String, dynamic>{};
+    }
+  }
+
+  Future<void> _write(Map<String, dynamic> prefs) async {
+    if (kIsWeb) {
+      _memory = prefs;
+      return;
+    }
+    try {
+      final file = await _prefsFile();
+      if (file == null) return;
+      await file.writeAsString(jsonEncode(prefs));
+    } catch (e) {
+      // Preferences are a convenience; persistence failure must not crash.
+      debugPrint('Preferences save failed: $e');
+    }
+  }
+
+  /// Last chosen theme mode, or [ThemeMode.system] when unset/unknown.
+  Future<ThemeMode> loadThemeMode() async {
+    final prefs = await _read();
+    switch (prefs['theme_mode'] as String?) {
+      case 'light':
+        return ThemeMode.light;
+      case 'dark':
+        return ThemeMode.dark;
+      default:
+        return ThemeMode.system;
+    }
+  }
+
+  /// Persists the theme mode.
+  Future<void> saveThemeMode(ThemeMode mode) async {
+    final prefs = await _read();
+    prefs['theme_mode'] = switch (mode) {
+      ThemeMode.light => 'light',
+      ThemeMode.dark => 'dark',
+      ThemeMode.system => 'system',
+    };
+    await _write(prefs);
+  }
+}
diff --git a/lib/core/theme/theme_controller.dart b/lib/core/theme/theme_controller.dart
new file mode 100644
index 0000000..42685d4
--- /dev/null
+++ b/lib/core/theme/theme_controller.dart
@@ -0,0 +1,62 @@
+import 'package:flutter/material.dart';
+
+import '../services/preferences_store.dart';
+
+/// Holds the user's chosen [ThemeMode] and persists it through a
+/// [PreferencesStore].
+///
+/// `main()` loads the stored value before the first frame so the app opens
+/// in the chosen theme without a flash; [setMode] notifies listeners first
+/// and persists afterwards so the UI reacts on the same frame.
+class ThemeController extends ChangeNotifier {
+  ThemeController({PreferencesStore? store, ThemeMode? initialMode})
+    : _store = store ?? PreferencesStore.instance,
+      _mode = initialMode ?? ThemeMode.system;
+
+  final PreferencesStore _store;
+  ThemeMode _mode;
+
+  ThemeMode get mode => _mode;
+
+  /// Reads the persisted mode (defaults to system when nothing is stored).
+  Future<void> load() async {
+    final stored = await _store.loadThemeMode();
+    if (stored == _mode) return;
+    _mode = stored;
+    notifyListeners();
+  }
+
+  /// Applies [mode] immediately and persists it.
+  Future<void> setMode(ThemeMode mode) async {
+    if (mode == _mode) return;
+    _mode = mode;
+    notifyListeners();
+    await _store.saveThemeMode(mode);
+  }
+}
+
+/// Exposes the app-level [ThemeController] to descendant widgets.
+///
+/// Lives directly above [MaterialApp]; pages below it (e.g. the theme
+/// picker) read it through [ThemeScope.of] and rebuild whenever the mode
+/// changes. `MaterialApp` switches themes through its built-in
+/// [AnimatedTheme], so every surface eases to the new mode.
+class ThemeScope extends InheritedNotifier<ThemeController> {
+  const ThemeScope({
+    super.key,
+    required ThemeController controller,
+    required super.child,
+  }) : super(notifier: controller);
+
+  /// The controller above [context]. Requires a [ThemeScope] ancestor
+  /// (the app provides one around `MaterialApp`).
+  static ThemeController of(BuildContext context) {
+    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
+    assert(scope != null, 'No ThemeScope found above this widget.');
+    return scope!.notifier!;
+  }
+
+  /// The controller above [context], or null when there is none.
+  static ThemeController? maybeOf(BuildContext context) =>
+      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
+}
diff --git a/lib/core/theme/widgets/credit_bill_page_route.dart b/lib/core/theme/widgets/credit_bill_page_route.dart
new file mode 100644
index 0000000..0f0e538
--- /dev/null
+++ b/lib/core/theme/widgets/credit_bill_page_route.dart
@@ -0,0 +1,34 @@
+import 'package:flutter/material.dart';
+
+/// Shared page transition for settings navigation: a short fade with a
+/// subtle upward slide, built on Flutter's built-in animation APIs.
+///
+/// Honours the platform's "remove animations" accessibility setting â€”
+/// when `disableAnimations` is on, content is shown without transition.
+class CreditBillPageRoute<T> extends PageRouteBuilder<T> {
+  CreditBillPageRoute({required WidgetBuilder builder})
+    : super(
+        transitionDuration: const Duration(milliseconds: 240),
+        reverseTransitionDuration: const Duration(milliseconds: 200),
+        opaque: true,
+        pageBuilder: (context, _, _) => builder(context),
+        transitionsBuilder: (context, animation, secondaryAnimation, child) {
+          if (MediaQuery.disableAnimationsOf(context)) return child;
+          final curved = CurvedAnimation(
+            parent: animation,
+            curve: Curves.easeOutCubic,
+            reverseCurve: Curves.easeInCubic,
+          );
+          return FadeTransition(
+            opacity: curved,
+            child: SlideTransition(
+              position: Tween<Offset>(
+                begin: const Offset(0, 0.05),
+                end: Offset.zero,
+              ).animate(curved),
+              child: child,
+            ),
+          );
+        },
+      );
+}
diff --git a/lib/features/settings/presentation/pages/about_page.dart b/lib/features/settings/presentation/pages/about_page.dart
new file mode 100644
index 0000000..faf9866
--- /dev/null
+++ b/lib/features/settings/presentation/pages/about_page.dart
@@ -0,0 +1,178 @@
+import 'package:flutter/material.dart';
+import 'package:flutter/services.dart' show rootBundle;
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+import '../../../../core/theme/widgets/credit_bill_background.dart';
+import '../../../../core/theme/widgets/credit_bill_logo.dart';
+import '../widgets/settings_section_header.dart';
+
+/// About: real app identity â€” the version is parsed from the bundled
+/// `pubspec.yaml` asset (single source of truth, no hard-coded copy), and
+/// the license listing is Flutter's built-in [showLicensePage], which
+/// reads the actual licenses of every package in the build.
+class AboutPage extends StatefulWidget {
+  const AboutPage({super.key});
+
+  @override
+  State<AboutPage> createState() => _AboutPageState();
+}
+
+class _AboutPageState extends State<AboutPage> {
+  /// Raw version from pubspec (`1.0.0+1`), null until loaded.
+  String? _rawVersion;
+  bool _versionFailed = false;
+
+  @override
+  void initState() {
+    super.initState();
+    _loadVersion();
+  }
+
+  Future<void> _loadVersion() async {
+    try {
+      final yaml = await rootBundle.loadString('pubspec.yaml');
+      final match = RegExp(
+        r'^version:[ \t]*(\S+)',
+        multiLine: true,
+      ).firstMatch(yaml);
+      if (!mounted) return;
+      setState(() {
+        _rawVersion = match?.group(1);
+        _versionFailed = _rawVersion == null;
+      });
+    } catch (_) {
+      if (!mounted) return;
+      setState(() => _versionFailed = true);
+    }
+  }
+
+  String get _versionDisplay {
+    final raw = _rawVersion;
+    if (raw == null) return _versionFailed ? 'Unavailable' : 'Loadingâ€¦';
+    final parts = raw.split('+');
+    return parts.length > 1 ? '${parts[0]} (build ${parts[1]})' : raw;
+  }
+
+  void _openLicenses() {
+    showLicensePage(
+      context: context,
+      applicationName: 'Credit Bill System',
+      applicationVersion: _rawVersion ?? '',
+      applicationLegalese:
+          'CreditBill is an offline-first customer credit app. All records '
+          'stay on this device.',
+    );
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text('About'),
+        backgroundColor: CreditBillColors.primaryBlue,
+        foregroundColor: CreditBillColors.white,
+      ),
+      body: CreditBillBackground(
+        child: ListView(
+          padding: const EdgeInsets.all(16),
+          children: [
+            const SizedBox(height: 8),
+            const Center(child: CreditBillLogo(size: 64)),
+            const SizedBox(height: 12),
+            Center(
+              child: Text(
+                'Credit Bill System',
+                style: CreditBillTextTheme.brandName,
+              ),
+            ),
+            const SizedBox(height: 4),
+            Center(
+              child: Text(
+                'Version $_versionDisplay',
+                key: const Key('aboutVersion'),
+                style: CreditBillTextTheme.inputLabel,
+              ),
+            ),
+            const SizedBox(height: 16),
+            Container(
+              padding: const EdgeInsets.all(14),
+              decoration: BoxDecoration(
+                color: CreditBillColors.white,
+                borderRadius: BorderRadius.circular(12),
+                boxShadow: [
+                  BoxShadow(
+                    color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+                    blurRadius: 6,
+                    offset: const Offset(0, 3),
+                  ),
+                ],
+              ),
+              child: Text(
+                'Offline-first customer credit and bill management. Cards, '
+                'customers, transactions, payments and reports are stored '
+                'locally on this device â€” the app works without an internet '
+                'connection and never sends your data anywhere.',
+                style: CreditBillTextTheme.inputLabel.copyWith(height: 1.55),
+              ),
+            ),
+            const SizedBox(height: 16),
+            const SettingsSectionHeader(title: 'Legal'),
+            // Material (not a bare DecoratedBox) so ListTile paints its
+            // own background and ink splash â€” the framework asserts on
+            // an opaque DecoratedBox in between.
+            Material(
+              color: CreditBillColors.white,
+              shape: RoundedRectangleBorder(
+                borderRadius: BorderRadius.circular(12),
+              ),
+              elevation: 0,
+              child: Container(
+                decoration: BoxDecoration(
+                  borderRadius: BorderRadius.circular(12),
+                  boxShadow: [
+                    BoxShadow(
+                      color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+                      blurRadius: 6,
+                      offset: const Offset(0, 3),
+                    ),
+                  ],
+                ),
+                child: ListTile(
+                  key: const Key('openLicensesButton'),
+                  shape: RoundedRectangleBorder(
+                    borderRadius: BorderRadius.circular(12),
+                  ),
+                  title: Text(
+                    'Open-source licenses',
+                    style: CreditBillTextTheme.sectionLabel,
+                  ),
+                  subtitle: Text(
+                    'Licenses of Flutter and every bundled package',
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
+                    style: CreditBillTextTheme.inputLabel,
+                  ),
+                  trailing: const Icon(
+                    Icons.chevron_right,
+                    size: 20,
+                    color: CreditBillColors.secondaryText,
+                  ),
+                  onTap: _openLicenses,
+                ),
+              ),
+            ),
+            const SizedBox(height: 20),
+            Center(
+              child: Text(
+                'Â© 2026 CreditBill. All rights reserved.',
+                style: CreditBillTextTheme.inputLabel,
+              ),
+            ),
+            const SizedBox(height: 8),
+          ],
+        ),
+      ),
+    );
+  }
+}
diff --git a/lib/features/settings/presentation/pages/help_support_page.dart b/lib/features/settings/presentation/pages/help_support_page.dart
new file mode 100644
index 0000000..511ffad
--- /dev/null
+++ b/lib/features/settings/presentation/pages/help_support_page.dart
@@ -0,0 +1,160 @@
+import 'package:flutter/material.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+import '../../../../core/theme/widgets/credit_bill_background.dart';
+import '../widgets/settings_section_header.dart';
+
+/// Help & Support: an offline FAQ with expandable answers plus a short
+/// statement of how the app handles data. Every answer describes shipped
+/// behaviour â€” there is no contact form or link that could dead-end.
+class HelpSupportPage extends StatelessWidget {
+  const HelpSupportPage({super.key});
+
+  static const List<({String question, String answer})> _faqs = [
+    (
+      question: 'How do I add a customer?',
+      answer:
+          'Open Customers from the dashboard (or the "Add Customer" quick '
+          'action), fill in the name and phone number, and save. The customer '
+          'appears in your list immediately and is stored on this device.',
+    ),
+    (
+      question: 'How do statement bills work?',
+      answer:
+          'Use "Add Credit Bill" on a card to log its monthly statement with '
+          'the statement date, due date and amounts. The card shows a '
+          'countdown badge until the due date and a "Paid" badge once the '
+          'bill is settled.',
+    ),
+    (
+      question: 'How do I record a payment?',
+      answer:
+          'Open a customer (or use the "Record Payment" quick action), enter '
+          'the amount and date, and choose whether it settles a bill fully or '
+          'in part. Payments are allocated to outstanding transactions '
+          'automatically and the balance updates right away.',
+    ),
+    (
+      question: 'Where is my data stored?',
+      answer:
+          'Everything stays on this device in the app\'s local database. '
+          'CreditBill makes no network requests: your customers, '
+          'transactions, payments and profile are never uploaded anywhere.',
+    ),
+    (
+      question: 'What happens if I forget my password?',
+      answer:
+          'Use "Forgot password" on the login screen. A recovery code lets '
+          'you set a new password; the new password is stored only as a '
+          'bcrypt hash, and your old one never is.',
+    ),
+    (
+      question: 'How do I change my name, email or photo?',
+      answer:
+          'Go to Settings â†’ Edit profile. Changing your email additionally '
+          'asks for your current password to confirm it is you. The new '
+          'values are saved to this device and shown right away.',
+    ),
+    (
+      question: 'How do I switch between light and dark mode?',
+      answer:
+          'Open Settings â†’ Theme & Appearance and choose System default, '
+          'Light or Dark. The change applies to every screen immediately and '
+          'is remembered for your next launch.',
+    ),
+  ];
+
+  @override
+  Widget build(BuildContext context) {
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text('Help & Support'),
+        backgroundColor: CreditBillColors.primaryBlue,
+        foregroundColor: CreditBillColors.white,
+      ),
+      body: CreditBillBackground(
+        child: ListView(
+          padding: const EdgeInsets.all(16),
+          children: [
+            Text(
+              'Answers to the most common questions about CreditBill.',
+              style: CreditBillTextTheme.screenSubheading,
+            ),
+            const SizedBox(height: 16),
+            const SettingsSectionHeader(title: 'Frequently asked questions'),
+            for (final faq in _faqs)
+              _FaqTile(question: faq.question, answer: faq.answer),
+            const SizedBox(height: 8),
+            const SettingsSectionHeader(title: 'About your data'),
+            Container(
+              padding: const EdgeInsets.all(14),
+              decoration: BoxDecoration(
+                color: CreditBillColors.white,
+                borderRadius: BorderRadius.circular(12),
+                boxShadow: [
+                  BoxShadow(
+                    color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+                    blurRadius: 6,
+                    offset: const Offset(0, 3),
+                  ),
+                ],
+              ),
+              child: Text(
+                'CreditBill runs fully offline. Nothing you enter is sent '
+                'over the internet, and clearing the app\'s data is the only '
+                'way these records leave this device â€” keep your login '
+                'password safe.',
+                style: CreditBillTextTheme.inputLabel.copyWith(height: 1.5),
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+/// One expandable FAQ entry, styled to the CreditBill card language.
+class _FaqTile extends StatelessWidget {
+  final String question;
+  final String answer;
+
+  const _FaqTile({required this.question, required this.answer});
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      margin: const EdgeInsets.only(bottom: 10),
+      decoration: BoxDecoration(
+        color: CreditBillColors.white,
+        borderRadius: BorderRadius.circular(12),
+        boxShadow: [
+          BoxShadow(
+            color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+            blurRadius: 6,
+            offset: const Offset(0, 3),
+          ),
+        ],
+      ),
+      child: Theme(
+        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
+        child: ExpansionTile(
+          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
+          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
+          iconColor: CreditBillColors.primaryBlue,
+          collapsedIconColor: CreditBillColors.secondaryText,
+          shape: const Border(),
+          collapsedShape: const Border(),
+          title: Text(question, style: CreditBillTextTheme.sectionLabel),
+          children: [
+            Text(
+              answer,
+              style: CreditBillTextTheme.inputLabel.copyWith(height: 1.55),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
diff --git a/lib/features/settings/presentation/pages/security_privacy_page.dart b/lib/features/settings/presentation/pages/security_privacy_page.dart
new file mode 100644
index 0000000..a615924
--- /dev/null
+++ b/lib/features/settings/presentation/pages/security_privacy_page.dart
@@ -0,0 +1,410 @@
+import 'package:flutter/material.dart';
+import 'package:flutter_bloc/flutter_bloc.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+import '../../../../core/theme/widgets/credit_bill_background.dart';
+import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
+import '../../../../core/theme/widgets/credit_bill_text_field.dart';
+import '../../../auth/domain/usecases/auth_usecases.dart';
+import '../../../auth/presentation/bloc/auth_bloc.dart';
+import '../widgets/settings_section_header.dart';
+
+/// Security & Privacy: change the account password (verified against the
+/// stored bcrypt/legacy hash) and sign out â€” plus a truthful note about
+/// where the data lives.
+///
+/// Talks directly to [ChangePasswordUseCase] (auth domain), the same way
+/// the settings shell talks to [GetProfileUseCase]; no session or
+/// authenticated state changes, so `AuthBloc` needs no new surface.
+class SecurityPrivacyPage extends StatefulWidget {
+  final ChangePasswordUseCase changePasswordUseCase;
+
+  const SecurityPrivacyPage({super.key, required this.changePasswordUseCase});
+
+  @override
+  State<SecurityPrivacyPage> createState() => _SecurityPrivacyPageState();
+}
+
+class _SecurityPrivacyPageState extends State<SecurityPrivacyPage> {
+  final _currentController = TextEditingController();
+  final _newController = TextEditingController();
+  final _confirmController = TextEditingController();
+
+  bool _obscureCurrent = true;
+  bool _obscureNew = true;
+  bool _obscureConfirm = true;
+  bool _isSaving = false;
+
+  String? _currentError;
+  String? _newError;
+  String? _confirmError;
+  String? _formError;
+
+  final ScrollController _scrollController = ScrollController();
+
+  // Anchors used to scroll a field back into view after a failed submit:
+  // the form list can be scrolled, so a field may be off-screen.
+  final GlobalKey _currentAnchor = GlobalKey();
+  final GlobalKey _newAnchor = GlobalKey();
+  final GlobalKey _confirmAnchor = GlobalKey();
+
+  @override
+  void dispose() {
+    _currentController.dispose();
+    _newController.dispose();
+    _confirmController.dispose();
+    _scrollController.dispose();
+    super.dispose();
+  }
+
+  String? get _signedInEmail {
+    final state = context.read<AuthBloc>().state;
+    return state is AuthAuthenticatedState ? state.email : null;
+  }
+
+  Future<void> _onChangePassword() async {
+    setState(() {
+      _currentError = null;
+      _newError = null;
+      _confirmError = null;
+      _formError = null;
+    });
+
+    final current = _currentController.text;
+    final next = _newController.text;
+    final confirm = _confirmController.text;
+
+    var invalid = false;
+    if (current.isEmpty) {
+      setState(() => _currentError = 'Enter your current password.');
+      invalid = true;
+    }
+    if (next.length < 6) {
+      setState(() => _newError = 'Password must be at least 6 characters.');
+      invalid = true;
+    }
+    if (confirm != next) {
+      setState(() => _confirmError = 'Passwords do not match.');
+      invalid = true;
+    }
+    if (invalid) {
+      _revealFirstInvalidError();
+      return;
+    }
+
+    final email = _signedInEmail;
+    if (email == null) {
+      setState(
+        () => _formError = 'Please sign in again to change your password.',
+      );
+      return;
+    }
+
+    setState(() => _isSaving = true);
+    final result = await widget.changePasswordUseCase.execute(
+      email: email,
+      currentPassword: current,
+      newPassword: next,
+    );
+    if (!mounted) return;
+
+    result.fold(
+      (failure) {
+        setState(() {
+          _isSaving = false;
+          _formError = failure.message;
+        });
+        _showSnack(failure.message, CreditBillColors.errorRed);
+      },
+      (_) {
+        setState(() {
+          _isSaving = false;
+          _currentController.clear();
+          _newController.clear();
+          _confirmController.clear();
+          _formError = null;
+        });
+        _showSnack(
+          'Password changed successfully.',
+          CreditBillColors.successGreen,
+        );
+      },
+    );
+  }
+
+  void _revealFirstInvalidError() {
+    final anchor =
+        _currentError != null
+        ? _currentAnchor
+        : _newError != null
+        ? _newAnchor
+        : _confirmAnchor;
+    final fieldContext = anchor.currentContext;
+    if (fieldContext != null) {
+      Scrollable.ensureVisible(fieldContext);
+      return;
+    }
+    if (_scrollController.hasClients) {
+      _scrollController.jumpTo(0);
+    }
+    WidgetsBinding.instance.addPostFrameCallback((_) {
+      final ctx = anchor.currentContext;
+      if (ctx != null && mounted) Scrollable.ensureVisible(ctx);
+    });
+  }
+
+  void _showSnack(String message, Color background) {
+    ScaffoldMessenger.of(context).showSnackBar(
+      SnackBar(
+        content: Text(message),
+        backgroundColor: background,
+        behavior: SnackBarBehavior.floating,
+        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
+      ),
+    );
+  }
+
+  Future<void> _confirmSignOut() async {
+    final confirmed = await showDialog<bool>(
+      context: context,
+      builder: (_) => AlertDialog(
+        title: const Text('Sign out?'),
+        content: const Text(
+          'You will need your email and password to sign back in. '
+          'Your data stays on this device.',
+        ),
+        actions: [
+          CreditBillTextButton(
+            key: const Key('signOutCancelButton'),
+            text: 'Cancel',
+            onPressed: () => Navigator.of(context).pop(false),
+          ),
+          CreditBillTextButton(
+            key: const Key('signOutConfirmButton'),
+            text: 'Sign out',
+            color: CreditBillColors.errorRed,
+            onPressed: () => Navigator.of(context).pop(true),
+          ),
+        ],
+      ),
+    );
+    if (confirmed != true || !mounted) return;
+
+    context.read<AuthBloc>().add(LogoutRequestedEvent());
+    // Drop every pushed route so the AuthWrapper below shows the welcome
+    // screen once the bloc reports the session as cleared.
+    Navigator.of(context).popUntil((route) => route.isFirst);
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text('Security & Privacy'),
+        backgroundColor: CreditBillColors.primaryBlue,
+        foregroundColor: CreditBillColors.white,
+      ),
+      body: CreditBillBackground(
+        child: ListView(
+          controller: _scrollController,
+          padding: const EdgeInsets.all(16),
+          children: [
+            if (_formError != null) ...[
+              Container(
+                padding: const EdgeInsets.all(12),
+                decoration: BoxDecoration(
+                  color: CreditBillColors.errorRed.withValues(alpha: 0.1),
+                  borderRadius: BorderRadius.circular(12),
+                  border: Border.all(
+                    color: CreditBillColors.errorRed,
+                    width: 1,
+                  ),
+                ),
+                child: Row(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    const Icon(
+                      Icons.error_outline,
+                      size: 18,
+                      color: CreditBillColors.errorRed,
+                    ),
+                    const SizedBox(width: 8),
+                    Expanded(
+                      child: Text(
+                        _formError!,
+                        style: CreditBillTextTheme.errorText.copyWith(
+                          fontSize: 13,
+                        ),
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+              const SizedBox(height: 16),
+            ],
+            const SettingsSectionHeader(title: 'Change password'),
+            KeyedSubtree(
+              key: _currentAnchor,
+              child: CreditBillTextField(
+                key: const Key('changeCurrentPasswordField'),
+                label: 'Current password',
+                hint: 'Enter your current password',
+                controller: _currentController,
+                obscureText: _obscureCurrent,
+                textInputAction: TextInputAction.next,
+                errorText: _currentError,
+                onChanged: (_) {
+                  if (_currentError != null) {
+                    setState(() => _currentError = null);
+                  }
+                },
+                onToggleVisibility: () =>
+                    setState(() => _obscureCurrent = !_obscureCurrent),
+              ),
+            ),
+            const SizedBox(height: 14),
+            KeyedSubtree(
+              key: _newAnchor,
+              child: CreditBillTextField(
+                key: const Key('changeNewPasswordField'),
+                label: 'New password',
+                hint: 'At least 6 characters',
+                controller: _newController,
+                obscureText: _obscureNew,
+                errorText: _newError,
+                onChanged: (_) {
+                  if (_newError != null) setState(() => _newError = null);
+                },
+                onToggleVisibility: () =>
+                    setState(() => _obscureNew = !_obscureNew),
+              ),
+            ),
+            const SizedBox(height: 14),
+            KeyedSubtree(
+              key: _confirmAnchor,
+              child: CreditBillTextField(
+                key: const Key('changeConfirmPasswordField'),
+                label: 'Confirm new password',
+                hint: 'Repeat the new password',
+                controller: _confirmController,
+                obscureText: _obscureConfirm,
+                textInputAction: TextInputAction.done,
+                errorText: _confirmError,
+                onChanged: (_) {
+                  if (_confirmError != null) {
+                    setState(() => _confirmError = null);
+                  }
+                },
+                onToggleVisibility: () =>
+                    setState(() => _obscureConfirm = !_obscureConfirm),
+              ),
+            ),
+            const SizedBox(height: 20),
+            CreditBillPrimaryButton(
+              key: const Key('changePasswordButton'),
+              text: 'Update password',
+              isLoading: _isSaving,
+              onPressed: _isSaving ? null : _onChangePassword,
+            ),
+            const SizedBox(height: 24),
+            const SettingsSectionHeader(title: 'Session'),
+            _signOutTile(),
+            const SizedBox(height: 16),
+            const SettingsSectionHeader(title: 'Privacy'),
+            Container(
+              padding: const EdgeInsets.all(14),
+              decoration: BoxDecoration(
+                color: CreditBillColors.white,
+                borderRadius: BorderRadius.circular(12),
+                boxShadow: [
+                  BoxShadow(
+                    color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+                    blurRadius: 6,
+                    offset: const Offset(0, 3),
+                  ),
+                ],
+              ),
+              child: Text(
+                'All records â€” customers, transactions, payments and your '
+                'profile â€” are stored locally in the app database on this '
+                'device. CreditBill makes no network requests and shares '
+                'nothing with third parties. Signing out keeps the data; '
+                'only your session ends.',
+                style: CreditBillTextTheme.inputLabel.copyWith(height: 1.55),
+              ),
+            ),
+            const SizedBox(height: 8),
+          ],
+        ),
+      ),
+    );
+  }
+
+  Widget _signOutTile() {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 10),
+      child: InkWell(
+        key: const Key('signOutTile'),
+        onTap: _isSaving ? null : _confirmSignOut,
+        borderRadius: BorderRadius.circular(12),
+        child: Container(
+          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
+          decoration: BoxDecoration(
+            color: CreditBillColors.white,
+            borderRadius: BorderRadius.circular(12),
+            boxShadow: [
+              BoxShadow(
+                color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+                blurRadius: 6,
+                offset: const Offset(0, 3),
+              ),
+            ],
+          ),
+          child: Row(
+            children: [
+              Container(
+                padding: const EdgeInsets.all(8),
+                decoration: BoxDecoration(
+                  color: CreditBillColors.errorRed.withValues(alpha: 0.12),
+                  shape: BoxShape.circle,
+                ),
+                child: const Icon(
+                  Icons.logout,
+                  size: 20,
+                  color: CreditBillColors.errorRed,
+                ),
+              ),
+              const SizedBox(width: 12),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      'Sign out',
+                      style: CreditBillTextTheme.sectionLabel.copyWith(
+                        color: CreditBillColors.errorRed,
+                      ),
+                    ),
+                    const SizedBox(height: 2),
+                    Text(
+                      'End this session on this device',
+                      maxLines: 1,
+                      overflow: TextOverflow.ellipsis,
+                      style: CreditBillTextTheme.inputLabel,
+                    ),
+                  ],
+                ),
+              ),
+              const Icon(
+                Icons.chevron_right,
+                size: 20,
+                color: CreditBillColors.secondaryText,
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/lib/features/settings/presentation/pages/storage_data_page.dart b/lib/features/settings/presentation/pages/storage_data_page.dart
new file mode 100644
index 0000000..6a25ef4
--- /dev/null
+++ b/lib/features/settings/presentation/pages/storage_data_page.dart
@@ -0,0 +1,261 @@
+import 'dart:io' show File;
+
+import 'package:flutter/foundation.dart' show kIsWeb;
+import 'package:flutter/material.dart';
+
+import '../../../../core/database/database_helper.dart';
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+import '../../../../core/theme/widgets/credit_bill_background.dart';
+import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
+import '../widgets/settings_section_header.dart';
+
+/// Storage & Data: real record counts from the app database, the real
+/// on-disk database size, the live image-cache size and a working
+/// "clear cache" action. Every figure is read from this device â€” nothing
+/// is estimated or faked.
+class StorageDataPage extends StatefulWidget {
+  final DatabaseHelper databaseHelper;
+
+  const StorageDataPage({super.key, required this.databaseHelper});
+
+  @override
+  State<StorageDataPage> createState() => _StorageDataPageState();
+}
+
+class _StorageDataPageState extends State<StorageDataPage> {
+  static const List<({String label, String table})> _rowTables = [
+    (label: 'Customers', table: DatabaseHelper.tableCustomers),
+    (
+      label: 'Credit transactions',
+      table: DatabaseHelper.tableCreditTransactions,
+    ),
+    (label: 'Payments', table: DatabaseHelper.tablePayments),
+    (label: 'Cards', table: DatabaseHelper.tableCards),
+    (label: 'Statement bills', table: DatabaseHelper.tableBills),
+  ];
+
+  Map<String, int> _counts = {};
+  int? _dbBytes;
+  int _cacheBytes = 0;
+  bool _loading = true;
+  String? _error;
+
+  @override
+  void initState() {
+    super.initState();
+    _load();
+  }
+
+  Future<void> _load() async {
+    setState(() {
+      _loading = true;
+      _error = null;
+    });
+    try {
+      final db = await widget.databaseHelper.database;
+      final counts = <String, int>{};
+      for (final row in _rowTables) {
+        final result = await db.rawQuery(
+          'SELECT COUNT(*) AS c FROM ${row.table}',
+        );
+        counts[row.label] =
+            (result.first['c'] as int?) ??
+            int.tryParse('${result.first['c']}') ??
+            0;
+      }
+
+      int? dbBytes;
+      if (!kIsWeb) {
+        try {
+          final file = File(await DatabaseHelper.databaseFilePath);
+          if (await file.exists()) dbBytes = await file.length();
+        } catch (_) {
+          dbBytes = null;
+        }
+      }
+
+      if (!mounted) return;
+      setState(() {
+        _counts = counts;
+        _dbBytes = dbBytes;
+        _cacheBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
+        _loading = false;
+      });
+    } catch (e) {
+      if (!mounted) return;
+      setState(() {
+        _loading = false;
+        _error = 'Could not read storage information: $e';
+      });
+    }
+  }
+
+  Future<void> _clearCache() async {
+    final imageCache = PaintingBinding.instance.imageCache;
+    imageCache.clear();
+    if (!mounted) return;
+    setState(() => _cacheBytes = imageCache.currentSizeBytes);
+    ScaffoldMessenger.of(context).showSnackBar(
+      SnackBar(
+        content: const Text('Image cache cleared.'),
+        backgroundColor: CreditBillColors.successGreen,
+        behavior: SnackBarBehavior.floating,
+        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
+      ),
+    );
+  }
+
+  static String _formatBytes(int bytes) {
+    if (bytes < 1024) return '$bytes B';
+    if (bytes < 1024 * 1024) {
+      return '${(bytes / 1024).toStringAsFixed(1)} KB';
+    }
+    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text('Storage & Data'),
+        backgroundColor: CreditBillColors.primaryBlue,
+        foregroundColor: CreditBillColors.white,
+      ),
+      body: CreditBillBackground(
+        child: _loading
+            ? const Center(child: CircularProgressIndicator())
+            : _error != null
+            ? Center(
+                child: Padding(
+                  padding: const EdgeInsets.all(24),
+                  child: Column(
+                    mainAxisSize: MainAxisSize.min,
+                    children: [
+                      Text(
+                        _error!,
+                        textAlign: TextAlign.center,
+                        style: CreditBillTextTheme.screenSubheading,
+                      ),
+                      const SizedBox(height: 12),
+                      TextButton(onPressed: _load, child: const Text('Retry')),
+                    ],
+                  ),
+                ),
+              )
+            : ListView(
+                padding: const EdgeInsets.all(16),
+                children: [
+                  Text(
+                    'Everything below is read directly from this device.',
+                    style: CreditBillTextTheme.screenSubheading,
+                  ),
+                  const SizedBox(height: 16),
+                  const SettingsSectionHeader(title: 'Record counts'),
+                  Container(
+                    padding: const EdgeInsets.all(14),
+                    decoration: BoxDecoration(
+                      color: CreditBillColors.white,
+                      borderRadius: BorderRadius.circular(12),
+                      boxShadow: [
+                        BoxShadow(
+                          color: CreditBillColors.deepBlue.withValues(
+                            alpha: 0.08,
+                          ),
+                          blurRadius: 6,
+                          offset: const Offset(0, 3),
+                        ),
+                      ],
+                    ),
+                    child: Column(
+                      children: [
+                        for (final entry in _counts.entries)
+                          Padding(
+                            padding: const EdgeInsets.symmetric(vertical: 6),
+                            child: Row(
+                              children: [
+                                Expanded(
+                                  child: Text(
+                                    entry.key,
+                                    style: CreditBillTextTheme.inputLabel,
+                                  ),
+                                ),
+                                Text(
+                                  '${entry.value}',
+                                  style: CreditBillTextTheme.sectionLabel
+                                      .copyWith(
+                                        color: CreditBillColors.textDark,
+                                      ),
+                                ),
+                              ],
+                            ),
+                          ),
+                      ],
+                    ),
+                  ),
+                  const SizedBox(height: 16),
+                  const SettingsSectionHeader(title: 'Usage'),
+                  Container(
+                    padding: const EdgeInsets.all(14),
+                    decoration: BoxDecoration(
+                      color: CreditBillColors.white,
+                      borderRadius: BorderRadius.circular(12),
+                      boxShadow: [
+                        BoxShadow(
+                          color: CreditBillColors.deepBlue.withValues(
+                            alpha: 0.08,
+                          ),
+                          blurRadius: 6,
+                          offset: const Offset(0, 3),
+                        ),
+                      ],
+                    ),
+                    child: Column(
+                      children: [
+                        _usageRow(
+                          'Database file',
+                          kIsWeb
+                              ? 'Not available on the web'
+                              : _dbBytes == null
+                              ? 'Not created yet'
+                              : _formatBytes(_dbBytes!),
+                        ),
+                        _usageRow('Image cache', _formatBytes(_cacheBytes)),
+                      ],
+                    ),
+                  ),
+                  const SizedBox(height: 20),
+                  CreditBillPrimaryButton(
+                    key: const Key('clearCacheButton'),
+                    text: 'Clear image cache',
+                    onPressed: _clearCache,
+                  ),
+                  const SizedBox(height: 10),
+                  Text(
+                    'Clearing the cache frees temporary images (photos re-load '
+                    'on demand). Your records are never touched.',
+                    style: CreditBillTextTheme.inputLabel.copyWith(height: 1.5),
+                  ),
+                ],
+              ),
+      ),
+    );
+  }
+
+  Widget _usageRow(String label, String value) {
+    return Padding(
+      padding: const EdgeInsets.symmetric(vertical: 6),
+      child: Row(
+        children: [
+          Expanded(child: Text(label, style: CreditBillTextTheme.inputLabel)),
+          Text(
+            value,
+            style: CreditBillTextTheme.sectionLabel.copyWith(
+              color: CreditBillColors.textDark,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
diff --git a/lib/features/settings/presentation/pages/theme_settings_page.dart b/lib/features/settings/presentation/pages/theme_settings_page.dart
new file mode 100644
index 0000000..8fff31c
--- /dev/null
+++ b/lib/features/settings/presentation/pages/theme_settings_page.dart
@@ -0,0 +1,104 @@
+import 'package:flutter/material.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+import '../../../../core/theme/theme_controller.dart';
+import '../../../../core/theme/widgets/credit_bill_background.dart';
+import '../widgets/settings_option_tile.dart';
+import '../widgets/settings_section_header.dart';
+
+/// Theme & Appearance: pick System / Light / Dark.
+///
+/// The selection applies to the whole app on the same frame (the page and
+/// `MaterialApp` both listen to [ThemeController]; Material eases the
+/// switch with its built-in [AnimatedTheme]) and is persisted by the
+/// controller so it survives an app restart.
+class ThemeSettingsPage extends StatelessWidget {
+  const ThemeSettingsPage({super.key});
+
+  @override
+  Widget build(BuildContext context) {
+    // Reading the controller here subscribes this page to mode changes.
+    final controller = ThemeScope.of(context);
+    final mode = controller.mode;
+
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text('Theme & Appearance'),
+        backgroundColor: CreditBillColors.primaryBlue,
+        foregroundColor: CreditBillColors.white,
+      ),
+      body: CreditBillBackground(
+        child: ListView(
+          padding: const EdgeInsets.all(16),
+          children: [
+            Text(
+              'Choose how CreditBill looks. The selection applies to every '
+              'screen and is saved on this device.',
+              style: CreditBillTextTheme.screenSubheading,
+            ),
+            const SizedBox(height: 16),
+            const SettingsSectionHeader(title: 'Appearance'),
+            SettingsOptionTile(
+              key: const Key('themeSystemOption'),
+              icon: Icons.brightness_auto_outlined,
+              title: 'System default',
+              subtitle: 'Match your device light/dark setting',
+              selected: mode == ThemeMode.system,
+              onTap: () => controller.setMode(ThemeMode.system),
+            ),
+            SettingsOptionTile(
+              key: const Key('themeLightOption'),
+              icon: Icons.light_mode_outlined,
+              title: 'Light',
+              subtitle: 'Always use the light theme',
+              selected: mode == ThemeMode.light,
+              onTap: () => controller.setMode(ThemeMode.light),
+            ),
+            SettingsOptionTile(
+              key: const Key('themeDarkOption'),
+              icon: Icons.dark_mode_outlined,
+              title: 'Dark',
+              subtitle: 'Always use the dark theme',
+              selected: mode == ThemeMode.dark,
+              onTap: () => controller.setMode(ThemeMode.dark),
+            ),
+            const SizedBox(height: 8),
+            Container(
+              padding: const EdgeInsets.all(14),
+              decoration: BoxDecoration(
+                color: CreditBillColors.white,
+                borderRadius: BorderRadius.circular(12),
+                boxShadow: [
+                  BoxShadow(
+                    color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+                    blurRadius: 6,
+                    offset: const Offset(0, 3),
+                  ),
+                ],
+              ),
+              child: Row(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  const Icon(
+                    Icons.palette_outlined,
+                    size: 18,
+                    color: CreditBillColors.primaryBlue,
+                  ),
+                  const SizedBox(width: 8),
+                  Expanded(
+                    child: Text(
+                      'Theme changes apply instantly across the app and are '
+                      'kept for your next launch.',
+                      style: CreditBillTextTheme.inputLabel,
+                    ),
+                  ),
+                ],
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
diff --git a/lib/features/settings/presentation/widgets/settings_option_tile.dart b/lib/features/settings/presentation/widgets/settings_option_tile.dart
new file mode 100644
index 0000000..783b339
--- /dev/null
+++ b/lib/features/settings/presentation/widgets/settings_option_tile.dart
@@ -0,0 +1,104 @@
+import 'package:flutter/material.dart';
+
+import '../../../../core/theme/credit_bill_colors.dart';
+import '../../../../core/theme/credit_bill_theme.dart';
+
+/// A selectable settings row (white card + leading icon + trailing check)
+/// used by the theme picker.
+///
+/// [selected] draws the accent border/check mark and is announced to
+/// accessibility services through the semantics `selected` flag.
+class SettingsOptionTile extends StatelessWidget {
+  final IconData icon;
+  final String title;
+  final String? subtitle;
+  final bool selected;
+  final VoidCallback? onTap;
+
+  const SettingsOptionTile({
+    super.key,
+    required this.icon,
+    required this.title,
+    this.subtitle,
+    this.selected = false,
+    this.onTap,
+  });
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 10),
+      child: Semantics(
+        selected: selected,
+        button: true,
+        child: InkWell(
+          onTap: onTap,
+          borderRadius: BorderRadius.circular(12),
+          child: Container(
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
+            decoration: BoxDecoration(
+              color: CreditBillColors.white,
+              borderRadius: BorderRadius.circular(12),
+              border: Border.all(
+                color: selected
+                    ? CreditBillColors.primaryBlue
+                    : Colors.transparent,
+                width: 1.5,
+              ),
+              boxShadow: [
+                BoxShadow(
+                  color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
+                  blurRadius: 6,
+                  offset: const Offset(0, 3),
+                ),
+              ],
+            ),
+            child: Row(
+              children: [
+                Container(
+                  padding: const EdgeInsets.all(8),
+                  decoration: BoxDecoration(
+                    color: CreditBillColors.primaryBlue.withValues(alpha: 0.12),
+                    shape: BoxShape.circle,
+                  ),
+                  child: Icon(
+                    icon,
+                    size: 20,
+                    color: CreditBillColors.primaryBlue,
+                  ),
+                ),
+                const SizedBox(width: 12),
+                Expanded(
+                  child: Column(
+                    crossAxisAlignment: CrossAxisAlignment.start,
+                    children: [
+                      Text(title, style: CreditBillTextTheme.sectionLabel),
+                      if (subtitle != null && subtitle!.isNotEmpty) ...[
+                        const SizedBox(height: 2),
+                        Text(
+                          subtitle!,
+                          maxLines: 1,
+                          overflow: TextOverflow.ellipsis,
+                          style: CreditBillTextTheme.inputLabel,
+                        ),
+                      ],
+                    ],
+                  ),
+                ),
+                AnimatedOpacity(
+                  opacity: selected ? 1 : 0,
+                  duration: const Duration(milliseconds: 150),
+                  child: const Icon(
+                    Icons.check_circle,
+                    size: 22,
+                    color: CreditBillColors.primaryBlue,
+                  ),
+                ),
+              ],
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/test/core/theme/theme_controller_test.dart b/test/core/theme/theme_controller_test.dart
new file mode 100644
index 0000000..c2d2350
--- /dev/null
+++ b/test/core/theme/theme_controller_test.dart
@@ -0,0 +1,68 @@
+import 'package:credit_bill_system/core/services/preferences_store.dart';
+import 'package:credit_bill_system/core/theme/theme_controller.dart';
+import 'package:flutter/material.dart' show ThemeMode;
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mocktail/mocktail.dart';
+
+class MockPreferencesStore extends Mock implements PreferencesStore {}
+
+void main() {
+  late MockPreferencesStore store;
+
+  setUp(() {
+    store = MockPreferencesStore();
+  });
+
+  test('defaults to system before anything is stored', () async {
+    when(
+      () => store.loadThemeMode(),
+    ).thenAnswer((_) async => ThemeMode.system);
+    final controller = ThemeController(store: store);
+    addTearDown(controller.dispose);
+
+    expect(controller.mode, ThemeMode.system);
+    await controller.load();
+    expect(controller.mode, ThemeMode.system);
+  });
+
+  test('load() applies the persisted mode and notifies listeners', () async {
+    when(() => store.loadThemeMode()).thenAnswer((_) async => ThemeMode.dark);
+    final controller = ThemeController(store: store);
+    addTearDown(controller.dispose);
+    var notified = false;
+    controller.addListener(() => notified = true);
+
+    await controller.load();
+
+    expect(controller.mode, ThemeMode.dark);
+    expect(notified, isTrue);
+  });
+
+  test('setMode notifies listeners, then persists the choice', () async {
+    when(
+      () => store.saveThemeMode(ThemeMode.light),
+    ).thenAnswer((_) async {});
+    final controller = ThemeController(store: store);
+    addTearDown(controller.dispose);
+    var notified = false;
+    controller.addListener(() => notified = true);
+
+    await controller.setMode(ThemeMode.light);
+
+    expect(controller.mode, ThemeMode.light);
+    expect(notified, isTrue);
+    verify(() => store.saveThemeMode(ThemeMode.light)).called(1);
+  });
+
+  test('setMode is a no-op when the mode is unchanged', () async {
+    final controller = ThemeController(store: store);
+    addTearDown(controller.dispose);
+    var notified = false;
+    controller.addListener(() => notified = true);
+
+    await controller.setMode(ThemeMode.system);
+
+    expect(notified, isFalse);
+    verifyZeroInteractions(store);
+  });
+}
diff --git a/test/features/auth/change_password_usecase_test.dart b/test/features/auth/change_password_usecase_test.dart
new file mode 100644
index 0000000..0ac3e1e
--- /dev/null
+++ b/test/features/auth/change_password_usecase_test.dart
@@ -0,0 +1,159 @@
+import 'package:credit_bill_system/core/errors/either.dart';
+import 'package:credit_bill_system/core/errors/failures.dart';
+import 'package:credit_bill_system/core/utils/password_hasher.dart';
+import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
+import 'package:credit_bill_system/features/auth/domain/repositories/user_repository.dart';
+import 'package:credit_bill_system/features/auth/domain/usecases/auth_usecases.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mocktail/mocktail.dart';
+
+class MockUserRepository extends Mock implements UserRepository {}
+
+void main() {
+  late MockUserRepository repository;
+  late ChangePasswordUseCase useCase;
+
+  setUp(() {
+    repository = MockUserRepository();
+    useCase = ChangePasswordUseCase(repository: repository);
+  });
+
+  UserEntity userWith({String password = 'OldSecret1'}) => UserEntity(
+    id: 'user-0001',
+    email: 'ada@example.com',
+    fullName: 'Ada Lovelace',
+    passwordHash: PasswordHasher.hash(password),
+    createdAt: DateTime(2026, 1, 15),
+    isEmailVerified: true,
+  );
+
+  UserEntity legacyUserWith({String password = 'OldSecret1'}) =>
+      UserEntity(
+        id: 'user-0002',
+        email: 'grace@example.com',
+        fullName: 'Grace Hopper',
+        passwordHash: PasswordHasher.legacyHash(password),
+        createdAt: DateTime(2026, 1, 15),
+        isEmailVerified: true,
+      );
+
+  test('rejects an empty current password without touching the repository', () async {
+    final result = await useCase.execute(
+      email: 'ada@example.com',
+      currentPassword: '',
+      newPassword: 'BrandNew1',
+    );
+
+    expect(result.isLeft, isTrue);
+    expect(result.leftOrNull!.message, 'Enter your current password.');
+    verifyZeroInteractions(repository);
+  });
+
+  test('rejects a new password shorter than six characters', () async {
+    final result = await useCase.execute(
+      email: 'ada@example.com',
+      currentPassword: 'OldSecret1',
+      newPassword: 'abc',
+    );
+
+    expect(result.isLeft, isTrue);
+    expect(
+      result.leftOrNull!.message,
+      'Password must be at least 6 characters.',
+    );
+    verifyZeroInteractions(repository);
+  });
+
+  test('rejects reusing the current password as the new one', () async {
+    final result = await useCase.execute(
+      email: 'ada@example.com',
+      currentPassword: 'OldSecret1',
+      newPassword: 'OldSecret1',
+    );
+
+    expect(result.isLeft, isTrue);
+    expect(
+      result.leftOrNull!.message,
+      'New password must be different from your current password.',
+    );
+    verifyZeroInteractions(repository);
+  });
+
+  test('rejects a wrong current password against the stored bcrypt hash', () async {
+    when(
+      () => repository.findUserByEmail('ada@example.com'),
+    ).thenAnswer((_) async => Right<Failure, UserEntity?>(userWith()));
+
+    final result = await useCase.execute(
+      email: 'ada@example.com',
+      currentPassword: 'WrongPass1',
+      newPassword: 'BrandNew1',
+    );
+
+    expect(result.isLeft, isTrue);
+    expect(result.leftOrNull!.message, 'Current password is incorrect.');
+    verify(() => repository.findUserByEmail('ada@example.com')).called(1);
+    verifyNever(() => repository.resetPassword(any(), any()));
+  });
+
+  test('verifies a legacy FNV-1a hash so pre-bcrypt accounts can change', () async {
+    when(
+      () => repository.findUserByEmail('grace@example.com'),
+    ).thenAnswer((_) async => Right<Failure, UserEntity?>(legacyUserWith()));
+    when(
+      () => repository.resetPassword('grace@example.com', 'BrandNew1'),
+    ).thenAnswer((_) async => Right<Failure, UserEntity>(legacyUserWith()));
+
+    final result = await useCase.execute(
+      email: 'grace@example.com',
+      currentPassword: 'OldSecret1',
+      newPassword: 'BrandNew1',
+    );
+
+    expect(result.isRight, isTrue);
+    verify(
+      () => repository.resetPassword('grace@example.com', 'BrandNew1'),
+    ).called(1);
+  });
+
+  test('reports a missing account instead of attempting a write', () async {
+    when(
+      () => repository.findUserByEmail('nobody@example.com'),
+    ).thenAnswer((_) async => const Right<Failure, UserEntity?>(null));
+
+    final result = await useCase.execute(
+      email: 'nobody@example.com',
+      currentPassword: 'OldSecret1',
+      newPassword: 'BrandNew1',
+    );
+
+    expect(result.isLeft, isTrue);
+    expect(result.leftOrNull!.message, 'No account found with this email.');
+    verifyNever(() => repository.resetPassword(any(), any()));
+  });
+
+  test('a verified current password writes the bcrypt re-hash', () async {
+    when(
+      () => repository.findUserByEmail('ada@example.com'),
+    ).thenAnswer((_) async => Right<Failure, UserEntity?>(userWith()));
+    when(
+      () => repository.resetPassword('ada@example.com', 'BrandNew1'),
+    ).thenAnswer((_) async => Right<Failure, UserEntity>(userWith()));
+
+    final result = await useCase.execute(
+      email: 'ada@example.com',
+      currentPassword: 'OldSecret1',
+      newPassword: 'BrandNew1',
+    );
+
+    expect(result.isRight, isTrue);
+    verify(
+      () => repository.resetPassword('ada@example.com', 'BrandNew1'),
+    ).called(1);
+    // The repository path hashes with bcrypt â€” the plain new password
+    // never reaches persistence.
+    verifyNever(
+      () => repository.resetPassword('ada@example.com', 'BrandNew1Plain'),
+    );
+  });
+}
diff --git a/test/features/settings/presentation/help_about_page_test.dart b/test/features/settings/presentation/help_about_page_test.dart
new file mode 100644
index 0000000..5ac6ebd
--- /dev/null
+++ b/test/features/settings/presentation/help_about_page_test.dart
@@ -0,0 +1,97 @@
+import 'dart:io';
+
+import 'package:credit_bill_system/features/settings/presentation/pages/about_page.dart';
+import 'package:credit_bill_system/features/settings/presentation/pages/help_support_page.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+
+import '../settings_test_harness.dart';
+
+void main() {
+  testWidgets('FAQ answers are revealed by tapping their question', (
+    tester,
+  ) async {
+    await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));
+    await tester.pumpAndSettle();
+
+    const answerNeedle = 'Everything stays on this device in the app';
+    // Collapsed: the answer is not in the tree.
+    expect(find.textContaining(answerNeedle), findsNothing);
+
+    // The list is lazy â€” bring each question into view before tapping it.
+    await tester.scrollUntilVisible(
+      find.text('How do statement bills work?'),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(find.text('How do statement bills work?'));
+    await tester.pumpAndSettle();
+    expect(
+      find.textContaining('countdown badge until the due date'),
+      findsOneWidget,
+    );
+
+    await tester.scrollUntilVisible(
+      find.text('Where is my data stored?'),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(find.text('Where is my data stored?'));
+    await tester.pumpAndSettle();
+    expect(find.textContaining(answerNeedle), findsOneWidget);
+  });
+
+  testWidgets('About shows the real bundled version and opens licenses', (
+    tester,
+  ) async {
+    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
+
+    // The version comes from the bundled pubspec.yaml asset â€” a real
+    // platform-channel/file read that only progresses on the real event
+    // loop, while setState can only build on a pump. Alternate real-loop
+    // turns with frame pumps: bounded, and it fails loudly if the
+    // version never resolves.
+    var resolved = false;
+    for (var i = 0; i < 200; i++) {
+      await tester.runAsync(
+        () => Future<void>.delayed(const Duration(milliseconds: 5)),
+      );
+      await tester.pump(const Duration(milliseconds: 25));
+      if (!tester.any(find.textContaining('Loadingâ€¦'))) {
+        resolved = true;
+        break;
+      }
+    }
+    if (!resolved) {
+      throw StateError('About page never resolved the bundled version');
+    }
+    await tester.pumpAndSettle();
+
+    // Expected value parsed from the same file the app bundles â€” the
+    // screen must not drift from the actual build version.
+    final pubspec = File('pubspec.yaml').readAsStringSync();
+    final version = RegExp(
+      r'^version:[ \t]*(\S+)',
+      multiLine: true,
+    ).firstMatch(pubspec)!.group(1)!;
+    final parts = version.split('+');
+    final expected = parts.length > 1
+        ? '${parts[0]} (build ${parts[1]})'
+        : version;
+    expect(find.text('Version $expected'), findsOneWidget);
+
+    // Lazy list: the legal section sits below the fold.
+    await tester.scrollUntilVisible(
+      find.byKey(const Key('openLicensesButton')),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(const Key('openLicensesButton')));
+    await tester.pump(); // begin the route transition
+    await tester.pump(const Duration(milliseconds: 400)); // complete it
+    expect(find.byType(LicensePage), findsOneWidget);
+  });
+}
diff --git a/test/features/settings/presentation/security_privacy_page_test.dart b/test/features/settings/presentation/security_privacy_page_test.dart
new file mode 100644
index 0000000..61e3b0a
--- /dev/null
+++ b/test/features/settings/presentation/security_privacy_page_test.dart
@@ -0,0 +1,218 @@
+import 'package:credit_bill_system/core/errors/either.dart';
+import 'package:credit_bill_system/core/errors/failures.dart';
+import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
+import 'package:credit_bill_system/features/auth/presentation/bloc/auth_bloc.dart';
+import 'package:credit_bill_system/features/settings/presentation/pages/security_privacy_page.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_bloc/flutter_bloc.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mocktail/mocktail.dart';
+
+import '../settings_test_harness.dart';
+
+void main() {
+  late AuthBloc bloc;
+  late MockChangePasswordUseCase changePassword;
+
+  Future<void> pumpSecurity(WidgetTester tester) async {
+    await tester.pumpWidget(
+      BlocProvider<AuthBloc>.value(
+        value: bloc,
+        child: MaterialApp(
+          home: SecurityPrivacyPage(changePasswordUseCase: changePassword),
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+  }
+
+  Future<void> fillAndSubmit(
+    WidgetTester tester, {
+    required String current,
+    required String next,
+    required String confirm,
+  }) async {
+    await tester.enterText(
+      find.byKey(const Key('changeCurrentPasswordField')),
+      current,
+    );
+    await tester.enterText(
+      find.byKey(const Key('changeNewPasswordField')),
+      next,
+    );
+    await tester.enterText(
+      find.byKey(const Key('changeConfirmPasswordField')),
+      confirm,
+    );
+    await tester.pump();
+    await tester.tap(find.byKey(const Key('changePasswordButton')));
+    await tester.pumpAndSettle();
+  }
+
+  /// SnackBars arm a 4-second dismiss timer; advance past it so the test
+  /// never ends with a pending timer.
+  Future<void> flushSnackBar(WidgetTester tester) async {
+    await tester.pump(const Duration(seconds: 5));
+    await tester.pumpAndSettle();
+  }
+
+  setUp(() async {
+    final auth = await signedInAuthBloc(sampleUser());
+    bloc = auth.bloc;
+    addTearDown(bloc.close);
+    changePassword = MockChangePasswordUseCase();
+  });
+
+  testWidgets('validates the form before calling the use case', (
+    tester,
+  ) async {
+    await pumpSecurity(tester);
+
+    await tester.tap(find.byKey(const Key('changePasswordButton')));
+    await tester.pumpAndSettle();
+
+    expect(find.text('Enter your current password.'), findsOneWidget);
+    expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
+    verifyZeroInteractions(changePassword);
+  });
+
+  testWidgets('mismatched confirmation is caught inline', (tester) async {
+    await pumpSecurity(tester);
+    await fillAndSubmit(
+      tester,
+      current: 'OldSecret1',
+      next: 'NewSecret1',
+      confirm: 'Different1',
+    );
+
+    expect(find.text('Passwords do not match.'), findsOneWidget);
+    verifyZeroInteractions(changePassword);
+  });
+
+  testWidgets('a rejected change surfaces the error and keeps the inputs', (
+    tester,
+  ) async {
+    when(
+      () => changePassword.execute(
+        email: 'ada@example.com',
+        currentPassword: 'WrongOld1',
+        newPassword: 'BrandNew1',
+      ),
+    ).thenAnswer(
+      (_) async => Left<Failure, UserEntity>(
+        const ValidationFailure('Current password is incorrect.'),
+      ),
+    );
+
+    await pumpSecurity(tester);
+    await fillAndSubmit(
+      tester,
+      current: 'WrongOld1',
+      next: 'BrandNew1',
+      confirm: 'BrandNew1',
+    );
+
+    // Shown both inline and as the red SnackBar â€” and nothing was cleared.
+    expect(find.text('Current password is incorrect.'), findsWidgets);
+    expect(find.text('WrongOld1'), findsOneWidget);
+    verify(
+      () => changePassword.execute(
+        email: 'ada@example.com',
+        currentPassword: 'WrongOld1',
+        newPassword: 'BrandNew1',
+      ),
+    ).called(1);
+    await flushSnackBar(tester);
+  });
+
+  testWidgets('a successful change clears the form and confirms', (
+    tester,
+  ) async {
+    when(
+      () => changePassword.execute(
+        email: 'ada@example.com',
+        currentPassword: 'OldSecret1',
+        newPassword: 'NewSecret1',
+      ),
+    ).thenAnswer((_) async => Right<Failure, UserEntity>(sampleUser()));
+
+    await pumpSecurity(tester);
+    await fillAndSubmit(
+      tester,
+      current: 'OldSecret1',
+      next: 'NewSecret1',
+      confirm: 'NewSecret1',
+    );
+
+    expect(find.text('Password changed successfully.'), findsOneWidget);
+    expect(find.text('OldSecret1'), findsNothing);
+    expect(find.text('NewSecret1'), findsNothing);
+    verify(
+      () => changePassword.execute(
+        email: 'ada@example.com',
+        currentPassword: 'OldSecret1',
+        newPassword: 'NewSecret1',
+      ),
+    ).called(1);
+    await flushSnackBar(tester);
+  });
+
+  testWidgets('sign out confirms, clears the session and logs the bloc out', (
+    tester,
+  ) async {
+    await pumpSecurity(tester);
+
+    // The sign-out row sits below the fold in the lazy list.
+    await tester.scrollUntilVisible(
+      find.byKey(const Key('signOutTile')),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(const Key('signOutTile')));
+    await tester.pumpAndSettle();
+    expect(find.text('Sign out?'), findsOneWidget);
+
+    await tester.tap(find.byKey(const Key('signOutConfirmButton')));
+    await tester.pumpAndSettle();
+
+    // The logout handler awaits real session-file I/O on the real event
+    // loop, which plain pumps never turn â€” wait for the actual state with
+    // a bounded timeout instead of a fixed delay.
+    await tester.runAsync(() async {
+      if (bloc.state is! AuthUnauthenticatedState) {
+        await bloc.stream
+            .firstWhere((state) => state is AuthUnauthenticatedState)
+            .timeout(
+              const Duration(seconds: 5),
+              onTimeout: () => throw StateError(
+                'AuthBloc never emitted AuthUnauthenticatedState',
+              ),
+            );
+      }
+    });
+    await tester.pumpAndSettle();
+    expect(bloc.state, isA<AuthUnauthenticatedState>());
+  });
+
+  testWidgets('cancelling the sign-out confirmation signs nothing out', (
+    tester,
+  ) async {
+    await pumpSecurity(tester);
+
+    // The sign-out row sits below the fold in the lazy list.
+    await tester.scrollUntilVisible(
+      find.byKey(const Key('signOutTile')),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(const Key('signOutTile')));
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(const Key('signOutCancelButton')));
+    await tester.pumpAndSettle();
+
+    expect(find.text('Sign out?'), findsNothing);
+    expect(bloc.state, isA<AuthAuthenticatedState>());
+  });
+}
diff --git a/test/features/settings/presentation/storage_data_page_test.dart b/test/features/settings/presentation/storage_data_page_test.dart
new file mode 100644
index 0000000..1f2b0e1
--- /dev/null
+++ b/test/features/settings/presentation/storage_data_page_test.dart
@@ -0,0 +1,111 @@
+import 'package:credit_bill_system/core/database/database_helper.dart';
+import 'package:credit_bill_system/features/settings/presentation/pages/storage_data_page.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:path/path.dart' as p;
+import 'package:sqflite_common_ffi/sqflite_ffi.dart';
+
+import '../settings_test_harness.dart';
+
+void main() {
+  late DatabaseHelper databaseHelper;
+
+  setUpAll(() {
+    sqfliteFfiInit();
+    databaseFactory = databaseFactoryFfi;
+    databaseHelper = DatabaseHelper();
+  });
+
+  setUp(() async {
+    await databaseHelper.close();
+    final databasePath = p.join(
+      await getDatabasesPath(),
+      'credit_bill_system.db',
+    );
+    await deleteDatabase(databasePath);
+  });
+
+  tearDownAll(() async {
+    await databaseHelper.close();
+  });
+
+  /// Pumps the page and waits for its real device I/O to finish. The load
+  /// mixes database/file futures, which only progress on the real event
+  /// loop, with frame builds, which only happen on a pump â€” so alternate
+  /// real-loop turns and pumps. Bounded, and it fails loudly if the
+  /// spinner never clears.
+  Future<void> pumpStorage(WidgetTester tester) async {
+    await tester.pumpWidget(
+      MaterialApp(home: StorageDataPage(databaseHelper: databaseHelper)),
+    );
+    var loaded = false;
+    for (var i = 0; i < 200; i++) {
+      await tester.runAsync(
+        () => Future<void>.delayed(const Duration(milliseconds: 5)),
+      );
+      await tester.pump(const Duration(milliseconds: 25));
+      if (!tester.any(find.byType(CircularProgressIndicator))) {
+        loaded = true;
+        break;
+      }
+    }
+    if (!loaded) {
+      throw StateError('StorageDataPage never finished loading its figures');
+    }
+    await tester.pumpAndSettle();
+  }
+
+  testWidgets('shows real record counts and usage figures from the device', (
+    tester,
+  ) async {
+    await pumpStorage(tester);
+
+    // Record counts come from COUNT queries over the existing tables â€”
+    // a freshly created database really has zero rows everywhere.
+    expect(find.text('Record counts'), findsOneWidget);
+    for (final label in [
+      'Customers',
+      'Credit transactions',
+      'Payments',
+      'Cards',
+      'Statement bills',
+    ]) {
+      expect(find.text(label), findsOneWidget);
+    }
+    expect(find.text('0'), findsNWidgets(5));
+
+    // Usage figures are read from the file system / image cache.
+    expect(find.text('Usage'), findsOneWidget);
+    expect(find.text('Database file'), findsOneWidget);
+    expect(find.text('Image cache'), findsOneWidget);
+
+    // Lazy list: bring the clear action into view before asserting on it.
+    await tester.scrollUntilVisible(
+      find.byKey(const Key('clearCacheButton')),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    expect(find.byKey(const Key('clearCacheButton')), findsOneWidget);
+  });
+
+  testWidgets('clearing the image cache is a real, confirmed action', (
+    tester,
+  ) async {
+    await pumpStorage(tester);
+
+    await tester.scrollUntilVisible(
+      find.byKey(const Key('clearCacheButton')),
+      200,
+      scrollable: pageScrollable,
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(find.byKey(const Key('clearCacheButton')));
+    await tester.pumpAndSettle();
+
+    expect(find.text('Image cache cleared.'), findsOneWidget);
+    // SnackBar dismiss timer: advance past it so no timer leaks.
+    await tester.pump(const Duration(seconds: 5));
+    await tester.pumpAndSettle();
+  });
+}
diff --git a/test/features/settings/presentation/theme_settings_page_test.dart b/test/features/settings/presentation/theme_settings_page_test.dart
new file mode 100644
index 0000000..0288d0e
--- /dev/null
+++ b/test/features/settings/presentation/theme_settings_page_test.dart
@@ -0,0 +1,87 @@
+import 'package:credit_bill_system/core/theme/theme_controller.dart';
+import 'package:credit_bill_system/features/settings/presentation/pages/theme_settings_page.dart';
+import 'package:credit_bill_system/features/settings/presentation/widgets/settings_option_tile.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+
+import '../settings_test_harness.dart';
+
+void main() {
+  late FakePreferencesStore prefs;
+  late ThemeController controller;
+
+  bool isSelected(WidgetTester tester, String key) =>
+      tester
+          .widget<SettingsOptionTile>(find.byKey(Key(key)))
+          .selected;
+
+  Future<void> pumpTheme(WidgetTester tester) async {
+    await tester.pumpWidget(
+      ThemeScope(
+        controller: controller,
+        child: const MaterialApp(home: ThemeSettingsPage()),
+      ),
+    );
+    await tester.pumpAndSettle();
+  }
+
+  setUp(() async {
+    prefs = FakePreferencesStore();
+    controller = ThemeController(store: prefs);
+    await controller.load();
+    addTearDown(controller.dispose);
+  });
+
+  testWidgets('system default is the fallback and is shown as selected', (
+    tester,
+  ) async {
+    await pumpTheme(tester);
+
+    expect(find.byType(SettingsOptionTile), findsNWidgets(3));
+    expect(isSelected(tester, 'themeSystemOption'), isTrue);
+    expect(isSelected(tester, 'themeLightOption'), isFalse);
+    expect(isSelected(tester, 'themeDarkOption'), isFalse);
+
+    // Re-selecting the current mode is a no-op: no notification, no write.
+    await tester.tap(find.byKey(const Key('themeSystemOption')));
+    await tester.pumpAndSettle();
+    expect(prefs.savedMode, isNull);
+    expect(isSelected(tester, 'themeSystemOption'), isTrue);
+  });
+
+  testWidgets('a stored dark mode opens as selected and switching persists', (
+    tester,
+  ) async {
+    controller = ThemeController(store: prefs, initialMode: ThemeMode.dark);
+    await pumpTheme(tester);
+
+    expect(isSelected(tester, 'themeDarkOption'), isTrue);
+    expect(isSelected(tester, 'themeSystemOption'), isFalse);
+
+    await tester.tap(find.byKey(const Key('themeLightOption')));
+    await tester.pumpAndSettle();
+
+    expect(controller.mode, ThemeMode.light);
+    expect(prefs.savedMode, ThemeMode.light);
+    expect(isSelected(tester, 'themeLightOption'), isTrue);
+    expect(isSelected(tester, 'themeDarkOption'), isFalse);
+  });
+
+  testWidgets('every option announces itself as a selectable control', (
+    tester,
+  ) async {
+    await pumpTheme(tester);
+
+    for (final key in [
+      'themeSystemOption',
+      'themeLightOption',
+      'themeDarkOption',
+    ]) {
+      expect(find.byKey(Key(key)), findsOneWidget);
+      expect(
+        tester.widget<SettingsOptionTile>(find.byKey(Key(key))).onTap,
+        isNotNull,
+      );
+    }
+  });
+}


Do not invoke any skill, and do not spawn subagents of your own — you are the reviewer. If the instruction file is unreadable, report that exact failure and stop. Return your findings as text in your final message; do not route them through any findings-reporting tool the host may offer.
