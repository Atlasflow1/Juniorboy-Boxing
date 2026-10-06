'use client';

import { FormEvent, useState } from 'react';
import { useAuth } from '../providers';
import { can } from '@/lib/permissions';
import { call } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { useMemberProfiles } from '@/lib/member-cache';
import { Row } from '@/lib/types';
import { dateLabel, errorMessage, money, timeLabel } from '@/lib/utils';
import { Button, Empty, Loading, Modal, Notice, PageHeading } from '../ui';
import { MemberCell } from './member-cell';
import { cents, pacificDateTime } from './offer-shared';

const statuses = ['pending', 'approved', 'declined', 'paid', 'expired', 'cancelled'];

export function AdminRequests() {
  const { profile } = useAuth();
  const allowed = can(profile, 'approveRequests');
  const data = useRows(allowed ? 'sessionRequests' : null);
  const [status, setStatus] = useState('pending');
  const [selected, setSelected] = useState<Row | null>(null);
  const rows = data.rows.filter((row) => status === 'all' || row.status === status);
  const profiles = useMemberProfiles(rows.map((r) => r.userId as string));

  if (!allowed) return <Notice error>Requests permission is required.</Notice>;
  return (
    <>
      <PageHeading title="Requests." />
      <div className="admin-toolbar">
        <label className="field">
          Status
          <select value={status} onChange={(event) => setStatus(event.target.value)}>
            <option value="all">All</option>
            {statuses.map((item) => (
              <option key={item}>{item}</option>
            ))}
          </select>
        </label>
      </div>
      {data.error && <Notice error>{data.error}</Notice>}
      {data.loading ? (
        <Loading />
      ) : rows.length ? (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Member</th>
                <th>Type</th>
                <th>Seats</th>
                <th>Preferred times · Pacific</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>
                    <MemberCell uid={row.userId} profile={profiles[row.userId]} />
                  </td>
                  <td>{row.trainingType}</td>
                  <td>{row.seats}</td>
                  <td>
                    {(row.preferredTimes || [])
                      .map((time: { date: string; time: string }) => `${time.date} ${time.time}`)
                      .join(', ')}
                  </td>
                  <td>{row.status}</td>
                  <td>
                    <Button className="small" onClick={() => setSelected(row)}>
                      Details
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <Empty>No matching requests.</Empty>
      )}
      {selected && (
        <RequestDetail
          key={selected.id}
          row={selected}
          profile={profiles[selected.userId]}
          onClose={() => setSelected(null)}
        />
      )}
    </>
  );
}

function RequestDetail({
  row,
  profile,
  onClose,
}: {
  row: Row;
  profile?: any;
  onClose: () => void;
}) {
  const [startAt, setStartAt] = useState('');
  const [price, setPrice] = useState('');
  const [duration, setDuration] = useState('60');
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function decide(decision: 'approve' | 'decline', event?: FormEvent<HTMLFormElement>) {
    event?.preventDefault();
    setError('');
    let details: Record<string, unknown> = {};
    try {
      if (note.length > 500) throw new Error('Note must be 500 characters or fewer.');
      if (decision === 'approve') {
        const start = pacificDateTime(startAt);
        if (start <= Date.now()) throw new Error('Choose a future Pacific start time.');
        const minutes = Number(duration);
        if (!Number.isInteger(minutes) || minutes < 15 || minutes > 240)
          throw new Error('Duration must be 15 to 240 minutes.');
        details = { startAt: start, priceCents: cents(price), durationMinutes: minutes };
      }
      setBusy(true);
      await call('decideSessionRequest', { requestId: row.id, decision, note, ...details });
      onClose();
    } catch (cause) {
      setError(errorMessage(cause));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal title="Session request" onClose={onClose}>
      <div className="stack">
        <p>
          {row.trainingType} · {row.seats} seats · {row.status}
        </p>
        <div>
          <strong style={{ display: 'block', marginBottom: 4 }}>Member:</strong>
          <MemberCell uid={row.userId} profile={profile} />
        </div>
        <div>
          <strong>Preferred times · Pacific</strong>
          {(row.preferredTimes || []).map(
            (time: { date: string; time: string }, index: number) => (
              <p key={index}>
                {time.date} at {time.time}
              </p>
            )
          )}
        </div>
        {row.note && <p>Parent note: {row.note}</p>}
        {row.decisionNote && <p>Decision note: {row.decisionNote}</p>}
        {row.approvedStartAt && (
          <p>
            Approved: {dateLabel(row.approvedStartAt)} at {timeLabel(row.approvedStartAt)} PT ·{' '}
            {money(row.approvedPriceCents || 0)} per seat
          </p>
        )}
        {row.payBy && (
          <p>
            Pay by: {dateLabel(row.payBy)} at {timeLabel(row.payBy)} PT
          </p>
        )}
        {row.status === 'pending' && (
          <form className="stack" onSubmit={(event) => decide('approve', event)}>
            <label className="field">
              Start · Pacific
              <input
                type="datetime-local"
                required
                value={startAt}
                onChange={(event) => setStartAt(event.target.value)}
              />
            </label>
            <label className="field">
              Price per seat ($)
              <input
                type="number"
                min="0.01"
                max="1000"
                step="0.01"
                required
                value={price}
                onChange={(event) => setPrice(event.target.value)}
              />
            </label>
            <label className="field">
              Duration (minutes)
              <input
                type="number"
                min="15"
                max="240"
                step="1"
                required
                value={duration}
                onChange={(event) => setDuration(event.target.value)}
              />
            </label>
            <label className="field">
              Decision note (optional)
              <textarea
                maxLength={500}
                value={note}
                onChange={(event) => setNote(event.target.value)}
              />
            </label>
            {error && <Notice error>{error}</Notice>}
            <div className="row">
              <Button busy={busy}>Approve</Button>
              <Button
                type="button"
                className="secondary"
                disabled={busy}
                onClick={() => decide('decline')}
              >
                Decline
              </Button>
            </div>
          </form>
        )}
      </div>
    </Modal>
  );
}
