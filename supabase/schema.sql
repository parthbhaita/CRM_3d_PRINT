-- Print_Bud CRM v0.1 - PostgreSQL / Supabase foundation
-- Review and apply to a NEW Supabase project. Never run against production data without backup.
create extension if not exists pgcrypto;

-- Public application tables are intentionally exposed only to authenticated users via explicit grants and RLS.


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
  base_unit text not null default 'kg',
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


-- Print_Bud CRM secure tenant bootstrap and authorization.
-- This schema is intended for the verified empty Print_Bud CRM Supabase project.

-- The function is attached to Supabase's ensure_rls DDL event trigger.
-- It is not an RPC endpoint and must not be executable by API roles.
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

create or replace function private.current_company_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select p.company_id
  from public.profiles p
  where p.id = (select auth.uid())
    and p.is_active = true
  limit 1
$$;

create or replace function private.current_user_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select p.role
  from public.profiles p
  where p.id = (select auth.uid())
    and p.is_active = true
  limit 1
$$;

revoke all on function private.current_company_id() from public, anon;
revoke all on function private.current_user_role() from public, anon;
grant execute on function private.current_company_id() to authenticated;
grant execute on function private.current_user_role() to authenticated;

-- A new self-signup creates an isolated Print_Bud company, its first ADMIN profile,
-- one default workshop, and one default costing profile. User metadata is used
-- only for display/company labels, never to determine authorization.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_company_id uuid;
  v_full_name text;
  v_company_name text;
begin
  v_full_name := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(split_part(coalesce(new.email, 'Print_Bud Admin'), '@', 1), ''),
    'Print_Bud Admin'
  );
  v_company_name := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'company_name'), ''),
    'Print_Bud'
  );

  insert into public.companies (legal_name, display_name, email)
  values (v_company_name, 'Print_Bud', new.email)
  returning id into v_company_id;

  insert into public.profiles (id, company_id, full_name, role)
  values (new.id, v_company_id, v_full_name, 'ADMIN');

  insert into public.locations (company_id, code, name)
  values (v_company_id, 'MAIN', 'Main Workshop');

  insert into public.costing_profiles (
    company_id, name, pricing_method, default_markup_pct, is_default
  )
  values (v_company_id, 'Default', 'MARKUP', 35, true);

  return new;
end;
$$;

revoke all on function private.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- Updated timestamp maintenance.
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
revoke all on function private.set_updated_at() from public, anon, authenticated;

drop trigger if exists companies_set_updated_at on public.companies;
create trigger companies_set_updated_at before update on public.companies
for each row execute function private.set_updated_at();

drop trigger if exists printers_set_updated_at on public.printers;
create trigger printers_set_updated_at before update on public.printers
for each row execute function private.set_updated_at();

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at before update on public.orders
for each row execute function private.set_updated_at();

-- Tenant-safe composite keys and foreign keys prevent references to another company's rows.
alter table public.locations add constraint locations_company_id_id_uk unique (company_id, id);
alter table public.profiles add constraint profiles_company_id_id_uk unique (company_id, id);
alter table public.printers add constraint printers_company_id_id_uk unique (company_id, id);
alter table public.materials add constraint materials_company_id_id_uk unique (company_id, id);
alter table public.material_batches add constraint material_batches_company_id_id_uk unique (company_id, id);
alter table public.customers add constraint customers_company_id_id_uk unique (company_id, id);
alter table public.orders add constraint orders_company_id_id_uk unique (company_id, id);
alter table public.order_items add constraint order_items_company_id_id_uk unique (company_id, id);
alter table public.print_jobs add constraint print_jobs_company_id_id_uk unique (company_id, id);
alter table public.costing_profiles add constraint costing_profiles_company_id_id_uk unique (company_id, id);
alter table public.expense_categories add constraint expense_categories_company_id_id_uk unique (company_id, id);
alter table public.invoices add constraint invoices_company_id_id_uk unique (company_id, id);
alter table public.custom_fields add constraint custom_fields_company_id_id_uk unique (company_id, id);

alter table public.printers add constraint printers_company_location_fk
  foreign key (company_id, location_id) references public.locations(company_id, id);
alter table public.printer_logs add constraint printer_logs_company_printer_fk
  foreign key (company_id, printer_id) references public.printers(company_id, id);
alter table public.maintenance_logs add constraint maintenance_logs_company_printer_fk
  foreign key (company_id, printer_id) references public.printers(company_id, id);
alter table public.material_batches add constraint material_batches_company_material_fk
  foreign key (company_id, material_id) references public.materials(company_id, id);
alter table public.material_batches add constraint material_batches_company_location_fk
  foreign key (company_id, location_id) references public.locations(company_id, id);
alter table public.stock_movements add constraint stock_movements_company_material_fk
  foreign key (company_id, material_id) references public.materials(company_id, id);
alter table public.stock_movements add constraint stock_movements_company_location_fk
  foreign key (company_id, location_id) references public.locations(company_id, id);
