-- Run this in Supabase Dashboard -> SQL Editor.
-- Real reviews, tied to actual delivered orders (one review per order, so it
-- can't be gamed) -- starts empty, no fabricated ratings.

drop table if exists reviews cascade;

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references orders(id) on delete cascade,
  seller_id uuid not null references auth.users(id) on delete cascade,
  grower_id uuid not null references auth.users(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

alter table reviews enable row level security;

drop policy if exists "reviews_public_read" on reviews;
create policy "reviews_public_read" on reviews for select using (true);

-- A grower may only review their own order, and only once it's delivered.
drop policy if exists "reviews_insert_own_delivered_order" on reviews;
create policy "reviews_insert_own_delivered_order" on reviews
  for insert
  with check (
    auth.uid() = grower_id
    and exists (
      select 1 from orders
      where orders.id = order_id
        and orders.grower_id = auth.uid()
        and orders.seller_id = reviews.seller_id
        and orders.status = 'delivered'
    )
  );
