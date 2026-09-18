# ExpenseFlow

A team expense reimbursement platform. Employees submit expenses, managers/admins review and approve or reject them, and admins mark approved expenses as reimbursed. Built with a Ruby on Rails (API-only) backend, PostgreSQL, and a React + TypeScript frontend.

## Tech Stack

- **Backend:** Ruby on Rails (API mode), PostgreSQL, JWT auth (`jwt` gem), authorization via `pundit`, pagination via `pagy`
- **Frontend:** React + TypeScript (Vite)
- **Infra:** Docker Compose (single command boots Postgres + Rails + React, runs migrations and seeds)

## Setup



```bash
git clone <repo-url>
cd expenseflow
docker compose up
```

## Demo Credentials

All seeded users share the password `password123`.

| Role | Email | Notes |
|---|---|---|
| Admin | `admin@expenseflow.com` | Admin One |
| Admin | `admin2@expenseflow.com` | Admin Two |
| Manager | `manager@expenseflow.com` | Manages the "Engineering" team |
| Employee | `employee@expenseflow.com` | Member of Engineering |
| Employee | `employee2@expenseflow.com` | Member of Engineering |

Seed data also includes 9 demo expenses spanning every status (draft, auto-approved, pending manager review, approved, rejected, reopened-after-rejection, fully reimbursed, a manager's own expense pending admin review, and an admin's own expense approved by the *other* admin) — all created through real `ExpenseTransitionService` calls rather than hardcoded statuses, so history and notifications are populated exactly as they would be in production.

## API Documentation

See [`docs/API.md`](docs/API.md) for the full endpoint reference.

## Database Schema

See [`docs/ERD.png`](docs/ERD.png) for the entity-relationship diagram.

## Approach & Key Design Decisions

- **Auth:** stateless JWT, 24h expiration. Logout is frontend-only (token discarded client-side) — a token remains technically valid until it expires even after "logout." No refresh-token flow.
- **Roles:** `employee` / `manager` / `admin`. Employees must belong to a team; managers may or may not manage a team; admins typically belong to none. `users.team_id` ("which team am I on") and `teams.manager_id` ("who manages this team") are independent and not kept in sync with each other.
- **Team/manager constraint is asymmetric:** a team must have a manager (validated), but a manager doesn't necessarily manage a team.
- **No nested team hierarchies**: a flat structure only; the spec doesn't call for sub-teams.
- **Visibility rules:** employees cannot see other users at all; managers can list their own team's members; admins see everyone. Teammates cannot see each other's data: an employee only ever sees their own expenses, regardless of team.
- **Invalid state transitions** (e.g. calling `approve` on a `draft` expense) raise a dedicated `InvalidTransitionError`, caught by a controller-level `rescue_from` and turned into a `422` with a descriptive message (e.g. `"Invalid transition: expense is approved, expected submitted"`) rather than a raw `500`.
- **Expense list date filters (`from`/`to`) filter on `spent_on`, not `created_at`.** The filter answers "which expenses were incurred in this period," which is what someone reviewing spending actually wants — when an expense was entered into the system is incidental.
- **Expense state machine:** `draft → submitted → approved → reimbursed`, with `submitted → rejected → draft` (reopen) as the other branch. Every transition is handled by a single service object (`ExpenseTransitionService`) wrapped in a DB transaction, writing exactly one `ExpenseHistory` row and one `Notification` per transition. Auto-approval (amount ≤ category's `auto_approve_limit`) reuses the same transition path with a `nil` actor, recorded as a "system" action.
- **Authorization split:** `403` means "you are never the right person for this action"; `422` means "you're the right person, but the expense isn't in the right state right now." Pundit policies check *who*; `ExpenseTransitionService` checks *state*, so the two never fight over which error code wins.
- **90-day submission window** is re-validated on every submission attempt, including resubmission after a rejection — not just an expense's very first submission. This is a deliberate reading of the spec ("cannot be more than 90 days before the expense is submitted") over an alternative "grandfathering" interpretation. See Known Limitations.
- **Reviewer assignment:** an employee's expense is reviewed by the manager of their team; a manager's or admin's expense is reviewed by any admin. Nobody reviews their own expense.
- **Admin report** is split by status via a required `status` query param (`approved` or `reimbursed`) rather than always returning both — grouped by category and month, using `approved_at`/`reimbursed_at` respectively (not `spent_on`, since an admin report cares when money moved, not when it was spent).
- **Pagination overflow** (requesting a page past the last one) returns `200` with an empty array, matching how large real-world paginated APIs behave, rather than raising an error.
- **Review queue** is filtered in application code (via the existing `ExpensePolicy#approve?`) rather than duplicated as a second SQL-level "who reviews whom" query, trading a small amount of query performance for a single source of truth on that rule.
- **Notifications** are surfaced via a bell icon in the header (not a dedicated page) with an unread-count badge and a dropdown of messages. The frontend polls `GET /notifications` every 30 seconds rather than using websockets/ActionCable — simple and sufficient for this app's scale, at the cost of up to a 30-second delay before a new notification appears. Clicking one marks it read (`POST /notifications/:id/mark_read`) and navigates to that expense's detail page.

## Known Limitations & Assumptions

- Logout does not invalidate the JWT server-side; a token is valid until its natural 24h expiry regardless of logout.
- `payment_reference` is a free-text string with no format or uniqueness validation — the spec doesn't specify a format, so none was enforced. Duplicate or malformed references are accepted.
- No minimum-admin-count enforcement; an admin cannot deactivate their own account, but a team of admins could otherwise deactivate each other.
- An expense rejected and left unfixed by its owner for more than 90 days past `spent_on` can no longer be resubmitted at all — a direct consequence of re-validating the 90-day window on every submission attempt (see Approach above).
- `sort`/`direction` params on the expense list silently fall back to `spent_on`/`desc` on an invalid value (order-only, so defaulting is harmless); an invalid `status` filter, by contrast, returns a `422` (it controls *which rows come back*, so a bad value shouldn't silently look like "no data").
- Single `ExpenseSerializer` is used for both list and detail views; in a larger system these would likely be split for payload-size/performance reasons.
- Notifications are near-real-time, not real-time — polling every 30s means a brand-new notification can take up to that long to appear. No push/websocket delivery was implemented.

## Testing

Manual end-to-end testing was performed via Postman (API-level: auth, all five state transitions, validation edge cases, authorization boundaries) and by clicking through the running frontend for each of the six required screens. 