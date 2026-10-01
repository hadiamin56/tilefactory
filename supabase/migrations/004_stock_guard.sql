-- Run this in Supabase Dashboard -> SQL Editor.
-- The existing decrement_listing_stock RPC silently clamps stock to 0 when
-- asked to decrement more than is available, instead of rejecting the
-- order — meaning checkout can currently oversell. This redefines it to
-- reject the update (and the checkout that triggered it) when there isn't
-- enough stock, at the database level so no client bug can bypass it.
create or replace function decrement_listing_stock(p_listing_id uuid, p_quantity int)
returns void
language plpgsql
security definer
as $$
begin
  update listings
  set stock = stock - p_quantity
  where id = p_listing_id and stock >= p_quantity;

  if not found then
    raise exception 'Not enough stock available for this item';
  end if;
end;
$$;
