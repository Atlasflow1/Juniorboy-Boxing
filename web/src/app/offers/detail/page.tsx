'use client';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { SessionDetailPage } from '@/components/sessions-public';
function Content(){const search=useSearchParams();return <SessionDetailPage id={search.get('id')||''}/>;}

export default function Page(){return <Suspense fallback={<div className="container page-wrap">Loading…</div>}><Content/></Suspense>;}
