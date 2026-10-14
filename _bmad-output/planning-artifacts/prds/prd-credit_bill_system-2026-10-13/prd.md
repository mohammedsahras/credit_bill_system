---
title: "Credit Bill System"
status: draft
created: 2026-10-13
updated: 2026-10-13
---

# PRD: Credit Bill System

## 0. Document Purpose

This Product Requirements Document (PRD) defines the product vision, user journeys, functional requirements (FRs), non-functional requirements (NFRs), and scope boundaries for the **Credit Bill System** — a privacy-first, offline-capable mobile application built with Flutter for Android and iOS. 

This document serves as the single source of truth for product definition, downstream UX/UI design (`bmad-ux`), technical architecture (`bmad-architecture`), and sprint backlog creation (`bmad-create-epics-and-stories`). Implementation details and framework specifics are decoupled from requirement definitions and captured in [`addendum.md`](file:///D:/project/credit_bill_system/_bmad-output/planning-artifacts/prds/prd-credit_bill_system-2026-10-13/addendum.md).

---

## 1. Vision

Managing multiple credit cards across various issuing banks is stressful and error-prone. Users struggle with mismatched billing cycles, forget due dates, trigger punitive late payment fees (often exceeding 35-42% annualized interest), and inadvertently damage their credit ratings by pushing individual or cumulative credit utilization ratios beyond recommended limits. Existing commercial financial trackers frequently compromise user trust by demanding full bank logins, remote server synchronization, or invasive SMS permissions that transmit personal financial histories to cloud databases.

**Credit Bill System** solves this through a zero-compromise, **100% offline-first personal credit command center**. The app empowers users to visualize their multi-card portfolio, track billing due dates with intelligent countdowns, receive deterministic local notifications, monitor credit utilization safety gauges (<30%), track active installment plans (EMIs), and analyze monthly expenditures without transmitting a single byte of financial data over the internet.

---

## 2. Target User & Journeys

### 2.1 Jobs To Be Done (JTBD)

* **Functional:** "When my monthly credit card statements are generated, I want a single clear dashboard that shows total dues, minimum dues, and payment deadlines across all my cards, so that I never incur late payment fines or interest."
* **Emotional / Peace of Mind:** "When using my cards for daily expenses, I want to know my combined credit utilization ratio in real-time, so that I feel confident my credit score remains protected."
* **Control & Transparency:** "When I convert major purchases to EMIs, I want to track remaining monthly installments and interest charges, so that I have complete visibility into my long-term debt commitments."
* **Privacy Sovereignty:** "When I track my personal finances on my mobile phone, I want complete assurance that my financial records and card details are stored locally on my device and protected by biometrics."

### 2.2 Non-Users (v1)

* **Commercial Enterprise Fleet Cards:** Businesses seeking multi-employee expense reconciliation with corporate accounting sync (e.g., QuickBooks/SAP).
* **Automated Cloud Sync Enthusiasts:** Users who expect hands-off bank account scraping through third-party aggregators (e.g., Plaid/Yodlee) and are comfortable sharing bank credentials.

### 2.3 Key User Journeys

#### UJ-1: Rahul adds his primary credit cards and configures billing dates
* **Persona & Context:** Rahul, a 28-year-old software engineer holding three credit cards (HDFC Millennia, ICICI Amazon Pay, and SBI SimplyCLICK), frequently misses payment windows due to differing statement generation dates.
* **Entry State:** Fresh app install, biometric protection established.
* **Path:**
  1. Rahul taps the "Add Card" action on the home screen.
  2. He enters the issuing bank ("HDFC"), card nickname ("Millennia"), last 4 digits ("4821"), card network ("Visa"), total credit limit ("₹1,50,000"), billing statement day ("12th"), and payment due day ("2nd").
  3. He picks a customized Deep Navy card gradient to visually match his physical card.
  4. He saves the card and repeats the process for his other two cards.
* **Climax:** The home screen displays a realistic stacked wallet view of all three cards, with aggregate credit limit and cumulative available balance immediately visible.
* **Resolution:** The app automatically schedules background notification checks for upcoming due dates.
* **Edge Case:** If the statement day is entered as the 31st, the app dynamically handles months with fewer than 31 days (e.g., February and April).

#### UJ-2: Sneha logs a newly generated bill and records a partial payment
* **Persona & Context:** Sneha receives her monthly statement via email. Her total bill is $1,250 with a minimum due of $100, due in 18 days.
* **Entry State:** Authenticated via fingerprint, viewing the Card Details screen.
* **Path:**
  1. Sneha selects her card and taps "Update Bill".
  2. She inputs Total Due ($1,250) and Minimum Due ($100).
  3. The card dashboard updates immediately, displaying an orange countdown badge ("Due in 18 days") and updating her global credit utilization.
  4. One week later, Sneha pays $750 towards the card from her banking portal and opens the app to tap "Record Payment".
  5. She enters $750 as a Partial Payment.
* **Climax:** The app confirms the payment, adjusts the remaining due to $500, records the transaction in payment history, and maintains the countdown for the remaining balance.
* **Resolution:** When she later pays the remaining $500, the bill status turns green ("Paid in Full") and prompts to archive the cycle.

#### UJ-3: Ankit checks his credit health before making a large electronics purchase
* **Persona & Context:** Ankit wants to purchase a laptop for ₹80,000 using his credit card but wants to ensure his credit rating won't take a hit from over-utilization.
* **Entry State:** Authenticated on home dashboard.
* **Path:**
  1. Ankit checks the **Credit Utilization Health Gauge** at the top of his dashboard.
  2. The gauge indicates his current aggregate utilization is at 18% (Safe Zone: <30%).
  3. He taps into the gauge simulator to test adding an ₹80,000 purchase against his ₹3,00,000 total credit limit.
  4. The gauge updates to 44.6% and displays an alert: "High Utilization Warning (>30%)".
* **Climax:** Ankit realizes the purchase will exceed recommended credit utilization on a single card and decides to split the expense or pay off an existing balance first.
* **Resolution:** Ankit avoids credit score degradation.

#### UJ-4: Priya tracks a 6-month phone installment (EMI)
* **Persona & Context:** Priya bought a smartphone converted into a 6-month no-cost EMI of $150/month on her Chase Sapphire card.
* **Entry State:** Viewing the EMI & Loans tab.
* **Path:**
  1. Priya taps "Add EMI", selects her Chase card, and inputs the title ("iPhone 15"), total principal ($900), monthly installment ($150), and tenure (6 months).
  2. The app generates an amortization schedule showing installments 1 through 6 with start and end dates.
  3. Each month, the $150 installment is automatically highlighted in her upcoming card bill obligations.
* **Climax:** After 6 payments, the EMI automatically marks as "Completed", releasing the held credit limit back into her available credit.
* **Resolution:** Priya has transparent tracking of her committed monthly cash outflows.

---

## 3. Glossary

* **Card Profile:** A local entity representing a single credit card, characterized by bank name, nickname, last 4 digits, network, credit limit, billing day, and payment due day. No CVV or 16-digit Primary Account Number (PAN) is ever captured or stored.
* **Billing Statement Date (Cycle Date):** The recurring calendar day of the month on which the issuing bank closes the billing cycle and generates the monthly statement.
* **Payment Due Date:** The deadline by which at least the Minimum Amount Due must be received by the card issuer to avoid late payment penalties and derogatory credit reporting.
* **Grace Period:** The interest-free window between the Billing Statement Date and the Payment Due Date.
* **Total Amount Due:** The entire outstanding balance billed in the current statement cycle.
* **Minimum Amount Due:** The baseline payment required by the issuer (typically 5% of total balance or interest plus fees) to prevent delinquent status.
* **Credit Utilization Ratio:** The percentage of revolving credit being used relative to total credit limit:  
  $$\text{Utilization (\%)} = \left(\frac{\text{Total Current Balance}}{\text{Total Credit Limit}}\right) \times 100$$
* **Safe Utilization Threshold:** The internationally recognized ceiling of 30% aggregate utilization, above which credit rating agencies penalize credit scores.
* **Equal Monthly Installment (EMI):** A structured installment plan where a purchase is repaid over fixed monthly tenures with predetermined installment amounts and interest/processing fees.
* **Local Scheduled Notification:** An operating-system-level notification scheduled directly on the device using device clocks, functioning without network connectivity or remote push servers.
* **Local Backup Archive:** An encrypted, portable file (JSON format) containing all user-configured cards, bills, EMIs, and transactions, exportable via system share sheets.

---

## 4. Features & Functional Requirements

### 4.1 Multi-Card Wallet Management
**Description:** Users can add, style, view, edit, and organize multiple credit cards in an intuitive carousel or list view. Realizes UJ-1.

#### FR-1: Add New Credit Card
Users can create a new Card Profile by supplying:
* Issuing Bank Name (text or quick selector)
* Card Nickname (e.g., "Daily Groceries", "Travel Card")
* Last 4 Digits of card number (numeric, strictly 4 digits)
* Card Network (Visa, Mastercard, American Express, RuPay, Discover, Diners Club)
* Total Credit Limit (positive decimal value)
* Billing Statement Day of Month (1–31)
* Payment Due Day of Month (1–31)
* Card Theme / Gradient (pre-built palette or custom colors)

**Consequences (testable):**
* System rejects inputs where last 4 digits are not exactly 4 digits.
* System rejects limit values $\le 0$.
* Form fields explicitly disallow and offer no input mechanism for CVV, expiration date, or full 16-digit card number.
* Upon submission, card entity is atomically committed to the local database and visible on the dashboard in $<100\text{ ms}$.

#### FR-2: Custom Card Visual Styling
Users can choose card face gradient colors and styling to visually reflect the physical card plastic.
**Consequences (testable):**
* Selected gradient is rendered on both dashboard card widgets and detailed card views.
* Default fallback palette provides distinct color defaults for popular banks.

#### FR-3: Edit & Archive Card
Users can edit credit limits and billing cycle dates, or archive/delete cards.
**Consequences (testable):**
* Archiving a card preserves historical paid bills and transactions but excludes the card from active due date countdowns and current utilization calculations.
* Deleting a card displays a permanent destruction confirmation modal.

---

### 4.2 Bill Statement Tracking & Payment Lifecycle
**Description:** Centralized tracking of monthly bill statements, countdown timers to due dates, and settlement handling for full or partial payments. Realizes UJ-2.

#### FR-4: Log Monthly Statement Bill
Users can log statement details for any card:
* Total Amount Due
* Minimum Amount Due
* Statement Date & Due Date (pre-filled from card defaults with manual override option)
* Status: Unpaid (default)

**Consequences (testable):**
* Minimum Amount Due cannot exceed Total Amount Due.
* Days remaining until due date is recalculated dynamically based on system clock.
* Color coding applies automatically: Green ($>7$ days), Amber ($3\text{--}7$ days), Red ($<3$ days or overdue).

#### FR-5: Payment Settlement (Full & Partial)
Users can record payments towards any active bill statement:
* "Mark as Paid in Full" — settles remaining balance to zero, updates status to `Paid`.
* "Record Partial Payment" — user enters partial payment amount ($X$); remaining balance updates to $(\text{Total Due} - X)$; status updates to `Partially Paid`.

**Consequences (testable):**
* Overpayments (paying more than total due) trigger a confirmation modal asking if this represents a negative card balance.
* Payment timestamp, amount, and remaining balance are logged in the card's payment ledger.

#### FR-6: Automated Billing Cycle Rollover
When a bill is marked as `Paid in Full` or when the calendar date passes the billing cycle day:
**Consequences (testable):**
* The app automatically generates the draft for the subsequent month's statement cycle using the card's recurring rules.
* Prior statement moves into the historical statements archive.

---

### 4.3 Due Date Reminders & Local Notifications
**Description:** Offline, deterministic notifications that alert users before payment deadlines. Realizes UJ-1, UJ-2.

#### FR-7: Scheduled Local Alerts
The system schedules background notifications for each unpaid bill at configurable offsets:
* 7 days prior to due date
* 3 days prior to due date
* 1 day prior to due date
* On the Due Date (morning alert)

**Consequences (testable):**
* Notifications trigger reliably without internet connectivity or cellular data.
* If a bill is marked `Paid in Full`, all pending scheduled notifications for that specific bill cycle are immediately canceled.
* Notification tap directly opens the relevant Card Bill settlement screen.

---

### 4.4 Credit Utilization Health Monitor
**Description:** Holistic and per-card credit utilization analytics that guard against credit score damage. Realizes UJ-3.

#### FR-8: Real-Time Utilization Gauge & Threshold Alert
The app calculates and renders:
* Total Combined Credit Limit (sum of all active card limits)
* Total Outstanding Balance (sum of all unpaid card balances)
* Aggregate Credit Utilization Percentage
* Per-Card Utilization Percentage

**Consequences (testable):**
* When utilization is $\le 30\%$, the gauge displays in Green ("Optimal Health").
* When utilization exceeds $30\%$, the gauge displays in Amber/Red with an informative alert banner: "High Credit Utilization Warning: Keep under 30% to protect credit score."
* Includes a quick "What-If" simulator allowing users to test how an upcoming expense affects their ratio.

---

### 4.5 Spend Logging & Category Analytics
**Description:** Quick manual expense logging categorized by spend type, coupled with monthly breakdown charts.

#### FR-9: Log Categorized Card Expense
Users can log transactions against any active card:
* Amount
* Date & Time
* Category (Dining, Groceries, Fuel, Utilities, Shopping, Travel, Entertainment, Healthcare, Other)
* Merchant / Note

**Consequences (testable):**
* Logging an expense automatically increments the card's current unbilled balance.
* Supports customizable custom categories.

#### FR-10: Monthly Visual Spend Breakdown
Users can view monthly analytics via visual donut/bar charts:
**Consequences (testable):**
* Visual breakdown by category percentage and total currency spend.
* Month-over-month trend comparison.

---

### 4.6 EMI & Loan Installment Tracker
**Description:** Tracks credit card purchases converted into equal monthly installments. Realizes UJ-4.

#### FR-11: Create & Manage Active EMIs
Users can record an EMI attached to a specific card:
* Title / Merchant (e.g. "Laptop purchase")
* Associated Credit Card
* Total Principal Amount
* Monthly Installment Amount
* Total Tenure (e.g., 3, 6, 9, 12, 24 months)
* Remaining Installments Count
* Start Date

**Consequences (testable):**
* System calculates remaining principal and projected completion date.
* Completed installments are incremented each month until tenure reaches zero.

#### FR-12: EMI Integration with Monthly Bill
**Consequences (testable):**
* Active EMI monthly installments are automatically listed as an itemized breakdown when reviewing the card's upcoming bill.

---

### 4.7 Security & Biometric Lock
**Description:** Protects personal financial information from unauthorized local access.

#### FR-13: App Lock with Biometrics & PIN Fallback
**Consequences (testable):**
* Users can toggle Biometric Lock on/off in Settings.
* When enabled, app backgrounding (>30 seconds) triggers biometric challenge (Fingerprint / Face ID) or device passcode fallback upon resume.
* App screen is obscured/blurred in the OS multitasking app switcher when lock is active.

---

### 4.8 Data Sovereignty & Local Backup
**Description:** Empowers users with total data ownership and portable offline backups.

#### FR-14: Encrypted JSON/CSV Backup & Restore
**Consequences (testable):**
* Users can export a complete database archive into an encrypted JSON or plaintext CSV file via standard OS share sheets (Save to Files, AirDrop, Google Drive, etc.).
* Users can import a backup file on a fresh install to restore all cards, bills, EMIs, and transaction history.
* Malformed or tampered backup files fail gracefully with clear validation error messages before touching the database.

---

## 5. Non-Goals (Explicit)

* **No Card Number / CVV / Expiration Date Storage:** The app will never request, process, or store full 16-digit PANs or 3-digit CVV/CVC codes.
* **No Direct Payment Processing / Money Movement:** The app is an informational tracker and command center; it does not process wire transfers, credit card payments, or integrate banking rails (users pay through their official banking apps/websites).
* **No Cloud Account or Remote Server Sync (v1):** The app operates strictly offline-first. There are no remote user accounts, passwords, or cloud database servers in v1.
* **No Automated SMS Scraping (v1):** Android SMS inbox scraping is explicitly out of scope for v1 to ensure 100% cross-platform parity with iOS and maintain complete user privacy.
* **No Live Foreign Currency FX Conversion (v1):** The app uses the user's local operating system currency symbol; cross-currency live exchange rate lookups are deferred.

---

## 6. MVP Scope

### 6.1 In Scope (v1)
* Multi-card wallet management (Add, edit, archive, visual gradients).
* Monthly statement logging with countdown timers to due dates.
* Full and partial payment recording with balance recalculations.
* Scheduled local push notifications (7d, 3d, 1d, and day-of).
* Credit Utilization health gauge with 30% warning threshold and simulator.
* Categorized spend logging with monthly visual charts.
* Active EMI & installment tracker integrated into card summaries.
* Biometric authentication lock (Fingerprint / Face ID).
* Encrypted local backup and restore (JSON/CSV).

### 6.2 Out of Scope for MVP (Deferred to v2)
* Automated bank statement PDF import and OCR parsing.
* Automated SMS transaction listening on Android.
* Credit card reward / cashback optimization engine.
* Multi-currency support and live FX rates.
* Optional end-to-end encrypted cloud sync (e.g., private iCloud / Google Drive sync).

---

## 7. Success Metrics & Non-Functional Requirements

### 7.1 Success Metrics
* **Due Date Adherence:** 0 missed due dates reported by active users.
* **Zero Data Leakage:** 0 bytes of financial data sent over the network.
* **App Launch Speed:** Cold start to interactive dashboard $< 800\text{ ms}$.
* **Backup Integrity:** 100% data fidelity on backup export and import test cycles.

### 7.2 Non-Functional Requirements (NFRs)

#### NFR-1: Performance & Responsiveness
* UI rendering consistently at 60 FPS (or 120 FPS on ProMotion displays) across all navigation flows.
* Local database queries execute in $< 25\text{ ms}$ even with 1,000+ logged transactions.

#### NFR-2: Security & Privacy
* Zero storage of sensitive PCI-DSS card credentials (CVV, full PAN).
* Local database encryption at rest using SQLCipher or platform-native keystore.
* Biometric authentication utilizes standard OS biometrics APIs (`local_auth`).

#### NFR-3: Reliability & Offline Autonomy
* 100% functional autonomy without an active internet connection.
* Notifications scheduled via OS notification daemon persist across device reboots.

#### NFR-4: Platform Support
* Android 8.0 (API level 26) and above.
* iOS 14.0 and above.
