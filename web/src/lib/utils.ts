import { DateTime } from 'luxon';
export const zone = 'America/Los_Angeles';
export function asDate(value: any): Date { return value?.toDate ? value.toDate() : new Date(value); }
export const dateLabel = (value: any) => DateTime.fromJSDate(asDate(value)).setZone(zone).toFormat('ccc, LLL d');
export const timeLabel = (value: any) => DateTime.fromJSDate(asDate(value)).setZone(zone).toFormat('h:mm a');
export const money = (amount: number) => new Intl.NumberFormat('en-US', {style:'currency',currency:'USD'}).format(amount / 100);
export function errorMessage(error: unknown): string {
  const e = error as { code?: string; message?: string; details?: {message?:string}|string };
  const code = (e?.code||'').replace(/^functions\//,'');
  if (['auth/invalid-credential','auth/wrong-password','auth/user-not-found'].includes(e?.code || '')) return 'Check your email and password.';
  if (e?.code === 'auth/email-already-in-use') return 'This email already has an account. Please sign in.';
  if (code === 'unauthenticated') return 'Sign in to continue.';
  if (code === 'permission-denied') return 'You do not have permission to do that.';
  if (code === 'failed-precondition') return (typeof e?.details==='object'?e.details?.message:undefined)||(/^internal(?:\s*\[\d+\])?$/i.test(e?.message||'')?'':e?.message)||'This action is not available yet. Please check your details and try again.';
  if (code === 'internal' || /\binternal\s*\[\d+\]/i.test(e?.message||'')) return 'Something went wrong. Please try again.';
  if (['unavailable','deadline-exceeded','network-request-failed','auth/network-request-failed'].includes(code)) return 'Connection unavailable. Please retry in a moment.';
  return e?.message?.replace(/^Firebase:\s*/,'').replace(/\s*\(auth\/[^)]+\)\.?$/,'') || 'Unable to complete this action. Please retry.';
}
export function downloadCSV(csv: string, filename: string) { const url = URL.createObjectURL(new Blob(['\ufeff',csv], {type:'text/csv;charset=utf-8;'})); const a = document.createElement('a'); a.href = url; a.download = filename; a.click(); URL.revokeObjectURL(url); }
export function isProfileComplete(profile: { childName?: string; childAge?: number; phone?: string; address?: string } | null): boolean {
  return !!profile && !!profile.childName?.trim() && !!profile.childAge && profile.childAge > 0 && !!profile.phone?.trim() && !!profile.address?.trim();
}
export function composeAddress(data: {houseNumber?:string; streetName?:string; city?:string; country?:string}): string {
  return [[data.houseNumber,data.streetName].filter(Boolean).join(' '), data.city, data.country].filter(Boolean).join(', ').trim();
}
