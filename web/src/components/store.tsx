'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { where } from 'firebase/firestore';
import { useRows } from '@/lib/hooks';
import { Row } from '@/lib/types';
import { money } from '@/lib/utils';
import { ActionLink, Button, Loading, Notice, Empty, PageHeading } from './ui';
export function Store() {
  const {rows,loading,error}=useRows('products',[where('isActive','==',true)]);
  const products=rows as Row[];
  const router=useRouter();
  const [selectedSize,setSelectedSize]=useState<Record<string,string>>({});
  if (loading) return <Loading/>;
  if (error) return <Notice error>{error}</Notice>;
  if (!products.length) return <Empty>Products will appear here when available.</Empty>;
  const visible=[...products].sort((a,b)=>(a.sortOrder??0)-(b.sortOrder??0));
  return <div className="plan-grid">{visible.map(p=>{const hasDiscount=p.discountActive===true&&p.discountPercent>0;const saleCents=hasDiscount?Math.round(p.price*(1-p.discountPercent/100)):p.price;const sizes:string[]=p.sizes||[];const size=selectedSize[p.id];return <article className="plan" key={p.id}>{p.imageUrl&&<img src={p.imageUrl} alt={p.name} style={{width:'100%',aspectRatio:'1',objectFit:'cover',borderRadius:12,marginBottom:12}}/>}<h3>{p.name}{hasDiscount&&<span className="badge badge-green">{p.discountPercent}% OFF</span>}</h3>{hasDiscount?<span className="price">{money(saleCents)}<span className="price-was">{p.priceLabel}</span></span>:<span className="price">{p.priceLabel}</span>}{p.description&&<p className="rate">{p.description}</p>}{sizes.length>0&&<div className="size-picker">{sizes.map(s=><button key={s} type="button" className={`button small ${size===s?'':'secondary'}`} onClick={()=>setSelectedSize(prev=>({...prev,[p.id]:s}))}>{s}</button>)}</div>}{sizes.length>0?<Button disabled={!size} onClick={()=>router.push(`/checkout?product=${p.id}&size=${encodeURIComponent(size)}`)}>Buy Now</Button>:<ActionLink href={`/checkout?product=${p.id}`}>Buy Now</ActionLink>}<ActionLink href="/contact" secondary>Question? Contact the gym</ActionLink></article>;})}</div>;
}
export function StorePage() { return <div className="container page-wrap"><PageHeading eyebrow="Gym store" title="Gear up.">Merchandise and equipment available through the gym.</PageHeading><Store/></div>; }
