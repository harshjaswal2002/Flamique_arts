import {createClient} from '@supabase/supabase-js';
import {supabaseUrl,supabasePublishableKey} from './config.js';

export const configured=!!(supabaseUrl&&supabasePublishableKey);
let client;
export async function connect(){
  if(!configured)throw new Error('The account service is not connected yet.');
  return client??=createClient(supabaseUrl,supabasePublishableKey);
}
function checked({data,error}){if(error)throw new Error(error.message);return data;}
function userView(user){return user?{uid:user.id,email:user.email,displayName:user.user_metadata?.name||'',photoURL:user.user_metadata?.avatar_url||null}:null;}
export async function signIn(email,password,signup=false,name=''){
  const s=await connect();
  const data=checked(signup?await s.auth.signUp({email,password,options:{data:{name},emailRedirectTo:location.origin+'/'}}):await s.auth.signInWithPassword({email,password}));
  return {user:userView(data.user),needsConfirmation:signup&&!data.session};
}
export async function signOut(){checked(await (await connect()).auth.signOut());}
export async function watchUser(cb){
  if(!configured){cb(null);return ()=>{};}
  const s=await connect();
  // Defer callbacks: Supabase auth callbacks must not await other auth methods.
  const {data:{subscription}}=s.auth.onAuthStateChange((_event,session)=>{
    setTimeout(()=>Promise.resolve(cb(userView(session?.user))).catch(err=>console.error('Account update failed:',err.message)),0);
  });
  return ()=>subscription.unsubscribe();
}
export async function isAdmin(){return checked(await (await connect()).rpc('is_admin'))===true;}
const tables=new Set(['products','categories','orders','users']);
export async function loadCollection(name){
  if(!tables.has(name))throw new Error('Unknown collection.');
  const s=await connect();let all=[];
  // Paginate so the admin does not silently lose records at the API row limit.
  for(let start=0;;start+=500){
    const rows=checked(await s.from(name).select('*').order(name==='orders'?'createdAt':'id',{ascending:name!=='orders'}).range(start,start+499));
    all.push(...rows);if(rows.length<500)return all;
  }
}
export async function saveRecord(collection,id,data){
  if(collection!=='categories')throw new Error('This record cannot be edited directly.');
  const {name,description,image,active}=data;
  checked(await (await connect()).from('categories').upsert({id,name,description,image,active,updatedAt:new Date().toISOString()}));
}
const procedures={createOrder:'create_order',updateOrder:'update_order',cancelOrder:'cancel_order',saveProduct:'save_product'};
export async function call(name,payload){
  if(!procedures[name])throw new Error('Unknown operation.');
  return checked(await (await connect()).rpc(procedures[name],{payload}));
}
export async function myOrders(uid){return checked(await (await connect()).from('orders').select('*').eq('userId',uid).order('createdAt',{ascending:false}));}
export async function profileUpdate(name){
  if(!name.trim()||name.length>80)throw new Error('Enter a name of up to 80 characters.');
  checked(await (await connect()).auth.updateUser({data:{name:name.trim()}}));
}
export async function resetPassword(email){
  checked(await (await connect()).auth.resetPasswordForEmail(email,{redirectTo:location.origin+'/'}));
}
export async function updatePassword(password){checked(await (await connect()).auth.updateUser({password}));}
export async function watchPasswordRecovery(cb){
  const {data:{subscription}}=(await connect()).auth.onAuthStateChange(event=>{if(event==='PASSWORD_RECOVERY')setTimeout(cb,0);});
  return ()=>subscription.unsubscribe();
}
export async function uploadProductImage(file){
  if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>5*1024*1024)throw new Error('Choose a JPEG, PNG or WebP image smaller than 5 MB.');
  const s=await connect();const path=`${crypto.randomUUID()}/${file.name.replace(/[^a-zA-Z0-9._-]/g,'_')}`;
  checked(await s.storage.from('product-images').upload(path,file,{contentType:file.type,upsert:false}));
  return s.storage.from('product-images').getPublicUrl(path).data.publicUrl;
}
