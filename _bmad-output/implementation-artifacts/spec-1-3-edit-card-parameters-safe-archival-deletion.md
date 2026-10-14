---
title: 'Story 1.3: Edit Card Parameters & Safe Archival/Deletion'
type: 'feature'
created: '2026-10-14'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: '9748bbd168d45ff863160627ffcba7e6b8cb6169'
context:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-WALKTHROUGH.md'
  - '_bmad-output/planning-artifacts/prds/prd-credit_bill_system-2026-10-13/prd.md'
  - '_bmad-output/implementation-artifacts/spec-1-2-custom-card-visual-styling-bank-gradient-themes.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Users cannot update saved card terms or remove closed accounts from their active wallet. The card model already stores an archive flag and selected gradient, but there are no edit, archive, or delete flows.

**Approach:** Add an offline-first card-management flow to edit credit limit, billing/due days, and the saved predefined gradient; allow archiving and confirmed permanent deletion, with state and persistence handled through the existing Clean Architecture boundaries.

## Boundaries & Constraints

**Always:**
- Preserve offline-first behavior, Feature-First Clean Architecture, and Story 1.1/1.2 behavior and tests.
- Persist edits through domain/use-case/repository/data-source boundaries; presentation must not access SQLite.
- Keep the existing gradient palette and stable `color_gradient_idx` meanings; do not add custom themes or reorder presets.
- Preserve card privacy: never collect or persist CVV, expiration date, or full card number.
- **Archive policy and AD-2 exception:** set `is_archived = 1` only; retain the card and linked history; exclude it from active-card results/flows; no archive list or restore action. Following Epic 1.3 and PRD FR-3 is an approved Story 1.3 exception to AD-2's archive cascade/reassignment clause, not compliance with its current wording; architecture reconciliation remains required. AD-2's deletion cascade applies when child tables exist.
- **AD-4 sequencing decision:** Story 1.3 persists a changed card due day and does not invoke notification reconciliation because bills and the service do not yet exist. Per the approved planning resolution, Story 3.2 owns invoking reconciliation for each affected active unpaid bill after due-day edits, using each bill's persisted due date. This remains a dependency on Story 3.2, not a Story 1.3 implementation requirement.
- Do not create bills, transactions, or EMI tables in this story. Delete the card row after confirmation; defer child-table foreign keys, delete cascades, and their verification to the corresponding feature stories when those tables are introduced. Those stories must ensure card deletion cascades to their dependent records.
- Management actions in this story apply only to active cards. An archive is one-way in this story: the archived row and history remain stored, but no active wallet/detail route, archived-card list, restore, edit, or delete route is provided for it.
- Enforce the active-only rule at mutation time: edit, archive, and delete target a row with `is_archived = 0`; an archived or missing row is a not-found failure, never a successful mutation.
- Use the add-card form's existing credit-limit validation: parse a finite number greater than zero. Days remain integers from 1 through 31. Theme edits accept only indices in the existing palette; display an unsupported saved index with the existing palette fallback.

**Never:**
- Add unrelated bill, transaction, EMI, or notification features.
- Change existing card identifiers or silently recreate a card during edits.
- Add restore UI or hypothetical child schemas to this story.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Edit card terms | Existing active card; valid finite limit, days, and palette index | Update only limit, billing day, due day, and theme on the same row; retain ID and all other card fields; refresh detail and wallet | If update affects no row or storage fails, emit an error; do not report success or mutate other fields |
| Invalid edit | Malformed/non-finite/non-positive limit, day outside 1–31, or unsupported theme index | Validation prevents saving | Show field-level validation; do not mutate persisted card |
| Edit with unknown saved theme | Active card has an unsupported stored theme index | Show the existing palette fallback; require a valid predefined selection before saving | Keep the persisted index unchanged until a valid choice is saved |
| Archive card | Existing active card; user confirms an explicit warning that archive has no restore flow here | Set `is_archived = 1`; retain the card row/history; remove it from active results/totals and return to refreshed wallet, including its empty state if last | If update affects no row or storage fails, retain it in active UI and surface error |
| Delete card | Existing active card; dialog identifies bank, nickname, and last four, and says deletion is permanent | On confirmation permanently remove the card row; refresh wallet and show empty state if last | Cancel leaves row unchanged; if no row is deleted or storage fails, keep card visible and surface error |

</frozen-after-approval>

## Code Map

- `lib/features/cards/domain/entities/card_entity.dart` -- already contains `totalLimit`, `billingDay`, `dueDay`, `colorGradientIdx`, and `isArchived`; retain the entity and equality semantics.
- `lib/features/cards/domain/repositories/card_repository.dart` -- current contract only supports add, active-list, and get-by-id; mutation contracts belong here.
- `lib/features/cards/data/datasources/card_local_data_source.dart` and `lib/features/cards/data/repositories/card_repository_impl.dart` -- SQLite card access and `Either<Failure, T>` handling; add precise update/archive/delete operations without using insert-replace as an edit.
- `lib/core/database/database_helper.dart` -- schema version 1 creates only `cards`, enables foreign keys, and indexes `is_archived`; do not add hypothetical dependent tables or migrations here.
- `lib/features/cards/domain/usecases/` and `lib/features/cards/presentation/bloc/` -- existing add/load patterns; mutations must use explicit use cases, events, and states.
- `lib/features/cards/presentation/pages/wallet_home_page.dart` and `card_detail_page.dart` -- wallet summary/carousel and display-only detail view; update active results after mutations and expose management actions here.
- `lib/features/cards/presentation/pages/add_card_page.dart` -- existing validation controls for limit and days can guide edit-form consistency.
- `lib/features/cards/presentation/widgets/card_gradient_palette.dart` -- source of stable predefined gradient indices for editing.
- `_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md` AD-4 and `_bmad-output/planning-artifacts/epics.md` Story 3.2 -- the approved sequencing assigns due-day notification reconciliation to Story 3.2 after bills and the service exist; Story 1.3 only persists the card edit.
- `test/features/cards/data/database_card_flow_test.dart`, `test/features/cards/presentation/bloc/card_bloc_test.dart`, and `test/features/cards/presentation/card_visual_styling_test.dart` -- real SQLite, Bloc, and wallet/detail widget-test patterns; preserve all existing tests.

