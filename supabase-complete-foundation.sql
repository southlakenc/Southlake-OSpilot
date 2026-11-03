-- SOUTHLAKE OS: complete operational foundation migration
-- Non-destructive to existing jobs, assignments, notes, messages, photos, and auth users.
-- Run only while the two owners are the only active accounts. Review before applying.
begin;
create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '', phone text,
 active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.team_memberships (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null check(role in ('owner','manager','team_lead','employee')),
 department text check(department in ('Flooring','Fixtures','Merchandise') or department is null),
 active boolean not null default true, created_at timestamptz not null default now(),
 unique(user_id,department)
);

alter table public.jobs add column if not exists work_order_number text;
alter table public.jobs add column if not exists customer_name text;
alter table public.jobs add column if not exists customer_contact text;
alter table public.jobs add column if not exists stage text not null default 'inquiry';
alter table public.jobs add column if not exists priority text not null default 'normal';
alter table public.jobs add column if not exists start_date date;
alter table public.jobs add column if not exists due_date date;
alter table public.jobs add column if not exists updated_at timestamptz not null default now();
alter table public.jobs add column if not exists archived_at timestamptz;
alter table public.assignments add column if not exists employee_id uuid references auth.users(id) on delete set null;
alter table public.assignments add column if not exists assignment_status text not null default 'assigned';

