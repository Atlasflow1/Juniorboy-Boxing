'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { call } from '@/lib/firebase';
import { useDocument, useRows } from '@/lib/hooks';
import { Row } from '@/lib/types';
import { errorMessage } from '@/lib/utils';
import { useAuth } from './providers';
import { ActionLink, Button, Empty, Loading, Notice, PageHeading } from './ui';
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

function SessionCard({ session }: { session: Row }) {
  const joined = (session.joinedUserIds || []).length;
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
          <div className="parent-offer-count muted">{joined} / {session.maxParticipants} joined</div>
        </div>
        <ActionLink href={`/offers/detail?id=${encodeURIComponent(session.id)}`}>View details</ActionLink>
      </div>
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
  const { user } = useAuth();
  const joinedUserIds: string[] = session?.joinedUserIds || [];
  const joined = !!user && joinedUserIds.includes(user.uid);
  const full = joinedUserIds.length >= (session?.maxParticipants || 0);

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
            <p className="muted">{joinedUserIds.length} of {session.maxParticipants} places taken</p>
            <ActionLink href={joined || full ? '#' : `/offers/book?session=${encodeURIComponent(id)}`}>
              {joined ? "You're in" : full ? 'Full' : `Join · $${Number(session.price || 0).toFixed(2)}`}
            </ActionLink>
          </div>
        </>
      )}
    </div>
  );
}

export function SessionJoinPage({ id }: { id: string }) {
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
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
            {joined ? (
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
