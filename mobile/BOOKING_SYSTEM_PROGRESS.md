# Booking System Progress

Tracking implementation of the admin-controlled session slots spec (`mobile/rx.md`). See the approved plan for full context.

## Status: In progress

## Part 1 — `saveSchedule` explicit end time + capacity rule enforcement
Status: **Done**

Changed `functions/src/bookings.ts` `saveSchedule`:
- Input schema now takes `date` (yyyy-MM-dd), `startTime`, `endTime` (both HH:mm) instead of one combined ISO datetime. End time is no longer derived from the class's `durationMinutes` — both start and end come directly from the admin.
- Server-side capacity rule enforced via new `capacityForType` map: Private must be exactly 1, Duo exactly 2, Group is the admin's chosen number (1–1000, unchanged range). Mismatches are rejected with a clear error naming the required count.
- New validation: end time must be after start time.
- All existing guards kept as-is (future-date check, "can't change time/class once booked," "capacity below current bookings").
- Added `trainingTypeLabel`/`TrainingType` import from `./domain` (already existed from the earlier per-type-balance work, no new file).

This is a **breaking change to the `saveSchedule` callable's input shape** — both callers (web admin, and the new mobile admin screen in Part 3) must send `{date, startTime, endTime}` instead of `{date}`. Web updated in Part 2.

`npx tsc --noEmit` in `functions/`: clean.

## Part 2 — Web admin session editor (date/start/end + capacity lock)
Status: **Done**

Changed `web/src/components/admin/schedule.tsx`, `ScheduleEditor`:
- Session kind: replaced the single `datetime-local` input with 3 separate inputs (Date, Start time, End time), matching the new `saveSchedule` call shape (`date, startTime, endTime` instead of one combined ISO string).
- Program `<select>` (shown for both `session` and `template` kinds) is now controlled via a new `classId` state, and its options show the program's training type inline (e.g. "Junior Boxing (Private)") so the admin can see it before picking.
- New `pickClass()` handler: when a program is selected, auto-sets Max Spots to 1 (Private) or 2 (Duo); leaves it editable for Group.
- Max Spots field is now `readOnly` (not `disabled`, so it still submits) whenever the selected program requires a fixed capacity, with a small inline hint ("locked to 1 for Private"). This applies to both `session` and `template` kinds — the `program` kind's own default-capacity field is untouched (unrelated to a specific bookable slot).
- `npx tsc --noEmit` and full `npm run build` in `web/`: both clean.

