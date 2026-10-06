'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { where } from 'firebase/firestore';
import { auth, call } from '@/lib/firebase';
import { useDocument, useRows } from '@/lib/hooks';
import { asDate, dateLabel, errorMessage, money, timeLabel } from '@/lib/utils';
import { seatsLeft, upcomingOpen } from '@/lib/parent-data';
import { useAuth } from './providers';
import { ActionLink, Button, Empty, Loading, Notice, PageHeading } from './ui';
import { ParentPayment } from './parent-payment';
import { AuthModal } from './auth-modal';
import './parent-offers.css';

function formatTrainingType(type?: string): string {
  if (!type) return 'Group';
  const lower = type.trim().toLowerCase();
  if (lower === 'private') return 'Private';
  if (lower === 'duo') return 'Duo';
  if (lower === 'group') return 'Group';
  return type.trim().charAt(0).toUpperCase() + type.trim().slice(1);
}

function formatAgeGroup(ageGroup?: string): string {
  if (!ageGroup || !ageGroup.trim()) return 'All ages';
  const trimmed = ageGroup.trim();
  if (/^all ages/i.test(trimmed)) return 'All ages';
  if (/^ages?\s+/i.test(trimmed)) {
    return 'Ages ' + trimmed.replace(/^ages?\s+/i, '');
  }
  return `Ages ${trimmed}`;
}

function OfferCard({ offer, upcomingCount }: { offer: Record<string, any>; upcomingCount: number }) {
  const typeText = formatTrainingType(offer.trainingType);
  const ageText = formatAgeGroup(offer.ageGroup);
  const eyebrowText = `${typeText} · ${ageText}`;
  const sessionsLabel = `${upcomingCount} upcoming ${upcomingCount === 1 ? 'date' : 'dates'}`;

  return (
    <article className="card parent-offer-card" key={offer.id}>
      {offer.imageUrl && (
        <img
          className="parent-offer-cover"
          src={offer.imageUrl}
          alt={offer.title || ''}
          loading="lazy"
        />
      )}
      <p className="eyebrow parent-offer-eyebrow">{eyebrowText}</p>
      <h3 className="parent-offer-title" title={offer.title}>
        {offer.title}
      </h3>
      <p className="parent-offer-desc" title={offer.description}>
        {offer.description}
      </p>
      <div className="parent-offer-footer">
        <div className="parent-offer-footer-row">
          <div className="parent-offer-pricing">
            <strong>{money(offer.priceCents)}</strong>
            <span className="parent-offer-meta-note">
              {' '}per seat · {offer.durationMinutes || 60} min
            </span>
          </div>
          <div className="parent-offer-count muted">{sessionsLabel}</div>
        </div>
        <ActionLink href={`/offers/detail?id=${encodeURIComponent(offer.id)}`}>
          View dates
        </ActionLink>
      </div>
    </article>
  );
}

export function HomeOffers() {
  const { rows, loading, error } = useRows('offers', [where('visibility', '==', 'public'), where('status', '==', 'published')]);
  const { rows: occurrences, loading: occLoading } = useRows('offerOccurrences', [where('visibility', '==', 'public'), where('offerStatus', '==', 'published')]);
  const offers = rows.filter(o => occurrences.some(x => x.offerId === o.id && upcomingOpen(x))).slice(0, 3);

  return (
    <section className="section">
      <div className="container">
        <div className="section-heading">
          <div>
            <p className="eyebrow">Upcoming training</p>
            <h2>Sessions</h2>
          </div>
          <Link href="/offers" className="section-link">See all sessions</Link>
        </div>
        {error && <Notice error>{error}</Notice>}
        {loading || occLoading ? (
          <Loading />
        ) : offers.length ? (
          <div className="offer-grid parent-offers-grid">
            {offers.map(o => (
              <OfferCard
                key={o.id}
                offer={o}
                upcomingCount={occurrences.filter(x => x.offerId === o.id && upcomingOpen(x)).length}
              />
            ))}
          </div>
        ) : (
          <Empty>No upcoming sessions are available right now.</Empty>
        )}
      </div>
    </section>
  );
}

