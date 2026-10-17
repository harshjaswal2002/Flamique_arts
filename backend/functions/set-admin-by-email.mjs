// Run only in a trusted environment with Application Default Credentials.
// Usage: node set-admin-by-email.mjs <verified-owner-email>
import {initializeApp,applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
const email=process.argv[2];
if(!email||!/^\S+@\S+\.\S+$/.test(email))throw new Error('Pass the verified owner email.');
initializeApp({credential:applicationDefault(),projectId:'flamiquearts'});
const auth=getAuth();const user=await auth.getUserByEmail(email);
await auth.setCustomUserClaims(user.uid,{...user.customClaims,admin:true});
console.log('Admin claim assigned to the existing account. Sign out and sign in again.');
