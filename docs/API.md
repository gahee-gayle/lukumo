# API surface (REST)

JSON over HTTPS. Auth via a session cookie or `Authorization: Bearer <token>`.
Money in cents. All list endpoints support `?limit=&offset=`.

Legend: 🔓 public · 🔒 authed · 👑 admin · ⏳ backend-gated (needs A1/A2 etc.)

## Auth
```
POST   /auth/signup            🔓  {name,email,password,role,country} → {user, token}
POST   /auth/login             🔓  {email,password} → {user, token}
POST   /auth/logout            🔒
GET    /auth/me                🔒  → {user}
```
OAuth (Google/Apple) added later as `/auth/oauth/:provider`.

## Users & profiles
```
GET    /users/:id              🔓  → public profile (shape depends on role)
PATCH  /users/me               🔒  edit own profile (role-appropriate fields)
POST   /users/me/avatar        🔒  multipart → {avatar_url}
GET    /users/:id/followers    🔓
GET    /users/:id/following    🔓
POST   /users/:id/follow       🔒
DELETE /users/:id/follow       🔒
```

## Portfolios & projects (mentor)
```
GET    /portfolios             🔓  filters: school, major, level, q, sort  (founding-first)
GET    /portfolios/:id         🔓
POST   /portfolios             🔒  (role=accepted)
PATCH  /portfolios/:id         🔒  (owner)
DELETE /portfolios/:id         🔒  (owner)
POST   /portfolios/:id/projects        🔒 (owner)   multipart images
PATCH  /projects/:id                   🔒 (owner)
DELETE /projects/:id                   🔒 (owner)
```

## Saved references & applicant work
```
GET    /me/saves               🔒
POST   /me/saves/:portfolioId  🔒
DELETE /me/saves/:portfolioId  🔒
GET    /me/work                🔒
POST   /me/work                🔒  multipart image → my_work row
DELETE /me/work/:id            🔒
```

## My Schools
```
GET    /me/tracked-schools     🔒
POST   /me/tracked-schools     🔒  {school,major,level}
PATCH  /me/tracked-schools/:id 🔒  deadlines/status/notes
DELETE /me/tracked-schools/:id 🔒
```

## Experts & applications
```
GET    /experts                🔓  filters: category, specialty, q
GET    /experts/:id            🔓  (active only, unless owner/admin)
POST   /expert-applications    🔒  submit expert signup (status=pending)
GET    /admin/applications     👑  review queue
POST   /admin/applications/:id/decision  👑  {action: approve|waitlist|decline}  ⏳(A2 email)
```

## Provider sessions & bookings
```
GET    /providers/:id/sessions 🔓  session types + prices (+ free intro)
GET    /providers/:id/availability  🔓  ⏳(A0 calendar)
POST   /bookings               🔒  {providerId, sessionId, date, time}  ⏳(A1 Stripe charge)
GET    /me/bookings            🔒  as student and as provider
PATCH  /bookings/:id           🔒  cancel / mark complete   ⏳(A1 payout/refund)
POST   /bookings/:id/review    🔒  {rating, body}           ⏳(A0)
```
`POST /bookings` computes commission server-side:
`rate = monthsSince(provider.joined_at) < 12 ? 0 : provider.rate_at_signup`.

## Requirements service (A3)
```
GET    /schools                          🔓
GET    /schools/:slug/programs?track=    🔓  drives track-aware major dropdowns (B1/B4)
GET    /schools/:slug/requirements?major= 🔓  requirements only (not deadlines)
```

## Referrals & wallet (A4)
```
GET    /me/referrals           🔒
GET    /me/points              🔒  balance + ledger
POST   /referrals/redeem       🔒  {code}   (qualifies on a later real action, not here)
```

## Notes
- **Row-level security:** on Supabase, most `/me/*` and owner-only writes are enforced by RLS
  policies keyed on `auth.uid()`; a custom server enforces the same checks in middleware.
- **Images:** uploads go to object storage; the DB stores URLs. The prototype's inline
  base64 images are migrated to files during cut-over.
- **Idempotency:** `POST /bookings` should accept an idempotency key once Stripe (A1) is live.
