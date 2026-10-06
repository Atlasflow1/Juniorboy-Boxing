'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { DateTime } from 'luxon';
import { limit, orderBy } from 'firebase/firestore';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  BarChart,
  Bar,
  CartesianGrid,
} from 'recharts';
import { call } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { useMemberProfiles } from '@/lib/member-cache';
import { Row } from '@/lib/types';
import { dateLabel, money, errorMessage, zone } from '@/lib/utils';
import { Loading, Notice, PageHeading, Icon } from '../ui';
import { MemberCell } from './member-cell';

export function AdminOverview() {
  const [stats, setStats] = useState<Row | null>(null);
  const [error, setError] = useState('');
  const today = DateTime.now().setZone(zone).startOf('day');
  const bookings = useRows('bookings', [orderBy('bookedAt', 'desc'), limit(10)]);
  const profiles = useMemberProfiles(bookings.rows.map((b) => b.userId as string));

  useEffect(() => {
    call<Row>('getDashboardStats')
      .then(setStats)
      .catch((e) => setError(errorMessage(e)));
  }, []);

  return (
    <>
      <PageHeading eyebrow={today.toFormat('cccc, LLLL d')} title="Good to have you, Coach.">
        Here’s what’s happening at the gym.
      </PageHeading>

      <div style={{ marginBottom: 24 }}>
        <Link
          href="/admin/gallery"
          className="card row"
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: 14,
            padding: '12px 18px',
            textDecoration: 'none',
          }}
        >
          <span
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 36,
              height: 36,
              borderRadius: 8,
              background: 'var(--accent-tint)',
              color: 'var(--red)',
            }}
          >
            <Icon name="photo_library" size={20} />
          </span>
          <div>
            <strong style={{ fontSize: 14, display: 'block' }}>Kids photos</strong>
            <span className="muted" style={{ fontSize: 12 }}>
              Photos shown on the home page in &apos;Our fighters, in their corner&apos;
            </span>
          </div>
          <Icon name="arrow_forward" size={16} className="muted" />
        </Link>
      </div>

      {error && <Notice error>{error}</Notice>}

      {!stats && !error ? (
        <Loading />
      ) : (
        stats && (
          <>
            <div className="stats-grid">
              {[
                ['Total Members', stats.totalMembers],
                ['Bookings Today', stats.bookingsToday],
                ...(stats.revenueThisMonth === null
                  ? []
                  : [['Revenue This Month', money(stats.revenueThisMonth)]]),
                ['Active Plans', stats.activePlans],
              ].map(([title, value]) => (
                <div className="card stat" key={title}>
                  <span>{title}</span>
                  <strong>{value}</strong>
                </div>
              ))}
            </div>

            <div className="charts">
              {stats.revenue !== null && (
                <div className="card chart-card">
                  <h3>Revenue · last 30 days</h3>
                  <div className="chart">
                    <ResponsiveContainer width="100%" height="100%">
                      <LineChart data={stats.revenue}>
                        <CartesianGrid stroke="#292929" vertical={false} />
                        <XAxis
                          dataKey="date"
                          tick={{ fontSize: 10, fill: '#888' }}
                          tickFormatter={(v) => v.slice(5)}
                        />
                        <YAxis
                          tick={{ fontSize: 10, fill: '#888' }}
                          tickFormatter={(v) => `$${v / 100}`}
                        />
                        <Tooltip
                          contentStyle={{ background: '#181818', border: '1px solid #444' }}
                          formatter={(v: number) => money(v)}
                        />
                        <Line
                          type="monotone"
                          dataKey="amount"
                          stroke="#E50914"
                          strokeWidth={2}
                          dot={false}
                        />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                </div>
              )}

              <div className="card chart-card">
                <h3>Popular classes</h3>
                <div className="chart">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={stats.popularClasses}>
                      <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#888' }} />
                      <YAxis allowDecimals={false} tick={{ fontSize: 10, fill: '#888' }} />
                      <Tooltip
                        contentStyle={{ background: '#181818', border: '1px solid #444' }}
                      />
                      <Bar dataKey="count" fill="#E50914" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>
          </>
        )
      )}

      <h2 style={{ fontSize: 26, marginTop: 34 }}>Recent bookings</h2>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Class</th>
              <th>Member</th>
              <th>Session</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {bookings.rows.map((b) => (
              <tr key={b.id}>
                <td>{b.className}</td>
                <td>
                  <MemberCell uid={b.userId} profile={profiles[b.userId]} />
                </td>
                <td>{dateLabel(b.date)}</td>
                <td>{b.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
