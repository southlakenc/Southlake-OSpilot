# Southlake Operations — Pilot 0.1

A mobile-friendly React/Vite PWA connected to Supabase. Current pilot modules: email/password sign-in, shared jobs, date-based daily assignments, job notes, private photo uploads, and job chat.

## Important pilot limitations
- This is a limited two-owner pilot, not the finished production system.
- Invite only the two owners initially. The SQL policies allow any authenticated pilot account to read pilot records; do not invite employees or outside contacts until membership-based access controls are implemented and tested.
- Assignment entries are currently labels (employee name/number), not linked employee accounts. This is deliberate for the first owner-only test.
- No approved change-order workflow, permanent user management, role-based permissions, employee PIN login, push notifications, audit history, or financial module yet.
- Do not upload sensitive customer, payment, bank, or confidential contract information during this pilot.
- Back up uploaded Storage files separately; database backups do not automatically provide a complete independent copy of photo objects.

## 1. Supabase setup
1. Open the `Southlake-Pilot` project.
2. Open **SQL Editor**, create a new query, paste `supabase-setup.sql`, and run it.
3. In **Authentication → Users**, invite only the two owners by email. If email confirmation is enabled, complete confirmation before signing in. Disable public sign-ups in the Auth settings so nobody else can create a pilot account.
4. In **Project Settings → API**, copy the Project URL and the publishable key (or legacy anon key). Never use the `service_role` / secret key in this browser app.

## 2. Add code to GitHub
Upload the contents of this folder to the root of the private `Southlake-OS` repository (not the enclosing folder). Commit to the default branch.

## 3. Deploy with Vercel
1. Import `Southlake-OS` in Vercel and choose the Vite framework preset (or let Vercel detect it).
2. Add environment variables:
   - `VITE_SUPABASE_URL` = Supabase Project URL
   - `VITE_SUPABASE_ANON_KEY` = Supabase publishable/anon key
3. Deploy. Later changes to the GitHub default branch trigger redeploys.

## 4. Install on phones
Open the Vercel deployment URL in Chrome on Android or Safari on iPhone. Use the browser's **Add to Home Screen** option. The pilot is responsive and has a web app manifest; offline editing and push notifications are not included.

## Local development
`npm install`, create `.env.local` from `.env.example`, then `npm run dev`.
