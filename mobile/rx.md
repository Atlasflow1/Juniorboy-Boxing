Inspect the existing Flutter boxing gym app before making any changes.

IMPORTANT:
Do NOT create a new booking/session system if one already exists. If the functionality already exists, modify and extend the existing implementation instead of duplicating it.

I need to improve the existing session availability and booking system.

The main requirement is that the ADMIN controls exactly which training sessions are available for users to book.

ADMIN SESSION MANAGEMENT:
The Admin must be able to create and edit an available session/booking slot with:
- Date
- Start time
- End time
- Training type: Private, Duo, or Group
- Maximum number of participants
- Availability status

Training rules:
- Private Training = maximum 1 participant
- Duo Training = maximum 2 participants
- Group Training = Admin chooses the maximum number of participants

Examples:
October 10, 10:00–11:00 → Private → 1 participant
October 10, 11:00–12:00 → Duo → 2 participants
October 10, 18:00–19:00 → Group → 10 participants

USER BOOKING:
When the user opens the booking screen, do NOT show a generic "Session" without details.

Every available session must clearly display:
- Date
- Start and end time
- Training type: Private / Duo / Group
- Available spots
- Maximum spots
- Correct price or package requirement

When the user books:
- Reserve exactly one spot.
- Increase the participant count.
- Decrease the available spots.
- Prevent booking when the session reaches its maximum capacity.
- Store the exact selected session/slot in the booking.
- Store the training type in the booking.
- Store the package/session information used for the booking.

TRAINING TYPE IS IMPORTANT:
A Private booking must use a Private session.
A Duo booking must use a Duo session.
A Group booking must use a Group session.

Do not allow one training type to consume or book another training type.

PRICING / PACKAGES:
Keep the existing pricing and package system unless changes are required to connect it correctly with the training type.

Current pricing:
Private:
- 1 session = $85
- 5 sessions = $350
- 10 sessions = $600

Group:
- 1 session = $60

Duo:
- 1 session = $60

The main goal is NOT to redesign the prices. The main goal is to correctly connect the user's package/training type with the Admin-created available session.

EXISTING SYSTEM:
First inspect:
- Existing Admin session management
- Existing booking screen
- Existing booking models
- Existing package/subscription models
- Existing Firebase/Firestore collections
- Existing services and business logic

If any required functionality already exists, modify it instead of creating duplicate models, screens, collections, or services.

DATA SAFETY:
Do not delete existing user bookings or packages.
Do not break existing Firebase configuration.
Keep existing data compatible whenever possible.
Use safe Firestore updates/transactions where necessary to prevent two users from taking the same remaining spot at the same time.

UI:
Keep the existing design and navigation unless a UI change is required for this functionality.
Only add the necessary fields, labels, filters, and booking information.

IMPLEMENTATION PROCESS:
Work step by step.

After completing each major part, update the project's relevant documentation/progress Markdown file (MD) with:
- What was completed
- What files were changed
- Any important data/model changes
- Any remaining tasks or issues

Before moving to the next major part, inspect the current implementation and continue from the actual project state.

After all changes are completed:
1. Run Flutter analyze.
2. Fix all errors related to your changes.
3. Check for null-safety issues.
4. Check Firestore consistency and race conditions.
5. Verify Admin can create/edit session slots.
6. Verify users can see the correct training type and available spots.
7. Verify capacity limits work correctly.
8. Verify bookings store the correct training type and session.
9. Update the MD progress/documentation one final time.

Do not modify unrelated features.
Do not replace working systems unnecessarily.
Do not stop after partially implementing the requirements.