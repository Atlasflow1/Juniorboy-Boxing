'use client';
import { useDocument } from '@/lib/hooks';
import { termsDraft, privacyDraft } from '@/lib/legal';
import { PageHeading } from './ui';
function LegalPage({page, title, draft}:{page:'terms'|'privacy'; title:string; draft:string}) {
  const document = useDocument(`legalDocuments/${page}`);
  return <div className="container page-wrap legal"><PageHeading title={`${title}.`}/><article style={{whiteSpace:'pre-wrap',lineHeight:1.85}}>{document?.published ? document.body : draft}</article></div>;
}
export function TermsPage() { return <LegalPage page="terms" title="Terms of Service" draft={termsDraft}/>; }
export function PrivacyPage() { return <LegalPage page="privacy" title="Privacy Policy" draft={privacyDraft}/>; }
