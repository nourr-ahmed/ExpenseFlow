# ExpenseFlow API Reference

Base URL: `http://localhost:3000/api/v1`

All endpoints except `POST /auth/login` require:
```
Authorization: Bearer <jwt>
```

Errors follow one of two shapes:
- **`{ "error": "..." }`** (singular) — a one-off rejection the controller raises itself (e.g. a missing required field on a transition, or a wrong-state guard).
- **`{ "errors": [...] }`** (plural array) — a Rails model validation failure (`expense.errors.full_messages`). 

---

## Auth

### `POST /auth/login`
No auth required.

**Body**
```json
{ "email": "user@example.com", "password": "password" }
```

**200** 
```json
{ "token": "<jwt>", "user": { "id": 1, "name": "Employee User", "email": "employee@expenseflow.com", "role": "employee", "active": true, "team": { "id": 1, "name": "Engineering" } } }
```

**401** on bad credentials — `{ "error": "Invalid email or password" }`

### `DELETE /auth/logout`
Frontend-only in effect (no server-side token invalidation). **204 No Content**.

### `GET /me`
Returns the current authenticated user.

**200**
```json
{ "id": 1, "name": "Employee User", "email": "employee@expenseflow.com", "role": "employee", "active": true, "team": { "id": 1, "name": "Engineering" } }
```
`team` is `null` for a user with no team (e.g. most admins).

---

## Expenses

