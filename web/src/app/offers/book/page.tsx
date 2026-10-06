'use client';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { SessionJoinPage } from '@/components/sessions-public';
function Content(){const search=useSearchParams();return <SessionJoinPage id={search.get('session')||''}/>;}

export default function Page(){return <Suspense fallback={<div className="container page-wrap">Loading…</div>}><Content/></Suspense>;}
