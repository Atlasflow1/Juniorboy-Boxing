'use client';
import { FormEvent, useState } from 'react';
import { Timestamp, doc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { useMemberProfiles } from '@/lib/member-cache';
import { Row } from '@/lib/types';
import { errorMessage } from '@/lib/utils';
import { Button, Notice, PageHeading, Modal, Loading } from '../ui';
import { MemberCell } from './member-cell';

const types = [
  ['individual', 'Individual'],
  ['duo', 'Duo'],
  ['team', 'Team'],
] as const;

function toDateInput(value: any): string {
  const d = value?.toDate ? value.toDate() : value ? new Date(value) : null;
  return d ? d.toISOString().slice(0, 10) : '';
}

function dateRangeLabel(row: Row): string {
  const fmt = (v: any) => {
    const d = v?.toDate ? v.toDate() : new Date(v);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };
  if (!row.startDate || !row.endDate) return '';
  const start = fmt(row.startDate), end = fmt(row.endDate);
  return start === end ? start : `${start} – ${end}`;
}

export function AdminSessions() {
  const { rows, loading, error } = useRows('sessions');
  const [selected, setSelected] = useState<Row | null>(null);
  const sorted = [...rows].sort((a, b) => (a.startDate?.seconds || 0) - (b.startDate?.seconds || 0));

  return (
    <>
      <PageHeading title="Sessions." eyebrow="Create and manage bookable sessions — shown on the app and the website" />
      <div className="admin-toolbar">
        <Button onClick={() => setSelected({ id: '' })}>Create Session</Button>
      </div>
      {error && <Notice error>{error}</Notice>}
      {loading ? (
        <Loading />
      ) : sorted.length === 0 ? (
        <p className="muted">No sessions yet. Create one to feature it on the app and the website.</p>
      ) : (
        <div className="stack">
          {sorted.map((s) => (
            <article className="card row spread" key={s.id} onClick={() => setSelected(s)} style={{ cursor: 'pointer' }}>
              <div className="row">
                {s.images?.[0] && (
                  <img src={s.images[0]} alt="" style={{ width: 56, height: 56, objectFit: 'cover', borderRadius: 8 }} />
                )}
                <div>
                  <h3 style={{ margin: 0 }}>{s.title}</h3>
                  <p className="muted" style={{ margin: 0 }}>
                    {[dateRangeLabel(s), `${s.startTime}–${s.endTime}`, `${(s.joinedUserIds || []).length}/${s.maxParticipants} joined`].filter(Boolean).join(' · ')}
                  </p>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
      {selected && <SessionEditor row={selected} onClose={() => setSelected(null)} />}
    </>
  );
}

function SessionEditor({ row, onClose }: { row: Row; onClose: () => void }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [imageUrl, setImageUrl] = useState<string>(row.images?.[0] || '');
  const joinedUserIds: string[] = row.joinedUserIds || [];
  const profiles = useMemberProfiles(joinedUserIds);

  async function uploadImage(file: File | undefined) {
    if (!file) return;
    if (file.size >= 5 * 1024 * 1024 || !['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      setError('Choose a JPG, PNG or WebP smaller than 5 MB.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const id = row.id || (row.id = crypto.randomUUID());
      const target = ref(storage, `gym/sessions/${id}`);
      await uploadBytes(target, file, { contentType: file.type });
      setImageUrl(await getDownloadURL(target));
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  async function save(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = Object.fromEntries(new FormData(e.currentTarget)) as Record<string, string>;
    setBusy(true);
    setError('');
    try {
      await setDoc(
        doc(db, 'sessions', row.id || crypto.randomUUID()),
        {
          title: f.title,
          description: f.description,
          images: imageUrl ? [imageUrl] : [],
          type: f.type,
          price: Number(f.price),
          startDate: Timestamp.fromDate(new Date(f.startDate)),
          endDate: Timestamp.fromDate(new Date(f.endDate)),
          startTime: f.startTime,
          endTime: f.endTime,
          maxParticipants: Number(f.maxParticipants),
          joinedUserIds,
          createdAt: row.createdAt || serverTimestamp(),
          updatedAt: serverTimestamp(),
        },
        { merge: true }
      );
      onClose();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!row.id || !window.confirm('Delete this session?')) return;
    setBusy(true);
    try {
      await deleteDoc(doc(db, 'sessions', row.id));
      onClose();
    } catch (e) {
      setError(errorMessage(e));
      setBusy(false);
    }
  }

  return (
    <Modal title={row.id ? 'Edit Session' : 'Create Session'} onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <label className="field">
          Photo
          <div className="photo-grid">
            {imageUrl ? (
              <div className="photo-slot">
                <img src={imageUrl} alt="" />
                <button type="button" onClick={() => setImageUrl('')} className="photo-remove" aria-label="Remove photo">✕</button>
              </div>
            ) : (
              <label className="photo-add">
                +
                <input type="file" accept="image/jpeg,image/png,image/webp" disabled={busy} style={{ display: 'none' }} onChange={(e) => uploadImage(e.target.files?.[0])} />
              </label>
            )}
          </div>
        </label>
        <label className="field">Title<input name="title" defaultValue={row.title || ''} required /></label>
        <label className="field">Description<textarea name="description" defaultValue={row.description || ''} rows={3} /></label>
        <div className="field-grid">
          <label className="field">Price in USD<input name="price" type="number" min="0" step="0.01" defaultValue={row.price ?? ''} required /></label>
          <label className="field">
            Type
            <select name="type" defaultValue={row.type || 'individual'}>
              {types.map(([v, label]) => <option key={v} value={v}>{label}</option>)}
            </select>
          </label>
        </div>
        <div className="field-grid">
          <label className="field">Start Date<input name="startDate" type="date" defaultValue={toDateInput(row.startDate)} required /></label>
          <label className="field">End Date<input name="endDate" type="date" defaultValue={toDateInput(row.endDate)} required /></label>
        </div>
        <div className="field-grid">
          <label className="field">Start Time<input name="startTime" type="time" defaultValue={row.startTime || ''} required /></label>
          <label className="field">End Time<input name="endTime" type="time" defaultValue={row.endTime || ''} required /></label>
        </div>
        <label className="field">Max Participants<input name="maxParticipants" type="number" min="1" defaultValue={row.maxParticipants ?? ''} required /></label>
        {joinedUserIds.length > 0 && (
          <div className="field">
            Joined ({joinedUserIds.length})
            <div className="stack" style={{ gap: 6, marginTop: 6 }}>
              {joinedUserIds.map((uid) => <MemberCell key={uid} uid={uid} profile={profiles[uid]} />)}
            </div>
          </div>
        )}
        {error && <Notice error>{error}</Notice>}
        <div className="row">
          <Button busy={busy}>Save Session</Button>
          {row.id && <Button type="button" className="secondary" onClick={remove}>Delete</Button>}
        </div>
      </form>
    </Modal>
  );
}