alter table public.stock_movements add constraint stock_movements_company_batch_fk
  foreign key (company_id, batch_id) references public.material_batches(company_id, id);
alter table public.stock_movements add constraint stock_movements_company_creator_fk
  foreign key (company_id, created_by) references public.profiles(company_id, id);
alter table public.orders add constraint orders_company_location_fk
  foreign key (company_id, location_id) references public.locations(company_id, id);
alter table public.orders add constraint orders_company_customer_fk
  foreign key (company_id, customer_id) references public.customers(company_id, id);
alter table public.orders add constraint orders_company_creator_fk
  foreign key (company_id, created_by) references public.profiles(company_id, id);
alter table public.order_items add constraint order_items_company_order_fk
  foreign key (company_id, order_id) references public.orders(company_id, id);
alter table public.print_jobs add constraint print_jobs_company_order_item_fk
  foreign key (company_id, order_item_id) references public.order_items(company_id, id);
alter table public.print_jobs add constraint print_jobs_company_printer_fk
  foreign key (company_id, printer_id) references public.printers(company_id, id);
alter table public.print_jobs add constraint print_jobs_company_location_fk
  foreign key (company_id, location_id) references public.locations(company_id, id);
alter table public.print_jobs add constraint print_jobs_company_reprint_fk
  foreign key (company_id, reprint_of) references public.print_jobs(company_id, id);
alter table public.print_job_materials add constraint print_job_materials_company_job_fk
  foreign key (company_id, print_job_id) references public.print_jobs(company_id, id);
alter table public.print_job_materials add constraint print_job_materials_company_material_fk
  foreign key (company_id, material_id) references public.materials(company_id, id);
alter table public.print_job_materials add constraint print_job_materials_company_batch_fk
  foreign key (company_id, batch_id) references public.material_batches(company_id, id);
alter table public.cost_breakdowns add constraint cost_breakdowns_company_order_item_fk
  foreign key (company_id, order_item_id) references public.order_items(company_id, id);
alter table public.cost_breakdowns add constraint cost_breakdowns_company_print_job_fk
  foreign key (company_id, print_job_id) references public.print_jobs(company_id, id);
alter table public.expenses add constraint expenses_company_location_fk
  foreign key (company_id, location_id) references public.locations(company_id, id);
alter table public.expenses add constraint expenses_company_category_fk
  foreign key (company_id, category_id) references public.expense_categories(company_id, id);
alter table public.expenses add constraint expenses_company_creator_fk
  foreign key (company_id, created_by) references public.profiles(company_id, id);
alter table public.invoices add constraint invoices_company_order_fk
  foreign key (company_id, order_id) references public.orders(company_id, id);
alter table public.invoices add constraint invoices_company_customer_fk
  foreign key (company_id, customer_id) references public.customers(company_id, id);
alter table public.invoice_items add constraint invoice_items_company_invoice_fk
  foreign key (company_id, invoice_id) references public.invoices(company_id, id);
alter table public.payments add constraint payments_company_invoice_fk
  foreign key (company_id, invoice_id) references public.invoices(company_id, id);
alter table public.payments add constraint payments_company_order_fk
  foreign key (company_id, order_id) references public.orders(company_id, id);
alter table public.payments add constraint payments_company_creator_fk
  foreign key (company_id, created_by) references public.profiles(company_id, id);
alter table public.shipments add constraint shipments_company_order_fk
  foreign key (company_id, order_id) references public.orders(company_id, id);
alter table public.custom_field_values add constraint custom_field_values_company_field_fk
  foreign key (company_id, custom_field_id) references public.custom_fields(company_id, id);
alter table public.audit_logs add constraint audit_logs_company_actor_fk
  foreign key (company_id, actor_id) references public.profiles(company_id, id);

-- Enable RLS explicitly (Supabase also has an event trigger for public tables).
alter table public.companies enable row level security;
do $$
declare
  t text;
