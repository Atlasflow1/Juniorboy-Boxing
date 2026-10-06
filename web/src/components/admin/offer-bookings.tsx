'use client';
import { FormEvent, useEffect, useRef, useState } from 'react';
import { DateTime } from 'luxon';
import { doc, getDoc } from 'firebase/firestore';
import { call, db } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { can } from '@/lib/permissions';
import { Row } from '@/lib/types';
import { asDate, dateLabel, errorMessage, money, timeLabel, zone } from '@/lib/utils';
import { Button, Empty, Loading, Modal, Notice, PageHeading } from '../ui';
import { useAuth } from '../providers';
import { useMemberProfiles } from '@/lib/member-cache';
import { Status } from './data';
import { MemberCell } from './member-cell';

type BookingDetails = { title: string; startAt: unknown; parent: string };

export function OfferAdminBookings() {
  const { profile } = useAuth();
  const allowRefund = can(profile, 'refund');
  const allowBook = can(profile, 'bookForMember');
  const canReadPayments = allowRefund || allowBook || can(profile, 'viewRevenue');
  const bookings = useRows('offerBookings', [], 'offer-bookings');
  const payments = useRows(canReadPayments ? 'payments' : null, [], 'offer-payments');
  const profiles = useMemberProfiles(bookings.rows.map(b => b.userId as string));
  const [details, setDetails] = useState<Record<string, BookingDetails>>({});
  const [status, setStatus] = useState('');
  const [date, setDate] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState('');
  const [book, setBook] = useState(false);
  const [refund, setRefund] = useState<Row | null>(null);
  const [cash, setCash] = useState<{ booking: Row; payment: Row } | null>(null);

  useEffect(() => {
    let active = true;
    const ids = [...new Set(bookings.rows.map(b => b.occurrenceId as string).filter(Boolean))];
    const users = [...new Set(bookings.rows.map(b => b.userId as string).filter(Boolean))];
    void Promise.all([
      Promise.all(ids.map(async id => {
        try { const snap = await getDoc(doc(db, 'offerOccurrences', id)); return [id, snap.data()] as const; }
        catch { return [id, undefined] as const; }
      })),
      Promise.all(users.map(async id => {
        try { const snap = await getDoc(doc(db, 'users', id)); return [id, snap.data()] as const; }
        catch { return [id, undefined] as const; }
      })),
    ]).then(([occurrences, parents]) => {
      if (!active) return;
      const occurrenceById = Object.fromEntries(occurrences);
      const parentById = Object.fromEntries(parents);
      setDetails(Object.fromEntries(bookings.rows.map(b => [b.id, {
        title: occurrenceById[b.occurrenceId]?.title || b.offerId || b.occurrenceId,
        startAt: occurrenceById[b.occurrenceId]?.startAt,
        parent: parentById[b.userId]?.fullName || b.userId,
      }])));
    });
    return () => { active = false; };
  }, [bookings.rows]);

  const rows = bookings.rows.filter(b => {
    if (status && b.status !== status) return false;
    const start = details[b.id]?.startAt;
    return !date || (start != null && DateTime.fromJSDate(asDate(start)).setZone(zone).toISODate() === date);
  }).sort((a, b) => {
    const left = details[a.id]?.startAt ?? a.createdAt;
    const right = details[b.id]?.startAt ?? b.createdAt;
    return asDate(right).getTime() - asDate(left).getTime();
  });

  async function submitRefund(reason: string) {
    if (!refund || !reason.trim()) return;
    setBusy(refund.id); setError('');
    try { await call('adminRefundOfferBooking', { bookingId: refund.id, reason: reason.trim() }); setRefund(null); }
    catch (e) { setError(errorMessage(e)); }
    finally { setBusy(''); }
  }
  async function submitCash(reference: string) {
    if (!cash || !reference.trim()) return;
    setBusy(cash.payment.id); setError('');
    try { await call('markCashRefunded', { paymentId: cash.payment.id, reference: reference.trim() }); setCash(null); }
    catch (e) { setError(errorMessage(e)); }
    finally { setBusy(''); }
  }

  return <>
    <PageHeading title="Session bookings." />
    <div className="admin-toolbar">
      <label className="field">Date<input type="date" value={date} onChange={e => setDate(e.target.value)} /></label>
      <label className="field">Status<select value={status} onChange={e => setStatus(e.target.value)}><option value="">All statuses</option>{['held','confirmed','refund_pending','refunded','expired','cancelled'].map(value => <option key={value} value={value}>{value.replace('_',' ')}</option>)}</select></label>
      {allowBook && <Button onClick={() => setBook(true)}>Book for member</Button>}
    </div>
    {(error || bookings.error || payments.error) && <Notice error>{error || bookings.error || payments.error}</Notice>}
    {bookings.loading ? <Loading /> : rows.length ? <div className="table-wrap"><table><thead><tr><th>Member</th><th>Session</th><th>Date</th><th>Seats</th><th>Amount</th><th>Status</th><th>Payment method</th><th>Actions</th></tr></thead><tbody>
      {rows.map(b => {
        const detail = details[b.id];
        const payment = payments.rows.find(p => p.id === b.currentPaymentId);
        return <tr key={b.id}>
          <td><MemberCell uid={b.userId} profile={profiles[b.userId]} /></td><td>{detail?.title || b.offerId}</td>
          <td>{detail?.startAt ? <>{dateLabel(detail.startAt)}<br /><span className="muted">{timeLabel(detail.startAt)} PT</span></> : '—'}</td>
          <td>{b.seats}</td><td>{money(b.amountCents || 0)}</td><td><Status row={b} /></td><td>{payment?.paymentMethod || '—'}</td>
          <td><div className="row">
            {allowRefund && b.status === 'confirmed' && <Button className="secondary small" onClick={() => setRefund(b)}>Refund</Button>}
            {allowRefund && payment?.status === 'refund_owed' && <Button className="secondary small" onClick={() => setCash({ booking: b, payment })}>Mark cash refunded</Button>}
          </div></td>
        </tr>;
      })}
    </tbody></table></div> : <Empty>No matching session bookings.</Empty>}
    {refund && <TextAction title="Refund session booking" label="Reason" busy={busy === refund.id} error={error} onClose={() => setRefund(null)} onSubmit={submitRefund} />}
    {cash && <TextAction title="Mark cash refunded" label="Refund reference" busy={busy === cash.payment.id} error={error} onClose={() => setCash(null)} onSubmit={submitCash} />}
    {book && <BookForMember onClose={() => setBook(false)} />}
  </>;
}

