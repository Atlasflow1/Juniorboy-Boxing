'use client';
import { FormEvent, useCallback, useEffect, useState } from 'react';
import { call } from '@/lib/firebase';
import { errorMessage } from '@/lib/utils';
import { useAuth } from '../providers';
import { Button, Empty, Loading, Modal, Notice, PageHeading } from '../ui';

type Permission = 'manageOffers'|'checkIn'|'approveRequests'|'cancelOccurrences'|'refund'|'bookForMember'|'viewRevenue'|'manageMembers'|'manageStore'|'manageContent';
type StaffRow = { uid:string; email:string; displayName:string; role:'admin'|'superAdmin'; permissions:Partial<Record<Permission,boolean>>; lastSignIn:string|null };
const labels:Record<Permission,string> = {
  manageOffers:'Manage sessions and schedule', checkIn:'Check in bookings', approveRequests:'Approve session requests',
  cancelOccurrences:'Cancel occurrences', refund:'Issue refunds', bookForMember:'Book for members',
  viewRevenue:'View revenue and exports', manageMembers:'Manage members', manageStore:'Manage store', manageContent:'Manage content',
};
const permissionNames=Object.keys(labels) as Permission[];
const emptyPermissions=()=>Object.fromEntries(permissionNames.map(name=>[name,true])) as Record<Permission,boolean>;

export function AdminStaff(){
  const {profile,user}=useAuth();
  const [rows,setRows]=useState<StaffRow[]>([]),[loading,setLoading]=useState(true),[error,setError]=useState(''),[message,setMessage]=useState('');
  const [editing,setEditing]=useState<StaffRow|null>(null),[creating,setCreating]=useState(false),[busy,setBusy]=useState(false);
  const refresh=useCallback(async()=>{setLoading(true);try{const result=await call<{staff:StaffRow[]}>('listStaff');setRows(result.staff.sort((a,b)=>a.displayName.localeCompare(b.displayName)));setError('');}catch(e){setError(errorMessage(e));}finally{setLoading(false);}},[]);
  useEffect(()=>{if(profile?.role==='superAdmin')void refresh();},[profile?.role,refresh]);
  if(profile?.role!=='superAdmin')return <Notice error>Super administrator access is required.</Notice>;
  async function save(e:FormEvent<HTMLFormElement>){
    e.preventDefault();const form=new FormData(e.currentTarget);
    const permissions=Object.fromEntries(permissionNames.map(name=>[name,form.get(name)==='on']));
    setBusy(true);setError('');setMessage('');
    try{await call('upsertStaff',{email:String(form.get('email')||'').trim(),displayName:String(form.get('displayName')||'').trim(),role:form.get('role'),permissions});setEditing(null);setCreating(false);setMessage('Staff access saved.');await refresh();}
    catch(err){setError(errorMessage(err));}finally{setBusy(false);}
  }
  async function remove(row:StaffRow){
    if(!window.confirm(`Remove staff access for ${row.displayName || row.email}?`))return;
    setBusy(true);setError('');setMessage('');
    try{await call('removeStaff',{uid:row.uid});setMessage('Staff access removed.');await refresh();}
    catch(err){setError(errorMessage(err));}finally{setBusy(false);}
  }
  const selected=editing||{uid:'',email:'',displayName:'',role:'admin' as const,permissions:emptyPermissions(),lastSignIn:null};
  return <><PageHeading title="Staff." eyebrow="Admin">Manage administrator roles and permissions.</PageHeading><div className="admin-toolbar"><Button onClick={()=>{setEditing(null);setCreating(true);setError('');}}>Add staff</Button></div>
    {error&&<Notice error>{error}</Notice>}{message&&<Notice>{message}</Notice>}
    {loading?<Loading/>:rows.length===0?<Empty>No staff accounts found.</Empty>:<div className="table-wrap"><table><thead><tr><th>Name</th><th>Email</th><th>Role</th><th>Permissions</th><th>Last sign in</th><th>Actions</th></tr></thead><tbody>{rows.map(row=><tr key={row.uid}><td>{row.displayName}</td><td>{row.email}</td><td>{row.role==='superAdmin'?'Super administrator':'Administrator'}</td><td>{row.role==='superAdmin'?'All':permissionNames.filter(name=>row.permissions[name]).map(name=>labels[name]).join(', ')||'None'}</td><td>{row.lastSignIn?new Date(row.lastSignIn).toLocaleString():'Never'}</td><td><div className="row"><Button className="secondary small" onClick={()=>{setEditing(row);setCreating(false);setError('');}}>Edit</Button><Button className="secondary small" disabled={busy||row.uid===user?.uid} onClick={()=>remove(row)}>Remove</Button></div></td></tr>)}</tbody></table></div>}
    {(creating||editing)&&<Modal title={editing?'Edit staff':'Add staff'} onClose={()=>{setEditing(null);setCreating(false);}}><form className="stack" onSubmit={save}><label className="field">Email<input name="email" type="email" defaultValue={selected.email} readOnly={!!editing} required/></label><label className="field">Display name<input name="displayName" defaultValue={selected.displayName} maxLength={100} required/></label><label className="field">Role<select name="role" defaultValue={selected.role}><option value="admin">Administrator</option><option value="superAdmin">Super administrator</option></select></label><fieldset><legend>Permissions (administrator role)</legend><div className="stack">{permissionNames.map(name=><label className="check-field" key={name}><input name={name} type="checkbox" defaultChecked={!!selected.permissions[name]}/>{labels[name]}</label>)}</div></fieldset>{error&&<Notice error>{error}</Notice>}<Button busy={busy}>{editing?'Save changes':'Add staff'}</Button></form></Modal>}</>;
}
