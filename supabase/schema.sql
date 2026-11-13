-- Print_Bud CRM v0.1 - PostgreSQL / Supabase foundation
-- Review and apply to a NEW Supabase project. Never run against production data without backup.
create extension if not exists pgcrypto;

create type public.printer_technology as enum ('FDM','RESIN','OTHER');
create type public.printer_status as enum ('IDLE','RUNNING','MAINTENANCE','OFFLINE');
create type public.order_status as enum ('ENQUIRY','QUOTATION','CONFIRMED','PRINTING','POST_PROCESSING','QUALITY_CHECK','PACKAGING','SHIPPED','DELIVERED','CANCELLED');
create type public.customer_type as enum ('INDIVIDUAL','BUSINESS','RESELLER','WHOLESALE');
create type public.billing_mode as enum ('GST','NON_GST');

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  display_name text not null default 'Print_Bud',
  gstin text,
  email text,
  phone text,
  website text,
  billing_address jsonb not null default '{}'::jsonb,
  logo_path text,
  currency_code char(3) not null default 'INR',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.locations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  code text not null,
  name text not null,
  address jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(company_id, code)
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  full_name text not null,
  phone text,
  role text not null check(role in ('ADMIN','STAFF','ACCOUNTANT')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.printers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  location_id uuid not null references public.locations(id),
  printer_code text not null,
  name text not null,
  manufacturer text,
  model text,
  technology public.printer_technology not null,
  power_watts numeric(10,2) not null default 0 check(power_watts >= 0),
  electricity_rate_per_kwh numeric(12,4) not null default 0,
  purchase_cost numeric(14,2) not null default 0,
  expected_life_hours numeric(12,2),
  maintenance_budget numeric(14,2) not null default 0,
  status public.printer_status not null default 'IDLE',
  total_run_hours numeric(14,2) not null default 0,
  purchased_on date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, printer_code)
);

create table public.printer_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  printer_id uuid not null references public.printers(id),
  started_at timestamptz not null,
  ended_at timestamptz,
  actual_hours numeric(12,2),
  energy_kwh numeric(12,4),
  notes text,
  created_at timestamptz not null default now()
);

create table public.maintenance_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  printer_id uuid not null references public.printers(id),
  maintenance_date date not null default current_date,
  category text not null,
  description text,
  cost numeric(14,2) not null default 0,
  next_due_date date,
  created_at timestamptz not null default now()
);

create table public.materials (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  sku text not null,
  name text not null,
  material_type text not null,
  technology public.printer_technology not null default 'FDM',
  base_unit text not null default 'g',
  reorder_level numeric(14,3) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(company_id, sku)
);

create table public.material_batches (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  material_id uuid not null references public.materials(id),
  location_id uuid not null references public.locations(id),
  batch_code text,
  brand text,
  colour text,
  received_quantity numeric(14,3) not null,
  remaining_quantity numeric(14,3) not null check(remaining_quantity >= 0),
  unit_cost numeric(14,4) not null,
  supplier_name text,
  purchased_on date,
  created_at timestamptz not null default now()
);

create table public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  material_id uuid not null references public.materials(id),
  batch_id uuid references public.material_batches(id),
  location_id uuid not null references public.locations(id),
  movement_type text not null check(movement_type in ('PURCHASE','CONSUMPTION','WASTAGE','ADJUSTMENT','TRANSFER_IN','TRANSFER_OUT','RETURN')),
  quantity numeric(14,3) not null,
  unit_cost numeric(14,4),
  reference_type text,
  reference_id uuid,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  customer_code text not null,
  customer_type public.customer_type not null default 'BUSINESS',
  display_name text not null,
  legal_name text,
  phone text,
  email text,
  gstin text,
  billing_address jsonb not null default '{}'::jsonb,
  shipping_address jsonb not null default '{}'::jsonb,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(company_id, customer_code)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  location_id uuid not null references public.locations(id),
  customer_id uuid not null references public.customers(id),
  order_number text not null,
  status public.order_status not null default 'ENQUIRY',
  order_date date not null default current_date,
  due_date date,
  billing_mode public.billing_mode not null default 'GST',
  subtotal numeric(14,2) not null default 0,
  discount_amount numeric(14,2) not null default 0,
  tax_amount numeric(14,2) not null default 0,
  shipping_amount numeric(14,2) not null default 0,
  grand_total numeric(14,2) not null default 0,
  advance_received numeric(14,2) not null default 0,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, order_number)
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  description text not null,
  quantity numeric(12,3) not null default 1,
  unit_price numeric(14,2) not null default 0,
  discount_amount numeric(14,2) not null default 0,
  tax_rate numeric(5,2) not null default 0,
  tax_amount numeric(14,2) not null default 0,
  line_total numeric(14,2) not null default 0,
  stl_file_path text,
  reference_image_path text
);

