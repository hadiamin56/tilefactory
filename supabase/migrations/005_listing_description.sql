-- Run this in Supabase Dashboard -> SQL Editor.
-- Adds an optional description field for the new Input Details page.
alter table listings add column if not exists description text;
