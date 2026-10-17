// Read-only API checks using the same publishable key shipped to the browser.
import assert from 'node:assert/strict';
import {createClient} from '@supabase/supabase-js';
import {supabaseUrl,supabasePublishableKey} from '../packages/shared/config.js';
const client=createClient(supabaseUrl,supabasePublishableKey,{auth:{persistSession:false,autoRefreshToken:false}});
for(const table of ['categories','products','store_settings']){
  const {data,error}=await client.from(table).select('*').limit(1);
  assert.equal(error,null,`${table}: ${error?.message}`);
  assert.ok(Array.isArray(data));console.log(`PASS: public ${table} API`);
}
for(const table of ['orders','users']){
  const {data,error}=await client.from(table).select('*').limit(1);
  assert.ok(error||data.length===0,`${table} must not expose private records`);
  console.log(`PASS: anonymous ${table} access blocked`);
}
const {error}=await client.rpc('create_order',{payload:{}});
assert.ok(error,'Anonymous checkout must fail');
console.log('PASS: anonymous checkout blocked');
const response=await fetch(`${supabaseUrl}/auth/v1/settings`,{headers:{apikey:supabasePublishableKey}});
assert.ok(response.ok,'Auth settings endpoint must be reachable');
const settings=await response.json();
assert.equal(settings.external?.email,true,'Email authentication must be enabled');
console.log(`PASS: email authentication enabled (automatic confirmation: ${settings.mailer_autoconfirm===true})`);
