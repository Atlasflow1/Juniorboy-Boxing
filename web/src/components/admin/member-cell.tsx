'use client';

import { formatMemberName, MemberSummary } from '@/lib/member-cache';

export function MemberCell({
  uid,
  profile,
}: {
  uid: string;
  profile?: MemberSummary | null;
}) {
  if (!uid) return <span className="muted">—</span>;

  if (!profile) {
    return <span style={{ fontFamily: 'monospace', fontSize: 12 }}>{uid}</span>;
  }

  const name = formatMemberName(profile.fullName, profile.lastName, profile.childName);
  const displayName = name || uid;
  const isFallback = !name;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 2, minWidth: 140 }}>
      <strong style={{ fontSize: 13, wordBreak: 'break-word', color: 'var(--text)' }}>
        {displayName}
      </strong>
      {profile.email && (
        <span className="muted" style={{ fontSize: 11, wordBreak: 'break-all' }}>
          {profile.email}
        </span>
      )}
      {profile.phone && (
        <a
          href={`tel:${profile.phone}`}
          style={{ fontSize: 11, color: 'var(--red)', textDecoration: 'none' }}
          onClick={(e) => e.stopPropagation()}
        >
          {profile.phone}
        </a>
      )}
      {!isFallback && (
        <span
          className="muted"
          style={{ fontSize: 10, fontFamily: 'monospace', opacity: 0.6 }}
        >
          {uid}
        </span>
      )}
    </div>
  );
}
