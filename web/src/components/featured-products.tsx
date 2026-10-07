'use client';
import { useEffect, useRef, useState } from 'react';
import { where } from 'firebase/firestore';
import { useRows } from '@/lib/hooks';
import { money } from '@/lib/utils';
import { soldOut } from '@/lib/parent-data';
import { Icon } from './ui';
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
        return <a key={p.id} href={`/store/product?id=${encodeURIComponent(p.id)}`} className="featured-slide">
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

export function HomeShopSection(){const {rows,loading,error}=useRows('products',[where('isActive','==',true)]);const products=[...rows].sort((a,b)=>(a.sortOrder??0)-(b.sortOrder??0));const trackRef=useRef<HTMLDivElement>(null);function scroll(dir:number){const el=trackRef.current;if(!el)return;const card=el.querySelector('.shop-card') as HTMLElement|null;const amount=(card?.offsetWidth||260)+20;el.scrollBy({left:dir*amount,behavior:'smooth'});}return <section className="section"><div className="container"><div className="section-heading"><div><p className="eyebrow">Fight-night shop</p><h2>Wear your corner.</h2></div><a href="/store" className="section-link">Shop all products</a></div>{error&&<p role="alert">{error}</p>}{loading?<p className="muted">Loading products…</p>:products.length?<><div className="home-shop-track" ref={trackRef}>{products.map(p=>{const price=p.discountActive&&p.discountPercent>0?Math.round(p.price*(1-p.discountPercent/100)):p.price;const out=soldOut(p);return <a className="shop-card" key={p.id} href={`/store/product?id=${encodeURIComponent(p.id)}`}><div className="shop-plate">{p.imageUrl&&<img src={p.imageUrl} alt="" loading="lazy"/>}</div><div className="shop-card-copy"><span className="featured-eyebrow">{p.category||'Gym shop'}</span><h3>{p.name}</h3><strong>{money(price)}</strong>{out&&<span className="shop-sold-out">Sold out</span>}</div></a>;})}</div>{products.length>1&&<div className="home-carousel-arrows"><button type="button" aria-label="Previous products" className="icon-button home-carousel-arrow" onClick={()=>scroll(-1)}><Icon name="chevron_left"/></button><button type="button" aria-label="Next products" className="icon-button home-carousel-arrow" onClick={()=>scroll(1)}><Icon name="chevron_right"/></button></div>}</>:<p className="muted">Products will appear here when available.</p>}</div></section>;}
