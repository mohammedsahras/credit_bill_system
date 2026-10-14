# Epic 1 Context: Multi-Card Wallet & Portfolio Management

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Enable users to configure, customize, and manage their credit card portfolio in a clean, offline-first visual wallet with custom card styling, limit tracking, and strict privacy boundaries (zero CVV/PAN storage).

## Stories

- Story 1.1: Project Bootstrap & SQLite Database Setup with Add Card Flow
- Story 1.2: Custom Card Visual Styling & Bank Gradient Themes
- Story 1.3: Edit Card Parameters & Safe Archival/Deletion

## Requirements & Constraints

- Strictly offline-first; no remote server sync, zero network transmission.
- Capture only: Bank Name, Card Nickname, strictly 4 digits for Last Four, Network (Visa/Mastercard/Amex/RuPay), Total Credit Limit (> 0), Billing Cycle Day (1-31), Due Day (1-31), and gradient theme index.
- Absolute privacy boundary: form fields and database schema strictly disallow CVV, expiration date, or 16-digit card numbers.
- Archiving a card preserves historical data while excluding it from active countdowns and utilization.

## Technical Decisions

- Architecture: Feature-First Clean Architecture (`lib/features/cards/` with `domain/`, `data/`, and `presentation/` layers).
- State Management: `flutter_bloc` / Cubit for predictable unidirectional state flow.
- Database: `sqflite` SQLite database with `cards` table using UUID v4 primary keys (`TEXT PRIMARY KEY`).
- Pinned packages: `flutter_bloc: ^8.1.6`, `sqflite: ^2.3.3+1`, `path_provider: ^2.1.2`, `path: ^1.9.0`, `uuid: ^4.4.0`, `equatable: ^2.0.5`, `intl: ^0.19.0`.
- Errors handled via functional `Either<Failure, T>` return types.

## Cross-Story Dependencies

- Story 1.1 creates the database engine, `cards` table, and basic card entity/repo, which Stories 1.2 and 1.3 build upon.
- Epic 2 (Bills), Epic 5 (Transactions), and Epic 6 (EMIs) link to `cards.id` with `ON DELETE CASCADE`.
