'use client';
import { FormEvent,useEffect,useState } from 'react';
import { DateTime } from 'luxon';
import { orderBy,where } from 'firebase/firestore';
import { getDownloadURL,ref,uploadBytes } from 'firebase/storage';
import { call,storage } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { Row } from '@/lib/types';
import { asDate,dateLabel,errorMessage,money,timeLabel,zone } from '@/lib/utils';
import { Button,Empty,Loading,Modal,Notice } from '../ui';
import { useAuth } from '../providers';
import { can } from '@/lib/permissions';
import { cents,compressImage,localInput,pacificDateTime,TrainingType,typeLabel,types,weekdays } from './offer-shared';

type Frequency='none'|'weekly'|'monthly'|'yearly';
type Action='draft'|'publish'|'schedule';
type OfferForm={templateId:string;title:string;description:string;trainingType:TrainingType;price:string;capacity:number;durationMinutes:number;ageGroup:string;imageUrl:string;frequency:Frequency;startDate:string;startTime:string;weekdays:number[];endMode:'date'|'count';endDate:string;count:number;showOnHome:boolean;homeOrder:number;publishAt:string};
function fromRow(row:Row):OfferForm {const r=row.recurrence||{};return {templateId:row.templateId||'',title:row.title||'',description:row.description||'',trainingType:row.trainingType||'private',price:row.priceCents?String(row.priceCents/100):'',capacity:row.capacity||1,durationMinutes:row.durationMinutes||60,ageGroup:row.ageGroup||'',imageUrl:row.imageUrl||'',frequency:r.frequency||'none',startDate:r.startDate||DateTime.now().setZone(zone).toISODate()||'',startTime:r.startTime||'16:00',weekdays:r.weekdays||[],endMode:r.endDate?'date':'count',endDate:r.endDate||'',count:r.count||1,showOnHome:!!row.showOnHome,homeOrder:row.homeOrder??100,publishAt:localInput(row.publishAt)};}
export function AdminOfferEditor({row,onClose}:{row:Row;onClose:()=>void}){
  const [form,setForm]=useState<OfferForm>(()=>fromRow(row)),[file,setFile]=useState<File|null>(null),[preview,setPreview]=useState(''),[busy,setBusy]=useState(false),[error,setError]=useState(''),[savedOfferId,setSavedOfferId]=useState(row.id);
  const templates=useRows('offerTemplates');const dates=useRows(row.id?'offerOccurrences':null,row.id?[where('offerId','==',row.id),orderBy('startAt')]:[],row.id);
  useEffect(()=>{if(!file)return;const url=URL.createObjectURL(file);setPreview(url);return()=>URL.revokeObjectURL(url);},[file]);
  function update<K extends keyof OfferForm>(key:K,value:OfferForm[K]){setForm(previous=>({...previous,[key]:value}));}
  function pickTemplate(templateId:string){const t=templates.rows.find(item=>item.id===templateId);if(!t){update('templateId','');return;}setForm(previous=>({...previous,templateId,title:t.title,description:t.description,trainingType:t.trainingType,price:String(t.defaultPriceCents/100),capacity:t.defaultCapacity,durationMinutes:t.durationMinutes,ageGroup:t.ageGroup,imageUrl:t.imageUrl||''}));setFile(null);setPreview('');}
  function pickType(value:TrainingType){setForm(previous=>({...previous,trainingType:value,capacity:value==='private'?1:value==='duo'?2:Math.max(3,previous.capacity)}));}
  async function save(action:Action){
    setBusy(true);setError('');try{
      const priceCents=cents(form.price),repeat=form.frequency!=='none';
      if(repeat&&form.frequency==='weekly'&&!form.weekdays.length)throw new Error('Choose at least one weekday.');
      if(repeat&&form.endMode==='date'&&!form.endDate)throw new Error('Choose an end date.');
      if(repeat&&form.endMode==='count'&&(!Number.isInteger(form.count)||form.count<1||form.count>104))throw new Error('Count must be between 1 and 104.');
      if(!Number.isInteger(form.homeOrder))throw new Error('Home order must be a whole number.');
      const publishAt=action==='schedule'?pacificDateTime(form.publishAt):null;
      if(action==='schedule'&&publishAt!==null&&publishAt<=Date.now())throw new Error('Choose a future publication time.');
      const base={templateId:form.templateId||null,title:form.title.trim(),description:form.description.trim(),trainingType:form.trainingType,priceCents,capacity:form.capacity,durationMinutes:form.durationMinutes,ageGroup:form.ageGroup.trim(),imageUrl:form.imageUrl||null,recurrence:{frequency:form.frequency,startDate:form.startDate,startTime:form.startTime,weekdays:form.frequency==='weekly'?[...form.weekdays].sort((a,b)=>a-b):[],endDate:repeat&&form.endMode==='date'?form.endDate:null,count:repeat&&form.endMode==='count'?form.count:null},showOnHome:form.showOnHome,homeOrder:form.homeOrder};
      let offerId=savedOfferId;
      if(file){
        const blob=await compressImage(file);if(blob.size>5*1024*1024)throw new Error('Compressed image exceeds 5 MB.');
        if(!offerId){const created=await call<{offerId:string}>('saveOffer',{...base,action:'draft',publishAt:null});offerId=created.offerId;setSavedOfferId(offerId);}
        const target=ref(storage,`offers/${offerId}/${crypto.randomUUID()}.jpg`);await uploadBytes(target,blob,{contentType:'image/jpeg'});base.imageUrl=await getDownloadURL(target);
      }
      await call('saveOffer',{...base,...(offerId?{offerId}:{}),action,publishAt});
      setFile(null);setPreview('');onClose();
    }catch(e){setError(errorMessage(e));}finally{setBusy(false);}
  }
  return <>{row.propagationPending&&<Notice>Updating dates…</Notice>}
    <form className="stack" onSubmit={(event:FormEvent)=>{event.preventDefault();save('draft');}}>
      <label className="field">Start from template<select value={form.templateId} onChange={e=>pickTemplate(e.target.value)}><option value="">No template</option>{templates.rows.filter(t=>t.isActive).map(t=><option key={t.id} value={t.id}>{t.title}</option>)}</select></label>
      {templates.error&&<Notice error>{templates.error}</Notice>}
      <label className="field">Title<input maxLength={80} required value={form.title} onChange={e=>update('title',e.target.value)}/></label>
      <label className="field">Description<textarea maxLength={1000} value={form.description} onChange={e=>update('description',e.target.value)}/></label>
      <div className="field-grid"><label className="field">Type<select value={form.trainingType} onChange={e=>pickType(e.target.value as TrainingType)}>{types.map(t=><option key={t} value={t}>{typeLabel(t)}</option>)}</select></label><label className="field">Seats<input type="number" min={form.trainingType==='group'?3:form.capacity} max={form.trainingType==='group'?50:form.capacity} readOnly={form.trainingType!=='group'} required value={form.capacity} onChange={e=>update('capacity',Number(e.target.value))}/></label></div>
      <div className="field-grid"><label className="field">Price per seat (USD)<input inputMode="decimal" required value={form.price} onChange={e=>update('price',e.target.value)}/></label><label className="field">Duration (minutes)<input type="number" min={15} max={240} required value={form.durationMinutes} onChange={e=>update('durationMinutes',Number(e.target.value))}/></label></div>
      <label className="field">Age group<input maxLength={40} value={form.ageGroup} onChange={e=>update('ageGroup',e.target.value)}/></label>
      <div className="field">Image (JPG, PNG, WebP; up to 5 MB)<div className="photo-grid">{(preview||form.imageUrl)?<div className="photo-slot"><img src={preview||form.imageUrl} alt="Session preview"/><button className="photo-remove" type="button" aria-label="Remove image" onClick={()=>{setFile(null);setPreview('');update('imageUrl','');}}>✕</button></div>:<label className="photo-add">+<input type="file" accept="image/jpeg,image/png,image/webp" style={{display:'none'}} onChange={e=>{const next=e.target.files?.[0];if(next){if(next.size>5*1024*1024||!['image/jpeg','image/png','image/webp'].includes(next.type)){setError('Choose a JPG, PNG or WebP image no larger than 5 MB.');return;}setFile(next);setError('');}}}/></label>}</div></div>
      <label className="field">Repeat<select value={form.frequency} onChange={e=>update('frequency',e.target.value as Frequency)}><option value="none">None</option><option value="weekly">Weekly</option><option value="monthly">Monthly</option><option value="yearly">Yearly</option></select></label>
      <div className="field-grid"><label className="field">Start date · Pacific<input type="date" required value={form.startDate} onChange={e=>update('startDate',e.target.value)}/></label><label className="field">Start time · Pacific<input type="time" required value={form.startTime} onChange={e=>update('startTime',e.target.value)}/></label></div>
      {form.frequency==='weekly'&&<div className="field">Weekdays<div className="row" style={{flexWrap:'wrap'}}>{weekdays.map((day,index)=><label key={day} className="check-field"><input type="checkbox" checked={form.weekdays.includes(index+1)} onChange={e=>update('weekdays',e.target.checked?[...form.weekdays,index+1].sort((a,b)=>a-b):form.weekdays.filter(d=>d!==index+1))}/>{day}</label>)}</div></div>}
      {form.frequency!=='none'&&<><div className="row"><label className="check-field"><input type="radio" name="endMode" checked={form.endMode==='date'} onChange={()=>update('endMode','date')}/>End by date</label><label className="check-field"><input type="radio" name="endMode" checked={form.endMode==='count'} onChange={()=>update('endMode','count')}/>End after count</label></div>{form.endMode==='date'?<label className="field">End date<input type="date" min={form.startDate} required value={form.endDate} onChange={e=>update('endDate',e.target.value)}/></label>:<label className="field">Number of dates<input type="number" min={1} max={104} required value={form.count} onChange={e=>update('count',Number(e.target.value))}/></label>}</>}
      <label className="check-field"><input type="checkbox" checked={form.showOnHome} onChange={e=>update('showOnHome',e.target.checked)}/>Show on Home</label><label className="field">Home order<input type="number" step={1} required value={form.homeOrder} onChange={e=>update('homeOrder',Number(e.target.value))}/></label>
      <label className="field">Schedule publication · Pacific<input type="datetime-local" value={form.publishAt} onChange={e=>update('publishAt',e.target.value)}/></label>
      {error&&<Notice error>{error}</Notice>}<div className="row" style={{flexWrap:'wrap'}}><Button type="submit" busy={busy}>Save draft</Button><Button type="button" className="secondary" busy={busy} onClick={()=>save('publish')}>Publish now</Button><Button type="button" className="secondary" busy={busy} onClick={()=>save('schedule')}>Schedule for…</Button></div>
    </form>{row.id&&<Occurrences rows={dates.rows} loading={dates.loading} error={dates.error} type={form.trainingType}/>}</>;
}
function Occurrences({rows,loading,error,type}:{rows:Row[];loading:boolean;error:string;type:TrainingType}){
  const {profile}=useAuth();const canCancel=can(profile,'cancelOccurrences');
  const [selected,setSelected]=useState<Row|null>(null);const [cancelling,setCancelling]=useState<Row|null>(null);const upcoming=rows.filter(r=>asDate(r.startAt).getTime()>=Date.now());
  return <section style={{marginTop:36}}><h2>Upcoming dates</h2>{error&&<Notice error>{error}</Notice>}{loading?<Loading/>:upcoming.length?<div className="stack">{upcoming.map(date=><article className="card row spread" key={date.id}><div><strong>{dateLabel(date.startAt)} · {timeLabel(date.startAt)}</strong><p className="muted" style={{margin:0}}>{date.seatsTaken}/{date.capacity} seats taken · {money(date.priceCents)} · {date.status}{date.isOverride?' · Edited':''}</p></div><div className="row" style={{gap:8}}><Button className="secondary small" disabled={date.status!=='open'} onClick={()=>setSelected(date)}>Edit this date</Button>{canCancel&&<Button className="secondary small" disabled={date.status!=='open'} onClick={()=>setCancelling(date)}>Cancel date</Button>}</div></article>)}</div>:<Empty>No upcoming dates.</Empty>}{selected&&<OccurrenceEditor row={selected} type={type} onClose={()=>setSelected(null)}/>}{cancelling&&<CancelOccurrenceDialog row={cancelling} onClose={()=>setCancelling(null)}/>}</section>;
}
function CancelOccurrenceDialog({row,onClose}:{row:Row;onClose:()=>void}){
  const [reason,setReason]=useState(''),[busy,setBusy]=useState(false),[error,setError]=useState('');
  async function submit(e:FormEvent){e.preventDefault();if(!reason.trim()){setError('Cancellation reason is required.');return;}setBusy(true);setError('');try{await call('cancelOccurrence',{occurrenceId:row.id,reason:reason.trim()});onClose();}catch(err){setError(errorMessage(err));}finally{setBusy(false);}}
  return <Modal title="Cancel date" onClose={onClose}><form className="stack" onSubmit={submit}><p><strong>{dateLabel(row.startAt)} · {timeLabel(row.startAt)}</strong></p><p className="muted">All booked members will receive a full refund and be notified. Held seats will be released.</p><label className="field">Reason for cancellation<textarea rows={3} required value={reason} onChange={e=>setReason(e.target.value)} placeholder="e.g. Coach sick, gym maintenance"/></label>{error&&<Notice error>{error}</Notice>}<div className="row" style={{justifyContent:'flex-end',gap:8}}><Button type="button" className="secondary" disabled={busy} onClick={onClose}>Keep date</Button><Button type="submit" busy={busy}>Cancel date</Button></div></form></Modal>;
}
function OccurrenceEditor({row,type,onClose}:{row:Row;type:TrainingType;onClose:()=>void}){
  const [time,setTime]=useState(DateTime.fromJSDate(asDate(row.startAt)).setZone(zone).toFormat('HH:mm')),[price,setPrice]=useState(String(row.priceCents/100)),[capacity,setCapacity]=useState(row.capacity),[busy,setBusy]=useState(false),[error,setError]=useState('');
  async function save(e:FormEvent){e.preventDefault();setBusy(true);setError('');try{await call('saveOccurrenceOverride',{occurrenceId:row.id,...(time!==DateTime.fromJSDate(asDate(row.startAt)).setZone(zone).toFormat('HH:mm')?{startTime:time}:{}),priceCents:cents(price),capacity});onClose();}catch(e){setError(errorMessage(e));}finally{setBusy(false);}}
  return <Modal title="Edit this date" onClose={onClose}><form className="stack" onSubmit={save}><p>{dateLabel(row.startAt)} · Pacific time</p><label className="field">Start time<input type="time" value={time} disabled={row.seatsTaken>0} onChange={e=>setTime(e.target.value)}/></label>{row.seatsTaken>0&&<Notice>Time cannot change because seats are taken. Cancel this date instead.</Notice>}<label className="field">Price per seat (USD)<input value={price} onChange={e=>setPrice(e.target.value)} required/></label><label className="field">Capacity<input type="number" min={type==='group'?Math.max(3,row.seatsTaken):row.capacity} max={type==='group'?50:row.capacity} readOnly={type!=='group'} value={capacity} onChange={e=>setCapacity(Number(e.target.value))}/></label>{error&&<Notice error>{error}</Notice>}<Button busy={busy}>Save date</Button></form></Modal>;
}
