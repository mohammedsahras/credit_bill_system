# Epic 2 Context: Statement Bill Tracking & Payment Settlements

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Let cardholders record each monthly statement, understand payment urgency, track full or partial settlements against the remaining balance, and move cleanly into the next cycle. This keeps bill status and payment urgency current while preserving prior statements for reference.

## Stories

- Story 2.1: Log Monthly Statement Bill with Countdown Badge
- Story 2.2: Settle Bill Payments (Full and Partial)
- Story 2.3: Automated Billing Cycle Rollover

## Requirements & Constraints

- A bill belongs to an active card and records total due, minimum due, statement date, and due date. Pre-fill statement date from the card billing day in the selected statement month and due date from the card due day in the next month, clamping short months; allow manual overrides only when due date is not before statement date. Start new statements as unpaid. Minimum due cannot exceed total due.
- Keep one bill per card and statement cycle; update the existing bill row only while unpaid. Recalculate days remaining from the local date and show urgency as green when more than 7 days remain, amber at 3–7 days, and red below 3 days or overdue. Full available credit including unbilled balances is deferred until Story 5.1 adds persisted expense data.
- Full settlement sets amount paid to total due, remaining balance to zero, and status to paid. A partial payment adds to the paid-to-date amount, reduces the remaining due, and sets status to partially paid. Confirm overpayments before treating them as a negative card balance. Keep a payment audit record with timestamp, amount, and remaining balance.
- When the bill is paid in full or the billing day has passed, prepare the next monthly draft using the card's recurring rules and archive the prior statement.
- Bill tracking must work offline. Keep bill queries responsive as local data grows; the broader app target is under 25 ms for local queries over 1,000+ transactions.

## Technical Decisions

- Place bill behavior in the `bills` feature using Feature-First Clean Architecture: presentation state (Bloc/Cubit) invokes Domain use cases; repositories/data sources own SQLite access. Mutations go through explicit use cases and return typed results; UI renders immutable state.
- Bills are local SQLite records linked to cards. Use non-empty UUID v4 text IDs, enforced foreign keys, and an index on `(card_id, due_date)`. Card deletion cascades to its bills. Store cycle month as `YYYY-MM`, statement/due dates as ISO-8601 dates, and timestamps as ISO-8601 UTC; format dates for local display in presentation.
- Bill fields include cycle month, statement and due dates, total/minimum due, amount paid, and status (`unpaid`, `partially_paid`, `paid`). Amounts use double or integer cents with explicit two-decimal rounding; never display raw unformatted values.
- Story 2.1 persists bills without scheduling because the notification service arrives in Story 3.1. Story 3.1 must reconcile already-stored active unpaid bills and schedule eligible future bills on create/update; Story 3.2 handles full/partial-payment alert changes and card due-day reconciliation.

## UX & Interaction Patterns

- Provide an “Update Bill” flow for entering bill amounts and dates, with clear validation and the due-date countdown badge on the card dashboard.
- Provide distinct “Mark as Paid in Full” and “Record Partial Payment” actions. Show the updated remaining due and payment success state; request confirmation for overpayment.
- Keep historical statements accessible after rollover while presenting the upcoming cycle as a draft.

## Cross-Story Dependencies

- Epic 2 depends on active-card records and recurring billing/due-day rules established by Epic 1; rollover uses those rules.
- Stories 2.2 and 2.3 build on bill records created in 2.1: settlement updates the same bill, while paid status or cycle closure triggers rollover and archival.
- Bill mutations and settlements must integrate with Epic 3's notification reconciliation once that service exists. Story 5.1 supplies the persisted expense source needed to calculate combined billed/unbilled available credit.
