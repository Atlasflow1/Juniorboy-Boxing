'use client';
import { getApp, getApps, initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { connectStorageEmulator, getStorage } from 'firebase/storage';

export const localMode = process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATORS === 'true';
const config = localMode ? { apiKey:'demo-api-key', authDomain:'demo-jbb.firebaseapp.com', projectId:'demo-jbb', appId:'1:123456789:web:demo', messagingSenderId:'123456789', storageBucket:'demo-jbb.appspot.com' } : { apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY, authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN, projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID, appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID, messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID, storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET };
const fresh = !getApps().length;
export const app = fresh ? initializeApp(config) : getApp();
export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app, 'us-central1');
export const storage = getStorage(app);
if (fresh && localMode) {
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
  connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  connectStorageEmulator(storage, '127.0.0.1', 9199);
}
// Client App Check is off for now, matching enforceAppCheck=false in functions/src/platform.ts:14 —
// reCAPTCHA Enterprise attestation was throttling real sign-ins (403s) and broke Google/email auth
// sitewide since Firebase Auth attaches an App Check token whenever App Check is initialized here.
// Flip both back on together once the reCAPTCHA Enterprise key is verified reliable.
export async function call<T = Record<string, unknown>>(name: string, data: unknown = {}): Promise<T> {
  return (await httpsCallable<unknown, T>(functions, name)(data)).data;
}
