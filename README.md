# Print_Bud CRM

A modular CRM / ERP foundation for a multi-location 3D-printing business.

## Product configuration

- Technologies: FDM and Resin
- Locations: multiple workshops / branches
- Roles: Admin, Staff and Accountant (database role model foundation)
- Billing modes: GST and Non-GST
- Currency: INR
- UI: responsive modern SaaS dashboard

## Current V0.1 prototype

- Dashboard with illustrative revenue, profit, order and printer KPIs
- Printer register with add / edit / delete
- Material register with add / edit / delete and low-stock alerts
- Customer directory with add / edit
- Order creation and order listing
- Costing calculator: material, electricity, machine time, painting, labour, packaging, shipping and other costs
- Markup-based price estimate with gross-margin display
- GST / Non-GST billing workspace placeholder
- Reports and company-default settings screens
- Browser localStorage persistence for prototype records

## Run locally

Requirements: Node.js 18 or newer.

```bash
npm install
npm run dev
```

Open the local URL printed by Vite (usually http://localhost:5173).

```bash
npm run build
npm run preview
```

## Environment setup

Copy `.env.example` to `.env.local` when Supabase integration is implemented. Never place a service-role key in frontend environment variables.

## Architecture target

- Frontend: React + Vite
- UI: custom responsive CSS + Lucide React
- Charts: Recharts
- Database / authentication / object storage: Supabase PostgreSQL, Auth and Storage
- Source control: GitHub
- Hosting: static frontend hosting plus Supabase / managed backend

GitHub stores application source and database migrations. Live customer, order, invoice and production data must remain in a protected database, not in Git.

## Database foundation

`supabase/schema.sql` contains the v0.1 relational schema and an initial company-scoped RLS policy foundation. Apply it only to a new Supabase project after review. The first-company / first-admin bootstrap and role-specific authorization still need a trusted server-side workflow.

## Important prototype limits

- Dashboard metrics and seed records are illustrative, not actual Print_Bud financial data.
- Prototype records are saved in the current browser; there is no live cloud persistence or multi-user synchronization yet.
- Invoice PDF, GST calculation, payment gateway, courier integrations, printer telemetry and D2C connections are not implemented.
- The costing calculator is an estimate, and currently uses markup-on-cost pricing. Margin and fixed-profit modes are part of the planned costing engine.
- Do not enter confidential customer, GST, payment or production data into this prototype.
- Validate GST applicability, HSN/SAC, place of supply and invoice treatments with your accountant before live billing.

## Next implementation milestones

1. Supabase project connection and secure onboarding.
2. Role-aware access for Admin, Staff and Accountant.
3. Location-aware printer, stock and production records.
4. Stock movement ledger and consumption posting.
5. Printer run logs, maintenance and failed-print / reprint handling.
6. Quotation, GST / Non-GST invoice PDFs and payment allocation.
7. Audit logging, backups, tests and production deployment.
