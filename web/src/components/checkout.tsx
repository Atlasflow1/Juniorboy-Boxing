'use client';
import { FormEvent, useEffect, useMemo, useRef, useState } from 'react';
import { Elements, PaymentElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { loadStripe } from '@stripe/stripe-js';
import { doc, onSnapshot } from 'firebase/firestore';
import { useSearchParams } from 'next/navigation';
import { auth, call, db } from '@/lib/firebase';
import { useDocument } from '@/lib/hooks';
import { errorMessage, money } from '@/lib/utils';
import { Button, Notice, Loading, PageHeading, ActionLink } from './ui';
import { MemberShell } from './member-pages';
import { useAuth } from './providers';
export function Checkout() {
  const search = useSearchParams(), productId = search.get('product'), size = search.get('size') || undefined, planId = productId ? '' : (search.get('plan') || 'ten'), {user, profile} = useAuth();
  const isProduct = !!productId;
  const settings = useDocument('gymSettings/config');
  const publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || settings?.stripePublishableKey || '';
  const stripePromise = useMemo(() => /^pk_(test|live)_/.test(publishableKey) ? loadStripe(publishableKey) : null, [publishableKey]);
  const [secret,setSecret] = useState(''), [paymentId,setPaymentId] = useState(''), [status,setStatus] = useState(''), [error,setError] = useState(''), [restartable,setRestartable] = useState(false), [attempt,setAttempt] = useState(0), [amount,setAmount] = useState<number|null>(null), [holdUntil,setHoldUntil]=useState<number|null>(null),[clock,setClock]=useState(Date.now());
  const checkoutRef=useRef({paymentId:'',status:'',isProduct:false,submitted:false});
  const expiredRef=useRef('');
  useEffect(()=>{checkoutRef.current={paymentId,status,isProduct,submitted:['submitted','processing','succeeded','completed'].includes(status)};},[paymentId,status,isProduct]);
  useEffect(()=>{const id=setInterval(()=>setClock(Date.now()),1000);return()=>clearInterval(id);},[]);
  useEffect(()=>()=>{const current=checkoutRef.current;if(auth.currentUser&&current.isProduct&&current.paymentId&&!current.submitted&&!['canceled','expired','refunded','refund_pending','completed'].includes(current.status))void call('abortProductCheckout',{paymentId:current.paymentId}).catch(()=>{});},[]);
  const ready = isProduct ? !!profile?.isActive : !!profile?.isActive && !!profile?.phone?.trim() && !!profile?.childName?.trim() && profile?.childAge > 0;
  const returnUrl = isProduct ? `/checkout?product=${encodeURIComponent(productId!)}${size ? `&size=${encodeURIComponent(size)}` : ''}` : `/checkout?plan=${encodeURIComponent(planId)}`;
  const key = `checkout:${isProduct ? 'product' : 'plan'}:${user?.uid}:${isProduct ? productId : planId}:${size || ''}`;
  useEffect(()=>{if(user&&isProduct&&paymentId&&holdUntil&&clock>=holdUntil&&!expiredRef.current.includes(paymentId)&&!['submitted','processing','succeeded','completed','canceled','expired'].includes(status)){expiredRef.current=paymentId;void call('abortProductCheckout',{paymentId}).then(()=>{setStatus('expired');setSecret('');setRestartable(true);localStorage.removeItem(key);}).catch(e=>setError(errorMessage(e)));}},[isProduct,paymentId,holdUntil,clock,status,key]);
  useEffect(() => {
    setSecret('');setPaymentId('');setStatus('');setError('');setRestartable(false);setAmount(null);
    if (!user || user.isAnonymous || !ready || !stripePromise) return;
    let active = true;
    let requestId = localStorage.getItem(key);
    if (!requestId) { requestId = sessionStorage.getItem(key) || crypto.randomUUID();localStorage.setItem(key,requestId); }
    const request = isProduct ? call<{clientSecret?:string;paymentId:string;status:string}>('createProductPaymentIntent',{productId,requestId,size}) : call<{clientSecret?:string;paymentId:string;status:string}>('createPaymentIntent',{planId,requestId});
    request.then(r => {
      if (!active) {if(isProduct&&r.paymentId&&!['completed','refunded','refund_pending'].includes(r.status))void call('abortProductCheckout',{paymentId:r.paymentId}).catch(()=>{});return;}setPaymentId(r.paymentId);setStatus(r.status);
      if (r.status === 'canceled') setRestartable(true);
      else if (r.clientSecret) setSecret(r.clientSecret);
    }).catch(e => { if (active) { setError(errorMessage(e));setRestartable(e?.details?.reason === 'checkout-expired'); } });
    return () => { active = false; };
  }, [user?.uid,ready,stripePromise,isProduct,productId,size,planId,attempt,key]);
  useEffect(() => {
    if (!paymentId) return;
    return onSnapshot(doc(db,'payments',paymentId), snap => {
      const order = snap.data(); if (!order) return;
      setAmount(order.amount);setHoldUntil(order.holdExpiresAt?.toMillis?.()??null);
      if (['completed','refunded','refund_pending'].includes(order.status)) {setStatus(order.status);setRestartable(order.status !== 'refund_pending');}
    }, e => setError(errorMessage(e)));
  }, [paymentId]);
  function restart() {localStorage.removeItem(key);sessionStorage.removeItem(key);setAttempt(n=>n+1);}
  async function abortProduct(){if(!user||!paymentId)return;try{await call('abortProductCheckout',{paymentId});setStatus('canceled');setSecret('');localStorage.removeItem(key);setRestartable(true);}catch(e){setError(errorMessage(e));}}
  const pending = ['processing','succeeded','submitted','requires_capture'].includes(status);
  return <MemberShell><PageHeading title="Payment.">{isProduct ? 'One-time purchase. Pick up your order at the gym.' : 'One-time purchase of training credits. No automatic renewal.'}</PageHeading>
    {!ready ? <><Notice>{isProduct ? 'Your account must be active before purchasing.' : 'Complete your phone number and participant details before purchasing.'}</Notice>{!isProduct && <ActionLink href="/settings">Complete Profile</ActionLink>}</> : !stripePromise ? <><Notice>Card payments are not configured yet. Contact the gym for a cash or manual payment.</Notice><ActionLink href="/contact">Contact the Gym</ActionLink></> : <>
    {amount !== null && <h2 style={{fontSize:28}}>Order total: {money(amount)}</h2>}
    {isProduct&&holdUntil&&status!=='completed'&&<p className="muted">Stock held for {Math.max(0,Math.ceil((holdUntil-clock)/1000/60))}:{String(Math.max(0,Math.ceil((holdUntil-clock)/1000))%60).padStart(2,'0')} · Pickup at the gym</p>}
    {error && <Notice error>{error}</Notice>}
    {status === 'completed' ? <><Notice>{isProduct ? 'Payment confirmed. Pick up your order at the gym.' : 'Payment confirmed. Your session credits have been added.'}</Notice><ActionLink href={isProduct ? '/store' : '/membership'}>{isProduct ? 'Back to Store' : 'View Membership'}</ActionLink></> : pending ? <><Notice>Your payment is being confirmed. Do not pay again. This page updates when the gym receives payment confirmation.</Notice><ActionLink href="/payments">Payment History</ActionLink></> : ['refunded','refund_pending','canceled'].includes(status) ? <Notice>Order status: {status.replace('_',' ')}.</Notice> : secret ? <Elements key={secret} stripe={stripePromise} options={{clientSecret:secret,appearance:{theme:'night',variables:{colorPrimary:'#E50914',colorBackground:'#181818'}}}}><CheckoutForm returnUrl={returnUrl} onConfirming={()=>{checkoutRef.current.submitted=true;}} onFailure={()=>{checkoutRef.current.submitted=false;}} onSubmitted={()=>setStatus('submitted')}/></Elements> : !error && <Loading/>}
    {restartable && <Button className="secondary" onClick={restart}>Start a New Purchase</Button>}
    {isProduct&&paymentId&&!pending&&!['completed','canceled','expired','refunded','refund_pending'].includes(status)&&<Button className="secondary" onClick={abortProduct}>Cancel checkout</Button>}
    </>}
    {!isProduct && <p className="muted" style={{marginTop:24}}>Read the <a href="/waiver">Waiver and Disclaimer</a> and <a href="/terms">Terms</a> before training.</p>}
  </MemberShell>;
}
function CheckoutForm({returnUrl,onSubmitted,onConfirming,onFailure}:{returnUrl:string;onSubmitted:()=>void;onConfirming?:()=>void;onFailure?:()=>void}) {
  const stripe = useStripe(), elements = useElements(), [busy,setBusy] = useState(false), [error,setError] = useState('');
  async function submit(e:FormEvent) {
    e.preventDefault(); if (!stripe || !elements || busy) return;setBusy(true);setError('');onConfirming?.();
    try {
      const result = await stripe.confirmPayment({elements,confirmParams:{return_url:`${window.location.origin}${returnUrl}`},redirect:'if_required'});
      if (result.error) {onFailure?.();setError(result.error.message || 'Payment was not completed.');} else onSubmitted();
    } catch(e) {onFailure?.();setError(errorMessage(e));} finally {setBusy(false);}
  }
  return <form className="card stack" style={{maxWidth:600}} onSubmit={submit}><PaymentElement/>{error&&<Notice error>{error}</Notice>}<Button busy={busy} disabled={!stripe || !elements}>Pay Securely →</Button></form>;
}
