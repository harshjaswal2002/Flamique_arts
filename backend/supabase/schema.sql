-- Applied to the hosted project with the Supabase migration API.
-- Private definer functions enforce identity/ownership before privileged writes.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated, anon;

create table private.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table private.admin_users enable row level security;
revoke all on private.admin_users from public, anon, authenticated;

create function private.is_admin() returns boolean
language sql stable security definer set search_path = ''
as $$ select auth.uid() is not null and exists(select 1 from private.admin_users where user_id = auth.uid()) $$;
revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to anon, authenticated;

create table public.categories (
  id text primary key default gen_random_uuid()::text check (id ~ '^[a-zA-Z0-9_-]{1,100}$'),
  name text not null check (length(btrim(name)) between 1 and 80),
  description text not null default '' check (length(description) <= 500),
  image text not null default '' check (image = '' or image ~ '^https://'),
  active boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);
create table public.products (
  id text primary key default gen_random_uuid()::text check (id ~ '^[a-zA-Z0-9_-]{1,100}$'),
  title text not null check (length(btrim(title)) between 1 and 120),
  description text not null check (length(btrim(description)) between 1 and 3000),
  category text not null references public.categories(id),
  price numeric(12,2) not null check (price between 1 and 1000000),
  quantity integer not null check (quantity between 0 and 100000),
  image text not null check (length(image) <= 2000 and image ~ '^https://'),
  scent text not null default '' check (length(scent) <= 100),
  weight text not null default '' check (length(weight) <= 100),
  tag text not null default '' check (length(tag) <= 100),
  active boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);
create index products_category_idx on public.products(category);
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '' check (length(name) <= 80),
  email text not null,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);
create table public.store_settings (
  id boolean primary key default true check (id),
  orders_enabled boolean not null default false,
  shipping_fee numeric(12,2) not null default 50 check (shipping_fee >= 0),
  free_shipping_threshold numeric(12,2) not null default 200 check (free_shipping_threshold >= 0)
);
insert into public.store_settings(id) values(true);
create table public.orders (
  id text primary key,
  "userId" uuid not null references auth.users(id),
  "requestId" text not null,
  items jsonb not null check (jsonb_typeof(items) = 'array'),
  address jsonb not null check (jsonb_typeof(address) = 'object'),
  subtotal numeric(12,2) not null check (subtotal > 0),
  shipping numeric(12,2) not null check (shipping >= 0),
  total numeric(12,2) not null check (total = subtotal + shipping),
  "paymentMethod" text not null default 'cod' check ("paymentMethod" = 'cod'),
  "paymentStatus" text not null default 'unpaid' check ("paymentStatus" in ('paid','unpaid')),
  status text not null default 'placed' check (status in ('placed','processing','packed','shipped','delivered','cancelled')),
  courier text not null default '',
  "trackingNumber" text not null default '',
  note text not null default '' check (length(note) <= 500),
  events jsonb not null default '[]',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  unique ("userId", "requestId")
);

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.users enable row level security;
alter table public.orders enable row level security;
alter table public.store_settings enable row level security;
revoke all on public.categories, public.products, public.users, public.orders, public.store_settings from anon, authenticated;
grant select on public.categories, public.products, public.store_settings to anon, authenticated;
grant select on public.users, public.orders to authenticated;
grant insert, update on public.categories to authenticated;
grant update(name) on public.users to authenticated;
create policy catalogue_read on public.categories for select to anon, authenticated using (active or (select private.is_admin()));
create policy products_read on public.products for select to anon, authenticated using (active or (select private.is_admin()));
create policy categories_insert on public.categories for insert to authenticated with check ((select private.is_admin()));
create policy categories_update on public.categories for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy users_read on public.users for select to authenticated using (id = (select auth.uid()) or (select private.is_admin()));
create policy users_update on public.users for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy orders_read on public.orders for select to authenticated using ("userId" = (select auth.uid()) or (select private.is_admin()));
create policy settings_read on public.store_settings for select to anon, authenticated using (true);

create function private.sync_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.users(id, name, email)
  values(new.id, left(coalesce(new.raw_user_meta_data->>'name',''),80), coalesce(new.email,''))
  on conflict(id) do update set name=excluded.name, email=excluded.email, "updatedAt"=now();
  return new;
end $$;
revoke all on function private.sync_profile() from public, anon, authenticated;
create trigger sync_profile after insert or update of raw_user_meta_data, email on auth.users
for each row execute function private.sync_profile();
insert into public.users(id,name,email)
select id,left(coalesce(raw_user_meta_data->>'name',''),80),coalesce(email,'') from auth.users;

create function public.is_admin() returns boolean language sql stable security invoker set search_path = ''
as $$ select private.is_admin() $$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

