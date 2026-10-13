# Locker Platform

Multi-tenant smart-locker platform: companies (e.g. Amazon, DPD) share one
application, employees work with their team's lockers, eLocker support
engineers can see and operate any locker. See [TASK.md](TASK.md) for the
original assignment.

## How to run

With Docker (no local Ruby needed):

```sh
docker compose up
```

First run installs gems, creates and seeds the database, then serves the app
on <http://localhost:3000>. Use the dropdown in the header to switch between
users (employees of different teams and companies, and a support engineer).

Run the tests:

```sh
docker compose run --rm web bin/rails test
```

Reset the demo data:

```sh
docker compose run --rm web bin/rails db:reset
```

Without Docker: Ruby 3.4, then `bundle install && bin/rails db:prepare && bin/rails server`.

## Data model

```
Company 1──* Team 1──* User   (role: employee)
               │
               1──* Locker    (state: closed | open, via AASM)
                      1──* LockerEvent (user, action, created_at)

User (role: support) — belongs to no team, sees the whole platform
```

- **Tenancy lives in one place.** `Locker.accessible_by(user)` returns
  everything for support and `where(team_id: user.team_id)` for employees.
  Every controller read goes through that scope — including the open/close
  POSTs — so a locker outside the user's reach is a plain 404, and the action
  log reuses the same scope via a join. There is no separate authorization
  layer to keep in sync with the queries: the queries are the authorization.
- **A locker belongs to exactly one team.** The brief says each team works
  with "its own set of the company's lockers", which I read as disjoint sets;
  `belongs_to :team` is the simplest model that satisfies it, and the company
  is derived through the team (no denormalized `company_id` to drift).
- **State is a real state machine** (AASM: `closed <-> open`). Two states
  hardly need a gem, but it buys validated transitions for free: opening an
  open locker is an `InvalidTransition`, not a silent no-op, and the UI only
  renders the action that is currently possible (`may_open?`).
- **Every transition is audited atomically.** Events take the acting user —
  `locker.open!(current_user)` — and write a `LockerEvent` in the same
  transaction as the state change, so the log can't disagree with the state.
  The "action log" screen is just this table, scoped to the current user.
- **Concurrent clicks can't double-log.** Lockers use optimistic locking
  (`lock_version`): when two requests race to open the same locker, one wins
  and the other gets a "just operated by someone else" message instead of a
  second bogus audit row. (Chosen over `SELECT ... FOR UPDATE`, which SQLite
  doesn't support.)
- **Roles are an enum on User** (`employee` / `support`), not separate models:
  two roles with one behavioral difference don't justify STI.
- Authentication is mocked per the brief: the acting user sits in the
  session, switched from the header dropdown. Access rules are real.

## Assumptions and questions for the business

- **Lockers don't move between teams and aren't shared.** If teams within a
  company can share lockers, the `belongs_to` becomes a join table and the
  scope changes one line — the question is whether the business needs it.
- **A team's employees all have equal rights** on the team's lockers; there
  are no per-user locker assignments and no company-level managers who see
  all teams. Who, if anyone, sits between "one team" and "all companies"?
- **Opening an already-open locker is a user mistake,** shown as a friendly
  message. Should the hardware treat a repeated "open" command as a retry
  instead, and should failed attempts be logged too?
- **The log never forgets.** Events keep a foreign key to users, so users
  with history can't be deleted — fine for this scope, but real user
  offboarding would need soft deletion or detaching events.
- What does a locker's state mean when the hardware is offline — is the app
  state a command queue or a mirror of reality? That decides whether we need
  `opening`/`closing` intermediate states and a reconciliation job.

## What I'd do next with more time

- Pagination and filters (by locker, user, date) on the action log.
- Turbo Streams on the locker list so open/close updates the row in place
  (right now it's a full-page redirect, which Turbo Drive already makes fast).
- A `Current.user` CurrentAttributes setup once more code needs the acting user.
- System tests (Capybara) on top of the integration tests.
- Proper authentication and admin screens for companies/teams/users.

## How I used AI tools

Built with Claude Code. The architecture decisions above (single
`accessible_by` scope as the tenancy boundary, locker-per-team model, AASM
with audited transitions, no authorization gem) came out of a design
discussion before any code was written; the tool then generated the app,
implementation and tests to that design, and every screen and access rule
was verified against a running container. Each step was committed separately
to keep the history reviewable.
