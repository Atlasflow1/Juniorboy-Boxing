'use client';
import { useEffect, useRef } from 'react';
import { AuthForm } from './auth-form';

export function AuthModal({onClose,onSignedIn}:{onClose:()=>void;onSignedIn:()=>void}){
  const ref=useRef<HTMLDialogElement>(null);
  useEffect(()=>{const dialog=ref.current;dialog?.showModal();return()=>dialog?.close();},[]);
  return <dialog ref={ref} className="auth-modal" aria-label="Sign in to continue" onCancel={onClose} onClick={e=>{if(e.target===ref.current)onClose();}}><button type="button" className="auth-modal-close" aria-label="Close sign in" onClick={onClose}>×</button><AuthForm onSignedIn={onSignedIn}/></dialog>;
}
