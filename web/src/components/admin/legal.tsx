'use client';
import { useState } from 'react';
import { call } from '@/lib/firebase';
import { useDocument } from '@/lib/hooks';
import { termsDraft, privacyDraft } from '@/lib/legal';
import { errorMessage } from '@/lib/utils';
import { Button, Notice, PageHeading } from '../ui';
function LegalEditor({page, title, draft}:{page:'terms'|'privacy'; title:string; draft:string}) {
  const current = useDocument(`legalDocuments/${page}`), [busy,setBusy] = useState(false), [error,setError] = useState(''), [message,setMessage] = useState('');
  return <form className="card stack" key={current?.publishedAt ? page : `${page}-draft`} onSubmit={async e => {
    e.preventDefault(); const f = new FormData(e.currentTarget); setBusy(true);setError('');setMessage('');
    try { await call('publishLegalPage',{page,title:f.get('title'),body:f.get('body')});setMessage('Published.'); } catch(e) { setError(errorMessage(e)); } finally { setBusy(false); }
  }}><h3 style={{margin:0}}>{title}</h3><label className="field">Title<input name="title" defaultValue={current?.title || title} minLength={5} maxLength={120} required/></label><label className="field">Published text<textarea name="body" defaultValue={current?.body || draft} minLength={50} maxLength={30000} rows={18} required/></label>{error&&<Notice error>{error}</Notice>}{message&&<Notice>{message}</Notice>}<Button busy={busy}>Publish {title}</Button></form>;
}
export function AdminLegal() {
  return <><PageHeading title="Legal Pages."/><Notice>Edit and publish the Terms of Service and Privacy Policy shown on the website and app. Add your business address, phone number or any other detail you want included — these pages are not pre-filled with gym contact details.</Notice><div className="stack">
    <LegalEditor page="terms" title="Terms of Service" draft={termsDraft}/>
    <LegalEditor page="privacy" title="Privacy Policy" draft={privacyDraft}/>
  </div></>;
}
