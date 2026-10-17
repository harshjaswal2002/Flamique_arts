-- Private, owner-managed allowlist. Only verified Auth email addresses qualify.
create table private.admin_emails (
  email text primary key check (email=lower(email))
);
alter table private.admin_emails enable row level security;
revoke all on private.admin_emails from public, anon, authenticated;
create policy admin_emails_deny_clients on private.admin_emails for all to anon, authenticated using (false) with check (false);
create policy admin_users_deny_clients on private.admin_users for all to anon, authenticated using (false) with check (false);
create or replace function private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and (
    exists(select 1 from private.admin_users where user_id=auth.uid()) or
    exists(select 1 from auth.users u join private.admin_emails a on a.email=lower(u.email)
      where u.id=auth.uid() and u.email_confirmed_at is not null)
  )
$$;
-- Owner email is inserted separately, so this file is reusable for other projects.
