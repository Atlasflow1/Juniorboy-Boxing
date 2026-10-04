'use client';
import { useEffect, useRef, useState } from 'react';
import { where } from 'firebase/firestore';
import { useRows } from '@/lib/hooks';
export function ProgramAdsCarousel() {
  const {rows} = useRows('classes',[where('isActive','==',true)]);
  const slides = rows.flatMap(p => ((p.adImages||[]) as string[]).map((imageUrl,i) => ({key:`${p.id}_${i}`, classId:p.id, className:p.className, imageUrl})));
  const [index,setIndex] = useState(0);
  const trackRef = useRef<HTMLDivElement>(null);
  const scrollTimer = useRef<ReturnType<typeof setTimeout>>();
  useEffect(()=>{
    if (slides.length < 2) return;
    const id = setInterval(()=>setIndex(i=>(i+1)%slides.length), 5000);
    return ()=>clearInterval(id);
  },[slides.length]);
  useEffect(()=>{
    const el = trackRef.current; if (!el) return;
    el.scrollTo({left: index*el.clientWidth, behavior:'smooth'});
  },[index]);
  if (!slides.length) return null;
  return <div className="featured-carousel">
    <div ref={trackRef} className="featured-track" onScroll={e=>{
      const el=e.currentTarget;
      clearTimeout(scrollTimer.current);
      scrollTimer.current = setTimeout(()=>{
        const i=Math.round(el.scrollLeft/(el.clientWidth||1));
        setIndex(current=>i!==current?i:current);
      }, 150);
    }}>
      {slides.map(s=><a key={s.key} href={`/schedule?program=${s.classId}`} className="program-ad-slide"><img src={s.imageUrl} alt={s.className||''}/></a>)}
    </div>
    {slides.length>1&&<div className="featured-dots">{slides.map((s,i)=><button key={s.key} aria-label={`Go to slide ${i+1}`} className={i===index?'active':''} onClick={()=>setIndex(i)}/>)}</div>}
  </div>;
}
