-- Run this in Supabase Dashboard -> SQL Editor.
-- Adds real product photos for listings: a storage bucket for uploads
-- plus an image_url column to point at them.

alter table listings add column if not exists image_url text;

insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

drop policy if exists "listing_images_public_read" on storage.objects;
create policy "listing_images_public_read" on storage.objects
  for select using (bucket_id = 'listing-images');

drop policy if exists "listing_images_auth_insert" on storage.objects;
create policy "listing_images_auth_insert" on storage.objects
  for insert with check (bucket_id = 'listing-images' and auth.role() = 'authenticated');

drop policy if exists "listing_images_owner_update" on storage.objects;
create policy "listing_images_owner_update" on storage.objects
  for update using (bucket_id = 'listing-images' and owner = auth.uid());

drop policy if exists "listing_images_owner_delete" on storage.objects;
create policy "listing_images_owner_delete" on storage.objects
  for delete using (bucket_id = 'listing-images' and owner = auth.uid());
