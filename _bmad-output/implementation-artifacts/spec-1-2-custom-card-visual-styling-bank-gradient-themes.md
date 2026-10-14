---
title: 'Story 1.2: Custom Card Visual Styling & Bank Gradient Themes'
type: 'feature'
created: '2026-10-14'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'd764a1c0e6dda6e600723dc160b1fcad5fef2b17'
context:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-credit_bill_system-2026-10-13/ARCHITECTURE-WALKTHROUGH.md'
  - '_bmad-output/planning-artifacts/prds/prd-credit_bill_system-2026-10-13/prd.md'
  - '_bmad-output/implementation-artifacts/spec-1-1-project-bootstrap-sqlite-database-setup-with-add-card-flow.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Cards currently have a persisted gradient index and a gradient-rendering wallet card, but users cannot choose a theme during card creation; the required live preview and carousel/detail presentation are not defined by an implementation-ready story spec.

**Approach:** Let users choose from the existing predefined gradient themes while creating a card, update a card preview immediately, and persist the selected palette index. Show the saved gradient, a bank icon, and network badge in a horizontally navigable wallet carousel and a card detail view.

## Boundaries & Constraints

**Always:**
- Preserve offline-first operation, Feature-First Clean Architecture, and existing card data privacy constraints.
- Keep styling selection in Presentation and persistence through existing card domain/data boundaries; do not make widgets access SQLite directly.
- Keep existing Story 1.1 behavior and tests intact.
- Use the existing predefined palette only; retain `color_gradient_idx` as the persisted selection and keep its palette-index meaning stable.
- Story 1.2 covers theme choice during card creation only. The epic's “creating or editing a card” criterion explicitly includes existing-card edits; by the user's scope decision, defer theme editing of an existing card to Story 1.3. This is a deliberate story-scope exception, not a technical or architecture constraint.
- Render a generic bank icon because the project contains no bank-logo assets or bank-to-logo mapping. Do not add external logo retrieval.

**Never:**
- Add CVV, expiration date, or full card number fields or storage.
- Add arbitrary/custom color picking or custom-color persistence.
- Add editing of existing cards or expand billing/portfolio behavior.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Select a theme during creation | User selects a predefined palette option | Preview immediately displays the selected gradient; selection is not persisted until save | N/A |
| Save and reload | Card is saved with a non-default palette index, then loaded from SQLite | The same theme index is restored and displayed in the carousel and detail view | Surface save/load failures through existing Bloc error behavior |
| Unknown stored theme | Card has an unsupported palette index | Card remains renderable using the defined safe fallback | N/A |

</frozen-after-approval>

## Code Map

