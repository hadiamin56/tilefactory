-- Run this in Supabase Dashboard -> SQL Editor.
-- Lets admins see and act on verification_requests (previously only the
-- submitting user could see their own request, so nobody could review them).

drop policy if exists "verification_requests_admin_select" on verification_requests;
create policy "verification_requests_admin_select" on verification_requests
  for select using (is_admin());

drop policy if exists "verification_requests_admin_update" on verification_requests;
create policy "verification_requests_admin_update" on verification_requests
  for update using (is_admin());
