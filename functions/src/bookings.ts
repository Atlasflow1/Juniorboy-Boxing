import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { z } from 'zod';
import { audit, callable, db, id, notify, now } from './platform';
import { canCancel, overlaps, reservationAvailable, trainingTypeLabel, type TrainingType } from './domain';

export async function reserveBooking(uid: string, scheduleId: string) {
  const ref = db.doc(`bookings/${uid}_${scheduleId}`);
  return db.runTransaction(async tx => {
    const [userSnap, scheduleSnap, previous] = await Promise.all([
      tx.get(db.doc(`users/${uid}`)), tx.get(db.doc(`schedule/${scheduleId}`)), tx.get(ref),
    ]);
    const user = userSnap.data(), session = scheduleSnap.data(), old = previous.data();
    if (!user?.isActive) throw new HttpsError('permission-denied', 'Account is not active.');
    if (old?.status === 'confirmed') return { bookingId: ref.id, alreadyBooked: true };
    const waiver = (await tx.get(db.doc('legalDocuments/waiver'))).data();
    if (waiver?.published && waiver.requiredOnBooking && (user.waiverVersion !== waiver.version || user.waiverParticipantName !== user.childName?.trim() || user.waiverParticipantAge !== user.childAge)) throw new HttpsError('failed-precondition', 'Read and sign the current Waiver and Disclaimer before booking.');
    if (old && old.status !== 'cancelled') throw new HttpsError('already-exists', 'This booking has already been attended.');
    if (!session || session.isCancelled || session.date.toMillis() <= Date.now()) throw new HttpsError('failed-precondition', 'This class is not available.');
    const classSnap = await tx.get(db.doc(`classes/${session.classId}`));
    if (!classSnap.data()?.isActive) throw new HttpsError('failed-precondition', 'This program is not active.');
    if (session.bookedSpots >= session.maxSpots) throw new HttpsError('resource-exhausted', 'This class is full.');
    const trainingType: TrainingType = classSnap.data()?.trainingType || 'private';
    const remainingField = `${trainingType}SessionsRemaining`, reservedField = `${trainingType}SessionsReserved`;
    if (reservationAvailable(user[remainingField] ?? 0, user[reservedField] ?? 0) < 1) throw new HttpsError('failed-precondition', `You have 0 remaining ${trainingTypeLabel(trainingType)} sessions. Purchase a ${trainingTypeLabel(trainingType)} package to book this class.`);
    const existing = await tx.get(db.collection('bookings').where('userId', '==', uid).where('status', '==', 'confirmed'));
    for (const b of existing.docs) {
      const data = b.data();
      if (overlaps(session.date.toMillis(), session.endAt.toMillis(), data.date.toMillis(), data.endAt.toMillis())) throw new HttpsError('already-exists', 'You already have a booking at this time.');
    }
    const revision = (old?.revision ?? 0) + 1;
    tx.set(ref, {
      userId: uid, scheduleId, classId: session.classId, className: classSnap.data()!.className,
      category: classSnap.data()!.category || '', trainingType,
      date: session.date, endAt: session.endAt, startTime: session.startTime, endTime: session.endTime,
      status: 'confirmed', bookedAt: now(), cancelledAt: null, cancelReason: null,
      creditDeducted: false, creditRefunded: false, revision,
    });
    tx.update(scheduleSnap.ref, { bookedSpots: session.bookedSpots + 1, updatedAt: now() });
    tx.update(userSnap.ref, {
      [reservedField]: (user[reservedField] ?? 0) + 1,
      sessionsReserved: (user.sessionsReserved ?? 0) + 1,
      updatedAt: now(),
    });
    notify(tx, `booking_${ref.id}_${revision}`, uid, 'Booking confirmed', `Your ${classSnap.data()!.className} session is booked.`, 'booking_confirmed', { bookingId: ref.id });
    return { bookingId: ref.id, alreadyBooked: false };
  });
}

