# Data model

Derived from the prototype's `DB` object and Build Spec v7 (groups A–C). Entities below
map 1:1 to tables in [`db/schema.sql`](../db/schema.sql).

## Core

### users
One row per account. `role` drives which extra fields matter.
- Common: `id`, `name`, `email` (unique), `password_hash`, `role` (`aspiring` | `accepted` | `expert`), `country`, `avatar_url`, `bio`, `title`, `links` (jsonb), `created_at`, `joined_at`.
- **Applicant** (`aspiring`): `target_level` (`Undergraduate` | `Graduate`), `grad_year`, `prior_degree`, `statement`, `public_profile`, `stage_override`.
- **Mentor** (`accepted`): `school`, `major`, `level`, `grad_year`, `verified`, `founding`.
- **Expert** (`expert`): `status` (`pending` | `active`), `category` (`teacher` | `advisor` | `admission` | `pro`), `company`, `education`, `years_experience`, `languages` (jsonb), `location`, `timezone`, `rate_at_signup`.

Tier/achievement badges (Founding, Gold Mentor, Top, Verified…) are **derived**, not stored
as flags — except `verified` and `founding`, which are grant events (see Roadmap B3).

### portfolios
An accepted portfolio owned by a mentor. `owner_id → users`.
`school`, `major`, `level`, `year_accepted`, `title`, `requirements`, `interpretation`,
`cover_url`, `created_at`.

### projects
Pieces inside a portfolio. `portfolio_id → portfolios`.
`title`, `description`, `files` (jsonb array of image URLs), `video` (jsonb), `position`.

## Marketplace

### provider_sessions
Session types a provider offers (mentor or expert). `provider_id → users`.
`minutes`, `price`, plus a flag for the free 15-min intro call (expert, B2).

### bookings
A booked 1:1. `provider_id → users`, `student_id → users`.
`provider_kind` (`mentor` | `expert`), `minutes`, `price`, `commission_rate`,
`commission`, `payout`, `status` (`confirmed` | `completed` | `cancelled` | `refunded`),
`date`, `time`, `video_link`, `created_at`.
Commission rule (A1): `0%` for a provider's first 12 months, then `rate_at_signup` (10%),
grandfathered.

### expert_applications
Submitted expert signups awaiting review (A2). `user_id → users`.
`category`, `title`, `work`, `specialties` (jsonb), `sessions` (jsonb), `availability`
(jsonb), `status` (`pending` | `waitlist` | `declined` | `approved`), `created_at`.

### reviews (backend-gated, A0+)
`booking_id → bookings`, `rating` (1–5), `text`, `created_at`. Feeds Top/rating badges.

## Applicant workspace

### my_work
Applicant's private work-in-progress (becomes the mentor portfolio on acceptance).
`user_id → users`, `title`, `img_url`, `position`, `created_at`.

### tracked_schools
"My Schools" list. `user_id → users`, `school`, `major`, `level`,
`student_deadlines` (jsonb — student-entered), `status` (jsonb), `notes`.

### saves
Saved reference portfolios. `user_id → users`, `portfolio_id → portfolios`. (unique pair)

## Social & growth

### follows
`follower_id → users`, `following_id → users`. (unique pair)

### referrals + points_ledger (A4)
`referrals`: `referrer_id`, `referred_id`, `code`, `qualified` (bool — set on a real
action, not signup), `created_at`.
`points_ledger`: append-only wallet — `user_id`, `delta`, `reason`, `booking_id?`,
`expires_at?`, `created_at`. Balance = sum of deltas.

## Requirements service (A3)

### schools
`id`, `name`, `slug`, `country`.

### programs
Which majors a school actually offers — backs track-aware validation (B1/B4).
`school_id → schools`, `major`, `degree_type` (`BFA` | `BA` | `MFA` | `MA` | …),
`track` (`ug` | `grad`), `source_url`, `status` (`active` | `paused` | `closing` | `none`),
`last_verified`. Seed from `Lukumo_Grad_Programs_DB.xlsx` (39 US schools).

### requirements
Per school (+ optional major). `school_id → schools`, `major?`, `body` (jsonb),
`source_url`, `last_verified`. Requirements only — **deadlines stay student-entered** in
`tracked_schools`.

## Relationships at a glance

```
users 1───n portfolios 1───n projects
users 1───n my_work
users 1───n tracked_schools
users n───n users            (follows)
users n───n portfolios       (saves)
users 1───n provider_sessions
users 1───n bookings         (as provider)  and  1───n bookings (as student)
users 1───1 expert_applications (latest)
schools 1───n programs
schools 1───n requirements
```
