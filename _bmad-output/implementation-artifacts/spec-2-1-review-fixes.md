---
title: 'Story 2.1 Follow-up: Resolve Review Findings'
type: 'bugfix'
created: '2026-10-14'
status: 'in-review'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: '62a233e2e74302d93c716e5d34563166d09ec539'
context:
  - '_bmad-output/implementation-artifacts/spec-2-1-log-monthly-statement-bill-with-countdown-badge.md'
  - '_bmad-output/implementation-artifacts/epic-2-context.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-WALKTHROUGH.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Story 2.1 implementation has review findings involving feature boundaries, bill date/state handling, cycle targeting, and verification gaps.

**Approach:** Correct those defects without expanding into settlement, rollover, notifications, or Story 2.2. Preserve existing uncommitted work and unrelated user changes; do not commit or push.

## Boundaries & Constraints

**Always:**
- Preserve AD-1: cards presentation must not depend on bills presentation. Keep cross-feature contracts in Domain or Core and compose feature behavior at the application boundary.
- A statement-date change must keep the due date valid and derive any automatic due date from the card's due day in the following month, clamped to month end.
- Bill loading, saving, or failed refreshes must not discard the last successfully loaded bill list from wallet presentation.
- Persisted unpaid cycles remain editable in place; persisted partially paid or paid cycles remain protected against edits.
- The card-detail bill action edits or creates only the current statement cycle; identify that scope in the UI. Editing older cycles is out of scope.
- Preserve offline-first behavior, current database data, and unrelated dirty-worktree changes.

**Never:**
- Implement payment settlement, billing-cycle rollover, notification scheduling, expense tracking, or Story 2.2.
- Commit, push, reset, or discard existing user changes.
- Silently change which statement cycle an existing wallet action edits.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Change statement date | Selected statement date makes the automatic due date invalid | Recalculate the automatic due date from the card schedule; clamp short months | Keep statement and due dates valid |
| Reload failure | Bills were loaded successfully before a later load/save refresh fails | Show the error and retain prior wallet bill badges | Do not replace the retained list with an empty list |
| Paid cycle edit | Existing bill is partially paid or paid | Reject the update and leave the full row unchanged | Surface conflict |
| Database upgrade | Existing v1 database is opened and a bill is saved | Save and reload bill through upgraded schema | Test failure if either operation fails |

</frozen-after-approval>

## Code Map

- `lib/features/cards/presentation/widgets/card_item_widget.dart` -- currently imports and renders a bills-presentation countdown widget; accept a badge widget slot supplied by the app-level composition page without importing bills UI.
- `lib/features/cards/presentation/pages/wallet_home_page.dart` and `card_detail_page.dart` -- currently read the BillBloc, choose earliest-unpaid and current-cycle bills separately, and route bill editing; accept bill data and callbacks from the app-level composition boundary without importing bills presentation.
- `lib/app.dart` -- root dependency registration; add an app-level wallet composition page to coordinate CardBloc and BillBloc, retain bill data, provide badge UI, and route bill editing.
- `lib/features/bills/presentation/bloc/bill_bloc.dart` and `bill_state.dart` -- loading/saving/error states currently omit the last successful list; retain and expose it through transitions.
- `lib/features/bills/presentation/pages/update_bill_page.dart` and `domain/usecases/bill_date_calculator.dart` -- date picker currently sets due date equal to a later statement date; reuse the calculator for automatic due-date recomputation.
- `lib/core/database/database_helper.dart` and `test/features/bills/data/database_bill_flow_test.dart` -- schema migration creates bill storage; migration test currently checks table existence but does not save/reload a bill after upgrade.
- `test/features/bills/presentation/bill_entry_test.dart` -- add deterministic date-change, retained-list, existing-cycle route, and countdown day-rollover coverage.
- `test/widget_test.dart` -- current app-level test covers card creation; extend an FFI-backed production-wiring path through bill creation and wallet display.
- `_bmad-output/implementation-artifacts/spec-2-1-log-monthly-statement-bill-with-countdown-badge.md` -- update stale post-implementation Code Map and record review/fix disposition without rewriting its approved frozen intent.
- `_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-WALKTHROUGH.md` -- remove the unused status-index blueprint entry; no current bill query filters by status.

## Tasks & Acceptance

**Execution:**
- [ ] Keep the bill action explicitly scoped to the current statement cycle and identify that scope in wallet/detail UI; older-cycle editing remains unsupported.
- [ ] Add an app-level wallet composition page to coordinate bill/card presentation; make cards presentation consume bill Domain data and callbacks only, while preserving countdown and bill-entry behavior under AD-1.
- [ ] Preserve the last loaded bill collection through bill loading, saving, and error states; recompute automatic due dates correctly after statement-date changes.
- [ ] Add regression coverage for migrated-schema save/read, paid-cycle edit rejection, existing unpaid-cycle editing, retained wallet badges on reload failure, date changes, and deterministic midnight refresh.
- [ ] Add a production-DI widget flow test for card creation, bill save, and wallet display, plus an FFI-backed repository/use-case persistence and reload test.
- [ ] Reconcile implementation-facing architecture/spec documentation and keep Story 2.1 status in review until implementation and verification pass.

**Acceptance Criteria:**
- Given a statement date changes and the due date was automatically derived, when the date picker closes, then the due date follows the card's following-month due day and month-end clamp.
- Given wallet bills were loaded and a later load or post-save refresh fails, when the wallet renders the failure, then it surfaces the error and retains the previously loaded countdowns.
- Given the user opens the bill action for a card with bills in multiple cycles, when the action is presented, then it is labeled as current-cycle only and does not imply that the displayed older-cycle badge is being edited.
- Given an existing v1 database is upgraded, when a bill is saved and loaded, then the migrated schema supports both operations and legacy cards remain intact.
- Given a paid or partially paid bill is updated through persistence, when the save is attempted, then the operation conflicts and all bill/payment data remains unchanged.
- Given the app creates and saves a bill through its production dependency wiring, when the wallet reloads, then the persisted bill is displayed with its countdown.
- Given local midnight passes while a countdown badge remains mounted, when the date changes, then the badge updates without requiring unrelated navigation or a rebuild.

## Implementation Notes

- The production-DI widget flow uses a deterministic database adapter; SQLite migration and bill persistence/reload are verified separately with sqflite FFI because platform FFI work does not complete inside the widget test binding's fake-async zone.
## Spec Change Log

## Review Triage Log

## Design Notes

AD-1 is an explicit constraint, not a style preference. If the minimal shared-contract/composition change cannot preserve existing user behavior, stop and request an architecture decision rather than introducing a cross-feature presentation import.

## Verification

**Commands:**
- `dart format` on changed Dart files -- expected: no formatting changes remain.
- `flutter analyze` -- expected: no issues.
- `flutter test --reporter expanded test\features\bills test\features\cards\data\database_card_flow_test.dart test\features\cards\presentation\card_management_test.dart test\features\cards\presentation\card_visual_styling_test.dart test\widget_test.dart` -- expected: all targeted tests pass.
- `flutter test --reporter expanded` -- expected: full suite passes.
- `git diff --check` -- expected: no whitespace errors.
