# server/

The API implementation lands here in Phase A0 (see `../docs/ROADMAP.md`).

It implements `../docs/API.md` against the schema in `../db/schema.sql`.

Left empty on purpose until the hosting/stack choice is made:
- **Supabase:** much of this is generated (auto REST + RLS); this folder holds edge
  functions for anything custom (booking/commission, Stripe webhooks, email).
- **Custom Node:** an Express/Fastify app with routes mirroring `../docs/API.md`.

Nothing here yet needs secrets. When it does, copy `.env.example` → `.env` (git-ignored).
