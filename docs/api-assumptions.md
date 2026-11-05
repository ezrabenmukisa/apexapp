# API assumptions made by the app

## Live status (https://apex.pntr.dev/docs, checked 2026-11-05)

| Feature | Endpoints | App |
|---|---|---|
| Auth | `POST /auth/firebase` | **Live** |
| Profile | `GET` / `PATCH /users/me` | **Live**, but no `user_role` yet (kept on the phone) |
| Projects, members & invitations | `/projects`, `/projects/{id}/members`, `POST /projects/invitations/accept` | **Live** (`LIVE_PROJECTS=true`); mapped from the OpenAPI schemas |
| Milestones | `/projects/{id}/milestones`, `/milestones/{id}` | **Live** (`LIVE_MILESTONES=true`) |
| Evidence & reviews | `/milestones/{id}/evidence`, `…/evidence/upload-urls`, `/evidence/{id}/reviews` | **Live** (`LIVE_EVIDENCE=true`); submission not yet run end to end against the live API (needs a site-manager account) |
| Notifications & push token | `/notifications`, `/devices/push-token` | **Live** (`LIVE_NOTIFICATIONS=true`) |

Live response details: `user_id` is a UUID, and `contact_email` may be `null`.

The [API contract](../../docs/Apex_API_Operations.pdf) names enums and list responses but doesn't spell out every value. The app currently assumes the values below. The mock server (`lib/core/mock/mock_api_server.dart`) implements exactly these, so the screens work end to end.

**Backend team: please confirm or correct these.** If yours differ, only the JSON model mappings in `lib/features/*/data/models/` need to change.

## Enum values

| Field | Values the app sends / expects |
|---|---|
| `projects.status` | `ACTIVE`, `SUSPENDED`, `COMPLETED` (**live**; the UI says "Paused") |
| `user_role` (member, invitation), `current_user_role` | `owner`, `manager`, `member` (**live**, lowercase; unknown values are treated as `member`) |
| `users.user_role` (requested addition) | `OWNER`, `MANAGER` |
| `milestones.status` | `PENDING`, `IN_PROGRESS`, `COMPLETED`, `DELAYED` (**live**) |
| `evidence.status` | `SUBMITTED`, `APPROVED`, `REQUEST_CHANGES`, `FLAGGED` (**live**) |
| `reviews.decision` | `APPROVED`, `REQUEST_CHANGES`, `FLAGGED` (**live**) |
| `devices/push-token.platform` | `android`, `ios` (**live**, lowercase; the API also has `web`) |

Unknown values don't crash the app; they fall back to a safe default (e.g. "Not started").

## What a milestone card shows

The API keeps progress on the milestone and review state on its latest evidence. The app folds them into one badge (`MilestoneModel.displayStatus`):

1. Milestone `COMPLETED` → **Approved**.
2. Otherwise, if the milestone has evidence, its latest evidence status wins: `SUBMITTED` → **Review / Awaiting review**, `REQUEST_CHANGES` → **Changes requested**, `FLAGGED` → **Flagged**, `APPROVED` → **Approved**.
3. Otherwise the milestone status: `PENDING` → **Not started**, `IN_PROGRESS` → **In progress**, `DELAYED` → **Delayed**.

So listing a project's milestones costs one `GET /milestones/{id}/evidence` per milestone (404 = none yet). **Backend team:** returning the latest evidence status on `MilestoneResponse` (e.g. `latest_evidence_status`) would save those requests.

## Status transitions the app expects the backend to make

- `POST /milestones/{id}/evidence` → evidence `SUBMITTED`.
- `POST /evidence/{id}/reviews` → evidence becomes `APPROVED` / `REQUEST_CHANGES` / `FLAGGED` to match the decision. A `comment` is required for every decision. (The mock also sets the milestone to `COMPLETED` on approval; the app doesn't depend on it.)
- After `REQUEST_CHANGES` or `FLAGGED`, the site manager can submit **new** evidence. Evidence itself is never edited.
- `GET /milestones/{id}/evidence` returns the **latest** submission for the milestone, or `404` if there is none yet (**live**: `{"detail": "No evidence submitted for this milestone."}`).
- Only project managers can request upload URLs or submit evidence (**live**: 403 for the owner).

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
     "decision": "APPROVED",
     "comment": "Good, thanks for the DPC close-up.",
     "reviewed_at": "2026-10-02T18:14:00Z"
   }
   ```
   If it's absent, those cards are simply hidden.

## Evidence submission (live: S3 upload URLs + JSON)

1. `POST /milestones/{id}/evidence/upload-urls {filenames, folder}` once for `site_media` and, if there are receipts, once for `receipt_media`. Returns `[{file_key, upload_url}]` in the same order as `filenames`.
2. `PUT` each file's bytes to its `upload_url`, with a `Content-Type` guessed from the extension. This goes through the app's shared Dio, so it's logged like every other call, but it's marked to skip the Firebase token (`AuthInterceptor.skipAuthKey`), and the log hides the presigned signature.
3. `POST /milestones/{id}/evidence` as JSON: `description`, `captured_latitude`, `captured_longitude`, `captured_at` (ISO UTC), `site_media_keys`, and optionally `expenditure_notes`, `total_cost_spent`, `receipt_media_keys`.

`captured_*` is the GPS fix and time taken when the shutter fired on the first site photo. If any step fails, the submission stays in the outbox and the whole thing is retried later (new upload URLs each time).

**Backend team:** if the presigned URLs are signed with a specific `ContentType`, tell us which, or the PUT will fail with `SignatureDoesNotMatch`.
