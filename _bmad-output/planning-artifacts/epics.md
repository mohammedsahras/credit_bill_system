---
status: final
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-credit_bill_system-2026-10-13/prd.md
  - _bmad-output/planning-artifacts/prds/prd-credit_bill_system-2026-10-13/addendum.md
  - _bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-WALKTHROUGH.md
---

# credit_bill_system - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for credit_bill_system, decomposing the requirements from the PRD and Architecture into implementable, testable developer stories.

## Requirements Inventory

### Functional Requirements

- **FR-1: Add New Credit Card** — Users can add a Card Profile with Bank Name, Card Nickname, Last 4 digits (strictly 4 digits), Network (Visa/Mastercard/Amex/RuPay), Total Credit Limit (> 0), Billing Statement Day (1-31), Due Day (1-31), and visual gradient theme. Zero collection of CVV or full PAN.
- **FR-2: Custom Card Visual Styling** — Users can select from preset bank palettes or custom gradient color styles to match their physical cards.
- **FR-3: Edit & Archive Card** — Users can modify credit limits, billing dates, or archive/delete cards. Archiving preserves historical records while removing active reminders and current utilization calculation.
- **FR-4: Log Monthly Statement Bill** — Users can log statement bills with Total Amount Due, Minimum Amount Due (≤ Total Due), Statement Date, Due Date, and dynamic countdown days color-coded (Green: >7d, Amber: 3-7d, Red: <3d).
- **FR-5: Payment Settlement (Full & Partial)** — Users can record full or partial payments. Partial payments update remaining balance to (Total Due - Paid) and update status to `partially_paid`.
- **FR-6: Automated Billing Cycle Rollover** — When a bill is paid in full or the billing date passes, the system automatically creates the next month's bill draft with new due date.
- **FR-7: Scheduled Local Alerts** — Deterministic offline push notifications scheduled at 7 days, 3 days, 1 day, and morning of due date. Canceled immediately when bill is paid in full.
- **FR-8: Real-Time Utilization Gauge & Threshold Alert** — Calculates aggregate and per-card credit utilization. Displays green gauge (≤30%) or amber/red alert banner (>30%) with what-if purchase simulator.
- **FR-9: Log Categorized Card Expense** — Users can log card expenses with amount, date/time, category (Dining, Groceries, Fuel, Shopping, Travel, etc.), and optional merchant note.
- **FR-10: Monthly Visual Spend Breakdown** — Visual donut and bar charts showing category spend distribution and month-over-month trend.
- **FR-11: Create & Manage Active EMIs** — Users can create active EMIs attached to a card with principal, monthly installment, total tenure, and remaining installments.
- **FR-12: EMI Integration with Monthly Bill** — Active monthly EMI installments are automatically itemized within the card's upcoming bill breakdown.
- **FR-13: App Lock with Biometrics & PIN Fallback** — Optional biometric lock (Fingerprint / Face ID / PIN). Obscures app screen on backgrounding (>30s) and requires authentication on resume.
- **FR-14: Encrypted JSON/CSV Backup & Restore** — Export complete database to AES-256-GCM encrypted JSON envelope (schema version 1) or CSV via system share sheet; restore from backup file.

### NonFunctional Requirements

- **NFR-1: Performance & Responsiveness** — 60 FPS fluid rendering across all Flutter navigation flows. Database queries execute in < 25ms for 1,000+ records. App cold start to interactive < 800ms.
- **NFR-2: Security & Privacy** — Zero storage of sensitive PCI-DSS card data (CVV, full 16-digit PAN). Local SQLite database encryption at rest support. Biometrics via platform-native `local_auth`.
- **NFR-3: Reliability & Offline Autonomy** — 100% functionality without internet connection. Scheduled local notifications persist across device reboots.
- **NFR-4: Platform Support** — Android 8.0 (API level 26+) and iOS 14.0+.

### Additional Requirements

