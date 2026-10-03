'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { doc, getDoc } from 'firebase/firestore';
import { signInWithPopup, GoogleAuthProvider } from 'firebase/auth';
import { auth, db, call } from '@/lib/firebase';
import { errorMessage, isProfileComplete } from '@/lib/utils';
import { Button, Notice } from './ui';
export function AuthForm({signup=false}:{signup?:boolean}) {
  const [busy,setBusy]=useState(false),[error,setError]=useState(''),router=useRouter();
  function onward(){const next=new URLSearchParams(window.location.search).get('next');router.push(next?.startsWith('/')&&!next.startsWith('//')?next:'/dashboard');}
  async function google(){setBusy(true);setError('');try{const result=await signInWithPopup(auth,new GoogleAuthProvider());await call('initializeProfile');const snap=await getDoc(doc(db,'users',result.user.uid));const profile=snap.exists()?snap.data():null;if(!isProfileComplete(profile as any))router.push('/complete-profile');else onward();}catch(e){setError(errorMessage(e));}finally{setBusy(false);}}
  return <div className="auth-panel card"><p className="eyebrow">Your corner is waiting</p><h1>{signup?'Start your journey.':'Welcome back.'}</h1><p className="muted">{signup?'Sign in with Google to create your family’s account.':'Sign in with Google to keep your training moving.'}</p>{error&&<Notice error>{error}</Notice>}<Button busy={busy} onClick={google}>Continue with Google</Button></div>;
}
