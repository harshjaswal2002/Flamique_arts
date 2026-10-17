-- Execute in a trusted SQL session. Every fixture and setting change rolls back.
begin;
select set_config('test.customer',gen_random_uuid()::text,true),
       set_config('test.other',gen_random_uuid()::text,true),
       set_config('test.admin',gen_random_uuid()::text,true);
insert into auth.users(id,email,raw_user_meta_data)
select current_setting('test.customer')::uuid,'commerce-customer@example.invalid','{"name":"Test Customer","admin":true}'::jsonb
union all select current_setting('test.other')::uuid,'commerce-other@example.invalid','{}'::jsonb
union all select current_setting('test.admin')::uuid,'commerce-admin@example.invalid','{}'::jsonb;
insert into private.admin_users(user_id) values(current_setting('test.admin')::uuid);
insert into public.categories(id,name) values('__test_category','Test');
insert into public.products(id,title,description,category,price,quantity,image)
values('__test_product','Test Product','Test only','__test_category',99.99,3,'https://example.invalid/image.png');
update public.store_settings set orders_enabled=true;
select set_config('test.payload',jsonb_build_object('requestId','test-request','paymentMethod','cod',
  'items',jsonb_build_array(jsonb_build_object('productId','__test_product','quantity',2)),
  'address',jsonb_build_object('name','Test Customer','email','test@example.invalid','phone','9876543210','address','Test Road','city','Chandigarh','state','Chandigarh','postalCode','160001'))::text,true);
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('test.customer'),'role','authenticated')::text,true);
set local role authenticated;
do $$
declare a jsonb; b jsonb;
begin
  if public.is_admin() then raise exception 'FAIL: user metadata granted admin access'; end if;
  if (select count(*) from public.users) <> 1 then raise exception 'FAIL: profile privacy'; end if;
  begin
    insert into public.categories(id,name) values('__forbidden','Forbidden');
    raise exception 'FAIL: customer category write';
  exception when insufficient_privilege then null; end;
  begin
    update public.products set quantity=100 where id='__test_product';
    raise exception 'FAIL: direct stock write';
  exception when insufficient_privilege then null; end;
  begin
    perform public.save_product('{}');
    raise exception 'FAIL: customer product RPC';
  exception when insufficient_privilege then null; end;
  a := public.create_order(current_setting('test.payload')::jsonb);
  b := public.create_order(current_setting('test.payload')::jsonb);
  if a<>b or (select quantity from public.products where id='__test_product')<>1 then raise exception 'FAIL: checkout retry stock'; end if;
  if not exists(select 1 from public.orders where id=a->>'orderId' and subtotal=199.98 and shipping=50 and total=249.98) then raise exception 'FAIL: trusted pricing'; end if;
  perform set_config('test.order',a->>'orderId',true);
  begin
    perform public.update_order(jsonb_build_object('orderId',a->>'orderId','status','processing','paymentStatus','unpaid'));
    raise exception 'FAIL: customer admin RPC';
  exception when insufficient_privilege then null; end;
  begin
    perform public.create_order(jsonb_set(current_setting('test.payload')::jsonb,'{requestId}','"another-request"'));
    raise exception 'FAIL: oversold';
  exception when raise_exception then if sqlerrm like 'FAIL:%' then raise; end if; end;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('test.other'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
  if (select count(*) from public.orders)<>0 then raise exception 'FAIL: cross-user order read'; end if;
  begin
    perform public.cancel_order(jsonb_build_object('orderId',current_setting('test.order')));
    raise exception 'FAIL: cross-user cancellation';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('test.customer'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
  perform public.cancel_order(jsonb_build_object('orderId',current_setting('test.order')));
  perform public.cancel_order(jsonb_build_object('orderId',current_setting('test.order')));
  if (select quantity from public.products where id='__test_product')<>3 then raise exception 'FAIL: cancellation stock restoration'; end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('test.admin'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
  if not public.is_admin() then raise exception 'FAIL: admin denied'; end if;
  if (select count(*) from public.users)<3 then raise exception 'FAIL: admin customer access'; end if;
  perform public.save_product('{"id":"__test_product","product":{"title":"Updated","description":"Updated test","category":"__test_category","price":200,"quantity":3,"image":"https://example.invalid/image.png","scent":"","weight":"","tag":"","active":true}}');
  if not exists(select 1 from public.products where id='__test_product' and price=200) then raise exception 'FAIL: admin save product'; end if;
end $$;
reset role;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin
  if (select count(*) from public.products where id='__test_product')<>1 then raise exception 'FAIL: public catalogue'; end if;
  begin
    perform public.create_order('{}');
    raise exception 'FAIL: anonymous checkout';
  exception when insufficient_privilege then null; end;
  begin
    perform 1 from public.orders;
    raise exception 'FAIL: anonymous orders';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
-- Verify the reserved-email path grants nothing until Auth confirms the email.
insert into private.admin_emails(email) values ('commerce-other@example.invalid');
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('test.other'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
  if public.is_admin() then raise exception 'FAIL: unverified email became admin'; end if;
end $$;
reset role;
update auth.users set email_confirmed_at=now() where id=current_setting('test.other')::uuid;
set local role authenticated;
do $$ begin
  if not public.is_admin() then raise exception 'FAIL: verified allowlisted email denied'; end if;
end $$;
reset role;
rollback;
select 'PASS: privacy, admin authorization, pricing, idempotency, stock bounds, cancellation and anonymous access' as verification;
