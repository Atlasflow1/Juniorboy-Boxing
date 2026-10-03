'use client';
import { ButtonHTMLAttributes, CSSProperties, MouseEventHandler, ReactNode, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useAuth } from './providers';
export function Icon({name,size=20,outlined=true,className='',style,onClick}:{name:string;size?:number;outlined?:boolean;className?:string;style?:CSSProperties;onClick?:MouseEventHandler<HTMLSpanElement>}) {
  return <span aria-hidden="true" translate="no" onClick={onClick} className={`notranslate ${outlined?'material-icons-outlined':'material-icons'}${className?' '+className:''}`} style={{fontSize:size,...style}}>{name}</span>;
}
export function Button({children,busy,...props}:ButtonHTMLAttributes<HTMLButtonElement>&{busy?:boolean}) { return <button {...props} className={`button ${props.className||''}`} disabled={busy||props.disabled}>{busy?<Icon name="autorenew" className="spin" size={18}/>:null}{children}</button>; }
export function ActionLink({href,children,secondary=false}:{href:string;children:ReactNode;secondary?:boolean}) { return <Link className={`button ${secondary?'secondary':''}`} href={href}>{children}<Icon name="arrow_forward" size={17}/></Link>; }
/** A signup-CTA that switches copy/destination once we know the visitor's auth state, with a same-size skeleton while that's still loading (avoids flicker/layout shift). */
export function AuthCTA({signedOut,signedIn,secondary=false}:{signedOut:{label:string;href:string};signedIn:{label:string;href:string};secondary?:boolean}) {
  const {user,loading} = useAuth();
  if (loading) return <span className={`button skel-btn${secondary?' secondary':''}`} aria-hidden="true"/>;
  const target = user ? signedIn : signedOut;
  return <ActionLink href={target.href} secondary={secondary}>{target.label}</ActionLink>;
}
export function Notice({children,error=false}:{children:ReactNode;error?:boolean}) { return <div role={error?'alert':'status'} className={`notice ${error?'error':''}`}>{children}</div>; }
export function Loading() {return <div aria-label="Loading" className="loading"><Icon name="autorenew" className="spin"/> Loading…</div>;}
export function Empty({children}:{children:ReactNode}) {return <div className="empty">{children}</div>;}
export function Modal({title,onClose,children}:{title:string;onClose:()=>void;children:ReactNode}) {
  const ref=useRef<HTMLDialogElement>(null);
  useEffect(()=>{ref.current?.showModal(); const prior=document.body.style.overflow;document.body.style.overflow='hidden';return()=>{document.body.style.overflow=prior;};},[]);
  return <dialog ref={ref} className="modal" onCancel={onClose} onClick={e=>{if(e.target===ref.current) onClose();}}><div className="modal-head"><h2>{title}</h2><button className="icon-button" aria-label="Close dialog" onClick={onClose}><Icon name="close"/></button></div>{children}</dialog>;
}
export function PageHeading({eyebrow,title,children}:{eyebrow?:string;title:string;children?:ReactNode}) {return <div className="page-heading">{eyebrow&&<p className="eyebrow">{eyebrow}</p>}<h1>{title}</h1>{children&&<p className="lede">{children}</p>}</div>;}
