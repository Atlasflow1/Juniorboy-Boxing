'use client';

import { useEffect, useState } from 'react';
import { where } from 'firebase/firestore';
import { call } from '@/lib/firebase';
import { formatMemberName, searchMemberUids, useMemberProfiles } from '@/lib/member-cache';
import { Row } from '@/lib/types';
import { dateLabel, timeLabel, asDate, errorMessage, downloadCSV } from '@/lib/utils';
import { Button, Notice, PageHeading, Loading, Empty, Modal } from '../ui';
import { usePaged, Pagination, Status } from './data';
import { MemberCell } from './member-cell';

export function AdminBookings() {
  return <ClassAdminBookings />;
}

function ClassAdminBookings() {
  const [status, setStatus] = useState('');
  const [member, setMember] = useState('');
  const [resolvedUid, setResolvedUid] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState('');
  const [exporting, setExporting] = useState(false);

  useEffect(() => {
    const trimmed = member.trim();
    if (!trimmed) {
      setResolvedUid('');
      return;
    }
    let active = true;
    if (!trimmed.includes('@') && !trimmed.includes(' ') && trimmed.length >= 20) {
      setResolvedUid(trimmed);
      return;
    }
    const timer = setTimeout(async () => {
      const uids = await searchMemberUids(trimmed);
      if (active) {
        setResolvedUid(uids[0] || '');
      }
    }, 300);
    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [member]);

  const targetUid = resolvedUid || (member.trim().length >= 20 ? member.trim() : '');
  const data = usePaged(
    'bookings',
    'date',
    [
      ...(status ? [where('status', '==', status)] : []),
      ...(targetUid ? [where('userId', '==', targetUid)] : []),
    ],
    `${status}:${targetUid}`
  );

  const profiles = useMemberProfiles(data.rows.map((b) => b.userId as string));

  const displayRows = data.rows.filter((b) => {
    const filter = member.trim().toLowerCase();
    if (!filter || targetUid) return true;
    const p = profiles[b.userId];
    const name = p ? formatMemberName(p.fullName, p.lastName).toLowerCase() : '';
    const email = (p?.email || '').toLowerCase();
    return (
      b.userId.toLowerCase().includes(filter) ||
      name.includes(filter) ||
      email.includes(filter)
    );
  });

  async function action(name: string, row: Row, extra = {}) {
    setBusy(row.id);
    setError('');
    try {
      await call(name, { bookingId: row.id, ...extra });
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy('');
    }
  }

  return (
    <>
      <PageHeading title="Bookings." />
      <div className="admin-toolbar">
        <input
          className="search-input"
          aria-label="Filter by member name, email, or ID"
          placeholder="Filter by name, email or ID"
          value={member}
          onChange={(e) => setMember(e.target.value)}
        />
        <label className="field">
          Status
          <select value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="">All statuses</option>
            {['confirmed', 'completed', 'cancelled', 'no-show'].map((s) => (
              <option key={s}>{s}</option>
            ))}
          </select>
        </label>
        <Button className="secondary" onClick={() => setExporting(true)}>
          Export CSV
        </Button>
      </div>

      {(error || data.error) && <Notice error>{error || data.error}</Notice>}

      {data.loading ? (
        <Loading />
      ) : displayRows.length ? (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Member</th>
                <th>Class</th>
                <th>Session</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {displayRows.map((b) => (
                <tr key={b.id}>
                  <td>
                    <MemberCell uid={b.userId} profile={profiles[b.userId]} />
                  </td>
                  <td>{b.className}</td>
                  <td>
                    {dateLabel(b.date)}
                    <br />
                    <span className="muted">{timeLabel(b.date)} PT</span>
                  </td>
                  <td>
                    <Status row={b} />
                  </td>
                  <td>
                    <div className="row">
                      {b.status === 'confirmed' && (
                        <>
                          {asDate(b.endAt) <= new Date() && (
                            <>
                              <Button
                                className="small"
                                disabled={busy === b.id}
                                onClick={() =>
                                  action('markBookingCompleted', b, { status: 'completed' })
                                }
                              >
                                Present
                              </Button>
                              <Button
                                className="secondary small"
                                disabled={busy === b.id}
                                onClick={() =>
                                  action('markBookingCompleted', b, { status: 'no-show' })
                                }
                              >
                                No-show
                              </Button>
                            </>
                          )}
                          <Button
                            className="text small"
                            disabled={busy === b.id}
                            onClick={() => {
                              const reason = window.prompt('Cancellation reason');
                              if (reason) action('cancelBooking', b, { reason });
                            }}
                          >
                            Cancel
                          </Button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <Empty>No matching bookings.</Empty>
      )}

      <Pagination data={data} />
      {exporting && <ExportDialog collection="bookings" onClose={() => setExporting(false)} />}
    </>
  );
}

export function ExportDialog({
  collection,
  onClose,
}: {
  collection: 'bookings' | 'payments';
  onClose: () => void;
}) {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  return (
    <Modal title="Export CSV" onClose={onClose}>
      <form
        className="stack"
        onSubmit={async (e) => {
          e.preventDefault();
          const f = new FormData(e.currentTarget);
          setBusy(true);
          try {
            const result = await call<{ csv: string; filename: string }>('exportBookingsCSV', {
              collection,
              from: new Date(String(f.get('from'))).toISOString(),
              to: new Date(+new Date(String(f.get('to'))) + 86400000).toISOString(),
            });
            downloadCSV(result.csv, result.filename);
            onClose();
          } catch (e) {
            setError(errorMessage(e));
          } finally {
            setBusy(false);
          }
        }}
      >
        <label className="field">
          From
          <input name="from" type="date" required />
        </label>
        <label className="field">
          Through
          <input name="to" type="date" required />
        </label>
        {error && <Notice error>{error}</Notice>}
        <Button busy={busy}>Download CSV</Button>
      </form>
    </Modal>
  );
}
