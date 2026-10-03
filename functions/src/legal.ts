import { z } from 'zod';
import { audit, callable, db, now } from './platform';

export const publishLegalPage = callable(z.object({ page: z.enum(['terms', 'privacy']), title: z.string().trim().min(5).max(120), body: z.string().trim().min(50).max(30000) }), 'publishLegalPage', async (input, uid) => {
  await db.runTransaction(async tx => {
    tx.set(db.doc(`legalDocuments/${input.page}`), { title: input.title, body: input.body, published: true, publishedAt: now(), publishedBy: uid });
    audit(tx, uid, 'publishLegalPage', input.page);
  });
  return { success: true };
}, true);
