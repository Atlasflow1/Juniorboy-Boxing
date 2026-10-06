Act as a Senior Flutter & Firebase Developer. I have an existing Boxing Gym app with outdated/conflicting code. 

CRITICAL INSTRUCTION FOR EXISTING CODE:
You must audit, refactor, and OVERWRITE/DELETE any obsolete, buggy, or duplicated code from previous implementations. Do not leave dead code or duplicate methods—cleanly update the existing codebase to align strictly with the new requirements below.

### Tech Stack & Architecture:
- Framework: Flutter
- Backend: Firebase (Authentication, Firestore, Firebase Storage)
- Payment Processing: Stripe Integration

---

### Execution Plan (6 Phased Milestones):
Execute this project strictly phase by phase. After completing each phase, summarize what was done, verify that there are no errors, and remind yourself (and me) of the next phase before proceeding to it.

#### Phase 1: Code Base Clean-up & Data Models Setup
- Audit existing code and delete outdated or unused widgets/logic.
- Define clean models:
  - UserModel: uid, fullName, dateOfBirth, profilePicUrl, role ("admin" | "trainee"), createdAt.
  - SessionModel: id, title, description, price (double), images (List<String>), type ("individual" | "duo" | "team"), startDate, endDate, startTime, endTime, maxParticipants (int), joinedUserIds (List<String>).

#### Phase 2: Firebase Authentication & User Profiles
- Refactor Auth flow ensuring full name, birth date, and profile photo upload are captured properly.
- Ensure Firestore user document sync.

#### Phase 3: Trainer/Admin CRUD Operations
- Implement full CRUD features for role == "admin" users:
  - Create, edit, and delete training sessions or long-term courses.
  - Custom pricing, participant limits (maxParticipants), flexible date/time schedules.
  - Image uploading to Firebase Storage.

#### Phase 4: Stripe Payment & Enrollment Integration
- Set up Stripe Payment Sheet integration.
- On successful payment, record the booking and append uid to joinedUserIds in Firestore.

#### Phase 5: Main Dashboard UI & Enrolled Avatars List
- Redesign the main dashboard with interactive Session Cards.
- Dynamic Card components:
  - Timing, schedule, price, session type.
  - Admin controls (Edit/Delete - visible only to Admin).
  - Join button (triggers Stripe payment for trainees).
  - Horizontal list of avatars/names showing enrolled members (e.g., 5-10 trainees).

#### Phase 6: Code Audit, Error Resolution & Final Testing
- Run full diagnostics, fix all compiler warnings/errors, and test all state flows.

---
START WITH PHASE 1 NOW. Once Phase 1 is fully complete, state the progress clearly and prompt to move to Phase 2.