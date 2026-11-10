# Session M7.12: Accounts: sign up, sign in, log out

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 12. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `apps/battle_team`, `packages/appwrite_api_client` (in hawkbee itself) · **Branch:** `bt/m7-12-accounts` · **Depends on:** M7.1.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:static-security`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `appwrite:dart`.
**Read** (`plan/` is `apps/battle_team/plan/`): decisions 126, 220; `plan/stack/06-accounts-and-services.md`; `docs/project-setup.md` (local Appwrite, `env/development.json`); `packages/appwrite_api_client/lib/src/appwrite_api_client.dart` (`signIn`, `createJwt`, `selfSigned`); `packages/hawkbee_schema` (the `bt_sections`/`bt_battles` rows a player may read); the session logs of M5.18 (Appwrite data), M6.5 (sign-in is `EnterBattle`, host-side), M6.6 (host lookup), M7.1 (the `env/` sign-in to replace).

## Steps
1. **`appwrite_api_client`**: `signUp(email, password, name)` (`account.create` + session), `currentAccount()` (null when none), `signOut()` (`deleteSession('current')`); failures as typed exceptions as `signIn` does. Tests with the mocked `Client`/`Account` as the existing ones.
2. **Authentication feature** (`lib/authentication/`): `AuthenticationRepository` over `appwrite_api_client` (status stream: unknown → unauthenticated/authenticated); `SignInPage`, `SignUpPage` (email, password, confirm; validation with `formz` or plain validators — static-security skill: no password in logs or state dumps); a log-out action in the battle screen's menu.
3. **Routing**: `App` shows sign-in until authenticated, then the battle. Session kept across restarts: the Appwrite SDK keeps its cookie jar; `currentAccount()` at start decides the first screen.
4. **Which battle**: after sign-in, find the account's section and its battle in Appwrite (the rows M5.18/M5.21 define; the playtest tool writes them). The `env/` sign-in stays for `main_playtest.dart` only; the normal flavors drop it.
5. **Errors**: wrong password, existing email, unreachable Appwrite, each a localized message (en + fr); no technical text to the user.
6. **Gates** (§4, §6); **show it** (recording on the owner's phone: sign up → battle → log out → sign in; or a web build); **finish** (§5): hawkbee PR carries `appwrite_api_client`.

## Tests to write
- `appwrite_api_client`: `signUp`, `currentAccount`, `signOut` success and failure (mocked SDK).
- `AuthenticationRepository` status transitions (bloc_test / stream matchers).
- Sign-in and sign-up pages: validation, submit, error display, en and fr; log-out returns to sign-in.
- `App` routing by status; `decision 220 the app sends no EnterBattle: the host logs the player in on the socket` (the repository exposes no such call).

## Stop and ask when
- Reading "the account's battle" needs a row or permission the local schema lacks: ask before changing `hawkbee_schema`/`battle_backend`.
- The owner wants social sign-in now (Discord, decision 126): it is a later session; ask only to confirm.

## Pitfalls
- Appwrite's session cookie needs https on phones (see hawkbee1/battle_team#38): keep `trustSelfSigned` for the development flavor against the local stack, never in production.
- Never store the password; the SDK holds the session.
- `appwrite_api_client` is the only package allowed to import `package:appwrite`.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 12).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
