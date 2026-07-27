-- Lukumo — PostgreSQL schema (A0 foundation)
-- Stack-neutral: runs on Supabase, RDS, Render/Railway Postgres, or local.
-- Money is stored in integer cents. Timestamps are UTC (timestamptz).

create extension if not exists "pgcrypto";  -- gen_random_uuid()

-- ─────────────────────────── enums ───────────────────────────
create type user_role      as enum ('aspiring','accepted','expert');
create type target_level    as enum ('Undergraduate','Graduate');
create type expert_category as enum ('teacher','advisor','admission','pro');
create type expert_status   as enum ('pending','active');
create type application_status as enum ('pending','waitlist','declined','approved');
create type provider_kind   as enum ('mentor','expert');
create type booking_status  as enum ('confirmed','completed','cancelled','refunded');
create type program_track   as enum ('ug','grad');
create type program_status  as enum ('active','paused','closing','none');

-- ─────────────────────────── users ───────────────────────────
create table users (
  id              uuid primary key default gen_random_uuid(),
  role            user_role   not null,
  name            text        not null,
  email           text        not null unique,
  password_hash   text,                      -- null when using an external auth provider
  country         text,
  avatar_url      text,
  title           text,
  bio             text,
  links           jsonb       not null default '{}',   -- {website, instagram, linkedin, behance}
  created_at      timestamptz not null default now(),
  joined_at       timestamptz not null default now(),  -- drives 12-month commission window

  -- applicant
  target_level    target_level,
  grad_year       int,
  prior_degree    text,
  statement       text,
  public_profile  boolean not null default false,
  stage_override  text,

  -- mentor (accepted)
  school          text,
  major           text,
  level           text,
  verified        boolean not null default false,
  founding        boolean not null default false,

  -- expert
  status          expert_status,
  category        expert_category,
  company         text,
  education       text,
  years_experience int,
  languages       jsonb,
  location        text,
  timezone        text,
  rate_at_signup  numeric(4,3) not null default 0.10   -- grandfathered commission after 12 mo
);
create index on users (role);
create index on users (email);

-- ────────────────────── portfolios / projects ─────────────────
create table portfolios (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references users(id) on delete cascade,
  school        text not null,
  major         text not null,
  level         text,
  year_accepted int,
  title         text,
  requirements  text,
  interpretation text,
  cover_url     text,
  created_at    timestamptz not null default now()
);
create index on portfolios (owner_id);
create index on portfolios (school, major);

create table projects (
  id           uuid primary key default gen_random_uuid(),
  portfolio_id uuid not null references portfolios(id) on delete cascade,
  title        text,
  description  text,
  files        jsonb not null default '[]',   -- [url, ...]
  video        jsonb,                          -- {kind, url, thumb, watch}
  position     int  not null default 0
);
create index on projects (portfolio_id);

-- ──────────────────────── marketplace ─────────────────────────
create table provider_sessions (
  id          uuid primary key default gen_random_uuid(),
  provider_id uuid not null references users(id) on delete cascade,
  minutes     int  not null,
  price_cents int  not null,
  is_intro    boolean not null default false   -- free 15-min intro (expert, B2)
);
create index on provider_sessions (provider_id);

create table bookings (
  id              uuid primary key default gen_random_uuid(),
  provider_id     uuid not null references users(id) on delete restrict,
  provider_kind   provider_kind not null,
  student_id      uuid not null references users(id) on delete cascade,
  minutes         int  not null,
  price_cents     int  not null,
  commission_rate numeric(4,3) not null,
  commission_cents int not null,
  payout_cents    int  not null,
  status          booking_status not null default 'confirmed',
  session_date    date not null,
  session_time    text not null,
  video_link      text,
  created_at      timestamptz not null default now()
);
create index on bookings (provider_id);
create index on bookings (student_id);

create table expert_applications (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references users(id) on delete cascade,
  category     expert_category,
  title        text,
  work         text,
  specialties  jsonb not null default '[]',
  sessions     jsonb not null default '[]',
  availability jsonb not null default '[]',
  status       application_status not null default 'pending',
  created_at   timestamptz not null default now()
);
create index on expert_applications (status);

create table reviews (   -- backend-gated (A0+); feeds Top/rating badges
  id         uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  rating     int  not null check (rating between 1 and 5),
  body       text,
  created_at timestamptz not null default now()
);

-- ─────────────────── applicant workspace ──────────────────────
create table my_work (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  title      text,
  img_url    text not null,
  position   int  not null default 0,
  created_at timestamptz not null default now()
);
create index on my_work (user_id);

create table tracked_schools (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references users(id) on delete cascade,
  school            text not null,
  major             text,
  level             text,
  student_deadlines jsonb not null default '{}',   -- student-entered
  status            jsonb not null default '{}',
  notes             text
);
create index on tracked_schools (user_id);

create table saves (
  user_id      uuid not null references users(id) on delete cascade,
  portfolio_id uuid not null references portfolios(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (user_id, portfolio_id)
);

-- ──────────────────────── social / growth ─────────────────────
create table follows (
  follower_id  uuid not null references users(id) on delete cascade,
  following_id uuid not null references users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table referrals (
  id          uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references users(id) on delete cascade,
  referred_id uuid references users(id) on delete set null,
  code        text not null,
  qualified   boolean not null default false,   -- true only on a real action, not signup
  created_at  timestamptz not null default now()
);
create index on referrals (referrer_id);
create index on referrals (code);

create table points_ledger (   -- append-only wallet; balance = sum(delta)
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  delta      int  not null,
  reason     text not null,
  booking_id uuid references bookings(id) on delete set null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create index on points_ledger (user_id);

-- ─────────────────── requirements service (A3) ────────────────
create table schools (
  id      uuid primary key default gen_random_uuid(),
  name    text not null unique,
  slug    text not null unique,
  country text
);

create table programs (   -- which majors a school actually offers (track-aware, B1/B4)
  id            uuid primary key default gen_random_uuid(),
  school_id     uuid not null references schools(id) on delete cascade,
  major         text not null,
  degree_type   text,                 -- BFA / BA / MFA / MA / ...
  track         program_track not null,
  source_url    text,
  status        program_status not null default 'active',
  last_verified date,
  unique (school_id, major, track)
);
create index on programs (school_id, track);

create table requirements (
  id            uuid primary key default gen_random_uuid(),
  school_id     uuid not null references schools(id) on delete cascade,
  major         text,                 -- null = school-wide
  body          jsonb not null,
  source_url    text,
  last_verified date
);
create index on requirements (school_id);
