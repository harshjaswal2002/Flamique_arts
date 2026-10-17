# Where to make a change

`main` is the integrated, deployable release. Each named feature branch starts from that release so it works on its own. Branches are work streams, not separate copies to deploy independently forever. Code folders define the permanent separation.

1. Switch to the branch matching the change.
2. Merge current `main` into it before starting new work.
3. Change the relevant folder and any necessary shared interfaces.
4. Run `npm run build` and `npm test`.
5. Open a pull request into `main`; review the preview and merge.
6. Vercel builds `main` for production; feature branches may receive previews.

| Problem | Start here |
| --- | --- |
| Navbar, animations, mobile layout, cart, profile | `feature/storefront`, `apps/storefront/` |
| Product editor, order screens, admin mobile layout | `feature/admin-portal`, `apps/admin/` |
| Inventory, order calculations, permissions | `feature/firebase-backend`, `backend/` |
| Shared config, currencies, Supabase client | `feature/shared-commerce`, `packages/shared/` |
| Metadata, descriptions, policies, setup | `feature/seo-and-content`, `docs/` and storefront HTML |

Never deploy just the backend branch as the website root. Supabase database migrations deploy separately from `backend/supabase/`; Vercel serves the integrated frontend build from the repository root. Do not store passwords or service-account JSON in any branch.
