# Session M7.12: Accounts: sign up, sign in, log out

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 12. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `apps/battle_team`, `packages/appwrite_api_client` · **Branch:** `bt/m7-12-accounts` · **Depends on:** M7.1.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:static-security` (the forms), `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `appwrite:dart`.
**Read** (`plan/` is `apps/battle_team/plan/`): decisions 126 (later), 220; `plan/stack/06-accounts-and-services.md`; the session logs of M6.5 (sign-in is `EnterBattle`, host-side) and M6.6 (finding the host); `docs/project-setup.md` (local Appwrite).

## Notes
- Appwrite email + password: sign up (`account.create`), sign in, log out, the session kept across restarts; wrong password and unreachable Appwrite surfaced, localized.
- After sign-in, enter the battle the account's section is in (read from Appwrite as the playtest tool writes it); the `env/` sign-in stays for the playtest flavor only.
- The newcomer flow (SOC-03) and Discord linking (decision 126) are out: later sessions.
- End with a phone recording in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 12).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
