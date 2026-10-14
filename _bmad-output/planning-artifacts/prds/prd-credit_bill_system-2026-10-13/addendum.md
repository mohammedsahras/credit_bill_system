# Technical Addendum: Credit Bill System

This addendum captures technical architecture context, library recommendations, and design decisions recorded during the PRD process for the **Credit Bill System** Flutter mobile application. These serve as inputs to `bmad-architecture`.

---

## 1. Architectural Strategy & Constraints

* **Framework:** Flutter 3.x with Dart 3 (Null Safety).
* **Architecture Pattern:** Clean Architecture / Feature-First structure with separation of Data, Domain, and Presentation layers.
* **State Management Candidates:** Bloc / Cubit or Riverpod for predictable, testable state transitions.
* **Storage Engine Candidates:**
  * **Option A (Recommended):** `Isar Database` or `sqflite` (with SQLCipher for encrypted database at rest).
  * Fast query performance, typed schema models, indexing on card IDs and due dates.
* **Local Notifications:**
  * `flutter_local_notifications` plugin for deterministic scheduling across Android and iOS without remote APNs / FCM push infrastructure.
  * Integration with timezone support (`timezone` package) to ensure alarms fire accurately at local device times.
* **Biometric Authentication:**
  * `local_auth` plugin supporting fingerprint, Face ID, and biometric prompt with system PIN fallback.
* **Analytics & Visualization:**
  * `fl_chart` for lightweight, fluid donut charts (spend categories) and historical monthly spending bar graphs.
* **Data Export & Encryption:**
  * AES-256 GCM encryption for exported backup JSON archives with user-supplied password or secure salt.

---

## 2. Alternatives Considered & Rejected

1. **Third-Party Bank Aggregation (Plaid / Yodlee):**
   * *Rejected:* Incurs subscription costs, introduces high regulatory compliance overhead, and violates the app's foundational promise of 100% offline privacy and zero data leakage.
2. **Automated Android SMS Parsing in v1:**
   * *Rejected:* Android SMS permissions (`READ_SMS`) trigger strict Google Play policy scrutiny, offer zero functionality on iOS (due to Apple security sandbox restrictions), and fail silently when bank SMS formats change. Kept as a potential post-MVP opt-in Android plugin.
3. **Card Rewards & Perks Engine in v1:**
   * *Rejected:* Maintaining reward catalog accuracy (points per dollar, reward multipliers across hundreds of bank cards) requires ongoing scraping and adds complexity. Deferred to v2.