- **ARCH-1: Feature-First Clean Architecture** — Strict layer isolation: Presentation (`flutter_bloc`/Cubit) $\rightarrow$ Domain (Entities, UseCases) $\leftarrow$ Data (Repositories, SQLite DAOs). Zero direct Data imports in UI.
- **ARCH-2: Relational Schema & UUIDs** — All entities use UUID v4 text primary keys. Enforce `PRAGMA foreign_keys = ON;` with cascade on `card_id`. Mandatory indexes on `bills(card_id, due_date)` and `transactions(card_id, timestamp)`.
- **ARCH-3: Style B Dedicated UseCases** — Business operations orchestrated by single-purpose UseCases returning `Either<Failure, T>`.
- **ARCH-4: Reactive Notification Reconciliation** — `NotificationReconciliationService` reschedules local alarms on bill creation, payment settlement, card due day change, and app cold start.
- **ARCH-5: App Lifecycle Privacy Shield** — Immediate privacy shield overlay when app is `paused` or `inactive`; re-challenge after 30 seconds backgrounding.
- **ARCH-6: Versioned Backup Envelope** — Backup JSON format enforces `schema_version: 1`, timestamp, SHA-256 checksum, and optional AES-256-GCM encryption.

### UX Design Requirements

*(No standalone UX specification file — UI adheres to Flutter Material 3 design system, custom card visual gradient cards, and fl_chart visualizations as defined in PRD and Architecture).*

### FR Coverage Map

- **FR-1**: Epic 1 — Add New Credit Card with strict validation and zero CVV/PAN collection
- **FR-2**: Epic 1 — Custom visual card gradients and bank themes
- **FR-3**: Epic 1 — Edit card metadata and archive/delete with historical retention
- **FR-4**: Epic 2 — Log monthly statement bill with countdown badges and status tracking
- **FR-5**: Epic 2 — Full and partial bill payment settlements with balance recalculation
- **FR-6**: Epic 2 — Automated statement cycle rollover upon payment or cycle date
- **FR-7**: Epic 3 — Scheduled offline local push notifications (7d, 3d, 1d, 0d) with reactive cancellation
- **FR-8**: Epic 4 — Real-time credit utilization health gauge (>30% alert) and what-if simulator
- **FR-9**: Epic 5 — Log categorized card expenses with date, category, and notes
- **FR-10**: Epic 5 — Monthly visual spend breakdown charts (donut & bar trends)
- **FR-11**: Epic 6 — Create and manage active installment plans (EMIs) with amortization tracking
- **FR-12**: Epic 6 — Automatic inclusion of committed monthly EMI amounts in upcoming card bills
- **FR-13**: Epic 7 — Biometric app lock (Fingerprint / Face ID / PIN) and background task-switcher obscuring
- **FR-14**: Epic 7 — Encrypted JSON/CSV database backup and portable restore

## Epic List

### Epic 1: Multi-Card Wallet & Portfolio Management
Users can configure and manage their credit card portfolio in a visual wallet interface with custom card styling, limit tracking, and strict privacy boundaries (zero CVV/PAN storage).
**FRs covered:** FR-1, FR-2, FR-3 (Enforces ARCH-1, ARCH-2)

### Epic 2: Statement Bill Tracking & Payment Settlements
Users can record monthly statement bills, monitor due date countdowns, perform full or partial payment settlements with real-time balance recalculation, and have subsequent cycles auto-rollover.
**FRs covered:** FR-4, FR-5, FR-6 (Enforces ARCH-2, ARCH-3)

### Epic 3: Proactive Due Date Alerts & Notifications
Users receive reliable, offline local push notifications at configurable offsets (7d, 3d, 1d, day-of) to eliminate late payment penalties, with reactive cancellation when bills are settled.
**FRs covered:** FR-7 (Enforces ARCH-4)

### Epic 4: Credit Utilization & Financial Health Intelligence
Users can visualize their aggregate and per-card credit utilization health against the safe 30% ceiling and simulate how upcoming purchases will impact their credit rating.
**FRs covered:** FR-8 (Enforces NFR-1, ARCH-3)

### Epic 5: Card Expense Categorization & Spend Analytics
Users can log daily transactions against cards with spending categories and analyze monthly expenditure distributions via fluid donut and trend charts.
**FRs covered:** FR-9, FR-10 (Enforces ARCH-1, NFR-1)

### Epic 6: Active EMI & Installment Plan Tracker
Users can track active equal monthly installments (tenure, remaining balance, monthly commitment) and view them automatically itemized within monthly card bill obligations.
**FRs covered:** FR-11, FR-12 (Enforces ARCH-2, ARCH-3)