create table public.print_jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  order_item_id uuid references public.order_items(id),
  printer_id uuid not null references public.printers(id),
  location_id uuid not null references public.locations(id),
  job_code text not null,
  status text not null default 'QUEUED',
  estimated_hours numeric(12,2),
  actual_hours numeric(12,2),
  estimated_material_g numeric(14,3),
  actual_material_g numeric(14,3),
  started_at timestamptz,
  completed_at timestamptz,
  failure_reason text,
  reprint_of uuid references public.print_jobs(id),
  created_at timestamptz not null default now(),
  unique(company_id, job_code)
);

create table public.print_job_materials (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  print_job_id uuid not null references public.print_jobs(id) on delete cascade,
  material_id uuid not null references public.materials(id),
  batch_id uuid references public.material_batches(id),
  estimated_quantity_g numeric(14,3) not null default 0,
  actual_quantity_g numeric(14,3) not null default 0,
  unit_cost_per_kg numeric(14,4) not null default 0
);

create table public.costing_profiles (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  pricing_method text not null default 'MARKUP' check(pricing_method in ('MARKUP','MARGIN','FIXED_PROFIT')),
  default_markup_pct numeric(7,3) not null default 35,
  labour_rate_per_hour numeric(14,2) not null default 0,
  electricity_rate_per_kwh numeric(14,4) not null default 0,
  default_tax_rate numeric(5,2) not null default 0,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.cost_breakdowns (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  order_item_id uuid references public.order_items(id),
  print_job_id uuid references public.print_jobs(id),
  currency_code char(3) not null default 'INR',
  material_cost numeric(14,2) not null default 0,
  electricity_cost numeric(14,2) not null default 0,
  machine_depreciation numeric(14,2) not null default 0,
  maintenance_cost numeric(14,2) not null default 0,
  painting_cost numeric(14,2) not null default 0,
  labour_cost numeric(14,2) not null default 0,
  post_processing_cost numeric(14,2) not null default 0,
  packaging_cost numeric(14,2) not null default 0,
  shipping_cost numeric(14,2) not null default 0,
  other_cost numeric(14,2) not null default 0,
  total_cost numeric(14,2) not null default 0,
  pricing_method text not null,
  pricing_value numeric(12,3) not null default 0,
  suggested_price numeric(14,2) not null default 0,
  calculated_at timestamptz not null default now()
);

create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  unique(company_id, name)
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  location_id uuid references public.locations(id),
  category_id uuid references public.expense_categories(id),
  expense_date date not null default current_date,
  description text not null,
  amount numeric(14,2) not null,
  tax_amount numeric(14,2) not null default 0,
  vendor_name text,
  receipt_path text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  order_id uuid references public.orders(id),
  customer_id uuid not null references public.customers(id),
  invoice_number text not null,
  billing_mode public.billing_mode not null,
  invoice_date date not null default current_date,
  due_date date,
  place_of_supply text,
  reverse_charge boolean not null default false,
  subtotal numeric(14,2) not null default 0,
  discount_amount numeric(14,2) not null default 0,
  cgst_amount numeric(14,2) not null default 0,
  sgst_amount numeric(14,2) not null default 0,
  igst_amount numeric(14,2) not null default 0,
  grand_total numeric(14,2) not null default 0,
  status text not null default 'DRAFT',
  pdf_path text,
  created_at timestamptz not null default now(),
  unique(company_id, invoice_number)
);

create table public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  hsn_sac text,
  quantity numeric(12,3) not null default 1,
  unit text,
  unit_price numeric(14,2) not null default 0,
  discount_amount numeric(14,2) not null default 0,
  tax_rate numeric(5,2) not null default 0,
  taxable_value numeric(14,2) not null default 0,
  tax_amount numeric(14,2) not null default 0,
  line_total numeric(14,2) not null default 0
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  invoice_id uuid references public.invoices(id),
  order_id uuid references public.orders(id),
  payment_date date not null default current_date,
  amount numeric(14,2) not null,
  method text not null,
  transaction_reference text,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.shipments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  order_id uuid not null references public.orders(id),
  courier_name text,
  tracking_number text,
  shipping_cost numeric(14,2) not null default 0,
  shipped_at timestamptz,
  delivered_at timestamptz,
  status text not null default 'PENDING',
  created_at timestamptz not null default now()
);