create table if not exists public.job_documents (
 id uuid primary key default gen_random_uuid(), job_id uuid not null references public.jobs(id) on delete cascade,
 document_type text not null default 'other' check(document_type in ('work_order','change_order','email','text_message','photo','plan','estimate','approval','closeout','other')),
 title text not null, storage_path text not null, original_file_name text, notes text,
 department text check(department in ('Flooring','Fixtures','Merchandise') or department is null),
 uploaded_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.job_change_orders (
 id uuid primary key default gen_random_uuid(), job_id uuid not null references public.jobs(id) on delete cascade,
 change_number integer not null, title text not null, description text not null, requested_by text,
 source text not null default 'other' check(source in ('email','text','phone','onsite','other')),
 status text not null default 'draft' check(status in ('draft','submitted','approved','rejected','completed')),
 amount numeric(12,2), requested_date date not null default current_date,
 approved_by uuid references auth.users(id), approved_at timestamptz,
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
 unique(job_id,change_number)
);
create table if not exists public.job_team_messages (
 id uuid primary key default gen_random_uuid(), job_id uuid not null references public.jobs(id) on delete cascade,
 department text check(department in ('Flooring','Fixtures','Merchandise') or department is null),
 audience text not null default 'job' check(audience in ('job','department','management')),
 body text not null, created_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.job_coordination_flags (
 id uuid primary key default gen_random_uuid(), job_id uuid not null references public.jobs(id) on delete cascade,
 title text not null, details text, affected_departments text[] not null default '{}',
 status text not null default 'open' check(status in ('open','resolved')),
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), resolved_at timestamptz
);
create table if not exists public.assignment_history (
 id uuid primary key default gen_random_uuid(), assignment_id uuid, job_id uuid not null references public.jobs(id) on delete cascade,
 action text not null check(action in ('created','updated','removed')), employee_label text, employee_id uuid,
 department text, work_date date, changed_by uuid references auth.users(id), changed_at timestamptz not null default now()
);
create index if not exists assignments_employee_date_idx on public.assignments(employee_id,work_date);
create index if not exists job_documents_job_idx on public.job_documents(job_id,created_at desc);
create index if not exists change_orders_job_idx on public.job_change_orders(job_id,change_number);

create or replace function public.my_role() returns text language sql stable security definer set search_path=public
as $$ select role from public.team_memberships where user_id=auth.uid() and active order by case role when 'owner' then 1 when 'manager' then 2 when 'team_lead' then 3 else 4 end limit 1 $$;
create or replace function public.is_management() returns boolean language sql stable security definer set search_path=public
as $$ select coalesce(public.my_role() in ('owner','manager'),false) $$;
create or replace function public.is_job_member(target_job uuid) returns boolean language sql stable security definer set search_path=public
as $$ select public.is_management() or exists(select 1 from public.team_memberships m join public.assignments a on a.department=m.department and a.employee_id=m.user_id where m.user_id=auth.uid() and m.active and a.job_id=target_job) $$;

create or replace function public.log_assignment_change() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if tg_op='INSERT' then
  insert into public.assignment_history(assignment_id,job_id,action,employee_label,employee_id,department,work_date,changed_by) values(new.id,new.job_id,'created',new.employee_label,new.employee_id,new.department,new.work_date,auth.uid()); return new;
 elsif tg_op='UPDATE' then
  insert into public.assignment_history(assignment_id,job_id,action,employee_label,employee_id,department,work_date,changed_by) values(new.id,new.job_id,'updated',new.employee_label,new.employee_id,new.department,new.work_date,auth.uid()); return new;
 else
  insert into public.assignment_history(assignment_id,job_id,action,employee_label,employee_id,department,work_date,changed_by) values(old.id,old.job_id,'removed',old.employee_label,old.employee_id,old.department,old.work_date,auth.uid()); return old;
 end if;
end; $$;
drop trigger if exists assignments_audit_trigger on public.assignments;
create trigger assignments_audit_trigger after insert or update or delete on public.assignments for each row execute function public.log_assignment_change();

-- New tables start protected. Existing pilot-wide policies on core tables are intentionally
-- NOT silently removed here; replace them only after owner membership has been verified.
alter table public.user_profiles enable row level security;
alter table public.team_memberships enable row level security;
alter table public.job_documents enable row level security;
alter table public.job_change_orders enable row level security;
alter table public.job_team_messages enable row level security;
alter table public.job_coordination_flags enable row level security;
alter table public.assignment_history enable row level security;

-- Membership bootstrap: existing pilot users become owners; no staff accounts are created.
insert into public.user_profiles(user_id,display_name)
 select id,coalesce(raw_user_meta_data->>'full_name',split_part(email,'@',1)) from auth.users on conflict(user_id) do nothing;
insert into public.team_memberships(user_id,role,department)
 select id,'owner',null from auth.users on conflict(user_id,department) do nothing;

-- Policies for the new tables. Core-table policy hardening and Storage policies are a separate
-- verified step because current project policy names/storage configuration must be inspected first.
create policy profiles_self_read on public.user_profiles for select to authenticated using(user_id=auth.uid() or public.is_management());
create policy memberships_self_read on public.team_memberships for select to authenticated using(user_id=auth.uid() or public.is_management());
create policy memberships_owner_manage on public.team_memberships for all to authenticated using(public.my_role()='owner') with check(public.my_role()='owner');
create policy docs_member_read on public.job_documents for select to authenticated using(public.is_job_member(job_id));
create policy docs_member_add on public.job_documents for insert to authenticated with check(public.is_job_member(job_id) and uploaded_by=auth.uid());
create policy change_member_read on public.job_change_orders for select to authenticated using(public.is_job_member(job_id));
create policy change_member_add on public.job_change_orders for insert to authenticated with check(public.is_job_member(job_id) and created_by=auth.uid());
create policy change_management_update on public.job_change_orders for update to authenticated using(public.is_management()) with check(public.is_management());
create policy team_messages_read on public.job_team_messages for select to authenticated using(public.is_job_member(job_id));
create policy team_messages_add on public.job_team_messages for insert to authenticated with check(public.is_job_member(job_id) and created_by=auth.uid());
create policy coordination_read on public.job_coordination_flags for select to authenticated using(public.is_job_member(job_id));
create policy coordination_add on public.job_coordination_flags for insert to authenticated with check(public.is_job_member(job_id) and created_by=auth.uid());
create policy coordination_update on public.job_coordination_flags for update to authenticated using(public.is_management() or created_by=auth.uid()) with check(public.is_management() or created_by=auth.uid());
create policy assignment_history_management_read on public.assignment_history for select to authenticated using(public.is_management());

commit;

-- IMPORTANT SECURITY GATE:
-- Do not onboard employees yet. The current core-table pilot policies and job-photos Storage
-- policies must be inspected and replaced with role-aware policies before staff access is enabled.
-- Verify the two owners in team_memberships, then complete that hardening and test all four roles.