### Epic 7: Biometric Security & Data Sovereignty
Users can lock the application with biometric authentication (Fingerprint / Face ID / PIN) with background task-switcher obscuring, and create encrypted portable backups (AES-256-GCM) with full restore capabilities.
**FRs covered:** FR-13, FR-14 (Enforces ARCH-5, ARCH-6, NFR-2)

## Epic 1: Multi-Card Wallet & Portfolio Management

Users can configure and manage their credit card portfolio in a visual wallet interface with custom card styling, limit tracking, and strict privacy boundaries (zero CVV/PAN storage).

### Story 1.1: Project Bootstrap & SQLite Database Setup with Add Card Flow

As a cardholder,
I want to add my credit card with bank name, nickname, last 4 digits, network, credit limit, and billing cycle days,
So that I can establish my offline card wallet without risking sensitive financial data.

**Acceptance Criteria:**

**Given** the user is on the empty wallet home screen
**When** the user taps "Add Card" and submits valid card information (Bank name, nickname, strictly 4 digits for card number, network, credit limit > 0, billing day 1-31, due day 1-31)
**Then** a new card record is created with a unique UUID v4 in the local SQLite `cards` table
**And** the form strictly disallows and provides no fields for CVV, expiration date, or full 16-digit card numbers
**And** the card is immediately rendered in the wallet list with bank name, last 4 digits, and total limit.

### Story 1.2: Custom Card Visual Styling & Bank Gradient Themes

As a user,
I want to select from pre-built bank color themes or custom card gradients,
So that my virtual cards visually resemble my physical cards in my wallet.

**Acceptance Criteria:**

**Given** the user is creating or editing a card
**When** the user selects a gradient theme from the palette selector (e.g. Navy, Gold, Black, Emerald, Purple)
**Then** the card preview updates dynamically in real-time
**And** upon saving, the selected `color_gradient_idx` is persisted to SQLite
**And** the card renders with the chosen gradient, bank logo/icon, and network badge in both carousel and card detail views.

### Story 1.3: Edit Card Parameters & Safe Archival/Deletion

As a user,
I want to update card parameters (limit, billing days) or archive/delete cards,
So that my wallet stays accurate as banks update my terms or when I close accounts.

**Acceptance Criteria:**

**Given** an existing active card in the wallet
**When** the user edits the credit limit or billing/due dates and taps Save
**Then** the updated values are committed to SQLite and reflected across the dashboard
**And** when the user chooses "Archive Card", `is_archived` is set to 1, removing the card from active due date lists while preserving historical statements and transactions
**And** when the user chooses "Delete Card", a destructive confirmation dialog is required and the card is permanently deleted if confirmed. Each feature story that introduces bills, transactions, or EMIs must add and integration-test the corresponding card-linked deletion cascade; Story 1.3 does not create those child tables.

---

## Epic 2: Statement Bill Tracking & Payment Settlements

Users can record monthly statement bills, monitor due date countdowns, perform full or partial payment settlements with real-time balance recalculation, and have subsequent cycles auto-rollover.

### Story 2.1: Log Monthly Statement Bill with Countdown Badge

As a cardholder,
I want to log my monthly statement bill with Total Due, Minimum Due, and due date,
So that I have clear visibility into payment deadlines and urgency.

**Acceptance Criteria:**

**Given** an active card in the wallet
**When** the user opens "Update Bill" and inputs Total Due and Minimum Due (validated: Minimum Due <= Total Due)
**Then** the bill is saved in the `bills` table with status `unpaid`, creating a row for a new cycle or updating that cycle's existing unpaid row
**And** the card dashboard displays a color-coded countdown badge: Green (>7 days), Amber (3-7 days), or Red (<3 days / overdue)
**And** there is at most one bill per card and statement cycle; "Update Bill" edits the existing unpaid bill for that cycle.
**And** full available credit including billed and unbilled balances is deferred until Story 5.1 provides persisted expense data; Story 2.1 must not present a bill-only estimate as full available credit.
**And** statement date defaults from the card's billing day in the selected statement month, due date defaults from its due day in the following month (clamped to month end), and a due date before statement date is rejected.
**And** statement edits are rejected after any payment has been recorded so payment history is unchanged.

### Story 2.2: Settle Bill Payments (Full and Partial)

As a cardholder,
I want to record full or partial payments towards my card bill,
So that I can track my payment progress and see my exact remaining balance.

**Acceptance Criteria:**

