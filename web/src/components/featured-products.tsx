'use client';
import { useEffect, useRef, useState } from 'react';
import { where } from 'firebase/firestore';
import { useRows } from '@/lib/hooks';
import { money } from '@/lib/utils';
export function FeaturedProductsCarousel() {
  const {rows} = useRows('products',[where('isActive','==',true),where('isFeatured','==',true)]);
  const [index,setIndex] = useState(0);
  const trackRef = useRef<HTMLDivElement>(null);
  const scrollTimer = useRef<ReturnType<typeof setTimeout>>();
  useEffect(()=>{
    if (rows.length < 2) return;
    const id = setInterval(()=>setIndex(i=>(i+1)%rows.length), 5000);
    return ()=>clearInterval(id);
  },[rows.length]);
  useEffect(()=>{
    const el = trackRef.current; if (!el) return;
    el.scrollTo({left: index*el.clientWidth, behavior:'smooth'});
  },[index]);
  if (!rows.length) return null;
  return <div className="featured-carousel">
    <div ref={trackRef} className="featured-track" onScroll={e=>{
      const el=e.currentTarget;
      clearTimeout(scrollTimer.current);
      scrollTimer.current = setTimeout(()=>{
        const i=Math.round(el.scrollLeft/(el.clientWidth||1));
        setIndex(current=>i!==current?i:current);
      }, 150);
    }}>
      {rows.map(p=>{
        const hasDiscount=p.discountActive===true&&p.discountPercent>0;
        const saleCents=hasDiscount?Math.round(p.price*(1-p.discountPercent/100)):p.price;
        return <a key={p.id} href="/store" className="featured-slide">
          {p.imageUrl&&<img src={p.imageUrl} alt=""/>}
          <div>
            <span className="featured-eyebrow">From the gym store</span>
            <h3 style={{margin:0,fontSize:20}}>{p.name}</h3>
            {hasDiscount?<p style={{margin:'6px 0 0'}}><span className="price-was" style={{marginLeft:0,marginRight:8}}>{p.priceLabel}</span><strong style={{color:'var(--green)'}}>{money(saleCents)}</strong></p>:<p className="muted" style={{margin:'6px 0 0',fontSize:13}}>{p.priceLabel}</p>}
          </div>
        </a>;
      })}
    </div>
    {rows.length>1&&<div className="featured-dots">{rows.map((p,i)=><button key={p.id} aria-label={`Go to slide ${i+1}`} className={i===index?'active':''} onClick={()=>setIndex(i)}/>)}</div>}
  </div>;
}
