# Current configuration

Firebase public web config is supplied for `flamiquearts`. Business contact is flamiquearts@gmail.com; WhatsApp +91 78378 89616; Instagram @flamique_arts. Delivery is Chandigarh Tricity and nearby areas, ₹50 below ₹200 and free at ₹200 or more. Payment is cash on delivery. Damaged items are eligible for return, refund or replacement after review. Exact nearby PIN-code coverage, dispatch times and damage-reporting procedure remain to be confirmed.

The merchant will manage products and categories. The connected storefront loads Firestore catalogue entries and does not fall back to sample products when Firestore is empty/unavailable. Firebase admin access and backend deployment still require authenticated project access. Public configuration alone cannot grant privileges. Orders remain disabled.

Use the existing owner's Firebase Auth account and `node backend/functions/set-admin-by-email.mjs <owner-email>` in a trusted environment with Application Default Credentials to assign the admin claim. Do not put admin email/password allowlists in the frontend. The account must already exist.

# Firebase and Vercel setup

## Information needed from the owner

- Firebase public web app configuration object from **Project settings → General → Your apps → Web** for `flamiquearts` (apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId).
- The account email that should administer the store. Create that account, then use its Firebase Auth UID for claim assignment.
- Firebase App Check reCAPTCHA v3 public site key. Configure allowed production and local domains.
- Real logo, product photos, titles, descriptions, category, price, stock, weights/dimensions, ingredients/materials, fragrance and care instructions.
- Business contact email, WhatsApp/Instagram links, service regions, dispatch and delivery times, shipping charges, free shipping threshold, returns/cancellation policy and legal business identity.
- Meaning of offline payment: COD, bank transfer or another arrangement. The implementation currently labels it generically and records orders unpaid; only an admin can confirm receipt.

Do not send Firebase service-account keys or Vercel access tokens through chat.

## Connect Firebase

1. Create a Web app inside the existing `flamiquearts` project. Paste its **public** config into `packages/shared/config.js` as `firebaseConfig`. Supply `appCheckSiteKey` there as well.
2. Enable Authentication → Email/password. Add the production Vercel domain and your eventual custom domain as authorised domains.
3. Create Firestore and Storage in the desired region. Functions use `asia-south1`. Confirm billing requirements and quotas before enabling services.
4. Register the Web app in Firebase App Check with reCAPTCHA v3. Functions enforce App Check by default. Use Firebase's documented debug token flow locally; do not disable enforcement in production.
5. In a trusted local terminal with Firebase CLI and Node 22 installed:

```
cd backend/functions
npm install
cd ..
firebase login
firebase use flamiquearts
firebase emulators:start
```

Deploy when rules and function tests pass:

```
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

6. Callable function parameters default to `ORDERS_ENABLED=false`, `ENFORCE_APP_CHECK=true`, `SHIPPING_FEE_INR=50`, `FREE_SHIPPING_THRESHOLD_INR=200`. Review these with the business; these delivery amounts match the supplied business policy. Firebase prompts for parameters during deployment. Configure matching storefront values. Keep both order flags false until launch readiness is verified.
7. Create the owner's account in Firebase Auth. In a trusted environment authenticated with Application Default Credentials scoped to this Firebase project, run `node backend/functions/set-admin.mjs <verified-auth-uid>`. The owner signs out and in again. The script preserves existing custom claims. Never add a client-side admin password or email allowlist as security.
8. Sign into `/admin/` and add categories first, then actual products. A product editor also offers inline category creation, retaining the draft fields (reselect an unsaved upload if needed). Admin can upload JPEG, PNG or WebP below 5 MB to Storage.

All product and category documents are public catalogue data, including unpublished entries. Do not put supplier prices, personal information or confidential notes there. Orders and users are access-controlled.

## Deploy Vercel

Project: `flamique-arts`, team: `harshjaswal2002s-projects`, Git repository: `harshjaswal2002/Flamique_arts`, production branch: `main`. Build command `npm run build`; output directory `public`; root repository directory. Vercel is public by request. Firebase configuration is currently source-level public Web config; no secret belongs there. Frontend deployment does not deploy Firebase rules/functions.

## Verification before orders open

Use Firebase emulators and a staging Firebase project to check:

- Anonymous and ordinary user attempts cannot read other customers or change products, stock or orders.
- Valid admin claims permit category writes and product/order callables; revoked claims stop working after refresh.
- App Check rejects missing/invalid tokens and accepts the production app.
- Two simultaneous purchases of the last unit yield one order, with no oversell.
- Retrying a checkout with the same request ID does not duplicate orders or deduct stock twice.
- Cancellation restores stock once; shipped/delivered/paid orders cannot be cancelled through the normal flow.
- Online payment is unavailable and no browser-supplied price is trusted.
- Real accounts can see only their own order history, reset a password, update their name and sign out.
- Mobile and desktop browser checks cover keyboard focus, dropdowns, bag quantity limits, empty states, delivery form, errors and image loading.

Automated unit tests do not replace these integration checks.
