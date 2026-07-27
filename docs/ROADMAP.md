# Roadmap — Build Spec v7 → this repo

Maps the spec's groups to concrete work. Front-end (B) is largely done in `web/index.html`;
this repo drives the backend (A) and the SEO track (C).

## Phase 0 — Design & repo  ✅ (this commit)
Repo, data model, SQL schema, API surface, hosting options. No accounts needed.

## Phase A0 — Backend & real accounts  ← next
The foundation. Everything else in A depends on it.
- [ ] Provision Postgres from `db/schema.sql`.
- [ ] Auth: email+password (bcrypt) + sessions/JWT; OAuth later.
- [ ] Implement API reads then writes (`docs/API.md`), auth first.
- [ ] Object storage for images (avatars, portfolio pieces, my_work).
- [ ] Front-end `api.js` data layer; cut over feature by feature from `localStorage`.
- **External prerequisite:** a host (Supabase project, or Node host + managed Postgres) and,
  eventually, the `lukumo.com` domain.

## Phase A1 — Payments & commission
- [ ] Stripe Connect: charge student at booking, pay provider on completion, retain commission.
- [ ] Commission: 0% first 12 months, then 10% grandfathered (logic already in `POST /bookings`).
- [ ] Refunds / cancellations; generate video link.
- [x] 2-hour (120-min) session option — already in the prototype.
- **External prerequisite:** a Stripe account (business verification for Connect payouts).

## Phase A2 — Admin review & email
- [ ] Admin queue for expert/mentor applications (approve / waitlist / decline).
- [ ] On approve: flip `expert.status → active`, provision the public profile.
- [ ] Transactional email (approval/waitlist/decline, booking confirmations, reminders).
- **External prerequisite:** an email service + `SPF/DKIM/DMARC` DNS on `lukumo.com`.

## Phase A3 — Requirements service
- [ ] Load `schools`, `programs`, `requirements` (seed: 15-school reqs + `Lukumo_Grad_Programs_DB.xlsx`).
- [ ] Read APIs; wire the front-end major dropdowns to `programs` (kills invalid picks like
      "RISD MFA Illustration").
- [ ] AI-drafts → human-verifies update pipeline + small admin editor.

## Phase A4 — Referral points & wallet
- [ ] `referrals` qualify on a real action (verify+upload, or complete a session) — not signup.
- [ ] `points_ledger` wallet; capped partial discount at checkout; provider always paid full.
- [ ] Referral tier badges: Connector (3) / Super Connector (10) / Ambassador (25).

## Track C — Programmatic SEO (parallel)
- [ ] Pre-rendered `/schools/{school}/{major}` pages (SSG/SSR) from the requirements DB.
- [ ] `sitemap.xml`, `robots.txt`, Search Console + Bing.
- Needs an SSG/SSR front-end; plan alongside A3.

## Front-end status (for reference)
- [x] B1 Admission Advisors category + "Other" free-text (grad-major list wiring → A3)
- [x] B2 expert pending state + distinct expert profile
- [x] B3 badge system (Verified/School/New, Gold Mentor, Founding, applicant progress emblems)
- [x] B4 applicant profile UG/Grad split
- Card-badge refinements & remaining B2 static fields continue in `web/index.html`.
