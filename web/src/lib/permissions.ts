import { Permission, UserProfile } from './types';

const STAFF_ROLES = new Set<string>(['admin', 'superAdmin']);

export function isStaff(profile?: UserProfile | null): boolean {
  if (!profile || profile.isActive !== true) return false;
  return profile.role ? STAFF_ROLES.has(profile.role) : false;
}

export function isSuperAdmin(profile?: UserProfile | null): boolean {
  if (!profile || profile.isActive !== true) return false;
  return profile.role === 'superAdmin';
}

export function can(profile: UserProfile | null | undefined, permission: Permission): boolean {
  if (!profile || profile.isActive !== true) return false;
  if (profile.role === 'superAdmin') return true;
  if (profile.role && STAFF_ROLES.has(profile.role)) {
    return profile.permissions?.[permission] === true;
  }
  return false;
}
