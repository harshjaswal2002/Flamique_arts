# Flamique Arts

A candle and handmade goods storefront with a separate admin studio, powered by Supabase Auth, PostgreSQL and Storage. The connected project is `ehxjggmrdlfgynuksiql` (`flamique_arts`).

The backend schema, protected order operations and public product-image bucket are deployed. The catalogue starts empty; sample products are available only in the read-only admin preview. COD checkout is enabled and uses live database settings. The merchant must add products before purchases are possible. No online payment provider is connected.

## Run

Use a current supported Node LTS version (22 or newer) and Python 3 for the static server.

```sh
npm ci
npm run build
npm test
npm run dev
```

Storefront: `http://localhost:3000/`. Admin: `http://localhost:3000/admin/`. The build bundles the pinned Supabase client into `public/shared/supabase.js`; no third-party SDK CDN is needed.

## Source

- `apps/storefront/`: storefront, accounts, cart and checkout.
- `apps/admin/`: products, collections, image uploads, orders and customers.
- `packages/shared/supabase.js`: Auth, database RPC and Storage client.
- `packages/shared/config.js`: public project URL/key and store presentation settings.
- `backend/supabase/`: schema, verified admin authorization and rollback-based integration verification.
- `backend/domain.js`: pure order helpers used by unit tests.

Orders use database transactions with server-owned prices, inventory row locks, unique checkout request keys, controlled fulfilment transitions and one-time cancellation stock restoration. Clients cannot directly write orders, payment totals or product stock. RLS protects customer records and unpublished catalogue entries. Admin access is checked in the database against a private owner-managed allowlist and a verified Auth email, or an explicitly assigned user ID.

See [setup](docs/SETUP.md) and [launch checklist](docs/LAUNCH.md). Firebase code and runtime configuration have been removed. Previously created Firebase resources were left in place; no customer/product data has been imported from Firebase.

The frontend changes are local until deployed through the existing website hosting workflow. Backend migrations do not publish the frontend.

Latest update: custom plum/cream studio storefront and matching admin, live database checkout settings, verified-email admin allowlist for the requested owner, and synchronized feature branches. The catalogue is intentionally empty until the merchant adds real products. Database integration checks pass; actual owner signup/email delivery and browser/device QA require verification.
