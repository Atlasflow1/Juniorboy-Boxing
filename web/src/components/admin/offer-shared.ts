import { DateTime } from 'luxon';
import { zone } from '@/lib/utils';

export const types = ['private','duo','group'] as const;
export type TrainingType = typeof types[number];
export const typeLabel = (value:string) => value === 'private' ? 'Private' : value === 'duo' ? 'Duo' : 'Group';
export const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
export function cents(value:string):number {
  if (!/^(?:\d+)(?:\.\d{1,2})?$/.test(value.trim())) throw new Error('Enter a dollar amount with at most two decimal places.');
  const [dollars, fraction=''] = value.trim().split('.');
  const amount = Number(dollars) * 100 + Number(fraction.padEnd(2,'0'));
  if (!Number.isSafeInteger(amount) || amount < 1 || amount > 100000) throw new Error('Price must be between $0.01 and $1,000.00.');
  return amount;
}
export function pacificDateTime(value:string):number {
  const date = DateTime.fromFormat(value,"yyyy-MM-dd'T'HH:mm",{zone});
  if (!date.isValid) throw new Error('Choose a valid Pacific date and time.');
  return date.toMillis();
}
export function localInput(value:unknown):string {
  const date = (value as {toDate?:()=>Date})?.toDate?.() ?? (value instanceof Date ? value : null);
  return date ? DateTime.fromJSDate(date).setZone(zone).toFormat("yyyy-MM-dd'T'HH:mm") : '';
}
export function compressImage(file:File):Promise<Blob> {
  if (!['image/jpeg','image/png','image/webp'].includes(file.type) || file.size > 5*1024*1024) throw new Error('Choose a JPG, PNG or WebP image no larger than 5 MB.');
  return new Promise((resolve,reject)=>{
    const url=URL.createObjectURL(file),image=new Image();
    image.onload=()=>{
      URL.revokeObjectURL(url);
      const scale=Math.min(1,1600/Math.max(image.width,image.height));
      const canvas=document.createElement('canvas');canvas.width=Math.round(image.width*scale);canvas.height=Math.round(image.height*scale);
      canvas.getContext('2d')?.drawImage(image,0,0,canvas.width,canvas.height);
      canvas.toBlob(blob=>blob?resolve(blob):reject(new Error('Could not compress this image.')),'image/jpeg',0.85);
    };
    image.onerror=()=>{URL.revokeObjectURL(url);reject(new Error('Could not read this image.'));};
    image.src=url;
  });
}