## Tasks & Acceptance

**Execution:**
- [x] Add edit/archive/delete domain contracts and use cases; preserve typed failure handling, target active rows by ID (`is_archived = 0`), and treat zero affected rows as not found.
- [x] Implement SQLite edits, archive flag persistence/filtering, and confirmed card-row deletion; do not add child tables or claim child cascade verification.
- [x] Add active-card edit UI for limit, billing day, due day, and existing predefined theme; preserve all other fields and use existing add-form validation rules.
- [x] Add archive confirmation explaining that the archived card will leave active flows with no in-story restore; after success return to refreshed wallet. Add delete confirmation identifying the target and permanent effect; after success return to refreshed wallet.
- [x] On archive/delete/edit failure or not-found, retain consistent persisted-state UI and surface a Bloc error; never optimistically remove a card before persistence succeeds.
- [x] Test persistence, invalid/non-finite values, unsupported theme indices, preservation of non-editable fields, zero-row mutations, archive filtering/history contract, confirmation/cancellation, database failures, and post-mutation wallet/empty states. Defer linked-record cascade tests until corresponding child schemas are introduced.

**Acceptance Criteria:**
- Given an existing active card, when its credit limit or billing/due days are edited and saved, then SQLite contains the updated values for that same card and the wallet/dashboard reflects them.
- Given an existing active card with a saved gradient, when the user edits its theme using a valid predefined option, then the stable selected palette index is persisted and shown in wallet and detail views; other card fields and its ID remain unchanged.
- Given a card with an unsupported saved gradient index, when it is edited, then the current safe palette fallback is displayed and only a valid predefined index can be saved.
- Given an active card, when the user confirms Archive Card's no-restore warning, then `is_archived` is set to 1, the card/history remain stored, and it is removed from active results/totals; return to the refreshed wallet or empty state. Verify row retention now and linked-history retention when those schemas exist.
- Given an active card, when the user chooses Delete Card, then the confirmation identifies the bank, nickname, and last four and states permanent deletion; confirming removes only the card row and refreshes the wallet, while cancellation leaves it unchanged. No delete route for archived cards is provided here. Future bill/transaction/EMI stories must add and verify their card foreign-key cascades.
- Given an edit, archive, or delete operation fails or affects no row, when the operation completes, then the UI retains consistent state and surfaces an error rather than emitting success or hiding the card.
- Given an archived or missing card ID reaches an edit, archive, or delete operation, when the mutation executes, then it affects no row and returns a not-found error.
- Given invalid limit/day values or a persistence failure, when a save is attempted, then invalid data is not persisted and errors are surfaced without replacing the prior card.

## Design Notes

- Story 1.2 explicitly deferred editing an existing card's gradient to Story 1.3; include it here without changing palette index meanings.

## Verification

**Commands:**
- `dart format <changed Dart files>` -- expected: no formatting changes remain.
- `flutter analyze` -- expected: no issues found.
- `flutter test <targeted Story 1.3 test files>` -- expected: all targeted tests pass.
- `flutter test` -- expected: full suite passes, including existing Story 1.1 database-flow tests.

## Review Triage Log

| Finding | Verdict | Evidence and disposition |
|---------|---------|--------------------------|
| Edited card display was not asserted for updated billing/due days and theme. | medium | Added widget assertions for both day badges and the selected gradient after a successful edit; returning to the wallet also verifies the updated combined limit. |
| Edit/delete failure widget paths were not covered. | medium | Added failure-path widget tests. Confirmed failure state also replaced the underlying wallet with a full-page error; mutation failures now trigger an active-card reload after surfacing the error, and tests verify the wallet remains usable after returning. |
| Mutation failures could leave the wallet on its error/retry screen after closing detail/edit. | medium | The BLoC now reloads active cards after an edit, archive, or delete failure; BLoC and widget tests verify refreshed wallet state. |
| Update/archive/delete BLoC mutation handlers lacked direct transition tests. | medium | Added success tests for all three handlers and a mutation-failure/reload test, asserting the emitted states. |
| Archive of a missing or already archived row lacked direct not-found assertions. | medium | SQLite flow tests now verify both cases return `NotFoundFailure`; existing-row retention and active-list exclusion remain asserted. |
| New repository mutation exception mappings lacked coverage. | low | Added update/archive/delete data-source exception tests asserting typed `DatabaseFailure` results. |
| Edit persistence failure lacked a widget assertion that prior card data remains. | medium | Added a failed-edit test that returns to the unchanged detail card and usable wallet. |
| Confirmed-delete persistence failure lacked a widget assertion that the active card remains. | medium | Added a failed-delete test that verifies the card stays in detail and in the refreshed wallet. |
| Editing an existing card with an unsupported saved theme lacked a form-level fallback/save test. | medium | Added a widget test for fallback preview, blocked save until a valid preset is selected, and successful save afterward. |
| Archive behavior with more than one active card lacked a preservation assertion. | low | Added a widget test confirming the other active card remains in the wallet after archiving the selected card. |
| The domain theme-count constant could drift from the presentation palette. | low | Added an assertion that the domain validation count matches the current palette length. |
| Implemented execution tasks remained unchecked during review. | low | Checked each execution task after its implementation and verification evidence was confirmed. |
