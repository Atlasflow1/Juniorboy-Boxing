'use client';
import { FormEvent, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { where } from 'firebase/firestore';
import { motion, useReducedMotion } from 'framer-motion';
import { useDocument, useRows } from '@/lib/hooks';
import { gym } from '@/lib/types';
import { call } from '@/lib/firebase';
import { errorMessage, money } from '@/lib/utils';
import { ActionLink, AuthCTA, Button, Icon, Notice, PageHeading } from './ui';
import { useAuth } from './providers';
import { Pricing, FAQ } from './pricing';
import { AdditionalPrograms } from './programs';
import { Schedule } from './schedule';
import { HeroFX, IntroSplash, Marquee, PunchTitle } from './fx';
import { FeaturedProductsCarousel } from './featured-products';
import { ProgramAdsCarousel } from './program-ads';
export function HomePage(){const reduced=useReducedMotion(),settings=useDocument('gymSettings/config')||gym,{profile}=useAuth(),isAdmin=profile?.role==='admin';return <><IntroSplash/><section className="hero"><HeroFX/><motion.div className="hero-copy" initial={reduced?false:{opacity:0,y:20}} animate={{opacity:1,y:0}} transition={{duration:.6}}><p className="eyebrow">Junior Boy Boxing</p><PunchTitle/><p className="lede">More confidence. More focus. A stronger tomorrow. Boxing for kids and teens, with Coach Sharif in your corner.</p><div className="hero-actions"><AuthCTA signedOut={{label:'Get Started',href:'/signup'}} signedIn={{label:'Book a Class',href:'/schedule'}}/><AuthCTA secondary signedOut={{label:'View Schedule',href:'/schedule'}} signedIn={{label:'My Dashboard',href:'/dashboard'}}/></div><div className="hero-stamp"><Icon name="bolt" size={14}/>Discipline builds champions</div></motion.div><div className="hero-photo"><img src={(settings as Record<string,string>).heroImageUrl||'/assets/images/backgrounds/bg_home_hero_logo.jpg'} alt="Junior Boy Boxing"/><div className="hero-caption"><span>STRONGER KIDS.<br/>BRIGHTER FUTURES.</span><Icon name="north_east" size={34}/></div></div></section><Marquee/><HomeAds/><div className="container"><FeaturedProductsCarousel/></div><section className="section"><div className="container"><div className="section-heading"><div><p className="eyebrow">Invest in their progress</p><h2>Find your rhythm.</h2></div>{isAdmin?<Link href="/admin/plans" className="button secondary small"><Icon name="edit" size={15}/>Edit Plans</Link>:<ActionLink href="/pricing" secondary>All Memberships</ActionLink>}</div><Pricing compact/></div></section><section className="section"><div className="container"><div className="section-heading"><div><p className="eyebrow">Find your program</p><h2>A place to start.<br/>A reason to keep going.</h2></div>{isAdmin?<Link href="/admin/schedule" className="button secondary small"><Icon name="edit" size={15}/>Edit Programs</Link>:<p className="muted" style={{maxWidth:300,fontSize:14}}>Focused coaching. Real fundamentals. Training that meets you where you are.</p>}</div><Programs/><AdditionalPrograms/><ProgramAdsCarousel/></div></section><section className="section"><div className="container two-col"><img className="about-photo" src="/assets/images/photos/boxing_gloves_hanging.png" alt="Boxing gloves at the gym" loading="lazy"/><div><p className="eyebrow">More than boxing</p><h2>Good habits.<br/>Stronger futures.</h2><p className="lede">Every round is a chance to learn. At Junior Boy Boxing, Coach Sharif helps young athletes build the confidence to try, the focus to improve and the discipline to show up.</p><ActionLink href="/about" secondary>Meet your corner</ActionLink><div className="values"><div><strong>Confidence</strong><span>One skill at a time</span></div><div><strong>Discipline</strong><span>Inside and outside the gym</span></div></div></div></div></section><section className="section"><div className="container"><div className="section-heading"><div><p className="eyebrow">Make time to get better</p><h2>Your next round.</h2></div><span className="muted" style={{fontSize:12}}>Live class availability</span></div><Schedule compact/></div></section><section className="section"><div className="container two-col"><div><p className="eyebrow">Our community</p><h2>Progress worth<br/>talking about.</h2><p className="lede">We’re making space for stories from our boxing families. Visit the gym, meet Coach Sharif and see what training can mean for your child.</p><ActionLink href="/contact" secondary>Talk to the coach</ActionLink></div><div><p className="eyebrow">What families say</p><h3>Real results, real reviews.</h3><p className="muted">See what other boxing families have to say, then book your first round.</p><ActionLink href="/reviews" secondary>Read Reviews</ActionLink></div></div></section><CTA/></>;}
export function HomeAds(){const {rows}=useRows('homeAds',[where('isActive','==',true)]);if(!rows.length)return null;const ads=[...rows].sort((a,b)=>a.sortOrder-b.sortOrder).slice(0,4);return <section className="section" style={{paddingTop:0}}><div className="container"><div className="section-heading"><div><p className="eyebrow">Don’t miss out</p><h2>This week’s offers.</h2></div></div><div className="offer-grid">{ads.map(a=><a key={a.id} href={a.linkHref||'/pricing'} className="program offer-tile">{a.imageUrl&&<img src={a.imageUrl} alt="" loading="lazy"/>}<div className="program-info"><h3 style={{fontSize:26}}>{a.title}</h3>{a.description&&<p>{a.description}</p>}<div className="row" style={{gap:10}}>{a.priceLabel&&<strong style={{color:'var(--red)'}}>{a.priceLabel}</strong>}{a.timeLabel&&<span className="muted" style={{fontSize:12}}>{a.timeLabel}</span>}</div></div></a>)}</div></div></section>;}
export function Programs(){
  const {rows}=useRows('classes',[where('isActive','==',true)]);
  const [index,setIndex]=useState(0);
  const trackRef=useRef<HTMLDivElement>(null);
  const scrollTimer=useRef<ReturnType<typeof setTimeout>>();
  useEffect(()=>{
    if (rows.length<2) return;
    const id=setInterval(()=>setIndex(i=>(i+1)%rows.length),5000);
    return ()=>clearInterval(id);
  },[rows.length]);
  useEffect(()=>{
    const el=trackRef.current; if (!el) return;
    el.scrollTo({left:index*el.clientWidth, behavior:'smooth'});
  },[index]);
  if (!rows.length) return null;
  return <div className="featured-carousel">
    <div ref={trackRef} className="featured-track" onScroll={e=>{
      const el=e.currentTarget;
      clearTimeout(scrollTimer.current);
      scrollTimer.current=setTimeout(()=>{
        const i=Math.round(el.scrollLeft/(el.clientWidth||1));
        setIndex(current=>i!==current?i:current);
      },150);
    }}>
      {rows.map(p=>{
        const hasDiscount=p.discountActive===true&&p.discountPercent>0&&p.price>0;
        const saleCents=hasDiscount?Math.round(p.price*(1-p.discountPercent/100)):p.price;
        return <a key={p.id} href={`/schedule?program=${p.id}`} className="featured-slide">
          {p.imageUrl&&<img src={p.imageUrl} alt=""/>}
          <div>
            {p.category&&<span className="featured-eyebrow">{p.category}</span>}
            <h3 style={{margin:0,fontSize:20}}>{p.className}</h3>
            {hasDiscount?<p style={{margin:'6px 0 0'}}><span className="price-was" style={{marginLeft:0,marginRight:8}}>{p.priceLabel}</span><strong style={{color:'var(--green)'}}>{money(saleCents)}</strong></p>:p.priceLabel&&<p className="muted" style={{margin:'6px 0 0',fontSize:13}}>{p.priceLabel}</p>}
          </div>
        </a>;
      })}
    </div>
    {rows.length>1&&<div className="featured-dots">{rows.map((p,i)=><button key={p.id} aria-label={`Go to slide ${i+1}`} className={i===index?'active':''} onClick={()=>setIndex(i)}/>)}</div>}
  </div>;
}
export function CTA(){return <section className="cta-band"><div className="container"><div><p style={{fontSize:11,letterSpacing:2,marginBottom:12}}>YOUR FIRST ROUND STARTS HERE</p><h2>Ready to train?</h2></div><AuthCTA signedOut={{label:'Join Junior Boy Boxing',href:'/signup'}} signedIn={{label:'Book a Class',href:'/schedule'}}/></div></section>;}
export function AboutPage(){const settings=useDocument('gymSettings/config')||gym;return <><div className="container page-wrap"><PageHeading eyebrow="Meet your corner" title="More than boxing.">A stronger future starts with the habits we build today.</PageHeading><div className="two-col"><img className="about-photo" src="/assets/images/photos/photo_kid_boxing.png" alt="Junior boxing training"/><div><p className="eyebrow">{settings.coachName}</p><h2>Train with purpose.</h2><p className="lede">{settings.aboutText}</p><p className="muted">We teach young athletes to listen, practise and improve in a focused training environment.</p><ActionLink href="/contact" secondary>Contact Coach Sharif</ActionLink></div></div><div className="section"><Programs/></div><FAQ/></div><CTA/></>;}
export function ContactPage(){const [busy,setBusy]=useState(false),[message,setMessage]=useState(''),[error,setError]=useState(''),settings=useDocument('gymSettings/config')||gym;async function submit(e:FormEvent<HTMLFormElement>){e.preventDefault();const form=e.currentTarget,data=Object.fromEntries(new FormData(form));setBusy(true);setError('');try{await call('contactGym',data);setMessage('Your message has been sent. The gym will be in touch.');form.reset();}catch(e){setError(errorMessage(e));}finally{setBusy(false);}}return <div className="container page-wrap"><PageHeading eyebrow="We’re in your corner" title="Let’s talk training.">Questions about classes, ages or getting started? Send Coach Sharif a message.</PageHeading><div className="two-col" style={{alignItems:'start'}}><form className="card stack" onSubmit={submit}><label className="field">Your name<input name="name" required minLength={2} maxLength={100} autoComplete="name"/></label><label className="field">Email<input name="email" type="email" required autoComplete="email"/></label><label className="field">Message<textarea name="message" required minLength={10} maxLength={4000}/></label><label className="hidden-trap" aria-hidden="true">Website<input name="website" tabIndex={-1} autoComplete="off"/></label>{error&&<Notice error>{error}</Notice>}{message&&<Notice>{message}</Notice>}<Button busy={busy}>Send Message →</Button></form><div><p><a href={`mailto:${settings.email}`}>{settings.email}</a></p><h3 style={{marginTop:24}}>Operating hours</h3>{Object.entries(settings.operatingHours||{}).length?Object.entries(settings.operatingHours||{}).map(([day,time])=><p className="row spread" key={day}><span>{day}</span><span className="muted">{String(time)}</span></p>):<p className="muted">Contact the gym to confirm training hours.</p>}</div></div></div>;}
