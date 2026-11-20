# Rasael Orders

The order book behind **Rasael** (رسائل), a small studio that sells personalised
Arabic gift pages: love letters, birthday pages, wedding invitations. Orders
arrive as WhatsApp messages from a web form; this app takes each one from that
message to a delivered link, and shows how the business is doing.

Built in Flutter for Android and the web, Arabic-first (RTL), on Supabase.

> **Status:** day 1 of a two-week build. Foundation, schema, auth and a live
> home screen are in; the full pipeline, paste-to-order parsing, saved replies
> and the dashboard follow.

## What's here so far

- **Home screen on live data.** One hero block for what needs attention now
  (late, due today, unpaid previews older than 48h), then every open order as
  a ledger line. Moving an order forward updates every open device in real time.
- **Pipeline that matches the real process.** New → in progress → preview
  sent (awaiting payment) → paid → delivered. Customers pay after seeing the
  preview, so payment comes after the preview, not before.
- **Supabase schema with row-level security.** Every row belongs to its owner;
  stage timestamps and the stage history are written by Postgres triggers, not
  by the client, so two devices can't disagree. See
  [`supabase/migrations`](supabase/migrations).
- **Demo mode with no backend.** Without keys the app runs on fictional orders
  (every name and number invented). That is the public web build.

## Design

Written down before the first screen: [`docs/DESIGN.md`](docs/DESIGN.md).
In short: an order book, not a CRM. Paper and ink with one wine accent;
colour only for attention; IBM Plex Sans Arabic for text and figures; no
letter-spacing on Arabic; codes and phone numbers kept as LTR islands; spring
press feedback instead of ripples; everything respects "reduce motion".

## Architecture

```
lib/
  core/        theme tokens, motion primitives, DI, routing, formatting
  features/
    auth/      AuthRepository (Supabase) + demo session, AuthCubit
    orders/    Order domain, OrderRepository (Supabase | in-memory demo),
               OrdersCubit, screens and widgets
supabase/      SQL migrations
docs/          design direction
```

- **flutter_bloc** for state, **go_router** with an auth redirect, **get_it**
  for wiring. Only `core/di/injector.dart` knows Supabase exists.
- The demo repository applies stage changes with `Order.movedTo`, which
  mirrors the database trigger, and a test pins the two together.

## Running

Demo only (no backend):

```bash
flutter run
```

With Supabase:

1. Create a project at supabase.com.
2. In the SQL editor, run `supabase/migrations/20261120000000_init.sql`, then
   `supabase/check_connection.sql`; every row should say `ok`.
3. Authentication → Users → add your user (email + password).
4. Copy `env/example.json` to `env/dev.json` and fill in the project URL and
   publishable key (Project Settings → API). `env/dev.json` is git-ignored.
5. `flutter run --dart-define-from-file=env/dev.json`

## Tests

```bash
flutter test
```

Covers the attention rules, the stage order, the trigger/demo parity, the
database row mapping, the demo repository and the no-backend app flow.

## Licence

Code: MIT. Fonts: IBM Plex Sans Arabic and El Messiri, SIL Open Font License
(see `assets/fonts`).
