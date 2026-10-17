// Trusted local setup only: authenticate with Application Default Credentials.
// Usage: node set-admin.mjs <firebase-auth-uid>. Never distribute service account keys.
import {initializeApp,applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
const uid=process.argv[2];if(!uid||uid.includes('/'))throw new Error('Pass the Firebase Auth UID of the verified owner account.');
initializeApp({credential:applicationDefault(),projectId:'flamiquearts'});
const auth=getAuth();const user=await auth.getUser(uid);await auth.setCustomUserClaims(uid,{...user.customClaims,admin:true});console.log('Admin claim assigned. Sign out and sign in again.');
