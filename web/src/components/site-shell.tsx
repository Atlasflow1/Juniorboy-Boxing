'use client';
import { ReactNode, useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from './providers';
import { useDocument } from '@/lib/hooks';
import { gym } from '@/lib/types';
import { Icon } from './ui';
import { SiteFX } from './fx';
function BackgroundToggle() {
  const [isBlack,setIsBlack] = useState(false);
  useEffect(()=>{setIsBlack(document.documentElement.getAttribute('data-theme')==='black');},[]);
  function toggle() {
    const next = !isBlack;
    setIsBlack(next);
    if (next) document.documentElement.setAttribute('data-theme','black');
    else document.documentElement.removeAttribute('data-theme');
    try { localStorage.setItem('jbb-bg-theme', next?'black':'teal'); } catch { /* storage blocked */ }
  }
  return <button type="button" className="icon-button" aria-label={isBlack?'Switch to teal background':'Switch to black background'} onClick={toggle}><Icon name={isBlack?'dark_mode':'circle'}/></button>;
}
export function SiteShell({children}:{children:ReactNode}) {
  const [open,setOpen]=useState(false),path=usePathname(),{user,loading}=useAuth(),settings=useDocument('gymSettings/config')||gym;
  if(path.startsWith('/admin')) return <>{children}</>;
  return <><SiteFX/><header className="site-header"><Link className="wordmark" href="/" aria-label="Junior Boy Boxing home">JUNIOR BOY <em>BOXING</em></Link><nav className={open?'site-nav open':'site-nav'} aria-label="Main navigation">{[['Programs','/programs'],['Schedule','/schedule'],['Membership','/pricing'],['Store','/store'],['Reviews','/reviews'],['Contact','/contact']].map(([label,href])=><Link onClick={()=>setOpen(false)} aria-current={path===href?'page':undefined} href={href} key={href}>{label}</Link>)}<Link onClick={()=>setOpen(false)} className="nav-cta" href={user?'/dashboard':'/signin'}>{user?'My Account':'Sign In'} <Icon name="north_east" size={16}/></Link></nav><BackgroundToggle/><button className="mobile-menu icon-button" aria-label={open?'Close menu':'Open menu'} aria-expanded={open} onClick={()=>setOpen(!open)}>{open?<Icon name="close"/>:<Icon name="menu"/>}</button></header><main id="main">{children}</main><footer className="site-footer"><div className="footer-top"><div><Link className="wordmark" href="/">JUNIOR BOY <em>BOXING</em></Link><p>Stronger kids. Brighter futures.</p></div><p><Icon name="location_on" size={18}/> {settings.address}</p>{loading ? <span className="footer-cta skel-text" aria-hidden="true"/> : <Link href={user?'/schedule':'/signup'} className="footer-cta">{user?'Book a Class':'Step into your corner'} <Icon name="north_east"/></Link>}</div><div className="footer-bottom"><span>© {new Date().getFullYear()} Junior Boy Boxing</span><div><Link href="/privacy">Privacy</Link><Link href="/terms">Terms</Link><Link href="/waiver">Waiver & Disclaimer</Link><Link href="/contact">Contact</Link>{Object.entries(settings.socialLinks||{}).filter(([,url])=>url&&/^https:\/\//.test(String(url))).map(([name,url])=><a key={name} href={String(url)} target="_blank" rel="noreferrer">{name}</a>)}</div></div></footer></>;
}
