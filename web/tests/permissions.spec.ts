import { expect, test } from '@playwright/test';
import { can, isStaff, isSuperAdmin } from '../src/lib/permissions';
import { adminAccess, nav } from '../src/components/admin/nav';
import { UserProfile } from '../src/lib/types';

test.describe('permissions and staff helpers', () => {
  test('isStaff checks active and staff roles', () => {
    expect(isStaff(null)).toBe(false);
    expect(isStaff(undefined)).toBe(false);

    // Inactive staff
    expect(isStaff({ id: '1', role: 'admin', isActive: false })).toBe(false);
    expect(isStaff({ id: '2', role: 'superAdmin', isActive: false })).toBe(false);

    // Active non-staff
    expect(isStaff({ id: '3', role: 'member', isActive: true })).toBe(false);
    expect(isStaff({ id: '4', role: 'coach', isActive: true })).toBe(false);

    // Active staff
    expect(isStaff({ id: '5', role: 'admin', isActive: true })).toBe(true);
    expect(isStaff({ id: '6', role: 'superAdmin', isActive: true })).toBe(true);
  });

  test('isSuperAdmin checks superAdmin role and active status', () => {
    expect(isSuperAdmin({ id: '1', role: 'admin', isActive: true })).toBe(false);
    expect(isSuperAdmin({ id: '2', role: 'superAdmin', isActive: false })).toBe(false);
    expect(isSuperAdmin({ id: '3', role: 'superAdmin', isActive: true })).toBe(true);
  });

  test('can checks permissions map for admin and grants all for superAdmin', () => {
    const inactiveAdmin: UserProfile = {
      id: '1',
      role: 'admin',
      isActive: false,
      permissions: { manageOffers: true },
    };
    expect(can(inactiveAdmin, 'manageOffers')).toBe(false);

    const activeMember: UserProfile = {
      id: '2',
      role: 'member',
      isActive: true,
      permissions: { manageOffers: true },
    };
    expect(can(activeMember, 'manageOffers')).toBe(false);

    const limitedAdmin: UserProfile = {
      id: '3',
      role: 'admin',
      isActive: true,
      permissions: {
        manageOffers: true,
        refund: true,
        manageStore: false,
      },
    };
    expect(can(limitedAdmin, 'manageOffers')).toBe(true);
    expect(can(limitedAdmin, 'refund')).toBe(true);
    expect(can(limitedAdmin, 'manageStore')).toBe(false);
    expect(can(limitedAdmin, 'manageMembers')).toBe(false);

    const superAdmin: UserProfile = {
      id: '4',
      role: 'superAdmin',
      isActive: true,
      permissions: {},
    };
    expect(can(superAdmin, 'manageOffers')).toBe(true);
    expect(can(superAdmin, 'manageMembers')).toBe(true);
    expect(can(superAdmin, 'manageStore')).toBe(true);
    expect(can(superAdmin, 'manageContent')).toBe(true);
    expect(can(superAdmin, 'refund')).toBe(true);
    expect(can(superAdmin, 'viewRevenue')).toBe(true);
    expect(can(superAdmin, 'bookForMember')).toBe(true);
    expect(can(superAdmin, 'checkIn')).toBe(true);
  });
});

test.describe('admin nav table and adminAccess', () => {
  const memberUser: UserProfile = { id: 'm1', role: 'member', isActive: true };
  const offersStaff: UserProfile = {
    id: 's1',
    role: 'admin',
    isActive: true,
    permissions: { manageOffers: true },
  };
  const membersStaff: UserProfile = {
    id: 's2',
    role: 'admin',
    isActive: true,
    permissions: { manageMembers: true },
  };
  const storeStaff: UserProfile = {
    id: 's3',
    role: 'admin',
    isActive: true,
    permissions: { manageStore: true },
  };
  const superAdminUser: UserProfile = {
    id: 'sa1',
    role: 'superAdmin',
    isActive: true,
  };

  test('non-staff gets Administrator access is required notice', () => {
    const res = adminAccess(memberUser, '/admin');
    expect(res.allowed).toBe(false);
    expect(res.notice).toBe('Administrator access is required.');
  });

  test('staff without permission gets You do not have access to this page notice', () => {
    const res = adminAccess(offersStaff, '/admin/members');
    expect(res.allowed).toBe(false);
    expect(res.notice).toBe("You don't have access to this page.");
  });

  test('staff with permission is allowed access to main and sub routes', () => {
    // Offers staff
    expect(adminAccess(offersStaff, '/admin').allowed).toBe(true);
    expect(adminAccess(offersStaff, '/admin/offers').allowed).toBe(true);
    expect(adminAccess(offersStaff, '/admin/offers/templates').allowed).toBe(true);
    expect(adminAccess(offersStaff, '/admin/schedule').allowed).toBe(true);

    // Members staff can access Members and Plans
    expect(adminAccess(membersStaff, '/admin/members').allowed).toBe(true);
    expect(adminAccess(membersStaff, '/admin/plans').allowed).toBe(true);
    expect(adminAccess(membersStaff, '/admin/offers').allowed).toBe(false);

    // Store staff can access Store and Payments
    expect(adminAccess(storeStaff, '/admin/store').allowed).toBe(true);
    expect(adminAccess(storeStaff, '/admin/payments').allowed).toBe(true);
    expect(adminAccess(storeStaff, '/admin/schedule').allowed).toBe(false);

    // SuperAdmin can access Gym Settings and Staff
    expect(adminAccess(offersStaff, '/admin/settings').allowed).toBe(false);
    expect(adminAccess(offersStaff, '/admin/staff').allowed).toBe(false);
    expect(adminAccess(superAdminUser, '/admin/settings').allowed).toBe(true);
    expect(adminAccess(superAdminUser, '/admin/staff').allowed).toBe(true);
  });

  test('nav table reflects 11.2 and 9.3 visibility predicates', () => {
    const visibleForOffers = nav.filter((i) => i.visible(offersStaff)).map((i) => i.title);
    expect(visibleForOffers).toContain('Overview');
    expect(visibleForOffers).toContain('Offers');
    expect(visibleForOffers).toContain('Schedule');
    expect(visibleForOffers).not.toContain('Members');
    expect(visibleForOffers).not.toContain('Staff');
    expect(visibleForOffers).not.toContain('Gym Settings');

    const visibleForSuper = nav.filter((i) => i.visible(superAdminUser)).map((i) => i.title);
    expect(visibleForSuper.length).toBe(nav.length);
  });
});
