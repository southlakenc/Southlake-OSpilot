# Southlake OS v0.3 — Foundation build

This package carries forward the working v0.2 phone-tested React/Vite/Supabase app and the exact Southlake logo.

## Added in this foundation package
- A complete product/workflow blueprint for the shared job record.
- Database structures for company profiles and memberships, real employee-account assignment links, assignment audit history, job document register, formal change orders, department-targeted job messages, and cross-team coordination flags.
- Job lifecycle fields: inquiry, site visit, estimating, quoted, approved, scheduled, in progress, change order, closeout, complete, and on hold.
- A migration that bootstraps existing auth users as owners and protects newly introduced tables with row-level security.

## Not yet enabled
This is not an employee rollout build. Existing core-table pilot policies and Supabase Storage object policies still require project-specific inspection and hardening. The migration deliberately does not pretend those are secure or remove existing access policies blindly. Keep only the two owners on the project until that work and role-by-role testing are complete.

## Files
- `supabase-complete-foundation.sql` — additive schema foundation; review before running.
- `BUILD-ROADMAP.md` — agreed product behavior and rollout gates.
- `src/` and `public/` — current tested app baseline and logo.
