# Southlake OS — Complete build direction

## Product rule
One shared job record is the source of truth from inquiry through closeout. Flooring, Fixtures, and Merchandise are team views/scopes on that same job—not separate copies of the job.

## Target workflow
1. Inquiry / work order received
2. Site visit and field notes/photos
3. Estimate and quote
4. Customer approval
5. Schedule and crew assignments
6. Work in progress
7. Change orders (with source evidence and approval trail)
8. Closeout and completion

## Core areas
- Jobs: work-order identity, customer/site details, stage, priority, dates, status.
- Teams: Flooring, Fixtures, Merchandise; team leads manage their own crew assignments.
- Assignments: real user accounts, work date, department, status, assignment/reassignment/unassignment audit trail.
- Documents: one job document register for work orders, email/text screenshots, plans, estimates, approvals, photos and closeout files.
- Change orders: numbered, status-controlled records linked to the job and supporting documents. Chat messages are never silently treated as approved scope changes.
- Coordination: cross-team flags, affected teams, details/sketch/photo, open/resolved state.
- Communication: shared job conversation plus department-targeted messages.
- Security: database-enforced roles and row-level security; UI hiding is not security.

## Roles
- Owner: full company-wide access and membership administration.
- Manager: company-wide operational access and assignment management.
- Team lead: sees shared job information for assigned jobs and manages assignments for their own department.
- Employee: sees their own assignments and the job information needed to do the work; cannot manage assignments or memberships.

## Rollout gates
- Keep only the two owner accounts active during development.
- Apply and verify role-based database policies before creating staff accounts.
- Secure Supabase Storage object policies as well as database rows before staff onboarding.
- Test owner, manager, team lead, and employee permissions independently.
- Verify on desktop, Android, and iPhone before company rollout.

## Existing pilot
The current app remains the working baseline while this build is developed. Test records are disposable; owner logins and project configuration should be preserved. Do not paste a Supabase service-role key into the browser app.
