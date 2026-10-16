# Apex (Siteproof) — Flutter app

Evidence and accountability app for remotely funded physical projects. Owners plan projects and review evidence; site managers submit geotagged evidence from site.

Specs live outside this repo in `../docs/`:
- `Apex_API_Operations.pdf`: ER diagram and REST contract (`/api/v1`, FastAPI, Firebase ID token auth).
- `Mobile app design clarification/siteproof/*.html`: prototype screens (390×844) plus `01 Foundations` / `02 Components` design system.

## Architecture

Clean architecture, one folder per feature, with BLoC for state.

```
lib/
  core/        config, di, error, network, router, theme, widgets, usecase
  features/<feature>/
    domain/        entities (Equatable), repositories (abstract), usecases
    data/          models (JSON), datasources (remote + mock), repositories (impl)
    presentation/  bloc (Bloc/Cubit + state), pages, widgets
```

Features: `auth` (sign-in, onboarding), `projects` (#2), `milestones` (#3), `evidence` (#4 — capture, outbox, review), `notifications` (#5), `account` (settings, permissions).

Rules:
- Dependencies point inward. `presentation` → `domain` ← `data`. Domain imports no Flutter, Dio or Firebase.
- Repositories return `Either<Failure, T>` (fpdart) and never throw. Data sources throw, and `mapErrorToFailure` converts.
- Every use case is an `@injectable` class with `call`.
- Blocs/cubits never navigate. `AuthBloc` state drives `go_router` redirects (`core/router/auth_redirect.dart`).
- DI is `get_it` + `injectable`. Run `dart run build_runner build` after adding or changing annotations.
- Screens that load data use `LoadCubit<T>` + `LoadView` (`core/bloc/`): loading/error/retry, actions with snackbars, and silent reload when another screen publishes a change on `DataChanges` (`core/sync/`). Repositories publish after every successful write.
- Cubits shared across tabs and full-screen pages (dashboard, inbox, site assignment, outbox, evidence draft, settings) live in `SessionScope` (`core/navigation/session_scope.dart`), rebuilt per signed-in user.
- Device capabilities (GPS, camera, receipts picker, geocoding, permissions, FCM token) are interfaces in `core/device/device_services.dart`. The current implementations are **simulations**; swap in real plugins there.

## Networking: Dio only (no `http` package)

- A single `Dio` is registered in `core/di/register_module.dart`. `AuthInterceptor` adds `Authorization: Bearer <Firebase ID token>` and retries once on 401 with a refreshed token.
- Paths live in `core/network/api_endpoints.dart`. JSON keys are snake_case exactly as in the PDF.

## Logging

Use `appLogger` (`core/logging/app_logger.dart`); never `print`. It is silent outside debug builds. In debug, `AppBlocObserver`, `LoggingInterceptor` (Dio, token never printed), `mapErrorToFailure` and the global error hooks in `main.dart` log automatically.

## Mock vs real backend

Every backend data source has an interface plus two implementations:
- `XxxRemote` annotated `@remote` (Dio).
- `XxxMock` annotated `@mock`, backed by `MockApiServer` (`core/mock/`). It is an in-app fake backend that stores API-shaped JSON per user in shared prefs, enforces owner-only writes and seeds the prototype's sample project for the user's role.

Assumed enum values and response shapes are listed in `docs/api-assumptions.md`.

`--dart-define=USE_MOCK_API=false` switches every feature to the real API (default: mocks). Firebase Auth is always real. When an endpoint goes live, only the `@remote` class changes.

```sh
flutter run                                        # mocks
flutter run --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://<host>/api/v1  # real API
```

## Auth flow (issue #1)

Sign-in options screen: **Continue with Google** (google_sign_in → Firebase credential), **Continue with phone** (Firebase OTP) or **Continue with email** (email/password). All three lead to `POST /auth/firebase {id_token}`, which returns `{user_id, profile_complete}`.
- If `profile_complete` is false, the router forces `/onboarding/profile`, which saves via `PATCH /users/me` (including `user_role`).
- Otherwise the app calls `GET /users/me` and opens the owner (`/owner`) or site-manager (`/site`) shell by `user_role`.
- Sign out is local only: `FirebaseAuth.signOut()` plus clearing the cached profile.
- The profile is cached in secure storage, so the app reopens offline.

`user_role` is on the User entity in the ER diagram but is not yet in the `/users/me` contract. The app sends it and tolerates its absence, keeping the locally chosen role.

## Design system

Use the tokens in `core/theme/`. Never hard-code colours or fonts in features.
- Paper `#F6F2EA` ground, Surface `#FFFDF8` cards, Ink `#1F1B16` text and primary buttons. Laterite `#A4441F` is for the brand mark and focus only.
- Status colour pairs: approved, awaiting, changes, flagged, not started. Status is never shown by colour alone; always add a label.
- Fonts: Newsreader for titles and money, Hanken Grotesk for the UI, IBM Plex Mono for proof data (coords, timestamps). They are bundled in `assets/fonts/` and declared in `pubspec.yaml`; never fetch fonts at runtime (no google_fonts).
- 4-pt spacing, radius 4/8/14, flat surfaces (shadows only on floating sheets), touch targets of at least 48 px.

## Firebase

Project `apex-9fcb6`; app id `com.apex.app` on Android and iOS. Full console setup, iOS steps and troubleshooting: `docs/firebase-setup.md`. Android builds are signed with shared team keys from `android/key.properties` + `android/keystore/` (gitignored; the repo is public, never commit them). Regenerate config with `flutterfire configure --project=apex-9fcb6 --platforms=android,ios --android-package-name=com.apex.app --ios-bundle-id=com.apex.app`.

## Checks

```sh
flutter analyze && flutter test
```

`test/app/` holds end-to-end widget tests. They boot the real app with a fake Firebase user against `MockApiServer` and walk the owner and site-manager flows. Overflows and runtime errors fail them.
