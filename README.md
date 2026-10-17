# Flamique Arts

A responsive candle and handmade goods storefront with a separate, access-controlled admin studio and Firebase backend. Public storefront preview: Vercel project `flamique-arts` in `harshjaswal2002s-projects`.

**Current state:** public preview with sample catalogue and stock photography; checkout submissions disabled. Firebase source is provided but not deployed/configured. No online payment provider is connected. Admin preview is read-only with no customer/order fixtures. This is not yet a live transactional store.

## Run

Requires Node 22+ and Python 3 for the optional static server.

```
npm run build
npm test
npm run dev
```

Storefront: `/`. Admin: `/admin/`. The build is dependency-free and copies source to ignored `public/`. Firebase SDK modules load only when configuration is supplied.

## Source ownership

| Folder | Responsibility | Branch |
| --- | --- | --- |
| `apps/storefront/` | Home, collections, search, product detail, wishlist, bag, profile and checkout | `feature/storefront` |
| `apps/admin/` | Admin shell, product editor, collections, orders, customer records | `feature/admin-portal` |
| `packages/shared/` | Catalogue, Firebase client, configuration, money and cart helpers | `feature/shared-commerce` |
| `backend/` | Callable functions, transactions, rules, storage and admin setup | `feature/firebase-backend` |
| `docs/`, SEO metadata | Setup, business policies, branch map | `feature/seo-and-content` |
| `main` | Integrated release deployed to Vercel | `main` |

See [setup](docs/SETUP.md), [branch workflow](docs/BRANCHES.md), and [launch checklist](docs/LAUNCH.md).

## Features

- Responsive editorial storefront in ivory, terracotta and warm neutral colours.
- Animated collection tiles, product cards, cart drawer, account menus and reduced-motion support.
- Search, category and price sorting; product details; wishlist and bag persist in this browser.
- Cart quantity limits and explicit empty states. Sample checkout shows online/offline choices without accepting an order.
- Firebase email/password account creation, sign in, sign out, password reset, profile name updates, order history and cancellation once configured.
- Admin product/collection CRUD through editing and visibility controls; photo upload to Storage; stock alerts; order tracking, offline payment status, customer lookup and CSV export.
- Server-authoritative order pricing, atomic stock reservation, retry idempotency, forward-only fulfilment transitions and one-time stock restoration on eligible cancellations.
- Firebase admin custom-claim protection. No client-writable orders, stock or payment totals. App Check enabled by default in callable functions.

## Important limitations

Firebase and App Check must be configured before backend flows run. Full Firebase emulator/integration and browser/device tests remain required before accepting real orders. Six unit tests cover domain calculations and transition boundaries, not deployed security rules. Payment capture, courier API integration, transactional notifications, refunds, coupons, review moderation and customer data deletion workflows are not implemented. The avatar displays an existing profile photo if provided by Auth, otherwise an initial; custom profile photo upload and Google login are not enabled. Product image URLs are configurable, and admins can upload images after Storage setup. Customer addresses are kept on orders, not in a separate address book.

Sample photography: Unsplash. Replace all sample entries and photos with the maker's real catalogue before opening sales. Do not imply sample fragrance, material, weight or price is final. There are no invented reviews or sales counts.
