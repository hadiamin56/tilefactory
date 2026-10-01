-- Run this in Supabase Dashboard -> SQL Editor.
-- Adds an admin role (granted manually, never selectable at signup) with
-- full read/write access to profiles, plus an account_status field used to
-- suspend/soft-delete accounts.

alter table profiles add column if not exists account_status text not null default 'active'
  check (account_status in ('active', 'suspended', 'deleted'));

-- Helper used inside RLS policies to check if the current user is an admin.
create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

-- Admins can read and write any profile (on top of the existing "own row" policies).
drop policy if exists "profiles_admin_select" on profiles;
create policy "profiles_admin_select" on profiles for select using (is_admin());

drop policy if exists "profiles_admin_update" on profiles;
create policy "profiles_admin_update" on profiles for update using (is_admin());

-- To make a user an admin, run (replace with their real id from auth.users):
-- update profiles set role = 'admin' where id = '00000000-0000-0000-0000-000000000000';