export async function releaseBooking(actor: string, bookingId: string, reason = '', system = false) {
  return db.runTransaction(async tx => {
    const [bookingSnap, actorSnap, config] = await Promise.all([
      tx.get(db.doc(`bookings/${bookingId}`)), tx.get(db.doc(`users/${actor}`)), tx.get(db.doc('gymSettings/config')),
    ]);
    const booking = bookingSnap.data();
    if (!booking) throw new HttpsError('not-found', 'Booking not found.');
    const isAdmin = system || (actorSnap.data()?.role === 'admin' && actorSnap.data()?.isActive);
    if (!system && !actorSnap.data()?.isActive) throw new HttpsError('permission-denied', 'Account is not active.');
    if (!isAdmin && booking.userId !== actor) throw new HttpsError('permission-denied', 'This booking belongs to another member.');
    if (booking.status === 'cancelled') return { cancelled: true };
    if (booking.status !== 'confirmed') throw new HttpsError('failed-precondition', 'Only upcoming bookings can be cancelled.');
    if (!isAdmin && !canCancel(booking.date.toMillis(), Date.now(), config.data()?.cancellationPolicyHours ?? 24)) throw new HttpsError('failed-precondition', 'The cancellation window has closed. Contact the gym.');
    const [session, user] = await Promise.all([tx.get(db.doc(`schedule/${booking.scheduleId}`)), tx.get(db.doc(`users/${booking.userId}`))]);
    tx.update(bookingSnap.ref, { status: 'cancelled', cancelledAt: now(), cancelReason: reason, cancelledBy: actor });
    if (session.exists) tx.update(session.ref, { bookedSpots: Math.max(0, session.data()!.bookedSpots - 1), updatedAt: now() });
    if (user.exists) {
      const trainingType: TrainingType = booking.trainingType || 'private';
      const reservedField = `${trainingType}SessionsReserved`;
      tx.update(user.ref, {
        [reservedField]: Math.max(0, (user.data()![reservedField] ?? 0) - 1),
        sessionsReserved: Math.max(0, (user.data()!.sessionsReserved ?? 0) - 1),
        updatedAt: now(),
      });
    }
    notify(tx, `cancel_${bookingId}_${booking.revision}`, booking.userId, 'Booking cancelled', 'Your reserved session credit is available again.', 'booking_cancelled', { bookingId });
    audit(tx, actor, 'cancelBooking', bookingId, { reason });
    return { cancelled: true };
  });
}

export async function completeBooking(actor: string, bookingId: string, status: 'completed' | 'no-show') {
  await db.runTransaction(async tx => {
    const [admin, snapshot] = await Promise.all([tx.get(db.doc(`users/${actor}`)), tx.get(db.doc(`bookings/${bookingId}`))]);
    if (!admin.data()?.isActive || admin.data()?.role !== 'admin') throw new HttpsError('permission-denied', 'Administrator access required.');
    const booking = snapshot.data();
    if (!booking) throw new HttpsError('not-found', 'Booking not found.');
    if (booking.status === status) return;
    if (booking.status !== 'confirmed') throw new HttpsError('failed-precondition', 'Booking is not confirmed.');
    if (booking.endAt.toMillis() > Date.now()) throw new HttpsError('failed-precondition', 'Attendance can be marked after the class ends.');
    tx.update(snapshot.ref, { status, completedAt: now() });
    audit(tx, actor, 'markAttendance', bookingId, { status });
  });
  await settleBooking(bookingId);
  return { success: true };
}

export async function settleBooking(bookingId: string) {
  await db.runTransaction(async tx => {
    const snapshot = await tx.get(db.doc(`bookings/${bookingId}`));
    const b = snapshot.data();
    if (!b || !['completed', 'no-show'].includes(b.status) || b.creditDeducted) return;
    const user = await tx.get(db.doc(`users/${b.userId}`));
    if (!user.exists) { tx.update(snapshot.ref, { creditDeducted: true }); return; }
    const u = user.data()!;
    const trainingType: TrainingType = b.trainingType || 'private';
    const remainingField = `${trainingType}SessionsRemaining`, reservedField = `${trainingType}SessionsReserved`;
    if ((u[remainingField] ?? 0) < 1 || (u[reservedField] ?? 0) < 1 || u.sessionsRemaining < 1 || u.sessionsReserved < 1) throw new Error(`Invalid credit ledger for booking ${bookingId}`);
    const remaining = u[remainingField] - 1;
    tx.update(user.ref, {
      [remainingField]: remaining, [reservedField]: u[reservedField] - 1,
      sessionsRemaining: u.sessionsRemaining - 1, sessionsReserved: u.sessionsReserved - 1,
      updatedAt: now(),
    });
    tx.update(snapshot.ref, { creditDeducted: true, creditDeductedAt: now() });
    if (remaining <= 2) notify(tx, `low_${bookingId}`, b.userId, remaining === 0 ? 'Sessions used' : 'Sessions running low', `You have ${remaining} ${trainingTypeLabel(trainingType)} session credits remaining.`, remaining === 0 ? 'membership_expired' : 'membership_expiring');
  });
}