### `GET /expenses`
List expenses visible to the current user (scoped by Pundit: employees see only their own, managers see their team's, admins see all).

**Query params** (all optional except none are required):
| Param | Notes |
|---|---|
| `status` | one of `draft/submitted/approved/rejected/reimbursed`. Invalid value → `422` |
| `category_id` | filter by category |
| `user_id` | filter by owner |
| `from`, `to` | ISO date (`YYYY-MM-DD`); **both must be present together** to filter — passing only one is ignored. Invalid date or `from > to` → `422` |
| `sort` | `spent_on` (default) / `amount` / `created_at`. Invalid value silently falls back to `spent_on`, no error |
| `direction` | `asc` / `desc` (default). Invalid value silently falls back to `desc` |
| `page` | default `1` |
| `per_page` | default `20` |

**200**
```json
{
  "expenses": [
    {
      "id": 12,
      "title": "Client dinner",
      "description": null,
      "amount": "84.50",
      "spent_on": "2026-08-20",
      "status": "submitted",
      "payment_reference": null,
      "approved_at": null,
      "reimbursed_at": null,
      "created_at": "2026-08-21T10:03:00Z",
      "updated_at": "2026-08-21T10:03:00Z",
      "category": { "id": 2, "name": "Meals", "auto_approve_limit": "50.00" },
      "owner": { "id": 5, "name": "Jane Doe", "role": "employee", "team": { "id": 1, "name": "Sales" } },
      "history": [
        { "from_status": null, "to_status": "draft", "actor": { "name": "system" }, "comment": null, "created_at": "..." },
        { "from_status": "draft", "to_status": "submitted", "actor": { "id": 5, "name": "Jane Doe" }, "comment": null, "created_at": "..." }
      ]
    }
  ],
  "pagination": { "page": 1, "pages": 3, "count": 47 }
}
```

### `GET /expenses/:id`
**200** — single expense, same shape as one item above.
**403** if the current user isn't allowed to view it. **404** if it doesn't exist.

### `POST /expenses`
Creates a new **draft** expense, owned by the current user.

**Body**
```json
{ "expense": { "title": "...", "description": "...", "amount": 42.50, "category_id": 2, "spent_on": "2026-09-01" } }
```

**201** — the created expense (same shape as above).
**422** — `{ "errors": ["Amount must be greater than 0", "Spent on can't be more than 90 days ago", ...] }` on validation failure (amount range, `spent_on` not future / not >90 days in the past, category must be active).

### `PATCH /expenses/:id`
Edits an existing expense. **Only allowed while the expense is a draft.**

**Body:** same shape as `POST`.

**200** — the updated expense.
**422** — `{ "error": "Only draft expenses can be edited" }` if the expense's current status isn't `draft`, or `{ "errors": [...] }` on a validation failure.

### `DELETE /expenses/:id`
Deletes an expense. **Only allowed while the expense is a draft.**

**204 No Content**.
**422** — `{ "error": "Only draft expenses can be deleted" }` if not a draft.

---

## Expense State Transitions

All five below: `POST /expenses/:id/<action>`. All return the updated expense (**200**) on success.

| Action | Who | From → To | Notes |
|---|---|---|---|
| `submit` | owner | `draft → submitted` (or straight to `approved` if `amount ≤ category.auto_approve_limit`) | |
| `approve` | eligible reviewer | `submitted → approved` | optional `comment` in body |
| `reject` | eligible reviewer | `submitted → rejected` | **`comment` required** — `422` `{ "error": "Comment is required to reject an expense" }` if missing |
| `reimburse` | admin | `approved → reimbursed` | **`payment_reference` required** — `422` `{ "error": "Payment reference is required" }` if missing |
| `reopen` | owner | `rejected → draft` | |

**Body examples**
```json
// POST /expenses/12/reject
{ "comment": "Missing receipt" }

// POST /expenses/12/reimburse
{ "payment_reference": "ACH-2026-0091" }
```

**Error responses**
- `403` — wrong person for this action (e.g. someone who isn't the owner tries to `submit`).
- `422` — right person, wrong state (e.g. approving something already `approved`): `{ "error": "Invalid transition: expense is approved, expected submitted" }`.

### `GET /expenses/review_queue`
Submitted expenses awaiting the current user's decision (computed via `ExpensePolicy#approve?`, not a role check — an employee gets `200` with `[]`, never a `403`, since they're simply never an eligible reviewer for anything).

**200**
```json
[ { "id": 12, "title": "...", "...": "same shape as GET /expenses item" } ]
```

### `GET /expenses/report`
Admin-only. Grouped totals by category and month.

**Query params**
| Param | Required | Notes |
|---|---|---|
| `status` | yes | `approved` or `reimbursed` — determines whether grouping uses `approved_at` or `reimbursed_at` |
| `from`, `to` | yes | ISO dates; missing/invalid/backwards range → `422` |

**200**
```json
[
  { "category": "Meals", "month": "2026-08", "total_amount": 412.50, "count": 6 },
  { "category": "Travel", "month": "2026-08", "total_amount": 1890.00, "count": 3 }
]
```
**403** for non-admins.

---

## Users

### `GET /users`
- Employee → `403`
- Manager → members of their managed team only
- Admin → all users

**200**
```json
[
  { "id": 4, "name": "Employee User", "email": "employee@expenseflow.com", "role": "employee", "active": true, "team": { "id": 1, "name": "Engineering" } }
]
```

### `GET /users/:id`
Same visibility rule as above, applied to a single record — same shape as one item above.

### `POST /users`
Admin-only. Creates a user.
```json
{ "user": { "name": "...", "email": "...", "password": "...", "role": "employee", "team_id": 1 } }
```
**201** / **422** `{ "errors": [...] }`.

### `PATCH /users/:id`
Admin-only, with one exception baked in: **an admin cannot deactivate their own account** (`{ "user": { "active": false } }` on yourself → `403`). Any other edit (including reactivating yourself) is allowed.

---

## Teams

### `GET /teams`
- Employee → their own team only
- Manager → their managed team only
- Admin → all teams

### `GET /teams/:id`, `POST /teams`, `PATCH /teams/:id`
Admin-only for create/update.
```json
{ "team": { "name": "...", "manager_id": 3 } }
```
**200 / 201**
```json
{ "id": 1, "name": "Engineering", "manager": { "id": 3, "name": "Manager User", "email": "manager@expenseflow.com" } }
```
`create` and `update` both return this same shape.

---

## Categories

### `GET /categories`
Visible to everyone (non-sensitive reference data).

**200**
```json
[
  { "id": 1, "name": "Travel", "auto_approve_limit": 200.0, "active": true },
  { "id": 2, "name": "Meals", "auto_approve_limit": 50.0, "active": true }
]
```
Note `auto_approve_limit` is a **number** here (this endpoint converts it with `.to_f`) — see the note under `GET /expenses` above about the same field coming back as a string when nested inside an expense.

### `POST /categories`, `PATCH /categories/:id`
Admin-only.
```json
{ "category": { "name": "...", "auto_approve_limit": 50.00, "active": true } }
```
**200 / 201** — same shape as `GET /categories`' items. **422** `{ "errors": [...] }` on validation failure.

---

## Notifications

### `GET /notifications`
Returns the current user's own notifications, newest first.

**200**
```json
[
  { "id": 8, "message": "Your expense \"Conference ticket\" was approved", "read": false, "expense_id": 12, "created_at": "2026-09-18T10:03:00Z" },
  { "id": 7, "message": "Your expense \"Team lunch\" was submitted", "read": true, "expense_id": 9, "created_at": "2026-09-17T09:00:00Z" }
]
```

### `POST /notifications/:id/mark_read`
Marks one of the current user's own notifications as read.

**200** — the updated notification (same shape as one item above, with `"read": true`).
**404** if the notification doesn't belong to the current user or doesn't exist.
