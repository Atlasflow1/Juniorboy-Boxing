'use client';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { CheckInPassPage } from '@/components/parent-bookings';
function Content(){const search=useSearchParams();return <CheckInPassPage id={search.get('id')||''}/>;}

export default function Page(){return <Suspense fallback={<div className="container page-wrap">Loading…</div>}><Content/></Suspense>;}
