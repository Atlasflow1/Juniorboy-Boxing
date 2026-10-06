'use client';
import { FormEvent, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { doc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage } from '@/lib/firebase';
import { useAuth } from './providers';
import { composeAddress, errorMessage } from '@/lib/utils';
import { AddressFields } from './address-fields';
import { Button, Loading, Notice } from './ui';
export function CompleteProfilePage() {
  const { user, profile, loading } = useAuth(), router = useRouter();
  const [busy,setBusy] = useState(false), [error,setError] = useState('');
  const [avatarUrl,setAvatarUrl] = useState('');
  useEffect(()=>{if(!loading&&!user)router.replace('/signin?next=/complete-profile');},[loading,user,router]);
  useEffect(()=>{if(profile?.avatarUrl)setAvatarUrl(profile.avatarUrl);},[profile]);
  if (loading || !user) return <Loading/>;
  async function uploadAvatar(file: File|undefined) {
    if (!file || !user) return;
    if (file.size>=5*1024*1024 || !['image/jpeg','image/png','image/webp'].includes(file.type)) { setError('Choose a JPG, PNG or WebP smaller than 5 MB.'); return; }
    setBusy(true); setError('');
    try { const target=ref(storage,`avatars/${user.uid}/profile`); await uploadBytes(target,file,{contentType:file.type}); setAvatarUrl(await getDownloadURL(target)); }
    catch (e) { setError(errorMessage(e)); } finally { setBusy(false); }
  }
  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault(); const data = Object.fromEntries(new FormData(e.currentTarget)) as Record<string,string>;
    const address = composeAddress(data);
    setBusy(true); setError('');
    try {
      await updateDoc(doc(db,'users',user!.uid), {fullName:data.fullName||profile?.fullName||'Member', childName:data.childName, childAge:Number(data.childAge), phone:data.phone, address, zipCode:data.zipCode, avatarUrl, updatedAt:serverTimestamp()});
      const next = new URLSearchParams(window.location.search).get('next');
      router.push(next?.startsWith('/')&&!next.startsWith('//')?next:'/dashboard');
    } catch (e) { setError(errorMessage(e)); setBusy(false); }
  }
  return <div className="auth-panel card"><p className="eyebrow">Almost there</p><h1>Complete your profile.</h1><p className="muted">Just a few details before you book your first session.</p>{error&&<Notice error>{error}</Notice>}<form className="stack" onSubmit={submit}>
    <h3 style={{margin:0}}>Profile photo</h3>
    <div className="row" style={{alignItems:'center',gap:16}}>{avatarUrl&&<img className="avatar" src={avatarUrl} alt="Your profile" style={{width:64,height:64,borderRadius:'50%',objectFit:'cover'}}/>}<label className="field" style={{flex:1}}>Upload a photo (optional)<input type="file" accept="image/jpeg,image/png,image/webp" disabled={busy} onChange={e=>uploadAvatar(e.target.files?.[0])}/></label></div>
    <h3 style={{margin:0}}>Your name</h3>
    <label className="field">Full name (optional)<input name="fullName" defaultValue={profile?.fullName||''} maxLength={100}/></label>
    <h3 style={{margin:0}}>Participant</h3>
    <label className="field">Participant name<input name="childName" required maxLength={100} defaultValue={profile?.childName||''}/></label>
    <label className="field">Participant age<input name="childAge" required type="number" min="1" max="120" defaultValue={profile?.childAge||''}/></label>
    <label className="field">Phone<input name="phone" required type="tel" pattern="[+0-9 ()-]{7,32}" autoComplete="tel" defaultValue={profile?.phone||''}/></label>
    <AddressFields defaultStreet={profile?.address||''} defaultZipCode={profile?.zipCode||''}/>
    <Button busy={busy}>Continue →</Button>
  </form></div>;
}
