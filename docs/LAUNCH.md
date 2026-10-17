# Before the first real order

- Create and verify the authorized owner's Supabase account and confirm access to `/admin/`.
- Set production/local Auth redirect URLs and verify confirmation/recovery email delivery.
- Add real collections, products, prices, stock and photos. Confirm specifications and care instructions.
- Finalize nearby delivery coverage, dispatch times, returns, cancellation and damage-reporting policies.
- Confirm COD collection and remittance. Online payments are not integrated.
- Run unit tests and database verification. Test two concurrent purchases of the last unit, a retried checkout, cancellation, admin fulfilment, profile editing and image uploads with real test sessions.
- Deploy the migrated frontend and verify it talks to the intended Supabase project.
- Enable checkout in both the frontend config and `public.store_settings` only after checks pass.
- Configure monitoring, backups and a customer-data deletion process appropriate to the chosen plan.

The Supabase backend and storefront are deployed. COD checkout is enabled following transaction-based database verification. Add the real catalogue; complete owner signup, email delivery and browser/device testing.