export function OffersPage() {
  const { rows, loading, error } = useRows('offers', [where('visibility', '==', 'public'), where('status', '==', 'published')]);
  const { rows: occurrences, loading: occLoading } = useRows('offerOccurrences', [where('visibility', '==', 'public'), where('offerStatus', '==', 'published')]);
  const offers = rows.filter(o => o.status === 'published');

  return (
    <div className="container page-wrap">
      <PageHeading eyebrow="Training sessions" title="Find your next round.">Book a place in an upcoming session.</PageHeading>
      {error && <Notice error>{error}</Notice>}
      {loading || occLoading ? (
        <Loading />
      ) : offers.length ? (
        <div className="offer-grid parent-offers-grid">
          {offers.map(o => (
            <OfferCard
              key={o.id}
              offer={o}
              upcomingCount={occurrences.filter(x => x.offerId === o.id && upcomingOpen(x)).length}
            />
          ))}
        </div>
      ) : (
        <Empty>No published sessions are available right now.</Empty>
      )}
    </div>
  );
}

export function OfferDetailPage({ id }: { id: string }) {
  const offer = useDocument(`offers/${id}`);
  const { rows, loading, error } = useRows('offerOccurrences', [
    where('visibility', '==', 'public'),
    where('offerStatus', '==', 'published'),
    where('offerId', '==', id),
    where('status', '==', 'open'),
  ]);
  const list = rows.filter(upcomingOpen).sort((a, b) => +asDate(a.startAt) - +asDate(b.startAt));

  return (
    <div className="container page-wrap parent-offer-detail">
      {!offer ? (
        <Loading />
      ) : offer.status !== 'published' ? (
        <Empty>This session is unavailable.</Empty>
      ) : (
        <>
          {offer.imageUrl && (
            <img className="parent-detail-cover" src={offer.imageUrl} alt={offer.title || ''} />
          )}
          <div className="parent-detail-info">
            <PageHeading title={offer.title}>{offer.description}</PageHeading>
            <div className="parent-detail-chips" role="list" aria-label="Session details">
              <span className="parent-chip" role="listitem">{formatTrainingType(offer.trainingType)}</span>
              <span className="parent-chip" role="listitem">{formatAgeGroup(offer.ageGroup)}</span>
              <span className="parent-chip" role="listitem">{offer.durationMinutes || 60} min</span>
              <span className="parent-chip" role="listitem">{money(offer.priceCents)} per seat</span>
            </div>
          </div>

          <div className="section-heading parent-sessions-heading">
            <div>
              <p className="eyebrow">Available dates</p>
              <h2>Upcoming dates</h2>
            </div>
          </div>

          {error && <Notice error>{error}</Notice>}
          {loading ? (
            <Loading />
          ) : list.length ? (
            <div className="stack parent-sessions-list">
              {list.map(x => (
                <article className="card parent-session-row" key={x.id}>
                  <div className="parent-session-info">
                    <h3 className="parent-session-time">
                      {dateLabel(x.startAt)} · {timeLabel(x.startAt)}
                    </h3>
                    <p className="parent-session-spots muted">
                      {seatsLeft(x)} of {x.capacity} places available
                    </p>
                  </div>
                  <div className="parent-session-action">
                    <ActionLink href={`/offers/book?offer=${encodeURIComponent(id)}&occurrence=${encodeURIComponent(x.id)}`}>
                      Choose seats
                    </ActionLink>
                  </div>
                </article>
              ))}
            </div>
          ) : (
            <Empty>No upcoming dates for this session.</Empty>
          )}
        </>
      )}
    </div>
  );
}

