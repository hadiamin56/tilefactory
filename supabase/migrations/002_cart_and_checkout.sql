-- Run this in Supabase Dashboard -> SQL Editor.
-- Adds a persisted cart + real checkout (delivery address) on top of the
-- existing orders/listings/profiles tables.

-- 1. Cart, one row per (grower, listing). Quantity increments on repeat "Add to Cart".
create table if not exists cart_items (
  id uuid primary key default gen_random_uuid(),
  grower_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid not null references listings(id) on delete cascade,
  quantity int not null check (quantity > 0),
  created_at timestamptz not null default now(),
  unique (grower_id, listing_id)
);

alter table cart_items enable row level security;

drop policy if exists "cart_select_own" on cart_items;
create policy "cart_select_own" on cart_items for select using (auth.uid() = grower_id);

drop policy if exists "cart_insert_own" on cart_items;
create policy "cart_insert_own" on cart_items for insert with check (auth.uid() = grower_id);

drop policy if exists "cart_update_own" on cart_items;
create policy "cart_update_own" on cart_items for update using (auth.uid() = grower_id);

drop policy if exists "cart_delete_own" on cart_items;
create policy "cart_delete_own" on cart_items for delete using (auth.uid() = grower_id);

-- 2. Delivery address snapshot on each order (address can change later; the
-- order should keep whatever was true at checkout time).
alter table orders add column if not exists delivery_name text;
alter table orders add column if not exists delivery_phone text;
alter table orders add column if not exists delivery_address text;

-- 3. One saved default address per grower, prefilled at checkout and editable
-- there (kept separate from the seller-only `delivery_areas` column).
alter table profiles add column if not exists saved_address text;
