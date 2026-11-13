# Print_Bud CRM — cloud setup checklist

This is the cloud-only setup path. Do not install Node.js, download the repository, or upload files locally.

## 1. Create the Supabase project

1. Sign in at https://supabase.com/dashboard.
2. Choose the organization that should own Print_Bud CRM, then select **New project**.
3. Project name: `print-bud-crm`.
4. Region: **South Asia (Mumbai)** — `ap-south-1`.
5. Choose the Free plan if that is the intended starting budget.
6. Set a strong database password and store it in your own password manager. Do not send it in chat or put it in GitHub.
7. Wait for the project to finish provisioning.

Supabase project URL and keys are available from the project's **Connect** dialog or **Settings → API Keys**.

## 2. Keep API keys safe

Use only the browser-safe **publishable key** (usually starts with `sb_publishable_`) in a Vite frontend. Set these Cloudflare Pages environment variable names:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`

Do not put a Supabase **secret key** (usually starts with `sb_secret_`) or the legacy `service_role` key in a `VITE_` variable, frontend source, or GitHub. A publishable key does not replace Row Level Security: every exposed table still needs correctly designed access policies.

## 3. Create the Cloudflare Pages site

1. Sign in at https://dash.cloudflare.com/.
2. Open **Workers & Pages → Create → Pages → Connect to Git**.
3. Select GitHub repository `parthbhaita/CRM_3d_PRINT`.
4. Production branch: `main`.
5. Framework preset: **Vite**.
6. Build command: `npm run build`.
7. Build output directory: `dist`.
8. Project name target: `printbud-crm`, producing `https://printbud-crm.pages.dev` if that Pages name is available.
9. Deploy.

## 4. Set Cloudflare environment variables

In the Pages project, open **Settings → Environment variables**. Add the two Supabase public values above for both Production and Preview if previews will use the same Supabase project. Save and trigger a new deployment.

## 5. Before live business data is entered

The current React app is still a prototype: its printers, materials, orders and customers are stored in browser localStorage. It is not yet reading from or writing to Supabase. Merely creating the cloud project or setting environment variables does not make records cloud-synchronized.

The existing `supabase/schema.sql` is an initial schema, not a production security sign-off. Review and harden role authorization, tenant isolation, cross-company foreign-key integrity, first-admin onboarding and audit controls before applying it to a production database. In particular, the current broad company-scoped profile write policy needs role-escalation protection.

After the Supabase project exists, finish that security review, then apply a versioned migration and implement the authenticated data layer before importing real customers, orders, GST, payment or production records.