**Given** an unpaid or partially paid bill
**When** the user taps "Mark as Paid in Full"
**Then** `amount_paid` is set to `total_amount_due`, status becomes `paid`, and the bill badge turns Green
**And** when the user selects "Record Partial Payment" and inputs amount X (< remaining balance)
**Then** `amount_paid` increments by X, remaining due becomes `total_amount_due - amount_paid`, and status updates to `partially_paid`
**And** the payment transaction is appended to the card's payment audit history.

### Story 2.3: Automated Billing Cycle Rollover

As a user,
I want my card statement cycle to automatically roll over to the next month once paid or when the cycle closes,
So that my dashboard is always ready for the next billing period without manual resetting.

**Acceptance Criteria:**

**Given** a card whose current bill has been settled (`status = paid`) or the calendar date has crossed the billing day
**When** the user opens the app or views the card
**Then** the system automatically generates a draft bill entity for the next cycle month (`YYYY-MM`) with statement and due dates calculated from the card's recurring rules
**And** the previous month's bill is archived in historical statements.

---

## Epic 3: Proactive Due Date Alerts & Notifications

Users receive reliable, offline local push notifications at configurable offsets (7d, 3d, 1d, day-of) to eliminate late payment penalties, with reactive cancellation when bills are settled.

### Story 3.1: Offline Local Notification Scheduling Service

As a user,
I want to receive local notifications on my device before my bill due dates,
So that I never miss a payment deadline even when my device is offline.

**Acceptance Criteria:**

**Given** an unpaid bill with a future due date
**When** the bill is logged or updated
**Then** local notification alarms are scheduled with `flutter_local_notifications` at 7 days, 3 days, 1 day prior, and 9:00 AM on the due date
**And** notifications fire deterministically without any remote network or push server connection
**And** tapping a notification launches the app directly into the bill payment settlement screen
**And** when notification scheduling is first introduced, all previously stored active unpaid bills with eligible future due dates are reconciled and scheduled.

### Story 3.2: Reactive Notification Reconciliation & Boot Recovery

As a user,
I want pending notifications to be canceled when I pay my bill and restored after a phone reboot,
So that I don't receive annoying phantom alerts for already-paid bills.

**Acceptance Criteria:**

**Given** a bill with scheduled notification alarms
**When** the user records a full payment settlement (`status = paid`)
**Then** all pending notification alarms for that bill ID are immediately canceled
**And** when the user records a partial payment, the notifications are rescheduled with updated remaining amount text
**And** when the app launches after a device reboot, an idempotent reconciliation check restores all active scheduled alarms for currently unpaid bills.
**And** when a card's due day is edited, the reconciliation service is invoked for each affected active unpaid bill so its scheduled alerts are reconciled against the bill's persisted due date.

---

## Epic 4: Credit Utilization & Financial Health Intelligence

Users can visualize their aggregate and per-card credit utilization health against the safe 30% ceiling and simulate how upcoming purchases will impact their credit rating.

### Story 4.1: Real-Time Aggregate & Per-Card Credit Utilization Gauge

As a financially conscious cardholder,
I want to see my aggregate and per-card credit utilization ratio on the dashboard,
So that I can keep my revolving credit below 30% and protect my credit score.

**Acceptance Criteria:**

**Given** one or more active credit cards with logged limits and balances
**When** the user views the home dashboard
**Then** the system calculates aggregate utilization: `(Sum of unpaid balances / Sum of credit limits) * 100`
**And** if utilization is <= 30.0%, the health gauge displays in Green ("Optimal Health")
**And** if utilization exceeds 30.0%, the gauge displays in Amber/Red with an alert banner: "High Utilization Warning: Keep under 30% to protect credit score"
**And** per-card utilization ratios are displayed on individual card cards.

### Story 4.2: What-If Purchase Simulator

As a user planning a major purchase,
I want to simulate how an expense amount will impact my credit utilization ratio,
So that I can decide whether to proceed or split the transaction before swiping.

**Acceptance Criteria:**

**Given** the user is viewing the Credit Health section
**When** the user enters a prospective purchase amount in the "What-If Simulator"
**Then** the projected utilization ratio is recalculated and rendered in real-time
**And** the UI clearly displays the delta ("+14.2% change") and indicates whether the expense would push the user into the >30% risk zone.

---

## Epic 5: Card Expense Categorization & Spend Analytics

