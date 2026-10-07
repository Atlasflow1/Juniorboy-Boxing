'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { call } from '@/lib/firebase';
import { useDocument, useRows } from '@/lib/hooks';
import { Row } from '@/lib/types';
import { errorMessage } from '@/lib/utils';
import { useAuth } from './providers';
import { isStaff } from '@/lib/permissions';
import { ActionLink, Button, Empty, Loading, Modal, Notice, PageHeading } from './ui';
import { ParentPayment } from './parent-payment';
import { AuthModal } from './auth-modal';
import './sessions-public.css';

function typeLabel(type?: string): string {
  if (type === 'duo') return 'Duo';
  if (type === 'team') return 'Team';
  return 'Individual';
}

function fmtDate(v: any): string {
  const d = v?.toDate ? v.toDate() : new Date(v);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function dateRange(row: Row): string {
  if (!row.startDate || !row.endDate) return '';
  const start = fmtDate(row.startDate), end = fmtDate(row.endDate);
  return start === end ? start : `${start} – ${end}`;
}

function isPast(row: Row): boolean {
  const end = row.endDate?.toDate ? row.endDate.toDate() : new Date(row.endDate);
  return end < new Date(new Date().toDateString());
}

type SessionMember = { uid: string; fullName: string; childName: string; profilePicUrl: string | null };

function useSessionMembers(sessionId: string) {
  const [members, setMembers] = useState<SessionMember[]>([]);
  useEffect(() => {
    if (!sessionId) return;
    let cancelled = false;
    call<{ members: SessionMember[] }>('getSessionMembers', { sessionId })
      .then((r) => { if (!cancelled) setMembers(r.members || []); })
      .catch(() => { if (!cancelled) setMembers([]); });
    return () => { cancelled = true; };
  }, [sessionId]);
  return members;
}

function JoinedAvatars({ members, totalCount, size = 26 }: { members: SessionMember[]; totalCount: number; size?: number }) {
  if (!totalCount) return null;
  const visible = members.filter((m) => m.profilePicUrl).slice(0, 5);
  const overflow = totalCount - visible.length;
  const step = size * 0.65;
  return (
    <div style={{ position: 'relative', height: size, width: step * visible.length + (overflow > 0 ? step : 0) + (size - step), flexShrink: 0 }}>
      {visible.map((m, i) => (
        <img key={m.uid} src={m.profilePicUrl!} alt="" style={{ position: 'absolute', left: i * step, top: 0, width: size, height: size, borderRadius: '50%', border: '2px solid var(--bg)', objectFit: 'cover' }} />
      ))}
      {overflow > 0 && (
        <div style={{ position: 'absolute', left: visible.length * step, top: 0, width: size, height: size, borderRadius: '50%', border: '2px solid var(--bg)', background: 'var(--red)', color: 'var(--on-accent)', fontSize: 10, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          +{overflow}
        </div>
      )}
    </div>
  );
}

function JoinedMembersModal({ session, onClose }: { session: Row; onClose: () => void }) {
  const members = useSessionMembers(session.id);
  const joinedUserIds: string[] = session.joinedUserIds || [];
  return (
    <Modal title="Joined members" onClose={onClose}>
      <div className="stack">
        <div>
          <h3 style={{ margin: 0 }}>{session.title}</h3>
          <div className="parent-detail-chips" role="list" aria-label="Session details" style={{ marginTop: 8 }}>
            <span className="parent-chip" role="listitem">{typeLabel(session.type)}</span>
            <span className="parent-chip" role="listitem">{dateRange(session)}</span>
            <span className="parent-chip" role="listitem">{session.startTime}–{session.endTime}</span>
          </div>
          <p className="muted" style={{ fontSize: 13, marginTop: 8 }}>{joinedUserIds.length} / {session.maxParticipants} joined</p>
        </div>
        {joinedUserIds.length === 0 ? (
          <Empty>No one has joined yet.</Empty>
        ) : members.length === 0 ? (
          <Loading />
        ) : (
          <div className="stack" style={{ gap: 10 }}>
            {members.map((m) => (
              <div key={m.uid} className="row" style={{ gap: 10, alignItems: 'center' }}>
                {m.profilePicUrl ? (
                  <img src={m.profilePicUrl} alt="" style={{ width: 36, height: 36, borderRadius: '50%', objectFit: 'cover' }} />
                ) : (
                  <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'var(--accent-tint)' }} />
                )}
                <span>{m.childName || m.fullName}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </Modal>
  );
}

function SessionCard({ session }: { session: Row }) {
  const joined = (session.joinedUserIds || []).length;
  const members = useSessionMembers(session.id);
  const [showMembers, setShowMembers] = useState(false);
  return (
    <article className="card parent-offer-card" key={session.id}>
      {session.images?.[0] && (
        <img className="parent-offer-cover" src={session.images[0]} alt={session.title || ''} loading="lazy" />
      )}
      <p className="eyebrow parent-offer-eyebrow">{typeLabel(session.type)} · {dateRange(session)}</p>
      <h3 className="parent-offer-title" title={session.title}>{session.title}</h3>
      <p className="parent-offer-desc" title={session.description}>{session.description}</p>
      <div className="parent-offer-footer">
        <div className="parent-offer-footer-row">
          <div className="parent-offer-pricing">
            <strong>${Number(session.price || 0).toFixed(2)}</strong>
          </div>
          <button type="button" onClick={() => joined && setShowMembers(true)} className="row" style={{ gap: 6, alignItems: 'center', background: 'transparent', border: 0, padding: 0, cursor: joined ? 'pointer' : 'default' }}>
            <JoinedAvatars members={members} totalCount={joined} />
            <span className="parent-offer-count muted">{joined} / {session.maxParticipants} joined</span>
          </button>
        </div>
        <ActionLink href={`/offers/detail?id=${encodeURIComponent(session.id)}`}>View details</ActionLink>
      </div>
      {showMembers && <JoinedMembersModal session={session} onClose={() => setShowMembers(false)} />}
    </article>
  );
}

export function SessionsPage() {
  const { rows, loading, error } = useRows('sessions');
  const upcoming = rows.filter((r) => !isPast(r));

  return (
    <div className="container page-wrap">
      <PageHeading eyebrow="Training sessions" title="Find your next round.">Book a place in an upcoming session.</PageHeading>
      {error && <Notice error>{error}</Notice>}
      {loading ? (
        <Loading />
      ) : upcoming.length ? (
        <div className="offer-grid parent-offers-grid">
          {upcoming.map((s) => <SessionCard key={s.id} session={s} />)}
        </div>
      ) : (
        <Empty>No upcoming sessions are available right now.</Empty>
      )}
    </div>
  );
}

export function SessionDetailPage({ id }: { id: string }) {
  const session = useDocument(`sessions/${id}`);
  const { user, profile } = useAuth();
  const joinedUserIds: string[] = session?.joinedUserIds || [];
  const joined = !!user && joinedUserIds.includes(user.uid);
  const full = joinedUserIds.length >= (session?.maxParticipants || 0);
  const members = useSessionMembers(session?.id || '');
  const [showMembers, setShowMembers] = useState(false);
  const staff = isStaff(profile);

  return (
    <div className="container page-wrap parent-offer-detail">
      {!session ? (
        <Loading />
      ) : (
        <>
          {session.images?.[0] && <img className="parent-detail-cover" src={session.images[0]} alt={session.title || ''} />}
          <div className="parent-detail-info">
            <PageHeading title={session.title}>{session.description}</PageHeading>
            <div className="parent-detail-chips" role="list" aria-label="Session details">
              <span className="parent-chip" role="listitem">{typeLabel(session.type)}</span>
              <span className="parent-chip" role="listitem">{dateRange(session)}</span>
              <span className="parent-chip" role="listitem">{session.startTime}–{session.endTime}</span>
              <span className="parent-chip" role="listitem">${Number(session.price || 0).toFixed(2)}</span>
            </div>
            <button type="button" onClick={() => joinedUserIds.length && setShowMembers(true)} className="row" style={{ gap: 8, alignItems: 'center', background: 'transparent', border: 0, padding: 0, cursor: joinedUserIds.length ? 'pointer' : 'default' }}>
              <JoinedAvatars members={members} totalCount={joinedUserIds.length} />
              <span className="muted">{joinedUserIds.length} of {session.maxParticipants} places taken</span>
            </button>
            {!staff && (
              <ActionLink href={joined || full ? '#' : `/offers/book?session=${encodeURIComponent(id)}`}>
                {joined ? "You're in" : full ? 'Full' : `Join · $${Number(session.price || 0).toFixed(2)}`}
              </ActionLink>
            )}
          </div>
          {showMembers && <JoinedMembersModal session={session} onClose={() => setShowMembers(false)} />}
        </>
      )}
    </div>
  );
}

export function SessionJoinPage({ id }: { id: string }) {
  const router = useRouter();
  const { user, profile, loading: authLoading } = useAuth();
  const staff = isStaff(profile);
  const session = useDocument(`sessions/${id}`);
  const [step, setStep] = useState<'review' | 'payment' | 'result'>('review');
  const [secret, setSecret] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [showAuth, setShowAuth] = useState(false);
  const submittedRef = useRef(false);
  const [submitted, setSubmitted] = useState(false);

  useEffect(() => {
    const saved = sessionStorage.getItem(`session-join:${id}`);
    if (saved && user) {
      sessionStorage.removeItem(`session-join:${id}`);
    }
  }, [id, user]);

  const joinedUserIds: string[] = session?.joinedUserIds || [];
  const joined = !!user && joinedUserIds.includes(user.uid);
  const full = joinedUserIds.length >= (session?.maxParticipants || 0);

  async function begin() {
    if (!user) {
      sessionStorage.setItem(`session-join:${id}`, '1');
      setShowAuth(true);
      return;
    }
    setBusy(true);
    setError('');
    try {
      const r = await call<{ paymentId: string; clientSecret?: string; status: string }>('joinSession', {
        sessionId: id,
        requestId: crypto.randomUUID(),
      });
      if (['completed', 'refunded', 'refund_pending'].includes(r.status)) {
        setStep('result');
      } else if (r.clientSecret) {
        setSecret(r.clientSecret);
        setStep('payment');
      } else {
        setError('Payment is processing. Check back shortly.');
      }
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  if (!session) return <div className="container page-wrap"><Loading /></div>;

  return (
    <div className="container page-wrap">
      <PageHeading title={session.title}>{dateRange(session)} · {session.startTime}–{session.endTime}</PageHeading>
      <div className="parent-flow card stack">
        {step === 'review' && (
          <>
            <h2>Confirm your spot</h2>
            {staff ? (
              <Empty>Admin accounts can't join sessions.</Empty>
            ) : joined ? (
              <Notice>You've already joined this session.</Notice>
            ) : full ? (
              <Empty>This session is full.</Empty>
            ) : (
              <>
                <p>${Number(session.price || 0).toFixed(2)} · pay securely to confirm your place.</p>
                <Button busy={busy || authLoading} onClick={begin}>Continue to card payment</Button>
              </>
            )}
          </>
        )}
        {step === 'payment' && (
          <>
            <h2>Card payment</h2>
            <p>${Number(session.price || 0).toFixed(2)}</p>
            {secret && (
              <ParentPayment
                secret={secret}
                returnPath={`/offers/book?session=${encodeURIComponent(id)}`}
                onConfirming={() => { submittedRef.current = true; setSubmitted(true); }}
                onFailure={() => { submittedRef.current = false; setSubmitted(false); }}
                onSubmitted={() => setStep('result')}
              />
            )}
            {submitted && <Notice>Payment submitted. Waiting for confirmation.</Notice>}
          </>
        )}
        {step === 'result' && (
          <>
            <h2>{joined ? "You're in!" : 'Payment submitted'}</h2>
            <p className="muted">{joined ? `You've joined ${session.title}.` : 'Confirming your payment — this page will update automatically.'}</p>
            <ActionLink href={`/offers/detail?id=${encodeURIComponent(id)}`}>Back to session</ActionLink>
          </>
        )}
        {error && <Notice error>{error}</Notice>}
      </div>
      {showAuth && (
        <AuthModal
          onClose={() => setShowAuth(false)}
          onSignedIn={() => { setShowAuth(false); }}
        />
      )}
    </div>
  );
}
