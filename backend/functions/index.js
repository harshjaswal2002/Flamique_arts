import {initializeApp} from 'firebase-admin/app';
import {getFirestore,FieldValue} from 'firebase-admin/firestore';
import {onCall,HttpsError} from 'firebase-functions/v2/https';
import {defineBoolean,defineInt} from 'firebase-functions/params';
import {allowedTransition,validItems,calculateOrder} from './domain.js';
initializeApp();const db=getFirestore();
const ordersEnabled=defineBoolean('ORDERS_ENABLED',{default:false});
const shippingFee=defineInt('SHIPPING_FEE_INR',{default:50});
const freeThreshold=defineInt('FREE_SHIPPING_THRESHOLD_INR',{default:200});
const appCheck=defineBoolean('ENFORCE_APP_CHECK',{default:true});
const options={region:'asia-south1',enforceAppCheck:appCheck,maxInstances:10};
function requireUser(r){if(!r.auth)throw new HttpsError('unauthenticated','Please sign in.');}
function requireAdmin(r){requireUser(r);if(r.auth.token.admin!==true)throw new HttpsError('permission-denied','Admin access required.');}
function text(v,max=300){return typeof v==='string'&&v.trim().length>0&&v.length<=max;}
function id(v){return typeof v==='string'&&/^[a-zA-Z0-9_-]{1,100}$/.test(v);}
export const createOrder=onCall(options,async r=>{
 requireUser(r);if(!ordersEnabled.value())throw new HttpsError('failed-precondition','Orders have not opened yet.');
 const {items,address,paymentMethod,note='',requestId}=r.data||{};
 if(!validItems(items)||!id(requestId)||paymentMethod!=='cod'||!address||!['name','email','phone','address','city','state','postalCode'].every(k=>text(address[k]))||!/^\S+@\S+\.\S+$/.test(address.email)||!/^\+?[0-9 ()-]{10,16}$/.test(address.phone)||! /^[1-9][0-9]{5}$/.test(address.postalCode)||typeof note!=='string'||note.length>500)throw new HttpsError('invalid-argument','Please check the items and delivery details.');
 const orderRef=db.doc(`orders/${r.auth.uid}_${requestId}`);const userRef=db.doc(`users/${r.auth.uid}`);
 return db.runTransaction(async tx=>{
  const existing=await tx.get(orderRef);if(existing.exists)return {orderId:orderRef.id};
  const snapshots=await Promise.all(items.map(i=>tx.get(db.doc(`products/${i.productId}`))));const lookup=Object.fromEntries(snapshots.map(s=>[s.id,s.exists?s.data():null]));
  let order;try{order=calculateOrder(items,lookup,shippingFee.value(),freeThreshold.value())}catch(err){throw new HttpsError('failed-precondition',err.message)}
  for(const i of items)tx.update(db.doc(`products/${i.productId}`),{quantity:lookup[i.productId].quantity-i.quantity,updatedAt:FieldValue.serverTimestamp()});
  const cleanAddress=Object.fromEntries(['name','email','phone','address','city','state','postalCode'].map(k=>[k,address[k].trim()]));
  tx.create(orderRef,{...order,address:cleanAddress,userId:r.auth.uid,paymentMethod:'cod',paymentStatus:'unpaid',status:'placed',note,createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp(),events:[{status:'placed',at:new Date().toISOString(),actor:r.auth.uid}]});
  tx.set(userRef,{name:cleanAddress.name,email:r.auth.token.email||cleanAddress.email,updatedAt:FieldValue.serverTimestamp()},{merge:true});
  return {orderId:orderRef.id};
 });
});
async function changeOrder(r,customer=false){
 requireUser(r);if(!customer)requireAdmin(r);const {orderId,status,courier='',trackingNumber='',paymentStatus}=r.data||{};
 if(!id(orderId)||typeof status!=='string'||typeof courier!=='string'||courier.length>80||typeof trackingNumber!=='string'||trackingNumber.length>120||(!customer&&!['paid','unpaid'].includes(paymentStatus)))throw new HttpsError('invalid-argument','Invalid order update.');
 return db.runTransaction(async tx=>{const ref=db.doc(`orders/${orderId}`),snap=await tx.get(ref);if(!snap.exists)throw new HttpsError('not-found','Order not found.');const o=snap.data();
 if(customer&&(o.userId!==r.auth.uid||o.status!=='placed'||status!=='cancelled'))throw new HttpsError('permission-denied','This order can no longer be cancelled by the customer.');
 if(!allowedTransition(o.status,status))throw new HttpsError('failed-precondition',`Cannot change ${o.status} to ${status}.`);
 if(status==='shipped'&&(!courier.trim()||!trackingNumber.trim()))throw new HttpsError('invalid-argument','Courier and tracking number are required before shipping.');
 if(status==='cancelled'&&o.paymentStatus==='paid')throw new HttpsError('failed-precondition','Paid orders need a manual refund review before cancellation.');
 if(status==='cancelled'&&o.status!=='cancelled'){const snaps=await Promise.all(o.items.map(i=>tx.get(db.doc(`products/${i.productId}`))));for(let n=0;n<o.items.length;n++){if(!snaps[n].exists)throw new HttpsError('failed-precondition','Product missing; stock restoration needs review.');tx.update(snaps[n].ref,{quantity:FieldValue.increment(o.items[n].quantity)});}}
 const update={status,updatedAt:FieldValue.serverTimestamp()};if(!customer){if(o.status==='cancelled'&&paymentStatus!==o.paymentStatus)throw new HttpsError('failed-precondition','Cancelled order payment cannot be changed.');Object.assign(update,{courier:courier.trim(),trackingNumber:trackingNumber.trim(),paymentStatus});}
 if(status!==o.status)update.events=FieldValue.arrayUnion({status,at:new Date().toISOString(),actor:r.auth.uid});tx.update(ref,update);return {orderId};});
}
export const updateOrder=onCall(options,r=>changeOrder(r));
export const cancelOrder=onCall(options,r=>changeOrder({...r,data:{orderId:r.data?.orderId,status:'cancelled'}},true));
export const saveProduct=onCall(options,async r=>{
 requireAdmin(r);const p=r.data?.product;const productId=r.data?.id||db.collection('products').doc().id;
 if(!id(productId)||!p||!text(p.title,120)||!text(p.description,3000)||!id(p.category)||!Number.isFinite(p.price)||p.price<1||p.price>1000000||!Number.isInteger(p.quantity)||p.quantity<0||p.quantity>100000||!text(p.image,2000)||!p.image.startsWith('https://')||typeof p.active!=='boolean'||['scent','weight','tag'].some(k=>typeof p[k]!=='string'||p[k].length>100))throw new HttpsError('invalid-argument','Please check all product fields.');
 await db.runTransaction(async tx=>{const c=await tx.get(db.doc(`categories/${p.category}`));if(!c.exists)throw new HttpsError('failed-precondition','Create or select a collection first.');
 const clean=Object.fromEntries(['title','description','category','price','quantity','image','scent','weight','tag','active'].map(k=>[k,p[k]]));
 tx.set(db.doc(`products/${productId}`),{...clean,updatedAt:FieldValue.serverTimestamp()},{merge:true});});return {productId};
});