create table public.custom_fields (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  entity_type text not null,
  field_key text not null,
  label text not null,
  field_type text not null check(field_type in ('TEXT','NUMBER','DATE','BOOLEAN','SELECT')),
  options jsonb not null default '[]'::jsonb,
  is_required boolean not null default false,
  is_active boolean not null default true,
  unique(company_id, entity_type, field_key)
);

create table public.custom_field_values (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  custom_field_id uuid not null references public.custom_fields(id) on delete cascade,
  record_id uuid not null,
  value jsonb,
  created_at timestamptz not null default now(),
  unique(custom_field_id, record_id)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  entity_type text not null,
  entity_id uuid,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create index idx_printers_company_location on public.printers(company_id, location_id);
create index idx_material_batches_location on public.material_batches(location_id, material_id);
create index idx_stock_movements_material_date on public.stock_movements(material_id, created_at desc);
create index idx_customers_company_name on public.customers(company_id, display_name);
create index idx_orders_company_status_date on public.orders(company_id, status, order_date desc);
create index idx_print_jobs_printer_status on public.print_jobs(printer_id, status);
create index idx_invoices_customer_date on public.invoices(customer_id, invoice_date desc);
create index idx_payments_company_date on public.payments(company_id, payment_date desc);


-- Tenant isolation and role-aware access for Print_Bud CRM.
-- The first company / owner is created only by the trusted bootstrap-company-admin Edge Function.

create table public.app_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  entity_type text not null check (entity_type in ('printers','materials','customers','orders','settings','estimates')),
  record_key text not null,
  payload jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, entity_type, record_key)
);
create index idx_app_records_company_entity on public.app_records(company_id, entity_type);

create or replace function public.current_company_id()
returns uuid
language sql stable security definer
set search_path = public, pg_temp
as $$
  select p.company_id
  from public.profiles p
  where p.id = auth.uid() and p.is_active = true
  limit 1
$$;

create or replace function public.current_user_role()
returns text
language sql stable security definer
set search_path = public, pg_temp
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid() and p.is_active = true
  limit 1
$$;

revoke all on function public.current_company_id() from public, anon;
revoke all on function public.current_user_role() from public, anon;
grant execute on function public.current_company_id() to authenticated;
grant execute on function public.current_user_role() to authenticated;

-- A project-level event trigger may enable RLS automatically. It must never be
-- callable as an RPC by browser roles.
revoke all on function public.rls_auto_enable() from public, anon, authenticated;

alter table public.companies enable row level security;
alter table public.profiles enable row level security;

drop policy if exists companies_select_own_tenant on public.companies;
drop policy if exists companies_admin_update on public.companies;
create policy companies_select_own_tenant on public.companies
  for select to authenticated
  using (id = public.current_company_id());
create policy companies_admin_update on public.companies
  for update to authenticated
  using (id = public.current_company_id() and public.current_user_role() = 'ADMIN')
  with check (id = public.current_company_id() and public.current_user_role() = 'ADMIN');

drop policy if exists profiles_select_self_or_admin on public.profiles;
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_select_self_or_admin on public.profiles
  for select to authenticated
  using (
    id = auth.uid()
    or (company_id = public.current_company_id() and public.current_user_role() = 'ADMIN')
  );
create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = auth.uid() and company_id = public.current_company_id())
  with check (id = auth.uid() and company_id = public.current_company_id());

-- Profile inserts / deletes and role changes are service-side only.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

revoke all on public.companies from anon, authenticated;
grant select, update on public.companies to authenticated;

do $$
declare
  t text;
  admin_staff text[] := array[
    'printers','printer_logs','maintenance_logs','materials','material_batches',
    'stock_movements','customers','orders','order_items','print_jobs',
    'print_job_materials','costing_profiles','cost_breakdowns','shipments',
    'custom_fields','custom_field_values'
  ];
  admin_accountant text[] := array[
    'expense_categories','expenses','invoices','invoice_items','payments'
  ];
