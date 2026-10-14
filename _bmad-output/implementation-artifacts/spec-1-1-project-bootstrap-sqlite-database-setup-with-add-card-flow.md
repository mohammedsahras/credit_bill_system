---
title: 'Story 1.1: Project Bootstrap & SQLite Database Setup with Add Card Flow'
type: 'feature'
created: '2026-10-13'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: '9b11d528be0eb93b7bd67fae26e3b77dfedd16bd'
context:
  - '_bmad-output/implementation-artifacts/epic-1-context.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Flutter project is a fresh skeleton without state management, database persistence, or the ability for users to record credit cards. Users need an offline-first command center to add credit cards securely without leaking sensitive credentials.

**Approach:** Install pinned dependencies (`flutter_bloc`, `sqflite`, `path_provider`, `path`, `equatable`, `uuid`, `intl`), scaffold Feature-First Clean Architecture (`lib/core/` and `lib/features/cards/`), initialize the SQLite database engine with `cards` table, and implement the complete Add Card form with strict validation and zero CVV/PAN collection.

## Boundaries & Constraints

**Always:**
- Use UUID v4 text strings for `cards.id`.
- Enforce `PRAGMA foreign_keys = ON;` in SQLite initialization.
- Strictly validate last four digits (exactly 4 numeric digits).
- Strictly validate total limit (> 0) and billing/due cycle days (1–31).
- Strictly follow Clean Architecture: Presentation (`flutter_bloc`) $\rightarrow$ Domain (Entities/UseCases) $\leftarrow$ Data (Models/Repositories/SQLite).

**Never:**
- Never create fields or capture CVV/CVC codes, card expiration dates, or full 16-digit card numbers.
- Never make external network requests (100% offline-first).
- Never allow UI widgets to directly query the database or instantiate data repositories.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Valid Card Addition | Bank: "HDFC", Nickname: "Millennia", Last 4: "4821", Network: "Visa", Limit: 150000, Billing Day: 12, Due Day: 2 | Card saved to SQLite `cards` table; UI emits `CardAddedState` and displays card in wallet list | N/A |
| Invalid Last 4 Digits | Last 4: "482" (3 digits) or "abcd" | Form rejects submission; displays inline error: "Must be exactly 4 digits" | Form validation error |
| Non-Positive Limit | Limit: 0 or -500 | Form rejects submission; displays inline error: "Credit limit must be greater than zero" | Form validation error |
| Invalid Cycle Days | Billing Day: 0 or 32 | Form rejects submission; displays inline error: "Day must be between 1 and 31" | Form validation error |
| Empty Wallet Home | Zero cards in SQLite | Home screen displays clean Empty Wallet view with "Add Your First Card" call to action | N/A |

</frozen-after-approval>

## Code Map

- `pubspec.yaml` -- Add dependencies (`flutter_bloc`, `sqflite`, `path_provider`, `path`, `equatable`, `uuid`, `intl`)
- `lib/core/database/database_helper.dart` -- SQLite open helper with `cards` table DDL and foreign keys pragma
- `lib/core/errors/failures.dart` -- Base `Failure`, `DatabaseFailure`, `ValidationFailure` classes
- `lib/features/cards/domain/entities/card_entity.dart` -- Pure Dart `CardEntity`
- `lib/features/cards/domain/repositories/card_repository.dart` -- Abstract repository contract
- `lib/features/cards/domain/usecases/add_card_usecase.dart` -- UseCase returning `Future<Either<Failure, CardEntity>>`
- `lib/features/cards/domain/usecases/get_cards_usecase.dart` -- UseCase returning `Future<Either<Failure, List<CardEntity>>>`
- `lib/features/cards/data/models/card_model.dart` -- SQLite map serialization
- `lib/features/cards/data/datasources/card_local_data_source.dart` -- Raw SQLite CRUD operations
- `lib/features/cards/data/repositories/card_repository_impl.dart` -- Concrete implementation of `CardRepository`
- `lib/features/cards/presentation/bloc/card_bloc.dart` -- Bloc handling `LoadCardsEvent` and `AddCardEvent`
- `lib/features/cards/presentation/pages/wallet_home_page.dart` -- Wallet home with empty state and cards list
- `lib/features/cards/presentation/pages/add_card_page.dart` -- Material 3 Add Card form
- `lib/main.dart` -- Dependency injection wiring and app entry point
- `test/features/cards/data/models/card_model_test.dart` -- Unit tests for card model serialization
- `test/features/cards/domain/usecases/add_card_usecase_test.dart` -- Unit tests for add card usecase

## Tasks & Acceptance

**Execution:**
- [x] `pubspec.yaml` -- Update dependencies -- Install required core and feature packages
- [x] `lib/core/database/database_helper.dart` -- Implement SQLite helper -- Manage database connection and schema creation
- [x] `lib/core/errors/failures.dart` -- Create Failure abstractions -- Standardize domain failure handling
- [x] `lib/features/cards/domain/entities/card_entity.dart` -- Implement CardEntity -- Immutable domain entity
- [x] `lib/features/cards/domain/repositories/card_repository.dart` -- Define repository interface -- Contract for card operations
- [x] `lib/features/cards/domain/usecases/add_card_usecase.dart` -- Implement AddCardUseCase -- Encapsulate validation and persistence logic
- [x] `lib/features/cards/domain/usecases/get_cards_usecase.dart` -- Implement GetCardsUseCase -- Retrieve active cards
- [x] `lib/features/cards/data/models/card_model.dart` -- Implement CardModel -- SQLite Map serialization/deserialization
- [x] `lib/features/cards/data/datasources/card_local_data_source.dart` -- Implement SQLite data source -- Direct database interactions
- [x] `lib/features/cards/data/repositories/card_repository_impl.dart` -- Implement CardRepositoryImpl -- Coordinate data source and map failures
- [x] `lib/features/cards/presentation/bloc/card_bloc.dart` -- Implement CardBloc, Event, State -- Unidirectional state management
- [x] `lib/features/cards/presentation/pages/wallet_home_page.dart` -- Build WalletHomePage -- Render card list and empty state
- [x] `lib/features/cards/presentation/pages/add_card_page.dart` -- Build AddCardPage -- Input form with validation
- [x] `lib/main.dart` -- Bootstrap app -- MultiBlocProvider and routing
- [x] `test/` -- Write tests -- Verify persistence, validation, state transitions, and widget behavior

**Acceptance Criteria:**
- Given an empty wallet, when the user launches the app, then an empty wallet state with "Add Card" button is displayed.
- Given the Add Card form, when the user enters valid card data, then a new card is stored in SQLite with a UUID and displayed in the wallet list.
- Given the Add Card form, when the user enters invalid card data (<4 digits, limit <= 0, invalid cycle day), then the form displays validation errors and blocks saving.
- Given the app code, no form field, model attribute, or database column exists for CVV, expiration date, or full 16-digit card numbers.

## Implementation Notes

<!-- Populated during implementation -->

## Spec Change Log

<!-- Populated during review loops -->

## Review Triage Log

| Verdict | Route | Evidence |
|---|---|---|
| medium | patch | Production `CreditBillApp` database/repository/BLoC wiring was not exercised: prior widget tests supplied their own mocked repository and the SQLite test assembled the stack directly. Added a root-level widget test that submits a card through production wiring and verifies it is stored and displayed. |
