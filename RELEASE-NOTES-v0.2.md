# Southlake OS v0.2 — mobile field-test candidate

## Included
- Southlake skyline monogram used in the login/header and as the PWA icon.
- Back to Job Overview navigation on Assignments, Notes, Photos, and Messages.
- Finger/mouse drawing pad in Job Notes; sketches are saved as job notes and shared with the job.
- Assignment removal in the UI.
- SQL migration adds assignment audit history (created/updated/removed) and a shared-job coordination flag table.

## Important pilot limits
- This is a test candidate, not a production security release.
- The assignment audit trigger and remove action require `supabase-v0.2-migration.sql` to be run in Supabase SQL Editor before testing those actions.
- Existing pilot RLS is broad for authenticated users. The migration preserves that pilot model and does NOT implement owner/manager/team-lead/employee permission tiers. Keep access restricted to the two owner accounts. Do not invite employees yet.
- Coordination flag storage is included in the migration, but the flag-management screen and notifications are not yet implemented.
- Sketches are stored as data URLs in `job_notes.body` for this small pilot; use only small sketches. A storage-backed design is needed before broad rollout.
- Assignment history is recorded in the database, but a history viewer and reassign editor are not yet included in this candidate.

## Safe rollout
1. Keep the current Vercel production deployment unchanged.
2. Create a separate GitHub branch named `v0.2-field-test`.
3. Put this source on that branch and use a Vercel Preview deployment.
4. Apply the migration to the existing Supabase pilot only after making a database backup/export.
5. Test login, job sync, notes, photos, messaging, sketch save/reload, assignment removal, and assignment history on iPhone, Android, and desktop.
6. Do not merge to the production branch until tests pass and role-based RLS has been implemented and reviewed.

## Build status
The project source and SQL were prepared. A local Vite build could not be completed in this environment because dependency installation timed out. Vercel should run the normal build in the preview deployment; review its build log before testing.