begin
  foreach t in array array[
    'locations','profiles','printers','printer_logs','maintenance_logs','materials',
    'material_batches','stock_movements','customers','orders','order_items','print_jobs',
    'print_job_materials','costing_profiles','cost_breakdowns','expense_categories',
    'expenses','invoices','invoice_items','payments','shipments','custom_fields',
    'custom_field_values','audit_logs'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

create policy companies_select_own
  on public.companies for select to authenticated
  using (id = (select private.current_company_id()));
create policy companies_admin_update
  on public.companies for update to authenticated
  using (
    id = (select private.current_company_id())
    and (select private.current_user_role()) = 'ADMIN'
  )
  with check (
    id = (select private.current_company_id())
    and (select private.current_user_role()) = 'ADMIN'
  );

create policy profiles_select_self_or_admin
  on public.profiles for select to authenticated
  using (
    id = (select auth.uid())
    or (
      company_id = (select private.current_company_id())
      and (select private.current_user_role()) = 'ADMIN'
    )
  );

-- Every tenant table gets company-scoped SELECT. No generic profile writes are granted.
do $$
declare
  t text;
begin
  foreach t in array array[
    'locations','printers','printer_logs','maintenance_logs','materials','material_batches',
    'stock_movements','customers','orders','order_items','print_jobs','print_job_materials',
    'costing_profiles','cost_breakdowns','expense_categories','expenses','invoices',
    'invoice_items','payments','shipments','custom_fields','custom_field_values'
  ] loop
    execute format(
      'create policy tenant_select on public.%I for select to authenticated using (company_id = (select private.current_company_id()))',
      t
    );
  end loop;
end $$;

create policy audit_logs_select_finance_admin
  on public.audit_logs for select to authenticated
  using (
    company_id = (select private.current_company_id())
    and (select private.current_user_role()) in ('ADMIN','ACCOUNTANT')
  );

-- Master data is maintained by Admin only.
do $$
declare
  t text;
begin
  foreach t in array array[
    'locations','printers','materials','costing_profiles','expense_categories','custom_fields'
  ] loop
    execute format(
      'create policy tenant_insert_admin on public.%I for insert to authenticated with check (company_id = (select private.current_company_id()) and (select private.current_user_role()) = ''ADMIN'')',
      t
    );
    execute format(
      'create policy tenant_update_admin on public.%I for update to authenticated using (company_id = (select private.current_company_id()) and (select private.current_user_role()) = ''ADMIN'') with check (company_id = (select private.current_company_id()) and (select private.current_user_role()) = ''ADMIN'')',
      t
    );
    execute format(
      'create policy tenant_delete_admin on public.%I for delete to authenticated using (company_id = (select private.current_company_id()) and (select private.current_user_role()) = ''ADMIN'')',
      t
    );
  end loop;
end $$;

-- Production/operations records are writable by Admin and Staff.
do $$
declare
  t text;
begin
  foreach t in array array[
    'printer_logs','maintenance_logs','material_batches','stock_movements',
    'customers','orders','order_items','print_jobs','print_job_materials',
    'cost_breakdowns','shipments','custom_field_values'
  ] loop
    execute format(
      'create policy tenant_insert_ops on public.%I for insert to authenticated with check (company_id = (select private.current_company_id()) and (select private.current_user_role()) in (''ADMIN'',''STAFF''))',
      t
    );
    execute format(
      'create policy tenant_update_ops on public.%I for update to authenticated using (company_id = (select private.current_company_id()) and (select private.current_user_role()) in (''ADMIN'',''STAFF'')) with check (company_id = (select private.current_company_id()) and (select private.current_user_role()) in (''ADMIN'',''STAFF''))',
      t
    );
    execute format(
      'create policy tenant_delete_admin on public.%I for delete to authenticated using (company_id = (select private.current_company_id()) and (select private.current_user_role()) = ''ADMIN'')',
      t
    );
  end loop;
end $$;

-- Finance records are writable by Admin and Accountant. Only Admin may delete.
do $$
declare
  t text;
begin
  foreach t in array array['expenses','invoices','invoice_items','payments'] loop
    execute format(
      'create policy tenant_insert_finance on public.%I for insert to authenticated with check (company_id = (select private.current_company_id()) and (select private.current_user_role()) in (''ADMIN'',''ACCOUNTANT''))',
      t
    );
    execute format(
      'create policy tenant_update_finance on public.%I for update to authenticated using (company_id = (select private.current_company_id()) and (select private.current_user_role()) in (''ADMIN'',''ACCOUNTANT'')) with check (company_id = (select private.current_company_id()) and (select private.current_user_role()) in (''ADMIN'',''ACCOUNTANT''))',
      t
    );
    execute format(
      'create policy tenant_delete_admin on public.%I for delete to authenticated using (company_id = (select private.current_company_id()) and (select private.current_user_role()) = ''ADMIN'')',
      t
    );
  end loop;
end $$;

-- Explicit Data API grants are required for newly created tables.
revoke all privileges on all tables in schema public from anon;
revoke all privileges on all tables in schema public from authenticated;
grant usage on schema public to authenticated;
grant select on all tables in schema public to authenticated;
grant update on public.companies to authenticated;

grant insert, update, delete on public.locations, public.printers, public.materials,
  public.costing_profiles, public.expense_categories, public.custom_fields to authenticated;

grant insert, update, delete on public.printer_logs, public.maintenance_logs,
  public.material_batches, public.stock_movements, public.customers, public.orders,
  public.order_items, public.print_jobs, public.print_job_materials, public.cost_breakdowns,
  public.shipments, public.custom_field_values to authenticated;

grant insert, update, delete on public.expenses, public.invoices, public.invoice_items,
  public.payments to authenticated;

grant usage on type public.printer_technology, public.printer_status,
  public.order_status, public.customer_type, public.billing_mode to authenticated;

-- API roles are intentionally not allowed to create companies or write profiles.
-- First ADMIN is created only by the trusted auth.users trigger above.
