-- Southlake OS v0.2 pilot migration. Non-destructive: preserves all existing rows.
-- Apply in Supabase SQL Editor while only the two owner accounts have access.
create table if not exists public.assignment_history (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid,
  job_id uuid not null references public.jobs(id) on delete cascade,
  action text not null check (action in ('created','updated','removed')),
  employee_label text,
  department text,
  work_date date,
  changed_by uuid references auth.users(id),
  changed_at timestamptz not null default now()
);

alter table public.assignment_history enable row level security;
create policy "pilot authenticated can read assignment history"
  on public.assignment_history for select to authenticated using (true);

-- Permit pilot owners to update/remove assignments. These policies are intentionally
-- pilot-wide; do not add employee accounts until role-based RLS replaces them.
create policy "pilot authenticated can update assignments"
  on public.assignments for update to authenticated using (true) with check (true);
create policy "pilot authenticated can remove assignments"
  on public.assignments for delete to authenticated using (true);

create or replace function public.log_assignment_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    insert into public.assignment_history(assignment_id,job_id,action,employee_label,department,work_date,changed_by)
    values(new.id,new.job_id,'created',new.employee_label,new.department,new.work_date,auth.uid());
    return new;
  elsif tg_op = 'UPDATE' then
    insert into public.assignment_history(assignment_id,job_id,action,employee_label,department,work_date,changed_by)
    values(new.id,new.job_id,'updated',new.employee_label,new.department,new.work_date,auth.uid());
    return new;
  elsif tg_op = 'DELETE' then
    insert into public.assignment_history(assignment_id,job_id,action,employee_label,department,work_date,changed_by)
    values(old.id,old.job_id,'removed',old.employee_label,old.department,old.work_date,auth.uid());
    return old;
  end if;
  return null;
end; $$;

drop trigger if exists assignments_audit_trigger on public.assignments;
create trigger assignments_audit_trigger
after insert or update or delete on public.assignments
for each row execute function public.log_assignment_change();

-- Team coordination flags stay attached to the shared job record.
create table if not exists public.job_coordination_flags (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  title text not null,
  details text,
  affected_departments text[] not null default '{}',
  status text not null default 'open' check (status in ('open','resolved')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
alter table public.job_coordination_flags enable row level security;
create policy "pilot authenticated can read coordination flags"
  on public.job_coordination_flags for select to authenticated using (true);
create policy "pilot authenticated can create coordination flags"
  on public.job_coordination_flags for insert to authenticated with check (auth.uid() = created_by);
create policy "pilot authenticated can update coordination flags"
  on public.job_coordination_flags for update to authenticated using (true) with check (true);

-- Sketches are saved as image data in job_notes.body in this pilot build.
-- This is suitable for small field sketches only; a storage-backed drawing table is
-- recommended before widespread use to avoid large database rows.