- `lib/features/cards/domain/entities/card_entity.dart` -- existing integer `colorGradientIdx` field; retain the entity representation and default.
- `lib/features/cards/data/models/card_model.dart` and `lib/core/database/database_helper.dart` -- model maps `color_gradient_idx`; SQLite already has this integer column, so no migration is needed.
- `lib/features/cards/presentation/widgets/card_gradient_palette.dart` -- five existing `LinearGradient` presets and `getGradient` fallback; reuse and expose stable display names for selection.
- `lib/features/cards/presentation/widgets/card_item_widget.dart` -- shared card face with the chosen gradient, bank name, and network text badge; add a generic bank icon and reuse it for carousel, preview, and detail.
- `lib/features/cards/presentation/pages/add_card_page.dart` -- existing palette swatches and `_selectedGradientIdx` submission; add a live card preview without changing card validation or sensitive-data boundaries.
- `lib/features/cards/presentation/pages/wallet_home_page.dart` -- currently renders cards in a vertical list; retain the aggregate credit summary and empty state while presenting loaded cards in a horizontal `PageView` carousel with detail navigation.
- `lib/features/cards/presentation/pages/card_detail_page.dart` -- new presentation-only view to render the selected card face; receive the already loaded `CardEntity`, with no repository/database access in the widget.
- `lib/features/cards/presentation/bloc/card_bloc.dart` -- existing load/add flow persists and reloads the entity; no new domain mutation/use case is needed.
- `test/widget_test.dart`, `test/features/cards/data/database_card_flow_test.dart`, and `test/features/cards/data/models/card_model_test.dart` -- extend coverage and preserve every existing Story 1.1 assertion/test.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/cards/presentation/widgets/card_gradient_palette.dart` -- name and expose the existing predefined themes without changing persisted index meanings -- present consistent selectable options.
- [x] `lib/features/cards/presentation/widgets/card_item_widget.dart` -- render selected gradient, generic bank icon, and network badge; allow preview-specific display values -- share the same visual card face across surfaces.
- [x] `lib/features/cards/presentation/pages/add_card_page.dart` -- show selectable presets and a live preview reflecting the current selected index -- let users see their creation choice before save.
- [x] `lib/features/cards/presentation/pages/wallet_home_page.dart` and `lib/features/cards/presentation/pages/card_detail_page.dart` -- show saved cards in a horizontal carousel and navigate to a styled detail view -- satisfy both required presentation contexts.
- [x] `lib/features/cards/domain/`, `data/`, and `core/database/` -- reuse existing `color_gradient_idx` end-to-end without unrelated schema changes -- preserve the selected preset on save/reload.
- [x] `test/` -- cover preview changes, non-default theme persistence/reload, carousel/detail presentation, and fallback behavior -- keep all existing Story 1.1 tests intact.

**Acceptance Criteria:**
- Given the user is creating a card, when they select one of the predefined gradient themes, then the preview immediately displays the selected gradient.
- Given the user saves a card with a non-default predefined theme, when the card is loaded from SQLite, then its `color_gradient_idx` is restored and its selected gradient is displayed.
- Given a saved card is shown in the wallet carousel or its detail view, then it displays its selected gradient, a generic bank icon, and its network badge.
- Given a card has an unsupported persisted theme index, when its carousel, preview, or detail face is rendered, then the palette fallback renders without a crash.
- Given the user is editing an existing card, when they want to change its theme, then that capability is outside Story 1.2 and is deferred to Story 1.3.

## Implementation Notes

- Reused the existing `color_gradient_idx` property and SQLite column; no database migration or domain-layer change was required.
- Added named palette options, a live creation preview, a horizontal wallet carousel, a card detail page, and shared gradient/bank-icon/network-badge rendering.
- Added tests for live preview selection, selected-index submission, SQLite persistence/reload, carousel/detail styling, unsupported-index fallback, accessibility selection state, long network labels, carousel reload position, and large card counts.
- Review fixes aligned palette names with their existing colors, used scalable theme labels and selected semantics, constrained the network badge, preserved the carousel page across reloads, and made page indicators horizontally scrollable.
- Verification: `dart format` completed with no remaining changes; targeted tests passed (7); `flutter analyze` reported no issues; `flutter test` passed all 27 tests.

## Spec Change Log

## Review Triage Log

| Verdict | Route | Evidence |
|---|---|---|
| low | patch | Blind hunter found the “Obsidian Gold” and “Sunset Crimson” labels did not match their preset colors; renamed them to “Charcoal Lavender” and “Electric Violet” without changing gradient indices or colors. |
| low | patch | Edge hunter found long network labels could overflow the card face; constrained the badge with a flexible width and ellipsis and added a long-label widget regression test. |
| low | patch | Verification reviewer found preset 1’s name did not match its purple/lavender colors; the palette label now describes the existing colors accurately. |
| low | patch | Verification reviewer found preset 4’s name did not match its violet colors; the palette label now describes the existing colors accurately. |
| low | patch | Verification reviewer found a reload could misalign the carousel and active dot; an explicit `PageStorageKey` now preserves the page and index together, covered by a reload test. |
| low | patch | Verification reviewer found many cards could overflow the page-indicator row; indicators now scroll horizontally and the widget test exercises 80 cards. |
| low | patch | Verification reviewer found fixed 9px theme labels were difficult to read; labels now use the theme’s scalable `labelSmall` style. |
| low | patch | Verification reviewer found selected palette state was not exposed to assistive technology; options now set Semantics `selected`, asserted in the widget test. |
| low | patch | Verification reviewer found the spec and sprint tracker temporarily disagreed during review; the tracker now uses `review`, matching the spec’s `in-review` stage. |

## Design Notes

- Preserve existing preset ordering: `color_gradient_idx` is stored as an integer and existing cards rely on those indices. Do not reorder the current palette while adding display labels.
- The epic AC names a bank logo/icon; with no bank-logo assets or mapping in the current app, use Flutter's built-in bank icon. Do not introduce network access or remote assets.
- Existing-card theme editing is intentionally excluded by explicit user decision despite the epic criterion's “creating or editing” language; implement creation-only selection now, so Story 1.3 must include editing the existing theme.

## Verification

**Commands:**
- `dart format <changed Dart files>` -- expected: changed Dart files formatted.
- `flutter analyze` -- expected: no issues found.
- `flutter test <targeted Story 1.2 test files>` -- expected: all targeted tests pass.
- `flutter test` -- expected: all tests pass, including Story 1.1 SQLite flow tests.