function TextAction({ title, label, busy, error, onClose, onSubmit }: { title: string; label: string; busy: boolean; error: string; onClose: () => void; onSubmit: (value: string) => Promise<void> }) {
  const [value, setValue] = useState('');
  return <Modal title={title} onClose={onClose}><form className="stack" onSubmit={e => { e.preventDefault(); void onSubmit(value); }}>
    <label className="field">{label}<input value={value} onChange={e => setValue(e.target.value)} minLength={1} maxLength={label === 'Reason' ? 500 : 200} required /></label>
    {error && <Notice error>{error}</Notice>}
    <Button busy={busy}>Confirm</Button>
  </form></Modal>;
}

function BookForMember({ onClose }: { onClose: () => void }) {
  const requestId = useRef<string | null>(null);
  const [seats, setSeats] = useState(1);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    requestId.current ??= crypto.randomUUID();
    const data = new FormData(event.currentTarget);
    const participants = Array.from({ length: seats }, (_, index) => ({
      name: String(data.get(`name-${index}`) || '').trim(),
      age: Number(data.get(`age-${index}`)),
    }));
    setBusy(true); setError('');
    try {
      await call('adminCreateOfferBooking', {
        userId: String(data.get('userId')).trim(), occurrenceId: String(data.get('occurrenceId')).trim(),
        seats, participants, method: data.get('method'), reference: String(data.get('reference')).trim(),
        requestId: requestId.current,
      });
      onClose();
    } catch (e) { setError(errorMessage(e)); }
    finally { setBusy(false); }
  }
  return <Modal title="Book for member" onClose={onClose}><form className="stack" onSubmit={submit}>
    <label className="field">Member ID<input name="userId" required /></label>
    <label className="field">Occurrence ID<input name="occurrenceId" required /></label>
    <label className="field">Seats<input type="number" min="1" max="50" value={seats} onChange={e => setSeats(Math.min(50, Math.max(1, Number(e.target.value) || 1)))} required /></label>
    {Array.from({ length: seats }, (_, index) => <div className="field-grid" key={index}>
      <label className="field">Participant {index + 1} name<input name={`name-${index}`} maxLength={60} required /></label>
      <label className="field">Age<input name={`age-${index}`} type="number" min="3" max="18" required /></label>
    </div>)}
    <label className="field">Method<select name="method"><option value="cash">Cash</option><option value="manual">Manual</option></select></label>
    <label className="field">Payment reference<input name="reference" maxLength={200} required /></label>
    {error && <Notice error>{error}</Notice>}
    <Button busy={busy}>Confirm booking</Button>
  </form></Modal>;
}