Users can log daily transactions against cards with spending categories and analyze monthly expenditure distributions via fluid donut and trend charts.

### Story 5.1: Log Categorized Card Expense

As a user,
I want to log expenses against a specific card with category tags and merchant notes,
So that I can maintain a record of my daily credit card spending.

**Acceptance Criteria:**

**Given** an active card in the wallet
**When** the user taps "Log Expense", enters an amount, selects a category (Dining, Groceries, Fuel, Shopping, Travel, Utilities, Entertainment, Other), and adds an optional note
**Then** a new record is saved in SQLite `transactions` linked to the `card_id`
**And** the card's current unbilled balance updates immediately
**And** available credit is calculated using the active card limit minus outstanding billed and unbilled balances
**And** the transaction appears in the card's recent transaction feed sorted by date descending.

### Story 5.2: Monthly Visual Spend Breakdown Charts

As a user,
I want to view interactive monthly expense breakdown charts by category,
So that I understand my spending patterns and identify where my money goes.

**Acceptance Criteria:**

**Given** logged transactions across one or more cards for a given month
**When** the user opens the Analytics tab
**Then** an interactive `fl_chart` donut chart displays spend distribution with category percentages and currency totals
**And** tapping a category slice highlights the category name and total amount spent
**And** a monthly trend bar chart compares total spending month-over-month.

---

## Epic 6: Active EMI & Installment Plan Tracker

Users can track active equal monthly installments (tenure, remaining balance, monthly commitment) and view them automatically itemized within monthly card bill obligations.

### Story 6.1: Create & Manage Active Card EMIs

As a user who bought items on installment,
I want to record and manage my active EMIs linked to my credit cards,
So that I have full visibility into my recurring installment commitments.

**Acceptance Criteria:**

**Given** an active credit card in the wallet
**When** the user taps "Add EMI", enters title, principal amount, monthly installment amount, total tenure in months, and start date
**Then** an EMI record is created in SQLite `emis` linked to `card_id`
**And** the EMI list displays the title, remaining installments count, remaining principal, and projected completion date
**And** when remaining installments reach 0, status automatically changes to `completed`.

### Story 6.2: Itemize Monthly EMI Installments in Card Bills

As a cardholder reviewing my upcoming bill,
I want to see an itemized list of all active EMIs due in that statement cycle,
So that I understand exactly what portion of my monthly bill is committed to installments.

**Acceptance Criteria:**

**Given** one or more active EMIs linked to a credit card
**When** the user inspects the card's current or upcoming bill details
**Then** an "Active Installments" section itemizes each active EMI title and its monthly installment contribution
**And** the total sum of monthly installments is displayed as part of the bill breakdown.

---

## Epic 7: Biometric Security & Data Sovereignty

Users can lock the application with biometric authentication (Fingerprint / Face ID / PIN) with background task-switcher obscuring, and create encrypted portable backups (AES-256-GCM) with full restore capabilities.

### Story 7.1: Biometric App Lock & Task-Switcher Privacy Shield

As a privacy-focused user,
I want to lock the app with biometrics and prevent sensitive balances from showing in the app switcher,
So that nobody can view my financial figures without my permission.

**Acceptance Criteria:**

**Given** the user toggles "Biometric Lock" ON in Settings
**When** the app is backgrounded or minimized
**Then** an opaque privacy protection overlay immediately obscures the UI so financial data is hidden in the OS multitasking switcher
**And** when the app is resumed after > 30 seconds, a `local_auth` prompt (Fingerprint / Face ID / Device Passcode) is presented
**And** access to the app is granted only upon successful authentication.

### Story 7.2: Encrypted Local Database Backup & Restore

As a user who values data ownership,
I want to export an encrypted backup of my data and restore it on another phone,
So that I never lose my financial history even though there is no cloud database.

**Acceptance Criteria:**

**Given** the user has cards, bills, transactions, and EMIs saved in the local database
**When** the user selects "Export Backup" and provides an optional passphrase
**Then** a versioned JSON envelope (`schema_version: 1`, AES-256-GCM encrypted, with SHA-256 checksum) is generated and shared via the system share sheet
**And** when the user selects "Restore Backup" and imports a valid backup file, the archive is decrypted and verified, populating the SQLite database
**And** an invalid, corrupted, or tampered backup file aborts gracefully with a clear error without corrupting existing data.
