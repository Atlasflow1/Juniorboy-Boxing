'use client';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { RequestPayPage } from '@/components/parent-requests';
function Content(){const search=useSearchParams();return <RequestPayPage bookingId={search.get('booking')||''} requestId={search.get('request')||''}/>;}

export default function Page(){return <Suspense fallback={<div className="container page-wrap">Loading…</div>}><Content/></Suspense>;}
