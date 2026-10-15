---
title: 'Story 2.1: Log Monthly Statement Bill with Countdown Badge'
type: 'feature'
created: '2026-10-14'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: '62a233e2e74302d93c716e5d34563166d09ec539'
context:
  - '_bmad-output/implementation-artifacts/epic-2-context.md'
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/prds/prd-credit_bill_system-2026-10-13/prd.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-WALKTHROUGH.md'
  - '_bmad-output/implementation-artifacts/spec-1-3-edit-card-parameters-safe-archival-deletion.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Cardholders cannot record monthly statement bills or see the urgency of an upcoming payment in the offline wallet.

**Approach:** Add a bill-recording flow for an active card, persist statement and due details locally, and show an urgency countdown on the card dashboard using the system date.

## Boundaries & Constraints

**Always:**
- Preserve offline-first behavior and Feature-First Clean Architecture; UI calls explicit use cases and never accesses SQLite directly.
- Use UUID v4 text IDs, ISO date fields and UTC timestamps; enforce foreign keys and index bills by `(card_id, due_date)`.
- Link each bill to an active card. Preserve bill history when a card is archived; confirmed card deletion cascades to its bills.
- Store total due, minimum due, amount paid, status, cycle month, statement date, due date, and updated timestamp. New bills start `unpaid`; amounts are nonnegative and minimum due cannot exceed total due.
- Calculate countdown days against the current local calendar date: green >7 days, amber 3–7 days, red <3 days or overdue.
- Use one bill per card and statement cycle. “Update Bill” edits the existing bill row rather than creating a duplicate. `cycle_month` identifies the statement month; default statement date uses the card billing day in that month and due date uses the card due day in the following month, clamped to month end.
- “Update Bill” may edit a cycle only while its bill has no recorded payment; once `amount_paid` is greater than zero, reject statement edits without changing payment or bill data.
- A manually selected due date must be on or after the statement date.
- Story 2.1 does not calculate or label available credit as including unbilled spend. Story 5.1 owns the full calculation once persisted expense data exists.
- Story 2.1 does not schedule notifications. Story 3.1 owns the service and must reconcile eligible unpaid bills already stored before that service exists.
- Preserve existing Stories 1.1–1.3 behavior and tests.

**Never:**
- Add payment settlement, rollover, expense entry, or notification scheduling to Story 2.1.
- Create a bill for an archived or missing card.
- Claim full available-credit calculation without a defined and persisted unbilled-balance source.
- Modify a bill's payment audit values as a side effect of editing its statement amounts.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Record bill | Active card; valid amounts and dates | Persist one unpaid bill; refresh the card dashboard countdown | Surface validation or persistence failure; retain prior state |
| Invalid amounts | Negative values or minimum greater than total | Do not persist; show field-level validation | Keep entered values for correction |
| Countdown boundary | Due date is past, today, 1–2, 3–7, or >7 local days away | Red, red, red, amber, or green urgency respectively | Recompute from current date |
| Card unavailable | Card is archived, missing, or deleted before save | No bill is created | Show not-found error |

</frozen-after-approval>

## Code Map