Note: recurring templates are saved via a direct Firestore `setDoc` (not a callable), so the capacity rule is enforced here client-side only for templates — the authoritative server-side check lives in `saveSchedule` (Part 1), which covers one-off sessions (the case explicitly described in the spec's examples).

## Part 3 — Mobile "Add Session" admin screen
Status: **Done**

- `mobile/lib/features/admin/screens/template_editor_screen.dart`: added the same capacity-lock as web Part 2 — selecting a program auto-sets Max Spots to 1 (Private)/2 (Duo), field becomes `readOnly` with a "Locked to N" helper text; free-form for Group. Reused the existing orphaned-class-reference defensive pattern unchanged.
- `mobile/lib/data/repositories/admin_repository.dart`: new `saveSession()` wrapping the `saveSchedule` callable with its new `{classId, date, startTime, endTime, maxSpots}` shape (Part 1) — same thin-wrapper style as the existing `generateScheduleNow()`.
- New `mobile/lib/features/admin/screens/session_editor_screen.dart`: one-off dated session creation — Program dropdown (shows training type inline, e.g. "Junior Boxing (Private)"), Date picker (`showDatePicker`), Start/End time pickers (`showTimePicker`), Max Spots (same lock behavior). This is the capability mobile was missing — previously only recurring weekly class times could be created from the phone.
- `mobile/lib/features/admin/screens/admin_dashboard_screen.dart`: restructured the Class Schedule Times header (title no longer crammed into one `Row` with 3 buttons — now title on its own line, buttons in a `Wrap` to avoid overflow on narrow screens) and added the new "Add Session" button alongside the renamed "Add Class Time" and existing "Generate Next Week".

Scope note (confirmed in the plan): editing/cancelling an existing one-off session remains web-only (the admin calendar already does this fully) — mobile gains **create**, which was the actual gap. A newly created one-off session has no "Active" toggle in this form since it starts bookable with zero bookings by definition; pulling it from availability later uses the existing cancel flow (web calendar), same as today.

`flutter analyze`: clean (whole project, not just these files).

## Part 4 — Booking list cards show type/spots/price
Status: **Done**

- `mobile/lib/core/widgets/jbb_class_card.dart`: added a training-type badge (PRIVATE/GROUP/DUO) next to the time, changed "X spots available" to "X of Y spots available", and added the program's `priceLabel` line when set.
- `mobile/lib/features/booking/screens/book_class_screen.dart` (confirmation screen): added an explicit TRAINING TYPE row, AVAILABILITY now shows "X of Y spots" instead of just X, and a PRICE row when the program has a `priceLabel`.
- `web/src/components/schedule.tsx` class-list row: same three additions — training type badge, "X of Y spots" (or "Fully booked"), price line.
- `web/src/components/schedule.tsx` `BookingDialog`: added a TRAINING TYPE row, AVAILABILITY now shows "X of Y spots", added a PRICE row when present.

All data was already available on the joined row/program objects (`trainingType`, `maxSpots`, `priceLabel`) — no new Firestore reads needed anywhere.

`flutter analyze` + debug APK build: clean. `npx tsc --noEmit` + full `npm run build` in `web/`: clean. `npm run build` in `functions/`: clean.

## Verification
Status: **Done** (build/type-level; interactive device test still pending — see note)

Going through the spec's explicit final checklist:

1. **Run Flutter analyze.** Done — clean, whole project, after every part.
2. **Fix all errors related to your changes.** None found at any point.
3. **Null-safety.** Reviewed every new/changed read: `program['trainingType'] as String?` style casts all have `?? 'private'`/`?? 0`/`?? ''` fallbacks; `session_editor_screen.dart`'s `!` uses are only reached after an explicit non-null validation in `save()`; `firstWhere(..., orElse: () => {})` used everywhere a class lookup could miss (reused the existing defensive pattern from `template_editor_screen.dart`).
4. **Firestore consistency and race conditions.** No change needed here — confirmed `reserveBooking`, `releaseBooking`, `settleBooking`, and now `saveSchedule` all already run inside `db.runTransaction`, which is Firestore's built-in optimistic-concurrency mechanism (conflicting concurrent writes are retried automatically) — this was already correct before this spec and remains the enforcement point.
5. **Admin can create/edit session slots.** Create: both web (existing, now with explicit end time + capacity lock) and mobile (new `SessionEditorScreen`). Edit: web admin calendar (unchanged, already worked). Recurring weekly class times: both platforms, now with the same capacity lock.
6. **Users see correct training type and available spots.** Done in Part 4, both platforms, both the list view and the booking confirmation screen.
7. **Capacity limits.** Enforced server-side in two places: `saveSchedule` now rejects a mismatched Private/Duo capacity at creation time; `reserveBooking` (pre-existing, unchanged) rejects booking once `bookedSpots >= maxSpots`.
8. **Bookings store training type and session.** Pre-existing from the earlier per-type-balance work — confirmed still correct: `bookings/{id}` carries `trainingType`, `classId`, `scheduleId`, `className`, `category`.
9. **Update MD one final time.** This entry.

**Build/deploy status:** `functions` (`npm run build` + `firebase deploy --only functions`), `web` (`npm run build` + `firebase deploy --only hosting`) both deployed live. `mobile` built clean (debug APK) but **not yet installed/tested on the physical device** — no device was connected at the time this work finished. Next time the phone is connected: install the new build, then as admin do a live walkthrough of Admin Dashboard → Add Session (create a Private slot, confirm Max Spots locks to 1; try Group, confirm it's freely editable) and confirm a member sees the new slot with the right type/spots/price and can book it.
