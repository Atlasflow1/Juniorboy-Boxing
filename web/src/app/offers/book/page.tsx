'use client';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { OfferBookingPage } from '@/components/parent-offers';
function Content(){const search=useSearchParams();return <OfferBookingPage id={search.get('offer')||''} occurrenceId={search.get('occurrence')||''}/>;}

export default function Page(){return <Suspense fallback={<div className="container page-wrap">Loading…</div>}><Content/></Suspense>;}
