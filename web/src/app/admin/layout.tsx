import type { Metadata } from 'next';
import { AdminShell } from '@/components/admin/shell';
export const metadata: Metadata = { title: 'Admin Dashboard' };
export default function Layout({children}:{children:React.ReactNode}){return <AdminShell>{children}</AdminShell>;}
