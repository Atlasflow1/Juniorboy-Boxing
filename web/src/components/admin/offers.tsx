'use client';
import { useState } from 'react';
import Link from 'next/link';
import { call } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { Row } from '@/lib/types';
import { dateLabel,errorMessage,money } from '@/lib/utils';
import { Button,Empty,Loading,Modal,Notice,PageHeading } from '../ui';
import { AdminOfferEditor } from './offer-editor';
import { typeLabel } from './offer-shared';

const statuses=['draft','scheduled','published','ended','archived'] as const;
export function AdminOffers(){
  const data=useRows('offers'),[status,setStatus]=useState('all'),[home,setHome]=useState(false),[error,setError]=useState(''),[busy,setBusy]=useState(''),[selected,setSelected]=useState<Row|null>(null);
  const rows=data.rows.filter(row=>(status==='all'||row.status===status)&&(!home||row.showOnHome)).sort((a,b)=>(a.homeOrder??100)-(b.homeOrder??100));
  async function change(row:Row,next:'published'|'draft'|'archived'|'scheduled'){
    if(next==='archived'&&!window.confirm(`Archive "${row.title}"? Future booked dates must be cancelled first.`))return;
    let publishAt:number|undefined;
    if(next==='scheduled'){
      const answer=window.prompt('Publish at (Pacific time, YYYY-MM-DDTHH:mm)');if(!answer)return;
      const {pacificDateTime}=await import('./offer-shared');
      try{publishAt=pacificDateTime(answer);if(publishAt<=Date.now())throw new Error('Choose a future publication time.');}catch(e){setError(errorMessage(e));return;}
    }
    setBusy(row.id);setError('');try{await call('setOfferStatus',{offerId:row.id,status:next,...(publishAt?{publishAt}:{})});}catch(e){setError(errorMessage(e));}finally{setBusy('');}
  }
  async function placement(row:Row,showOnHome:boolean,homeOrder:number){setBusy(row.id);setError('');try{await call('setOfferPlacement',{offerId:row.id,showOnHome,homeOrder});}catch(e){setError(errorMessage(e));}finally{setBusy('');}}
  return <><PageHeading title="Sessions." eyebrow="Admin"/><div className="admin-toolbar"><Button onClick={()=>setSelected({id:''})}>New session</Button><Link className="button secondary" href="/admin/offers/templates">Templates</Link></div>
    <div className="row" style={{flexWrap:'wrap',marginBottom:16}} aria-label="Session filters"><Button className={status==='all'?'small':'secondary small'} onClick={()=>setStatus('all')}>All</Button>{statuses.map(item=><Button key={item} className={status===item?'small':'secondary small'} onClick={()=>setStatus(item)}>{item[0].toUpperCase()+item.slice(1)}</Button>)}<label className="check-field"><input type="checkbox" checked={home} onChange={e=>setHome(e.target.checked)}/>On Home</label></div>
    {(error||data.error)&&<Notice error>{error||data.error}</Notice>}{data.loading?<Loading/>:rows.length===0?<Empty>No sessions match this filter.</Empty>:<div className="table-wrap"><table><thead><tr><th>Title</th><th>Type</th><th>Price</th><th>Seats</th><th>Next date</th><th>Status</th><th>Home order</th><th>Actions</th></tr></thead><tbody>{rows.map(row=><tr key={row.id}><td><strong>{row.title}</strong>{row.propagationPending&&<span className="badge">Updating dates…</span>}</td><td>{typeLabel(row.trainingType)}</td><td>{money(row.priceCents||0)}</td><td>{row.capacity}</td><td>{row.nextOccurrenceAt?dateLabel(row.nextOccurrenceAt):'—'}</td><td><span className={`status ${row.status}`}>{row.status}</span></td><td><label className="check-field"><input aria-label={`Show ${row.title} on Home`} type="checkbox" checked={!!row.showOnHome} disabled={busy===row.id} onChange={e=>placement(row,e.target.checked,row.homeOrder??100)}/>Show</label><input aria-label={`Home order for ${row.title}`} type="number" defaultValue={row.homeOrder??100} key={`${row.id}:${row.homeOrder}`} style={{width:72}} disabled={busy===row.id} onBlur={e=>{const order=Number(e.target.value);if(Number.isInteger(order)&&order!==(row.homeOrder??100))placement(row,!!row.showOnHome,order);}}/></td><td><div className="row" style={{flexWrap:'wrap'}}><Button className="secondary small" onClick={()=>setSelected(row)}>Edit</Button>{row.status==='draft'&&<><Button className="secondary small" disabled={busy===row.id} onClick={()=>change(row,'published')}>Publish</Button><Button className="secondary small" disabled={busy===row.id} onClick={()=>change(row,'scheduled')}>Schedule…</Button></>}{['published','scheduled'].includes(row.status)&&<Button className="secondary small" disabled={busy===row.id} onClick={()=>change(row,'draft')}>Back to draft</Button>}{row.status!=='archived'&&<Button className="secondary small" disabled={busy===row.id} onClick={()=>change(row,'archived')}>Archive</Button>}</div></td></tr>)}</tbody></table></div>}{selected&&<Modal title={selected.id?'Edit session':'New session'} onClose={()=>setSelected(null)}><AdminOfferEditor key={selected.id||'new'} row={selected} onClose={()=>setSelected(null)}/></Modal>}</>;
}
