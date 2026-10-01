-- Run this in Supabase Dashboard -> SQL Editor.
-- The existing check constraint on profiles.role predates the admin role
-- and only allowed 'grower'/'seller' -- widen it to include 'admin'.
alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check check (role in ('grower', 'seller', 'admin'));
