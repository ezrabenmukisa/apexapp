# Apex

Flutter app for remotely funded building projects: owners plan milestones and review evidence; site managers capture GPS- and time-stamped evidence on site.

## Setup

1. Install Flutter 3.47 or newer.
2. Create your local config:
   ```sh
   cp .env.example .env
   ```
   `.env` is gitignored. Its keys:
   - **`API_BASE_URL`**: the Apex API. Defaults in `.env.example` to `https://apex.pntr.dev/api/v1`.
   - **`LIVE_PROJECTS`**, **`LIVE_MILESTONES`**, **`LIVE_EVIDENCE`**, **`LIVE_NOTIFICATIONS`**: set one to `true` once its backend endpoint exists. Until then that feature runs on the in-app mock server.
3. Android signing and Firebase: see [docs/firebase-setup.md](docs/firebase-setup.md).
4. Run:
   ```sh
   flutter pub get
   flutter run
   ```

## Checks

```sh
flutter analyze && flutter test
```

More: [CLAUDE.md](CLAUDE.md) (architecture and conventions) and [docs/api-assumptions.md](docs/api-assumptions.md) (live API status).
