import {firebaseConfig,functionsRegion,appCheckSiteKey} from './config.js';
export const configured=!!firebaseConfig?.apiKey;
let sdk;
export async function connect(){if(!configured)throw new Error('Firebase is not connected yet.');if(sdk)return sdk;
const [app,auth,fs,fn]=await Promise.all([import('https://www.gstatic.com/firebasejs/12.4.0/firebase-app.js'),import('https://www.gstatic.com/firebasejs/12.4.0/firebase-auth.js'),import('https://www.gstatic.com/firebasejs/12.4.0/firebase-firestore.js'),import('https://www.gstatic.com/firebasejs/12.4.0/firebase-functions.js')]);
const a=app.initializeApp(firebaseConfig); if(appCheckSiteKey){const ac=await import('https://www.gstatic.com/firebasejs/12.4.0/firebase-app-check.js');ac.initializeAppCheck(a,{provider:new ac.ReCaptchaV3Provider(appCheckSiteKey),isTokenAutoRefreshEnabled:true});} sdk={auth,fs,fn,a,userAuth:auth.getAuth(a),db:fs.getFirestore(a),functions:fn.getFunctions(a,functionsRegion)};return sdk;}
export async function signIn(email,password,signup=false,name=''){const s=await connect();const c=signup?await s.auth.createUserWithEmailAndPassword(s.userAuth,email,password):await s.auth.signInWithEmailAndPassword(s.userAuth,email,password);if(signup){await s.auth.updateProfile(c.user,{displayName:name});await s.fs.setDoc(s.fs.doc(s.db,'users',c.user.uid),{name,email,createdAt:s.fs.serverTimestamp()},{merge:true});}return c.user;}
export async function signOut(){const s=await connect();await s.auth.signOut(s.userAuth);}
export async function watchUser(cb){if(!configured){cb(null);return ()=>{};}const s=await connect();return s.auth.onAuthStateChanged(s.userAuth,cb);}
export async function loadCollection(name){const s=await connect();const snap=await s.fs.getDocs(s.fs.collection(s.db,name));return snap.docs.map(d=>({...d.data(),id:d.id}));}
export async function saveRecord(collection,id,data){const s=await connect();await s.fs.setDoc(s.fs.doc(s.db,collection,id),{...data,updatedAt:s.fs.serverTimestamp()},{merge:true});}
export async function call(name,data){const s=await connect();return (await s.fn.httpsCallable(s.functions,name)(data)).data;}
export async function myOrders(uid){const s=await connect();const q=s.fs.query(s.fs.collection(s.db,'orders'),s.fs.where('userId','==',uid));return(await s.fs.getDocs(q)).docs.map(d=>({...d.data(),id:d.id}));}
export async function profileUpdate(name){const s=await connect();await s.auth.updateProfile(s.userAuth.currentUser,{displayName:name});await saveRecord('users',s.userAuth.currentUser.uid,{name});}
