- source_spec: none
  summary: Implement theme, appearance and display settings (light/dark/system theme, theme preview, font size, UI density, compact/comfortable layout, table and dashboard display preferences) with app-wide persistence.
  evidence: Split from the Settings module brief — independently shippable and mergeable as its own PR once the settings shell exists.
- source_spec: none
  summary: Add English/Tamil/Sinhala localization architecture via Flutter localization and wire existing screens to the selected language.
  evidence: Split from the Settings module brief — a self-contained l10n deliverable that touches every screen and can ship separately from settings UI.
- source_spec: none
  summary: Build security and privacy settings (change password with bcrypt/legacy compatibility, current-password verification, app lock, PIN, biometric auth, auto-lock timeout, login sessions, secure logout, confirmed delete account).
  evidence: Split from the Settings module brief — sensitive, independently testable work that overlaps Epic 7 and needs its own careful review.
- source_spec: none
  summary: Add persisted notification preferences (payment received/reminder, customer activity, new transaction, due payment, daily summary, sound, global enable/disable) without presenting them as functional until Epic 3 notification engine exists.
  evidence: Split from the Settings module brief — depends on Epic 3 stories still in backlog, so must be scoped and verified separately.
- source_spec: none
  summary: Implement storage and data settings (database information, safe validated backup/restore with confirmation, customer/transaction/payment exports, storage info, clear cache, web-compatible download) — overlaps Epic 7 story 7-2.
  evidence: Split from the Settings module brief — safety-critical, independently shippable, and needs reconciliation with the existing encrypted backup story.
- source_spec: none
  summary: Add help and support plus about screens (FAQ, user guide, contact support, report a problem, about CreditBill with logo, version, developer info, privacy policy, terms and conditions).
  evidence: Split from the Settings module brief — mostly static content, independently shippable from the settings shell.
