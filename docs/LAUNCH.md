# Before the first real order

- Replace sample catalogue data and stock images with actual products; confirm accurate specifications and safety instructions.
- Contact details, Tricity delivery, ₹50 shipping below ₹200 and damaged-item returns/refunds/replacements are published. Finalise exact nearby coverage, lead times, cancellation terms and the damage-reporting process.
- Cash on delivery is selected. Confirm collection and remittance procedures. Online payments require a separate provider integration with server verification and webhook reconciliation; never trust a browser success redirect.
- Configure Firebase, authentication domains, App Check, admin claims, Firestore rules and Storage rules; deploy functions.
- Complete emulator security and concurrency checks plus browser/device testing.
- Update the preview announcement, sample notes, FAQ answers, policies, shipping labels and footer in `apps/storefront/` once the store is genuinely ready. These deliberately describe the current preview.
- Set a permanent domain, canonical tags, sitemap, social sharing image and verified organisation/contact information after the final domain is known. Current page has semantic content, title/description, OG metadata and robots rules; admin is noindex. Product-specific indexable pages and Product JSON-LD should be added when the real catalogue and canonical domain exist.
- Add customer support, incident monitoring and a privacy/data-deletion process. Set up backups and billing alerts in Firebase.
- Then enable both storefront `ordersEnabled` and server `ORDERS_ENABLED` with matching shipping amounts.

Do not open real checkout merely because the public preview is deployed. The Firebase backend in this repository is prepared source and has not been deployed from this session.
