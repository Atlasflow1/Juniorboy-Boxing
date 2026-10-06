'use client';
import { ReactNode, useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from './providers';
import { useDocument } from '@/lib/hooks';
import { gym } from '@/lib/types';
import { isProfileComplete } from '@/lib/utils';
import { Icon, SocialIcon } from './ui';
const PROFILE_GATE_EXEMPT = ['/complete-profile','/signin','/signup','/waiver','/privacy','/terms','/contact','/about','/blog','/reviews','/store','/'];
function ThemeToggle(){
  const [dark,setDark]=useState(false);
  useEffect(()=>{setDark(document.documentElement.getAttribute('data-theme')==='dark'||(!document.documentElement.hasAttribute('data-theme')&&matchMedia('(prefers-color-scheme: dark)').matches));},[]);
  function toggle(){const next=!dark;setDark(next);document.documentElement.setAttribute('data-theme',next?'dark':'light');try{localStorage.setItem('jbb-theme',next?'dark':'light');}catch{}}
  return <button type="button" className="icon-button" aria-label={dark?'Use light theme':'Use dark theme'} onClick={toggle}><Icon name={dark?'light_mode':'dark_mode'}/></button>;
}
export function SocialLinks({links}:{links:Record<string,string>}){return <div className="footer-social">{(['instagram','facebook','tiktok'] as const).filter(name=>/^https:\/\//.test(links?.[name]||'')).map(name=><a key={name} href={links[name]} target="_blank" rel="noreferrer" aria-label={name} className="social-icon-btn"><SocialIcon name={name}/></a>)}</div>;}
export function SiteShell({children}:{children:ReactNode}){
  const path=usePathname(),router=useRouter(),{user,profile,loading}=useAuth(),settings=useDocument('gymSettings/config')||gym;
  useEffect(()=>{if(!loading&&user&&profile&&!isProfileComplete(profile as any)&&!PROFILE_GATE_EXEMPT.includes(path)&&!['/offers','/store/'].some(prefix=>path.startsWith(prefix)))router.replace('/complete-profile');},[loading,user,profile,path,router]);
  if(path.startsWith('/admin'))return <>{children}</>;
  const links=[['Sessions','/offers'],['Shop','/store'],['Account',user?'/dashboard':'/signin']];
  return <><header className="site-header"><Link className="wordmark" href="/" aria-label="Junior Boy Boxing home">JUNIOR BOY <em>BOXING</em></Link><nav className="site-nav" aria-label="Main navigation">{links.map(([label,href])=><Link aria-current={path===href?'page':undefined} href={href} key={label}>{label}</Link>)}</nav><ThemeToggle/></header><main id="main">{children}</main><footer className="site-footer"><div className="footer-top"><Link className="wordmark" href="/">JUNIOR BOY <em>BOXING</em></Link><SocialLinks links={settings.socialLinks||{}}/></div><div className="footer-bottom"><span>© {new Date().getFullYear()} Junior Boy Boxing</span><div><Link href="/privacy">Privacy</Link><Link href="/terms">Terms</Link><Link href="/waiver">Waiver</Link></div></div></footer></>;
}