type Participant={name:string;age:number};
export function OfferBookingPage({id,occurrenceId}:{id:string;occurrenceId:string}){const router=useRouter(),{user,profile,loading:authLoading}=useAuth(),offer=useDocument(`offers/${id}`),occ=useDocument(`offerOccurrences/${occurrenceId}`),waiver=useDocument('legalDocuments/waiver');const [step,setStep]=useState<'seats'|'participants'|'review'|'payment'|'result'>('seats'),[seats,setSeats]=useState(1),[people,setPeople]=useState<Participant[]>([{name:'',age:0}]),[secret,setSecret]=useState(''),[bookingId,setBookingId]=useState(''),[busy,setBusy]=useState(false),[submitted,setSubmitted]=useState(false),[error,setError]=useState(''),[showAuth,setShowAuth]=useState(false);const booking=useDocument(bookingId?`offerBookings/${bookingId}`:null);const activeRef=useRef(false),bookingRef=useRef(''),submittedRef=useRef(false);useEffect(()=>{bookingRef.current=bookingId;},[bookingId]);useEffect(()=>{submittedRef.current=submitted;},[submitted]);useEffect(()=>{activeRef.current=true;return()=>{activeRef.current=false;if(auth.currentUser&&bookingRef.current&&!submittedRef.current)void call('abortOfferCheckout',{bookingId:bookingRef.current}).catch(()=>{});};},[]);useEffect(()=>{if(authLoading)return;const saved=sessionStorage.getItem(`offer-booking:${occurrenceId}`);if(saved){try{const state=JSON.parse(saved);if(state.seats)setSeats(state.seats);if(state.people)setPeople(state.people);if(user){if(state.step)setStep(state.step);sessionStorage.removeItem(`offer-booking:${occurrenceId}`);}}catch{sessionStorage.removeItem(`offer-booking:${occurrenceId}`);}}},[occurrenceId,authLoading,user]);useEffect(()=>{if(booking?.status==='confirmed'||booking?.status==='refund_pending'||booking?.status==='refunded')setStep('result');},[booking?.status]);const left=occ?seatsLeft(occ):0,valid=!!occ&&upcomingOpen(occ)&&occ.offerId===id&&left>0;const waiverNeeded=waiver?.published&&waiver.requiredOnBooking&&(profile?.waiverVersion!==waiver.version||profile?.waiverParticipantName!==profile?.childName?.trim()||profile?.waiverParticipantAge!==profile?.childAge);function changeSeats(n:number){setSeats(n);setPeople(old=>Array.from({length:n},(_,i)=>old[i]||{name:i===0?profile?.childName||'':'',age:i===0?Number(profile?.childAge||0):0}));}function promptSignIn(nextStep:'participants'|'review'){sessionStorage.setItem(`offer-booking:${occurrenceId}`,JSON.stringify({seats,people,step:nextStep}));setShowAuth(true);}async function begin(){if(!user){promptSignIn('review');return;}if(!occ)return;setBusy(true);setError('');try{const r=await call<{bookingId:string;clientSecret?:string;status:string}>('createOfferCheckout',{occurrenceId,seats,participants:people.map(p=>({name:p.name.trim(),age:Number(p.age)})),requestId:crypto.randomUUID()});if(!activeRef.current){if(r.bookingId)void call('abortOfferCheckout',{bookingId:r.bookingId});return;}setBookingId(r.bookingId);if(r.status==='confirmed')setStep('result');else if(r.clientSecret){setSecret(r.clientSecret);setStep('payment');}else setError('Payment is processing. Check My Bookings for its status.');}catch(e){setError(errorMessage(e));}finally{setBusy(false);}}async function abort(){if(!bookingId){router.push(`/offers/detail?id=${encodeURIComponent(id)}`);return;}setBusy(true);try{await call('abortOfferCheckout',{bookingId});bookingRef.current='';router.push(`/offers/detail?id=${encodeURIComponent(id)}`);}catch(e){setError(errorMessage(e));setBusy(false);}}return <div className="container page-wrap"><PageHeading title={occ?.title||'Book session'}>{occ&&`${dateLabel(occ.startAt)} · ${timeLabel(occ.startAt)}`}</PageHeading>{!offer||!occ?<Loading/>:!valid&&step==='seats'?<Empty>This session is no longer available.</Empty>:<div className="parent-flow card stack">{step==='seats'&&<><h2>Claim your gloves</h2><div className="glove-wall">{Array.from({length:Number(occ.capacity)},(_,i)=><button type="button" key={i} className={`glove-seat ${i<Number(occ.seatsTaken)?'taken':i<Number(occ.seatsTaken)+seats?'selected':''}`} disabled={i<Number(occ.seatsTaken)} onClick={()=>changeSeats(Math.max(1,Math.min(left,i-Number(occ.seatsTaken)+1)))}><span aria-hidden="true">◯</span><small>{i<Number(occ.seatsTaken)?'Taken / held':i<Number(occ.seatsTaken)+seats?'Selected':'Free'}</small></button>)}</div><p>{left} of {occ.capacity} seats free · {money(occ.priceCents)} per seat</p><div className="row"><Button className="secondary" disabled={seats<=1} onClick={()=>changeSeats(seats-1)}>−</Button><strong>{seats}</strong><Button className="secondary" disabled={seats>=left} onClick={()=>changeSeats(seats+1)}>+</Button></div><Button disabled={authLoading} onClick={()=>{if(!user)promptSignIn('participants');else setStep('participants');}}>Continue</Button></>}{step==='participants'&&<><h2>Participants</h2>{people.map((p,i)=><div className="field-grid" key={i}><label className="field">Participant {i+1} name<input maxLength={60} value={p.name} onChange={e=>setPeople(old=>old.map((v,j)=>j===i?{...v,name:e.target.value}:v))}/></label><label className="field">Age<input type="number" min={3} max={18} value={p.age||''} onChange={e=>setPeople(old=>old.map((v,j)=>j===i?{...v,age:Number(e.target.value)}:v))}/></label></div>)}<div className="row"><Button className="secondary" onClick={()=>setStep('seats')}>Back</Button><Button disabled={people.some(p=>!p.name.trim()||p.age<3||p.age>18)} onClick={()=>setStep('review')}>Review</Button></div></>}{step==='review'&&<><h2>Review booking</h2><p>{people.map(p=>`${p.name.trim()} (${p.age})`).join(' · ')}</p><p>{seats} × {money(occ.priceCents)} = <strong>{money(seats*occ.priceCents)}</strong></p><p className="muted">Cancellation and refund eligibility depend on the session type and time remaining before it starts.</p>{waiverNeeded?<Notice>Please sign the current waiver before booking. <Link href="/waiver">Review waiver</Link></Notice>:<div className="row"><Button className="secondary" onClick={()=>setStep('participants')}>Back</Button><Button busy={busy} onClick={begin}>Continue to card payment</Button></div>}</>}{step==='payment'&&<><h2>Card payment</h2><p>{money(seats*occ.priceCents)} · Seats are held briefly while you pay.</p>{secret&&<ParentPayment secret={secret} returnPath={`/offers/book?offer=${encodeURIComponent(id)}&occurrence=${encodeURIComponent(occurrenceId)}`} onConfirming={()=>{submittedRef.current=true;setSubmitted(true);}} onFailure={()=>{submittedRef.current=false;setSubmitted(false);}} onSubmitted={()=>setSubmitted(true)}/>}<Button className="secondary" busy={busy} onClick={abort}>Cancel checkout</Button>{submitted&&<Notice>Payment submitted. Waiting for booking confirmation.</Notice>}</>}{step==='result'&&<><h2>{booking?.status==='confirmed'?'Booking confirmed':`Booking ${booking?.status?.replace('_',' ')||'processing'}`}</h2><ActionLink href="/bookings">My Bookings</ActionLink></>}{error&&<Notice error>{error}</Notice>}</div>}{showAuth&&<AuthModal onClose={()=>setShowAuth(false)} onSignedIn={()=>{setShowAuth(false);if(step==='seats')setStep('participants');}}/>}</div>;}