export const createBooking = callable(z.object({ scheduleId: id }), 'createBooking', ({ scheduleId }, uid) => reserveBooking(uid, scheduleId));
export const cancelBooking = callable(z.object({ bookingId: id, reason: z.string().max(500).default('') }), 'cancelBooking', ({ bookingId, reason }, uid) => releaseBooking(uid, bookingId, reason));
export const markBookingCompleted = callable(z.object({ bookingId: id, status: z.enum(['completed', 'no-show']).default('completed') }), 'attendance', ({ bookingId, status }, uid) => completeBooking(uid, bookingId, status), true);
export const deductSession = onDocumentUpdated({ document: 'bookings/{bookingId}', retry: true }, async event => {
  if (['completed', 'no-show'].includes(event.data?.after.data().status)) await settleBooking(event.params.bookingId);
});

export const cancelClass = callable(z.object({ scheduleId: id, reason: z.string().min(1).max(500) }), 'cancelClass', async ({ scheduleId, reason }, uid) => {
  const ref = db.doc(`schedule/${scheduleId}`);
  await db.runTransaction(async tx => {
    const session = await tx.get(ref);
    if (!session.exists) throw new HttpsError('not-found', 'Class session not found.');
    tx.update(ref, { isCancelled: true, cancelReason: reason, updatedAt: now() });
    audit(tx, uid, 'cancelClass', scheduleId, { reason });
  });
  await cancelSessionBookings(scheduleId, reason);
  return { success: true };
}, true);

export async function cancelSessionBookings(scheduleId: string, reason: string) {
  const bookings = await db.collection('bookings').where('scheduleId', '==', scheduleId).where('status', '==', 'confirmed').get();
  for (const booking of bookings.docs) await releaseBooking(booking.data().userId, booking.id, reason, true);
}
export const onClassCancelled = onDocumentUpdated({ document: 'schedule/{scheduleId}', retry: true }, async event => {
  if (event.data?.after.data().isCancelled && !event.data.before.data().isCancelled) await cancelSessionBookings(event.params.scheduleId, event.data.after.data().cancelReason || 'Class cancelled by gym');
});

const timeField = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);
const capacityForType: Record<TrainingType, number | null> = { private: 1, duo: 2, group: null };
export const saveSchedule = callable(z.object({ scheduleId: id.optional(), classId: id, date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/), startTime: timeField, endTime: timeField, maxSpots: z.number().int().min(1).max(1000) }), 'saveSchedule', async (input, uid) => {
  const { DateTime } = await import('luxon');
  const { zone } = await import('./platform');
  const ref = input.scheduleId ? db.doc(`schedule/${input.scheduleId}`) : db.collection('schedule').doc();
  await db.runTransaction(async tx => {
    const [old, c] = await Promise.all([tx.get(ref), tx.get(db.doc(`classes/${input.classId}`))]);
    if (!c.data()?.isActive) throw new HttpsError('failed-precondition', 'Select an active class.');
    const start = DateTime.fromFormat(`${input.date} ${input.startTime}`, 'yyyy-MM-dd HH:mm', { zone });
    const end = DateTime.fromFormat(`${input.date} ${input.endTime}`, 'yyyy-MM-dd HH:mm', { zone });
    if (!start.isValid || start.toMillis() <= Date.now()) throw new HttpsError('invalid-argument', 'Select a future time.');
    if (!end.isValid || end.toMillis() <= start.toMillis()) throw new HttpsError('invalid-argument', 'End time must be after the start time.');
    const trainingType: TrainingType = c.data()!.trainingType || 'private';
    const requiredCapacity = capacityForType[trainingType];
    if (requiredCapacity != null && input.maxSpots !== requiredCapacity) throw new HttpsError('invalid-argument', `${trainingTypeLabel(trainingType)} sessions must have exactly ${requiredCapacity} ${requiredCapacity === 1 ? 'spot' : 'spots'}.`);
    if ((old.data()?.bookedSpots ?? 0) > 0 && (old.data()!.date.toMillis() !== start.toMillis() || old.data()!.classId !== input.classId)) throw new HttpsError('failed-precondition', 'Cancel the booked session before changing its time or class.');
    if (input.maxSpots < (old.data()?.bookedSpots ?? 0)) throw new HttpsError('failed-precondition', 'Capacity is below current bookings.');
    tx.set(ref, { classId: input.classId, date: Timestamp.fromMillis(start.toMillis()), endAt: Timestamp.fromMillis(end.toMillis()), startTime: input.startTime, endTime: input.endTime, dayOfWeek: start.toFormat('cccc').toLowerCase(), maxSpots: input.maxSpots, bookedSpots: old.data()?.bookedSpots ?? 0, isRecurring: false, isCancelled: old.data()?.isCancelled ?? false, createdAt: old.data()?.createdAt ?? now(), updatedAt: now() });
    audit(tx, uid, 'saveSchedule', ref.id);
  });
  return { scheduleId: ref.id };
}, true);