create function private.create_order(payload jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid(); req text := payload->>'requestId'; order_id text;
  cart jsonb := payload->'items'; addr jsonb := payload->'address'; field text;
  line jsonb; p public.products%rowtype; qty integer;
  lines jsonb := '[]'; sub numeric(12,2) := 0; ship numeric(12,2);
  settings public.store_settings%rowtype;
begin
  if uid is null then raise exception 'Please sign in.' using errcode='42501'; end if;
  if req is null or req !~ '^[a-zA-Z0-9_-]{1,100}$' then raise exception 'Invalid checkout request.'; end if;
  -- Serialize retries from this user before checking the idempotency key.
  perform 1 from auth.users where id=uid for update;
  select id into order_id from public.orders where "userId"=uid and "requestId"=req;
  if found then return jsonb_build_object('orderId',order_id); end if;
  select * into strict settings from public.store_settings where id;
  if not settings.orders_enabled then raise exception 'Orders have not opened yet.'; end if;
  if jsonb_typeof(cart) is distinct from 'array' then raise exception 'Invalid shopping bag.'; end if;
  if jsonb_array_length(cart) not between 1 and 50 then raise exception 'Invalid shopping bag.'; end if;
  if (select count(distinct x->>'productId') from jsonb_array_elements(cart) x) <> jsonb_array_length(cart) then raise exception 'Duplicate or missing products.'; end if;
  if payload->>'paymentMethod' is distinct from 'cod' or jsonb_typeof(addr) is distinct from 'object'
    or length(coalesce(payload->>'note','')) > 500 then raise exception 'Invalid delivery details.'; end if;
  foreach field in array array['name','email','phone','address','city','state','postalCode'] loop
    if jsonb_typeof(addr->field) is distinct from 'string' or length(btrim(addr->>field)) not between 1 and 300 then raise exception 'Check delivery details: %',field; end if;
    addr := jsonb_set(addr,array[field],to_jsonb(btrim(addr->>field)));
  end loop;
  if addr->>'email' !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    or addr->>'phone' !~ '^\+?[0-9 ()-]{10,16}$'
    or addr->>'postalCode' !~ '^[1-9][0-9]{5}$' then raise exception 'Check email, phone and PIN code.'; end if;
  -- All purchase/cancellation paths lock inventory in product-id order.
  for line in select value from jsonb_array_elements(cart) order by value->>'productId' loop
    if jsonb_typeof(line->'productId') is distinct from 'string' or line->>'productId' !~ '^[a-zA-Z0-9_-]{1,100}$'
      or jsonb_typeof(line->'quantity') is distinct from 'number' or line->>'quantity' !~ '^[0-9]{1,3}$' then raise exception 'Invalid product or quantity.'; end if;
    qty := (line->>'quantity')::integer;
    if qty not between 1 and 100 then raise exception 'Quantity must be between 1 and 100.'; end if;
    select * into p from public.products where id=line->>'productId' for update;
    if not found or not p.active or p.quantity < qty then raise exception 'A product is unavailable or has insufficient stock.'; end if;
    sub := sub + p.price * qty;
    lines := lines || jsonb_build_array(jsonb_build_object('productId',p.id,'title',p.title,'price',p.price,'quantity',qty));
    update public.products set quantity=quantity-qty,"updatedAt"=now() where id=p.id;
  end loop;
  ship := case when sub >= settings.free_shipping_threshold then 0 else settings.shipping_fee end;
  order_id := gen_random_uuid()::text;
  insert into public.orders(id,"userId","requestId",items,address,subtotal,shipping,total,note,events)
  values(order_id,uid,req,lines,addr,sub,ship,sub+ship,coalesce(payload->>'note',''),jsonb_build_array(jsonb_build_object('status','placed','at',now(),'actor',uid)));
  return jsonb_build_object('orderId',order_id);
end $$;
revoke all on function private.create_order(jsonb) from public, anon;
grant execute on function private.create_order(jsonb) to authenticated;
create function public.create_order(payload jsonb) returns jsonb language sql security invoker set search_path = ''
as $$ select private.create_order(payload) $$;
revoke all on function public.create_order(jsonb) from public, anon;
grant execute on function public.create_order(jsonb) to authenticated;

create function private.change_order(payload jsonb, customer boolean) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid(); o public.orders%rowtype; line jsonb;
  next_status text := case when customer then 'cancelled' else payload->>'status' end;
  payment text; courier_value text := coalesce(payload->>'courier',''); tracking text := coalesce(payload->>'trackingNumber','');
begin
  if uid is null then raise exception 'Please sign in.' using errcode='42501'; end if;
  if not customer and not private.is_admin() then raise exception 'Admin access required.' using errcode='42501'; end if;
  select * into o from public.orders where id=payload->>'orderId' for update;
  if not found then raise exception 'Order not found.'; end if;
  if customer and (o."userId" <> uid or o.status not in ('placed','cancelled')) then raise exception 'This order can no longer be cancelled by the customer.' using errcode='42501'; end if;
  if next_status is null or not (next_status=o.status or
    (o.status='placed' and next_status in ('processing','cancelled')) or
    (o.status='processing' and next_status in ('packed','cancelled')) or
    (o.status='packed' and next_status in ('shipped','cancelled')) or
    (o.status='shipped' and next_status='delivered')) then raise exception 'Invalid order status transition.'; end if;
  payment := case when customer then o."paymentStatus" else payload->>'paymentStatus' end;
  if payment is null or payment not in ('paid','unpaid') or length(courier_value)>80 or length(tracking)>120 then raise exception 'Invalid order update.'; end if;
  if next_status='shipped' and (btrim(courier_value)='' or btrim(tracking)='') then raise exception 'Courier and tracking number are required before shipping.'; end if;
  if next_status='cancelled' and (o."paymentStatus"='paid' or payment='paid') then raise exception 'Paid orders need a manual refund review before cancellation.'; end if;
  if o.status='cancelled' and payment<>o."paymentStatus" then raise exception 'Cancelled order payment cannot be changed.'; end if;
  if next_status='cancelled' and o.status<>'cancelled' then
    for line in select value from jsonb_array_elements(o.items) order by value->>'productId' loop
      perform 1 from public.products where id=line->>'productId' for update;
      if not found then raise exception 'Product missing; stock restoration needs review.'; end if;
      update public.products set quantity=quantity+(line->>'quantity')::integer,"updatedAt"=now() where id=line->>'productId';
    end loop;
  end if;
  update public.orders set status=next_status,"paymentStatus"=payment,
    courier=case when customer then o.courier else btrim(courier_value) end,
    "trackingNumber"=case when customer then o."trackingNumber" else btrim(tracking) end,
    events=case when next_status=o.status then events else events||jsonb_build_array(jsonb_build_object('status',next_status,'at',now(),'actor',uid)) end,
    "updatedAt"=now() where id=o.id;
  return jsonb_build_object('orderId',o.id);
end $$;
revoke all on function private.change_order(jsonb,boolean) from public, anon;
grant execute on function private.change_order(jsonb,boolean) to authenticated;
create function public.update_order(payload jsonb) returns jsonb language sql security invoker set search_path = ''
as $$ select private.change_order(payload,false) $$;
create function public.cancel_order(payload jsonb) returns jsonb language sql security invoker set search_path = ''
as $$ select private.change_order(payload,true) $$;
revoke all on function public.update_order(jsonb), public.cancel_order(jsonb) from public, anon;
grant execute on function public.update_order(jsonb), public.cancel_order(jsonb) to authenticated;

create function private.save_product(payload jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare p jsonb := payload->'product'; pid text := coalesce(nullif(payload->>'id',''),gen_random_uuid()::text);
begin
  if auth.uid() is null or not private.is_admin() then raise exception 'Admin access required.' using errcode='42501'; end if;
  if jsonb_typeof(p) is distinct from 'object' or jsonb_typeof(p->'quantity') is distinct from 'number'
    or p->>'quantity' !~ '^[0-9]{1,6}$' or jsonb_typeof(p->'price') is distinct from 'number'
    or jsonb_typeof(p->'active') is distinct from 'boolean' then raise exception 'Invalid product fields.'; end if;
  insert into public.products(id,title,description,category,price,quantity,image,scent,weight,tag,active)
  values(pid,p->>'title',p->>'description',p->>'category',(p->>'price')::numeric,(p->>'quantity')::integer,p->>'image',p->>'scent',p->>'weight',p->>'tag',(p->>'active')::boolean)
  on conflict(id) do update set title=excluded.title,description=excluded.description,category=excluded.category,price=excluded.price,quantity=excluded.quantity,image=excluded.image,scent=excluded.scent,weight=excluded.weight,tag=excluded.tag,active=excluded.active,"updatedAt"=now();
  return jsonb_build_object('productId',pid);
end $$;
revoke all on function private.save_product(jsonb) from public, anon;
grant execute on function private.save_product(jsonb) to authenticated;
create function public.save_product(payload jsonb) returns jsonb language sql security invoker set search_path = ''
as $$ select private.save_product(payload) $$;
revoke all on function public.save_product(jsonb) from public, anon;
grant execute on function public.save_product(jsonb) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('product-images','product-images',true,5242880,array['image/jpeg','image/png','image/webp']);
create policy product_images_insert on storage.objects for insert to authenticated
with check(bucket_id='product-images' and (select private.is_admin()));
create policy product_images_update on storage.objects for update to authenticated
using(bucket_id='product-images' and (select private.is_admin())) with check(bucket_id='product-images' and (select private.is_admin()));
create policy product_images_select on storage.objects for select to authenticated
using(bucket_id='product-images' and (select private.is_admin()));
create policy product_images_delete on storage.objects for delete to authenticated
using(bucket_id='product-images' and (select private.is_admin()));