- `lib/core/database/database_helper.dart` -- schema v2 stores `cards` and `bills`; the v1-to-v2 migration creates bill storage without losing existing card rows.
- `lib/features/cards/domain/entities/card_entity.dart` and `features/cards/domain/repositories/card_repository.dart` -- active-card contract and entity patterns; keep bill types in a separate `features/bills/` feature.
- `lib/features/cards/data/datasources/card_local_data_source.dart` -- active-card filtering and SQLite conventions.
- `lib/features/cards/presentation/pages/wallet_home_page.dart`, `card_detail_page.dart`, and `widgets/card_item_widget.dart` -- wallet carousel/dashboard and existing due-day badges; add bill urgency without changing card management behavior.
- `lib/app.dart` -- current dependency wiring; register bill use cases/state management here.
- `test/features/cards/data/database_card_flow_test.dart` -- SQLite FFI database setup, migration and card lifecycle regression patterns.
- `test/features/cards/presentation/card_management_test.dart` and `test/widget_test.dart` -- navigation and presentation test patterns.
- `lib/features/bills/` contains the bill feature; notification scheduling and persisted expense sources remain outside this story. Do not treat bill-only balances as including unbilled expenses.

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/database/database_helper.dart` -- migrate existing v1 databases to the bills table, unique card/cycle constraint, and required indexes/foreign key -- preserve card data and support bill-linked deletion cascade.
- [x] `lib/features/bills/domain/entities/bill_entity.dart` and `domain/repositories/bill_repository.dart` -- define bill data and typed create/update/read contracts -- keep bill rules out of presentation.
- [x] `lib/features/bills/domain/usecases/save_bill_usecase.dart` and `get_active_bills_usecase.dart` -- validate amounts, date ordering, active card, and unpaid-only updates; load active-card bills for the wallet -- centralize domain behavior.
- [x] `lib/features/bills/data/models/bill_model.dart`, `data/datasources/bill_local_data_source.dart`, and `data/repositories/bill_repository_impl.dart` -- implement SQLite mapping and active-card, unique-cycle, and unpaid-only mutation guards -- persist bill data reliably.
- [x] `lib/features/bills/presentation/bloc/bill_bloc.dart`, `bill_event.dart`, and `bill_state.dart` -- model bill loading and save outcomes -- maintain immutable UI state and surface typed failures.
- [x] `lib/features/bills/presentation/pages/update_bill_page.dart`, `lib/features/cards/presentation/pages/card_detail_page.dart`, and `lib/features/cards/presentation/widgets/card_item_widget.dart` -- provide prefilled editable bill dates/amounts and countdown display -- make the flow discoverable from active cards.
- [x] `lib/app.dart` -- register bill repository, use cases, and state provider -- expose the feature through existing dependency wiring.
- [x] `test/features/bills/data/database_bill_flow_test.dart`, `test/features/bills/domain/bill_countdown_test.dart`, and `test/features/bills/presentation/bill_entry_test.dart` -- cover migration, persistence, constraints, active-card guard, deletion cascade, duplicate-cycle behavior, post-payment edit rejection, countdown boundaries, errors, and dashboard rendering -- protect requirements and prior card flows.

**Acceptance Criteria:**
- Given an active card, when the user enters a valid total/minimum due and statement/due dates, then one local bill is persisted for that card with a UUID, unpaid status, and correct cycle.
- Given invalid amounts or dates, when the user saves, then validation prevents persistence and explains the invalid input.
- Given a manual date override places due date before statement date, when the user saves, then the date is rejected and no bill is persisted.
- Given an unpaid bill already exists for the card and statement cycle, when the user updates it, then the same row is changed and no duplicate is created.
- Given a bill has a partial or full payment, when the user attempts to edit its statement, then the edit is rejected and the bill and payment history remain unchanged.
- Given a persisted unpaid bill, when the dashboard is shown, then countdown and color follow the defined local-date thresholds and update as the date changes.
- Given bills are created before notification scheduling exists, when Story 3.1 introduces the notification service, then it reconciles stored active unpaid bills as well as newly created or updated bills.
- Given unbilled expense data is not yet persisted, when Story 2.1 shows the card dashboard, then it does not present a bill-only estimate as full available credit; Story 5.1 adds the combined calculation.
- Given a bill for an active card, when the card is archived, then the bill remains stored but is excluded from active dashboard flows; when the card is permanently deleted, then the bill is deleted through the enforced foreign-key cascade.
- Given the app is using an existing v1 database, when it opens the upgraded schema, then all existing card data remains intact and bills can be stored.

## Implementation Notes

## Spec Change Log

## Review Triage Log

## Design Notes

- Bill schema blueprint fields: `id`, `card_id`, `cycle_month` (`YYYY-MM`), `statement_date`, `due_date`, `total_amount_due`, `minimum_amount_due`, `amount_paid`, `status`, `updated_at`. Database checks permit nonnegative amounts and statuses `unpaid`, `partially_paid`, `paid`; explicit cross-field minimum/total validation is also required.
- Approved decisions: full available credit including unbilled expenses is deferred to Story 5.1; Story 3.1 introduces notification scheduling and reconciles existing active unpaid bills; one bill per card/statement month is updated in place only while unpaid; cycle month is the statement month, the default due day falls in the following month and short months clamp to month end; manual due date must be on or after statement date.

## Verification

**Commands:**
- `dart format` on the changed Dart sources and tests -- formatted; no remaining formatting changes.
- `flutter analyze` -- no issues found.
- `flutter test --reporter expanded test\features\bills test\features\cards\data\database_card_flow_test.dart test\features\cards\presentation\card_management_test.dart test\features\cards\presentation\card_visual_styling_test.dart test\widget_test.dart` -- all 41 targeted tests passed.
- `flutter test --reporter expanded` -- all 63 tests passed, including existing SQLite card lifecycle tests.
- `git diff --check` -- no whitespace errors.

**Remaining risk:** Native Android/iOS visual testing was not performed; validation uses Flutter widget tests and SQLite FFI.
