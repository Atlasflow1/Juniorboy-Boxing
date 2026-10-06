'use client';
import { FormEvent, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { doc, getDoc } from 'firebase/firestore';
import { signInWithPopup, GoogleAuthProvider, signInWithEmailAndPassword, createUserWithEmailAndPassword, updateProfile, sendPasswordResetEmail, User } from 'firebase/auth';
import { auth, db, call } from '@/lib/firebase';
import { errorMessage, isProfileComplete } from '@/lib/utils';
import { Button, Notice } from './ui';
// Same three ways in as the mobile welcome screen, minus Apple (web Apple sign-in needs a Services ID that is not configured).
export function AuthForm({signup=false,onSignedIn}:{signup?:boolean;onSignedIn?:()=>void}) {
  const [busy,setBusy]=useState(''),[error,setError]=useState(''),[info,setInfo]=useState(''),[name,setName]=useState(''),[email,setEmail]=useState(''),[password,setPassword]=useState(''),[creating,setCreating]=useState(signup),router=useRouter();
  function onward(){const next=new URLSearchParams(window.location.search).get('next');router.push(next?.startsWith('/')&&!next.startsWith('//')?next:'/dashboard');}
  async function finish(user:User){await call('initializeProfile');const snap=await getDoc(doc(db,'users',user.uid));if(!isProfileComplete((snap.exists()?snap.data():null) as any)){const next=onSignedIn?`${window.location.pathname}${window.location.search}`:new URLSearchParams(window.location.search).get('next');router.push(`/complete-profile${next?`?next=${encodeURIComponent(next)}`:''}`);}else if(onSignedIn)onSignedIn();else onward();}
  async function run(kind:string,task:()=>Promise<void>){setBusy(kind);setError('');setInfo('');try{await task();}catch(e){setError(errorMessage(e));}finally{setBusy('');}}
  const google=()=>run('google',async()=>finish((await signInWithPopup(auth,new GoogleAuthProvider())).user));
  const submit=(e:FormEvent)=>{e.preventDefault();run('email',async()=>{if(creating){const r=await createUserWithEmailAndPassword(auth,email.trim(),password);await updateProfile(r.user,{displayName:name.trim()});await finish(r.user);}else await finish((await signInWithEmailAndPassword(auth,email.trim(),password)).user);});};
  const reset=()=>{if(!email.trim()){setError('Enter your email first, then tap Forgot password.');return;}run('reset',async()=>{await sendPasswordResetEmail(auth,email.trim());setInfo('Check your inbox for a link to reset your password.');});};
  const next=typeof window==='undefined'?'':window.location.search;
  return <div className="auth-panel card">
    <p className="eyebrow">Your corner is waiting</p>
    <h1>{creating?'Create your account.':'Welcome back.'}</h1>
    <p className="muted auth-lede">{creating?'One account for booking sessions and shop orders.':'Sign in to book sessions and see your schedule.'}</p>
    {error&&<Notice error>{error}</Notice>}{info&&<Notice>{info}</Notice>}
    <Button type="button" className="auth-google" busy={busy==='google'} disabled={!!busy} onClick={google}><GoogleMark/>Continue with Google</Button>
    <div className="auth-divider"><span>or with email</span></div>
    <form onSubmit={submit}>
      {creating&&<label className="field">Parent name<input required autoComplete="name" value={name} onChange={e=>setName(e.target.value)}/></label>}
      <label className="field">Email<input required type="email" autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)}/></label>
      <label className="field">Password<input required type="password" minLength={creating?8:undefined} autoComplete={creating?'new-password':'current-password'} value={password} onChange={e=>setPassword(e.target.value)}/></label>
      {!creating&&<button type="button" className="auth-link" onClick={reset} disabled={!!busy}>Forgot password?</button>}
      <Button type="submit" busy={busy==='email'} disabled={!!busy}>{creating?'Create account':'Sign in'}</Button>
    </form>
    <p className="switch-auth">{creating?<>Already have an account? {onSignedIn?<button type="button" className="auth-link" onClick={()=>setCreating(false)}>Sign in</button>:<Link href={`/signin${next}`}>Sign in</Link>}</>:<>New here? {onSignedIn?<button type="button" className="auth-link" onClick={()=>setCreating(true)}>Create an account</button>:<Link href={`/signup${next}`}>Create an account</Link>}</>}</p>
  </div>;
}
function GoogleMark(){return <svg aria-hidden="true" width="18" height="18" viewBox="0 0 48 48"><path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z"/><path fill="#FF3D00" d="m6.3 14.7 6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/><path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z"/><path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.4-.4-3.5z"/></svg>;}
