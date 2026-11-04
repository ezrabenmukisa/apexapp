# API assumptions made by the app

## Live status (https://apex.pntr.dev/docs, checked 2026-11-05)

| Feature | Endpoints | App |
|---|---|---|
| Auth | `POST /auth/firebase` | **Live** |
| Profile | `GET` / `PATCH /users/me` | **Live**, but no `user_role` yet (kept on the phone) |
| Projects, members & invitations | `/projects`, `/projects/{id}/members`, `POST /projects/invitations/accept` | **Live** (`LIVE_PROJECTS=true`); mapped from the OpenAPI schemas |
| Milestones | `/projects/{id}/milestones`, `/milestones/{id}` | Mock until shipped (`LIVE_MILESTONES`) |
| Evidence & reviews | `/milestones/{id}/evidence`, `/evidence/{id}/reviews` | Mock until shipped (`LIVE_EVIDENCE`) |
| Notifications & push token | `/notifications`, `/devices/push-token` | Mock until shipped (`LIVE_NOTIFICATIONS`) |

Live response details: `user_id` is a UUID, and `contact_email` may be `null`.

The [API contract](../../docs/Apex_API_Operations.pdf) names enums and list responses but doesn't spell out every value. The app currently assumes the values below. The mock server (`lib/core/mock/mock_api_server.dart`) implements exactly these, so the screens work end to end.

**Backend team: please confirm or correct these.** If yours differ, only the JSON model mappings in `lib/features/*/data/models/` need to change.

## Enum values

| Field | Values the app sends / expects |
|---|---|
| `projects.status` | `ACTIVE`, `SUSPENDED`, `COMPLETED` (**live**; the UI says "Paused") |
| `user_role` (member, invitation), `current_user_role` | `owner`, `manager`, `member` (**live**, lowercase; unknown values are treated as `member`) |
| `users.user_role` (requested addition) | `OWNER`, `MANAGER` |
| `milestones.status` | `NOT_STARTED`, `IN_PROGRESS`, `SUBMITTED`, `CHANGES_REQUESTED`, `APPROVED`, `FLAGGED` |
| `evidence.status` | `SUBMITTED`, `APPROVED`, `CHANGES_REQUESTED`, `FLAGGED` |
| `reviews.decision` | `APPROVE`, `REQUEST_CHANGES`, `FLAG` |
| `devices/push-token.platform` | `ANDROID`, `IOS` |

Unknown values don't crash the app; they fall back to a safe default (e.g. `NOT_STARTED`).

## Status transitions the app expects the backend to make

- `POST /milestones/{id}/evidence` → evidence `SUBMITTED`, milestone `SUBMITTED`.
- `POST /evidence/{id}/reviews` → evidence and milestone become `APPROVED` / `CHANGES_REQUESTED` / `FLAGGED` to match the decision. A `comment` is required for every decision.
- After `CHANGES_REQUESTED` or `FLAGGED`, the site manager can submit **new** evidence. Evidence itself is never edited.
- `GET /milestones/{id}/evidence` returns the **latest** submission for the milestone, or `404` if there is none yet.

## Response shapes

- **List endpoints** (`/projects`, `/projects/{id}/milestones`, `/projects/{id}/members`, `/notifications`): either a bare JSON array or `{"items": [...]}`. Both are accepted.
- **Members** (`GET /projects/{id}/members`): each item has `user_id`, `first_name`, `last_name`, `contact_email`, `user_role`. **Live.**
- **Invitations** (live): `POST /projects/{id}/members` takes `{contact_email, user_role, message}` (`message` is required; the app sends the owner's note or a default line) and returns a pending `ProjectInvitationResponse`. The person isn't in the members list until they accept. Accepting is `POST /projects/invitations/accept {token}` → `{message, project_id}`; the token comes from the emailed `https://apex.pntr.dev/invite?token=…` link.
- **Notifications:** each item has `notification_id`, `title`, `body`, `is_read`, and ideally `created_at` (ISO datetime), which the app uses for newest-first ordering.
- **Dates:** `date` fields are `YYYY-MM-DD`. `datetime` fields are ISO 8601 with a timezone (e.g. `2026-10-14T07:42:00Z`).
- **Money:** `planned_budget` and `total_cost_spent` are numbers (or numeric strings). `currency` defaults to `UGX`.
- **Errors:** FastAPI's default `{"detail": "..."}` or `{"detail": [{"msg": "..."}]}`. The message is shown to the user.

## Requested additions (optional but used by the UI)

1. **`user_role` on `/users/me`.** See the earlier message to the backend team.
2. **`latest_review` on the evidence response.** The site manager's Today screen shows the owner's last decision and comment, and the owner's review screen shows a past decision:
   ```json
   "latest_review": {
     "decision": "APPROVE",
     "comment": "Good, thanks for the DPC close-up.",
     "reviewed_at": "2026-10-02T18:14:00Z"
   }
   ```
   If it's absent, those cards are simply hidden.

## Evidence submission (multipart)

`POST /milestones/{id}/evidence` is sent as `multipart/form-data`:

- **Text fields:** `description`, `captured_latitude`, `captured_longitude`, `captured_at` (ISO UTC), and optionally `expenditure_notes` and `total_cost_spent`.
- **Files:**
  - `site_media`: repeated, one per photo or video, from the in-app camera only.
  - `receipt_media`: repeated, photos or PDFs, gallery allowed.

`captured_*` is the GPS fix and time taken when the shutter fired on the first site photo.
