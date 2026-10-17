# Supabase setup

Connected project: `ehxjggmrdlfgynuksiql`, region `ap-southeast-2`. The project URL and publishable key in `packages/shared/config.js` are public client configuration. Never place secret/service-role keys in frontend files.

## Backend

The hosted project has these applied migrations:

1. `supabase_commerce_backend`, corresponding to `backend/supabase/schema.sql`.
2. `verified_email_admin_access`, corresponding to `backend/supabase/admin-access.sql`.

For a new project, apply those scripts in order with the Supabase migration API or trusted SQL editor, then configure its public URL/key. The `private` schema must remain excluded from exposed Data API schemas. Public RPC wrappers call private, identity-checked functions. Security-definer functions use an empty search path and explicitly qualified relations. `private.admin_users` and `private.admin_emails` are intentionally inaccessible to clients.

Tables: `categories`, `products`, `users`, `orders`, `store_settings`. The `users` table is synchronized by an Auth trigger. All application tables have RLS. Public visitors see active catalogue records and shipping settings; account holders see their own profile and orders. Only studio administrators manage collections, products and orders. No product/order delete operation is exposed.

The public `product-images` bucket accepts JPEG, PNG and WebP up to 5 MiB. Only admins can upload, replace or remove files. Uploaded images are public product assets; never upload customer information there.

## Owner account

`kashity1997@gmail.com` is now authorized in the private database allowlist, as requested. The existing owner authorization is preserved. No Auth account for the requested email existed at verification. Create the account from the storefront, follow its email confirmation link, then sign in at `/admin/`. The account needs a Supabase password; a former Firebase password is not transferred. Never send passwords through chat.

To authorize a different owner, use the trusted SQL editor:

```sql
insert into private.admin_emails(email) values ('verified-owner@example.com') on conflict do nothing;
```

The database checks the actual Auth user's verified email, not browser-provided user metadata or email claims. Remove the row to revoke access. Explicit user-ID grants can also be stored in `private.admin_users`; revoke both paths if both were assigned.

## Authentication URLs and email delivery

In Supabase Authentication → URL Configuration, set the Site URL to the actual production storefront URL and allow the production origin plus `http://localhost:3000/` for development. Signup confirmation and password recovery need allowed redirect URLs. Keep email confirmation enabled. The frontend supports confirmation-required signup, recovery email, and a new-password form when a recovery link is opened.

Review email delivery/SMTP in the dashboard before launch. This migration does not change dashboard authentication delivery settings or create a password for the owner.

## Catalogue and checkout

Add collections first, then real products and images in `/admin/`. The empty connected catalogue does not fall back to sample entries.

Delivery is ₹50 below ₹200, free at ₹200 or more, for Chandigarh Tricity and nearby areas. Payment is COD. Confirm exact coverage and purchase policies before opening orders. COD checkout is enabled after the database integration suite passed. The storefront loads live rates and the order switch from `store_settings` on startup and again at checkout. To resume checkout after pausing, run this trusted SQL:

```sql
update public.store_settings set orders_enabled=true where id=true;
```

Shipping values in that row govern server totals and are loaded by the storefront; configuration values are fallback defaults. To pause purchases, set the database flag false first.

## Verification

`npm test` covers pure calculations and state transitions. Run `backend/supabase/verify.sql` with a trusted SQL connection or the Supabase SQL tool for actual RLS and database-function checks. It creates synthetic users/products/orders inside a transaction, tests ordinary/admin/anonymous access, prices, duplicate retries, stock limits and cancellation restoration, then rolls every change back. Do not split this script into separate requests.

The integration checks do not prove mail delivery or true simultaneous multi-connection checkout. Verify those plus browser sign-in, profile editing, password recovery, photo upload and order handling with test accounts before launch.

## Website hosting

The existing Vercel configuration still builds with `npm run build` and serves `public/`. Backend deployment is independent of frontend publishing. Publish the local migration through your normal Git/hosting workflow; no Vercel deployment or Git push is performed by the migration itself.