begin
  foreach t in array array[
    'locations','printers','printer_logs','maintenance_logs','materials',
    'material_batches','stock_movements','customers','orders','order_items','print_jobs',
    'print_job_materials','costing_profiles','cost_breakdowns','expense_categories',
    'expenses','invoices','invoice_items','payments','shipments','custom_fields',
    'custom_field_values','audit_logs','app_records'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists company_select on public.%I', t);
    execute format('drop policy if exists company_insert on public.%I', t);
    execute format('drop policy if exists company_update on public.%I', t);
    execute format('drop policy if exists company_delete on public.%I', t);
    execute format('create policy company_select on public.%I for select to authenticated using (company_id = public.current_company_id())', t);

    if t = 'locations' or t = 'custom_fields' then
      execute format('create policy company_insert on public.%I for insert to authenticated with check (company_id = public.current_company_id() and public.current_user_role() = ''ADMIN'')', t);
      execute format('create policy company_update on public.%I for update to authenticated using (company_id = public.current_company_id() and public.current_user_role() = ''ADMIN'') with check (company_id = public.current_company_id() and public.current_user_role() = ''ADMIN'')', t);
      execute format('create policy company_delete on public.%I for delete to authenticated using (company_id = public.current_company_id() and public.current_user_role() = ''ADMIN'')', t);
    elsif t = 'audit_logs' then
      -- Audit rows are readable only by admins and accountants; clients cannot mutate them.
      execute 'drop policy if exists company_select on public.audit_logs';
      execute 'create policy company_select on public.audit_logs for select to authenticated using (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''ACCOUNTANT''))';
    elsif t = 'app_records' then
      execute 'create policy company_insert on public.app_records for insert to authenticated with check (company_id = public.current_company_id() and ((entity_type = ''settings'' and public.current_user_role() = ''ADMIN'') or (entity_type <> ''settings'' and public.current_user_role() in (''ADMIN'',''STAFF''))))';
      execute 'create policy company_update on public.app_records for update to authenticated using (company_id = public.current_company_id() and ((entity_type = ''settings'' and public.current_user_role() = ''ADMIN'') or (entity_type <> ''settings'' and public.current_user_role() in (''ADMIN'',''STAFF'')))) with check (company_id = public.current_company_id() and ((entity_type = ''settings'' and public.current_user_role() = ''ADMIN'') or (entity_type <> ''settings'' and public.current_user_role() in (''ADMIN'',''STAFF''))))';
      execute 'create policy company_delete on public.app_records for delete to authenticated using (company_id = public.current_company_id() and ((entity_type = ''settings'' and public.current_user_role() = ''ADMIN'') or (entity_type <> ''settings'' and public.current_user_role() in (''ADMIN'',''STAFF''))))';
    elsif t = any(admin_accountant) then
      execute format('create policy company_insert on public.%I for insert to authenticated with check (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''ACCOUNTANT''))', t);
      execute format('create policy company_update on public.%I for update to authenticated using (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''ACCOUNTANT'')) with check (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''ACCOUNTANT''))', t);
      execute format('create policy company_delete on public.%I for delete to authenticated using (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''ACCOUNTANT''))', t);
    else
      execute format('create policy company_insert on public.%I for insert to authenticated with check (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''STAFF''))', t);
      execute format('create policy company_update on public.%I for update to authenticated using (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''STAFF'')) with check (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''STAFF''))', t);
      execute format('create policy company_delete on public.%I for delete to authenticated using (company_id = public.current_company_id() and public.current_user_role() in (''ADMIN'',''STAFF''))', t);
    end if;
  end loop;
end $$;

-- Browser roles receive table privileges; RLS above remains the authorization boundary.
grant select, insert, update, delete on
  public.locations, public.printers, public.printer_logs, public.maintenance_logs,
  public.materials, public.material_batches, public.stock_movements, public.customers,
  public.orders, public.order_items, public.print_jobs, public.print_job_materials,
  public.costing_profiles, public.cost_breakdowns, public.expense_categories,
  public.expenses, public.invoices, public.invoice_items, public.payments,
  public.shipments, public.custom_fields, public.custom_field_values, public.app_records
to authenticated;
grant select on public.audit_logs to authenticated;

-- The app_records bridge keeps the current interface's simple CRUD operational
-- while the dedicated production tables are progressively wired into screens.
