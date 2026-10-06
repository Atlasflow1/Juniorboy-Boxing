'use client';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { ProductDetailPage } from '@/components/store';
function Content(){const search=useSearchParams();return <ProductDetailPage id={search.get('id')||''}/>;}

export default function Page(){return <Suspense fallback={<div className="container page-wrap">Loading…</div>}><Content/></Suspense>;}
