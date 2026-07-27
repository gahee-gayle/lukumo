# Architecture

## Today (prototype)

```
Browser ──► web/index.html ──► localStorage "Lukumo.v4"
                (all logic + all data live in one file, per-browser)
```

One HTML file holds the UI, the business logic, and a `DB` object that is loaded from
and saved to `localStorage`. There is no server and no shared data: two people using the
app never see each other's accounts, portfolios, or bookings.

## Target (after A0)

```
Browser ──► web app ──►  HTTPS/JSON  ──► API ──► PostgreSQL
                                          │
                                          ├─ Auth (accounts, sessions)
                                          ├─ File storage (portfolio images, avatars)
                                          └─ (later) Stripe, email, requirements service
```

The front-end keeps almost all of its current UI. The one structural change is that the
`DB` layer — every place the code today reads/writes `localStorage` — is swapped for
`fetch()` calls to the API. Concretely, the prototype centralizes storage in a handful of
functions (`load()`, `save()`, `me()`, and the `DB.*` mutations); those become the seam we
replace with an API client. The rendering, routing, and views stay.

## Migration plan (incremental, keeps the app working)

1. **Stand up the database** from `db/schema.sql`.
2. **Stand up the API** implementing `docs/API.md` (auth first, then reads, then writes).
3. **Introduce a data-access module** in the front-end (`api.js`) with the same shape the
   code already expects, so views change as little as possible.
4. **Cut over feature by feature** — auth → profiles/portfolios → tracked schools →
   bookings — keeping `localStorage` as a fallback until each endpoint is live.
5. **Move images** from inline base64 (today) to object storage; store URLs in the DB.

## Hosting options (decide before the build phase)

| Option | What you run | Auth | Storage | Best when |
|---|---|---|---|---|
| **Supabase** (recommended) | Managed Postgres + auto REST/realtime | Built-in | Built-in | Fastest path; small team; keep the static front-end |
| **Firebase** | Managed (Firestore/Auth/Storage) | Built-in | Built-in | Comfortable with Google stack; note: not SQL |
| **Custom Node** | Express/Fastify + Postgres on Render/Railway | You build (JWT/session) | S3/R2 | Maximum control; willing to maintain a server |

This repo's schema + API are written to fit **any** of the three. Supabase can even
generate most of the API from `schema.sql` directly, which is why it's the recommended
first target once accounts are set up.

## What still needs real accounts / money (cannot be built without them)

- **Payments (A1):** a Stripe account (Stripe Connect for provider payouts).
- **Email (A2):** an email service (Resend/Postmark/SendGrid) + `SPF/DKIM/DMARC` DNS on `lukumo.com`.
- **Domain & hosting:** the `lukumo.com` domain and a host to run the API + serve the app.

These are noted in `docs/ROADMAP.md` as external prerequisites.
