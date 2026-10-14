# Architecture & Data Flow Walkthrough: Credit Bill System

This visual walkthrough accompanies [`ARCHITECTURE-SPINE.md`](file:///D:/project/credit_bill_system/_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md), detailing entity relationships, sequence interactions, and SQL database DDL for implementation.

---

## 1. Database Entity-Relationship Diagram (ERD)

```mermaid
erDiagram
    CARDS ||--o{ BILLS : "has monthly"
    CARDS ||--o{ TRANSACTIONS : "incurs"
    CARDS ||--o{ EMIS : "carries active"
    BILLS ||--o{ TRANSACTIONS : "optionally groups"

    CARDS {
        string id PK "UUID v4"
        string bank_name "e.g. HDFC, Chase"
        string nickname "e.g. Daily Rewards"
        string last_four "Strictly 4 digits"
        string network "Visa, Mastercard, Amex, RuPay"
        real total_limit "Credit limit amount"
        integer billing_day "1 to 31"
        integer due_day "1 to 31"
        integer color_gradient_idx "Visual theme index"
        integer is_archived "0 = active, 1 = archived"
        string created_at "ISO-8601 UTC"
    }

    BILLS {
        string id PK "UUID v4"
        string card_id FK "References CARDS(id) ON DELETE CASCADE"
        string cycle_month "Format YYYY-MM"
        string statement_date "ISO-8601 Date"
        string due_date "ISO-8601 Date"
        real total_amount_due "Total billed amount"
        real minimum_amount_due "Minimum payment"
        real amount_paid "Total settled so far"
        string status "unpaid | partially_paid | paid"
        string updated_at "ISO-8601 UTC"
    }

    TRANSACTIONS {
        string id PK "UUID v4"
        string card_id FK "References CARDS(id) ON DELETE CASCADE"
        string bill_id FK "Nullable: References BILLS(id)"
        real amount "Transaction amount"
        string category "Dining, Groceries, Fuel, etc."
        string timestamp "ISO-8601 UTC"
        string note "Merchant or note"
    }

    EMIS {
        string id PK "UUID v4"
        string card_id FK "References CARDS(id) ON DELETE CASCADE"
        string title "e.g. iPhone Purchase"
        real total_principal "Original amount"
        real monthly_installment "Monthly payment"
        integer tenure_months "Total installments"
        integer remaining_months "Installments remaining"
        string start_date "ISO-8601 Date"
        string status "active | completed"
    }
```

---

## 2. Core Interaction Sequence Diagrams

### Sequence 1: Logging a Bill & Reactive Notification Scheduling
When a user updates a monthly statement bill, the domain layer coordinates storage, utilization recalculation, and background notification scheduling.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant BillUI as Bill Presentation (Screen/Modal)
    participant BillBloc as BillBloc
    participant SaveBillUC as SaveBillUseCase
    participant BillRepo as BillRepositoryImpl
    participant SQLite as SQLite Database (sqflite)
    participant NotifService as NotificationReconciliationService

    User->>BillUI: Enters Total Due & Due Date, taps Save
    BillUI->>BillBloc: Add event SaveBillEvent(cardId, amount, dueDate)
    BillBloc->>SaveBillUC: execute(billEntity)
    SaveBillUC->>BillRepo: saveBill(billEntity)
    BillRepo->>SQLite: INSERT OR REPLACE INTO bills (...)
    SQLite-->>BillRepo: Success
    SaveBillUC->>NotifService: reconcileForBill(billEntity)
    NotifService->>NotifService: Cancel existing alarms for billId
    NotifService->>NotifService: Schedule 7d, 3d, 1d, and 0d local alarms
    BillRepo-->>SaveBillUC: Right(savedBill)
    SaveBillUC-->>BillBloc: Right(savedBill)
    BillBloc->>BillUI: Emit BillSavedState(bill)
    BillUI-->>User: Display updated countdown badge & success toast
```

---

### Sequence 2: Bill Payment Settlement (Partial or Full)
When a bill is paid, the balance is recalculated and notifications are cancelled if settled in full.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant SettleModal as Settle Payment Modal
    participant BillBloc as BillBloc
    participant SettleUC as SettleBillPaymentUseCase
    participant BillRepo as BillRepositoryImpl
    participant SQLite as SQLite Database
    participant NotifService as NotificationReconciliationService

    User->>SettleModal: Taps "Pay in Full" (or inputs Partial Amount)
    SettleModal->>BillBloc: SettlePaymentEvent(billId, amountPaid)
    BillBloc->>SettleUC: execute(billId, amountPaid)
    SettleUC->>BillRepo: recordPayment(billId, amountPaid)
    alt Full Payment Settled
        BillRepo->>SQLite: UPDATE bills SET amount_paid = total_amount_due, status = 'paid'
        SettleUC->>NotifService: cancelPendingAlerts(billId)
        NotifService->>NotifService: flutter_local_notifications.cancel(alarmIds)
    else Partial Payment Settled
        BillRepo->>SQLite: UPDATE bills SET amount_paid = amount_paid + X, status = 'partially_paid'
        SettleUC->>NotifService: rescheduleWithRemaining(billId, remainingAmount)
    end
    BillRepo-->>SettleUC: Right(updatedBill)
    SettleUC-->>BillBloc: Right(updatedBill)
    BillBloc->>SettleModal: Emit BillPaymentSuccessState(updatedBill)
    SettleModal-->>User: Dismiss modal, card turns Green
```

---

### Sequence 3: Credit Utilization Calculation & 30% Threshold Alert
Real-time credit health calculation ensures users stay informed on revolving debt.

```mermaid
sequenceDiagram
    autonumber
    participant Dashboard as DashboardScreen
    participant AnalyticsBloc as AnalyticsBloc
    participant CalcUtilUC as CalculateUtilizationUseCase
    participant CardRepo as CardRepositoryImpl
    participant BillRepo as BillRepositoryImpl

    Dashboard->>AnalyticsBloc: FetchCreditHealthEvent()
    AnalyticsBloc->>CalcUtilUC: execute()
    CalcUtilUC->>CardRepo: getActiveCards()
    CardRepo-->>CalcUtilUC: List<CardEntity> (Total Limit = Sum of limits)
    CalcUtilUC->>BillRepo: getUnpaidBalances()
    BillRepo-->>CalcUtilUC: Total Unpaid Balance = Sum of active balances
    CalcUtilUC->>CalcUtilUC: ratio = (Total Unpaid Balance / Total Limit) * 100
    alt ratio > 30.0%
        CalcUtilUC-->>AnalyticsBloc: CreditHealthEntity(ratio, isWarning = true, status = 'High Utilization')
    else ratio <= 30.0%
        CalcUtilUC-->>AnalyticsBloc: CreditHealthEntity(ratio, isWarning = false, status = 'Optimal')
    end
    AnalyticsBloc->>Dashboard: Emit CreditHealthLoaded(healthEntity)
    Dashboard->>Dashboard: Renders Gauge (Green or Amber/Red Warning Banner)
```

---

## 3. SQLite DDL Implementation Blueprint

```sql
-- Enable foreign key constraints
PRAGMA foreign_keys = ON;

-- 1. Cards Table
CREATE TABLE IF NOT EXISTS cards (
    id TEXT PRIMARY KEY,
    bank_name TEXT NOT NULL,
    nickname TEXT NOT NULL,
    last_four TEXT NOT NULL CHECK(length(last_four) = 4),
    network TEXT NOT NULL,
    total_limit REAL NOT NULL CHECK(total_limit > 0),
    billing_day INTEGER NOT NULL CHECK(billing_day BETWEEN 1 AND 31),
    due_day INTEGER NOT NULL CHECK(due_day BETWEEN 1 AND 31),
    color_gradient_idx INTEGER NOT NULL DEFAULT 0,
    is_archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
);

-- 2. Bills Table
CREATE TABLE IF NOT EXISTS bills (
    id TEXT PRIMARY KEY,
    card_id TEXT NOT NULL,
    cycle_month TEXT NOT NULL,
    statement_date TEXT NOT NULL,
    due_date TEXT NOT NULL,
    total_amount_due REAL NOT NULL CHECK(total_amount_due >= 0),
    minimum_amount_due REAL NOT NULL DEFAULT 0.0 CHECK(minimum_amount_due >= 0),
    amount_paid REAL NOT NULL DEFAULT 0.0 CHECK(amount_paid >= 0),
    status TEXT NOT NULL CHECK(status IN ('unpaid', 'partially_paid', 'paid')),
    updated_at TEXT NOT NULL,
    FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_bills_card_due ON bills(card_id, due_date);
CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);

-- 3. Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    card_id TEXT NOT NULL,
    bill_id TEXT,
    amount REAL NOT NULL CHECK(amount > 0),
    category TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    note TEXT,
    FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE,
    FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_transactions_card_time ON transactions(card_id, timestamp);

-- 4. EMIs Table
CREATE TABLE IF NOT EXISTS emis (
    id TEXT PRIMARY KEY,
    card_id TEXT NOT NULL,
    title TEXT NOT NULL,
    total_principal REAL NOT NULL CHECK(total_principal > 0),
    monthly_installment REAL NOT NULL CHECK(monthly_installment > 0),
    tenure_months INTEGER NOT NULL CHECK(tenure_months > 0),
    remaining_months INTEGER NOT NULL CHECK(remaining_months >= 0),
    start_date TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('active', 'completed')),
    FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
);
```
