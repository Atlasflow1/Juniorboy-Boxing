'use client';

import { useState } from 'react';
import { DateTime } from 'luxon';
import { Timestamp, orderBy, where } from 'firebase/firestore';
import { call } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { useMemberProfiles } from '@/lib/member-cache';
import { can } from '@/lib/permissions';
import { Row, UserProfile } from '@/lib/types';
import { dateLabel, timeLabel, errorMessage, zone } from '@/lib/utils';
import { useAuth } from '../providers';
import { Button, Empty, Loading, Notice, PageHeading } from '../ui';
import { MemberCell } from './member-cell';

export function AdminRoster() {
  const today = DateTime.now().setZone(zone).startOf('day');
  const occurrences = useRows(
    'offerOccurrences',
    [
      where('startAt', '>=', Timestamp.fromMillis(today.toMillis())),
      where('startAt', '<', Timestamp.fromMillis(today.plus({ days: 7 }).toMillis())),
      orderBy('startAt'),
    ],
    today.toISODate()!
  );
  const [selected, setSelected] = useState('');
  const active =
    selected ||
    occurrences.rows.find((o) => o.status === 'open')?.id ||
    occurrences.rows[0]?.id ||
    '';

  return (
    <>
      <PageHeading eyebrow="Next 7 days" title="Roster." />
      {occurrences.error && <Notice error>{occurrences.error}</Notice>}
      {occurrences.loading ? (
        <Loading />
      ) : occurrences.rows.length ? (
        <div className="admin-toolbar">
          <label className="field">
            Session
            <select value={active} onChange={(e) => setSelected(e.target.value)}>
              {occurrences.rows.map((o) => (
                <option key={o.id} value={o.id}>
                  {dateLabel(o.startAt)} · {timeLabel(o.startAt)} · {o.title}
                  {o.status === 'cancelled' ? ' (cancelled)' : ''}
                </option>
              ))}
            </select>
          </label>
        </div>
      ) : (
        <Empty>No sessions in the next 7 days.</Empty>
      )}
      {active && <RosterTable occurrenceId={active} />}
    </>
  );
}

function RosterTable({ occurrenceId }: { occurrenceId: string }) {
  const { profile } = useAuth(),
    staff = profile as UserProfile | null;
  const bookings = useRows(
    'offerBookings',
    [
      where('occurrenceId', '==', occurrenceId),
      where('status', 'in', ['confirmed', 'refund_pending']),
    ],
    occurrenceId
  );
  const profiles = useMemberProfiles(bookings.rows.map((b) => b.userId as string));
  const [busy, setBusy] = useState('');
  const [error, setError] = useState('');

  async function checkIn(b: Row) {
    setBusy(b.id);
    setError('');
    try {
      await call('checkInBooking', { bookingId: b.id, manual: true });
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy('');
    }
  }

  if (bookings.loading) return <Loading />;
  return (
    <>
      {(error || bookings.error) && <Notice error>{error || bookings.error}</Notice>}
      {bookings.rows.length ? (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Member</th>
                <th>Participants</th>
                <th>Seats</th>
                <th>Status</th>
                <th>Check-in</th>
              </tr>
            </thead>
            <tbody>
              {bookings.rows.map((b: Row) => (
                <tr key={b.id}>
                  <td>
                    <MemberCell uid={b.userId} profile={profiles[b.userId]} />
                  </td>
                  <td>
                    {(b.participants ?? [])
                      .map((p: Row) => `${p.name} (${p.age})`)
                      .join(', ')}
                  </td>
                  <td>{b.seats}</td>
                  <td>{b.status}</td>
                  <td>
                    {b.checkedInAt ? (
                      `Checked in ${timeLabel(b.checkedInAt)}`
                    ) : b.status === 'confirmed' && can(staff, 'checkIn') ? (
                      <Button
                        className="secondary small"
                        busy={busy === b.id}
                        onClick={() => checkIn(b)}
                      >
                        Check in
                      </Button>
                    ) : (
                      '—'
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <Empty>No bookings for this session.</Empty>
      )}
    </>
  );
}
