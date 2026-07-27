# Lukumo

Real accepted art & design portfolios — organized by school and major — plus a 1:1
session marketplace connecting applicants with the mentors (accepted students) and
experts (working pros, teachers, advisors) who can help them get in.

## Repository layout

```
web/            The current front-end app (single-file prototype, index.html)
docs/           Backend design — architecture, data model, API, roadmap
db/             Database schema (PostgreSQL DDL) + seed notes
server/         API server (to be built — see docs/ARCHITECTURE.md)
```

## Where things stand

The product currently lives as a **client-side prototype** in `web/index.html`:
all state (users, portfolios, bookings, tracked schools…) is held in the browser's
`localStorage` under the key `Lukumo.v4`. Everything a user does is real in the UI but
private to their browser — there are no accounts and no shared data.

**This repo starts the backend.** The goal of the first phase (A0) is to move that
state into a real database behind an API with real accounts, without throwing away the
front-end. See `docs/ROADMAP.md` for how the backend spec (A0 → A4) maps to work here.

## Backend design (start here)

1. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — the big picture and migration plan
2. [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) — entities and how they relate
3. [`db/schema.sql`](db/schema.sql) — PostgreSQL schema you can run as-is
4. [`docs/API.md`](docs/API.md) — the REST surface the front-end will call
5. [`docs/ROADMAP.md`](docs/ROADMAP.md) — phased plan (A0–A4) and what's front-end vs backend

## Design is stack-neutral

The schema is plain PostgreSQL and the API is plain REST, so this design drops onto
**either** a managed backend (Supabase / Firebase) **or** a custom server
(Node + Postgres on Render/Railway). The hosting choice is deliberately left open — see
`docs/ARCHITECTURE.md` for the trade-offs.
