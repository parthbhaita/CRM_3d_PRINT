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

## Cloud deployment: Cloudflare Pages

This repository is prepared for a Cloudflare Pages deployment. No local installation or file upload is needed for deployment.

- GitHub repository: https://github.com/parthbhaita/CRM_3d_PRINT
- Production branch: `main`
- Build command: `npm run build`
- Build output directory: `dist`
- Framework preset: `Vite`
- Initial Pages address target: `https://printbud-crm.pages.dev`
- SPA fallback: `public/_redirects` is copied by Vite to the build output as `_redirects`.

In Cloudflare Pages, create a Pages project using **Connect to Git** and select this repository. Choose the settings above and deploy the `main` branch. Subsequent merges to `main` trigger production deployments automatically; pull requests can use preview deployments.

The `printbud-crm.pages.dev` hostname is a requested target, not a reserved or confirmed address. Cloudflare confirms availability when the Pages project is created. If it is unavailable, choose another `*.pages.dev` name.

## Supabase connection

The intended backend is Supabase (PostgreSQL, Auth and Storage). Once the Supabase project is created:

1. Apply the reviewed SQL foundation in `supabase/schema.sql` to a **new** Supabase project.
2. Add the frontend environment variables in Cloudflare Pages → Settings → Environment variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_PUBLISHABLE_KEY` (browser-safe publishable key)
3. Trigger a new deployment after saving the variables.

Never expose a Supabase secret key or legacy service-role key in frontend code, Vite variables, GitHub or Cloudflare client-side environment variables. Use the publishable key only with correctly configured Row Level Security. See [cloud setup checklist](docs/CLOUD_SETUP.md).

## Architecture target

- Frontend: React + Vite
- UI: custom responsive CSS + Lucide React
- Charts: Recharts
- Database / authentication / object storage: Supabase PostgreSQL, Auth and Storage
- Source control: GitHub
- Hosting: Cloudflare Pages (static frontend) + Supabase (managed backend)

GitHub stores application source and database migrations. Live customer, order, invoice and production data must remain in a protected database, not in Git.

## Database foundation

`supabase/schema.sql` contains the v0.1 relational schema and an initial company-scoped RLS policy foundation. Apply it only to a new Supabase project after review. The first-company / first-admin bootstrap and role-specific authorization still need a trusted server-side workflow.

## Important prototype and production limits

- Dashboard metrics and seed records are illustrative, not actual Print_Bud financial data.
- Prototype records are saved in the current browser; there is no live cloud persistence or multi-user synchronization yet.
- The current app is not yet connected to Supabase. Do not enter confidential customer, GST, payment or production data.
- Invoice PDF, GST calculation, payment gateway, courier integrations, printer telemetry and D2C connections are not implemented.
- The costing calculator is an estimate, and currently uses markup-on-cost pricing. Margin and fixed-profit modes are part of the planned costing engine.
- Validate GST applicability, HSN/SAC, place of supply and invoice treatments with your accountant before live billing.
- The database schema is a foundation, not a production security sign-off. Complete trusted onboarding, role-based authorization, policy tests, backup configuration and audit controls before storing real business data.

## Next implementation milestones

1. Create and connect the Cloudflare Pages and Supabase cloud projects.
2. Connect the app to Supabase and implement secure onboarding.
3. Complete role-aware access for Admin, Staff and Accountant.
4. Add location-aware printer, stock and production records.
5. Add stock movement ledger and consumption posting.
6. Add quotation, GST / Non-GST invoice PDFs and payment allocation.
7. Add audit logging, backups, tests and production security review.
