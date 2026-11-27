# sdui-monorepo, November 2026: API fact check

Checked on 2026-11-27 against `7education/sdui-monorepo` with read-only `gh` (PR diffs, contents API on `main`,
repo rulesets). Security findings are left out on purpose.

Paths: Core prefixes every auth, public and internal route with `/v1` outside development and testing
(`apps/core/app/Providers/RouteServiceProvider.php` on `main`); locally the prefix is empty. The route list below
comes from the route snapshot `apps/core/tests/Security/__snapshots__/RouteSnapshotTest__testRouteSnapshot__1.yml`,
which every PR that changes a route must update. Net route changes in the checked PRs: #1824 removes one, #1801 adds
one, #1747 and #1748 add one each, #1790 and #1688 add none.

## 1. #1824 (merged 2026-11-25, PE-562): removed routes, who could call them, was "AI Chat" visible

**Answer.** One route was removed: `POST /v1/management/schools/{school}/idp` (name
`post.management.school.idp.realm.create`, middleware `auth`, `can:view,school`, `can:manage-sdui`). Only Sdui
internal staff with the `manage-sdui` ability could call it. Its only caller was the "Create Realm" button in the
Sdui admin panel. The `ai/*` routes (`POST ai/news/feedback`, `ai/news/generate`, `ai/seven-assistant/token`,
`ai/seven-assistant/exchange`) only moved inside the snapshot file; they still exist.

"AI Chat" was visible to users: a card in the app's "More" menu with a badge and an external link (the old
LibreChat). It showed only to teachers at schools with the flag `ai.chat.enabled` (`AI_CHAT_ENABLED`, default
false, marked "Deprecated LibreChat"). The PR body says it is "no longer active on Sdui".

API effects for other callers: the user resource (`FullUserResource`) no longer has a `name: 'ai_chat'` entry in
`meta.sdui_group.features`. That block is only sent when the returned user is the caller. The PR also removes the
Keycloak logout redirect for IDM users (`ThirdPartyLogoutService`) and the forced Keycloak session end
(`ForceLogoutService`).

**Evidence.** #1824: `apps/core/routes/schools/management.php` (route removed), `IDPManagementController` deleted,
snapshot diff; `apps/sdui-app/src/api/management.js` (`createIDPRealm`) and `AuthenticationDriver.vue`;
`MoreListView.vue` (`aiChatItem`); `FullUserResource`.

**Confidence.** High for the route and its callers. High that the card was user-visible where the flag was on.
Unknown how many schools had the flag on.

## 2. #1790 (merged 2026-11-26, SC-1999): translate returns 422

**Answer.** `GET /v1/channels/chats/{chat}/messages/{message}/translate` (route
`get.chats.single.messages.translate`, middleware `can:view,chat`, `can:translate,message`) now returns HTTP 422
with the message `chats.messages.translation.not_supported_for_local_ai` when the school flag
`local_ai_translation_service.enabled` (`LOCAL_AI_TRANSLATION_SERVICE_ENABLED`) is true. With the flag off,
nothing changes.

The flag is off by default (`school_features_template.php`). The PR has no migration or seeder, and no migration
on `main` mentions the flag. It is set per school through the school properties (`SchoolPropertiesService`); who
may set it was not checked.

Side effect: the school meta field `can.chat-translations` now comes from `UserPolicy::chatTranslations`. With the
local flag on, every user type except students gets it, whatever the DeepL flags say.

**Evidence.** #1790: `Modules/Channel/Routes/chat/messages.php`, `TranslationsController::translate`
(`Response::failed(trans('chats.messages.translation.not_supported_for_local_ai'), 422)`, line 32 of
`gh pr diff 1790`),
`school_features_template.php`, `SchoolMetaResource`, `UserPolicy`.

**Confidence.** High.

## 3. #1801 (merged 2026-11-26, SC-2079): /mcp/chat

**Answer.** New route `POST /v1/mcp/chat` (`/mcp/chat` locally), route name `post.mcp.chat`, registered in
`apps/core/routes/ai-chat.php`:

```php
Mcp::web('/mcp/chat', ChatServer::class)->middleware(['auth', 'throttle:200,1', McpAiChatSearchEnabledMiddleware::class])->name('post.mcp.chat');
```

Auth: the normal user `auth` guard with a user bearer token. Core mints a per-user token
(`createToken('seven-assistant-mcp')`) and hands the URL and bearer header to the Seven Assistant when it creates
the assistant token (`SevenAiTokenService::mcpServersFor`). Rate limit 200 requests per minute. Returns 403 "AI
chat search is not enabled for your school." unless the school flag `channels.ai_chat_search.enabled` is on
(default off, settable per school).

Audience: the Seven Assistant (Sdui's AI assistant). It exposes four read tools over the caller's own chats
(`list_chats`, `get_messages_by_chat`, `search_messages`, `get_recent_activity`) that reuse the existing Channel
controllers. It is not documented as an API for other teams.

Additive side changes other callers may notice: `GET /v1/channels/chats/{chat}/messages` accepts `per_page` (1 to
50, default 20); `GET /v1/channels/chats/messages/search` accepts `page` and `per_page` (1 to 100, default 20) and
returns 422 on invalid values.

Doc mismatches (outside the newsletter): `docs/sdui-platform/features/sduiapp-core/mcp.md` says a "Sanctum bearer
token" is needed, but the code uses the standard Passport `auth` guard. `docs/sdui-platform/architecture/crosscutting.md`
still says the MCP server moved to `packages/mcp-server`.

**Evidence.** #1801: `apps/core/routes/ai-chat.php` (renamed from `routes/ai.php`; line 2676 of `gh pr diff 1801`), snapshot entry for
`post.mcp.chat`, `McpAiChatSearchEnabledMiddleware`, `SevenAiTokenService`.

**Confidence.** High for path, auth and flag. Medium for "audience is only the Seven Assistant" (that is how it is
wired; nothing technically stops another holder of a user token at a flagged school).

## 4. #1688 (merged 2026-11-06, SC-1952): step-up lifetime and kill switch

**Answer.** The step-up lifetime (`IAM_STEP_UP_LIFETIME_IN_SECONDS`) default goes from 21600 s (6 h) to 86400 s
(24 h). New kill switch `services.iam.tms.step_up.sync_enabled` = env `IAM_STEP_UP_SYNC_ENABLED`, default true.
When set to false: Core stops sending the step-up enable call to IAM/TMS (disable still goes through), the
step-up middleware lets every request through, and the school meta reports `iam.step_up_auth.enabled: false`.

API behaviour: for schools with IAM, the authenticator app and step-up on, protected routes return 401
`{code: 'step_up_required', acr_values: '2'}` to Keycloak tokens below acr 2. Passport tokens pass.
`GET /v1/management/schools/{school}/classbooks/{classbook}/exports` no longer needs step-up;
`POST .../exports/create` still does.

Users notice it: the app now asks only for the second factor (no full re-login first) and asks about once a day,
after 04:00 (the frontend sets `max_age` instead of `prompt=login`). Before, the 6-hour lifetime could expire during
the school day. Two more effects users see:

- The middleware used to skip every user who did not use e-mail 2FA (`$user->tfa_mode !== TwoFactorService::MODE_EMAIL`).
  That skip is gone, so users with other or no 2FA at such schools can now get the 401 `step_up_required` too.
- In the app, the step-up check moved from the admin exports page (`management-exports`) to the sick notes overview
  (`sick-notes-overview`): opening sick notes now asks for the second factor, the exports page no longer does.

**Evidence.** #1688, line numbers in `gh pr diff 1688`: lines 10 and 23 (lifetime 86400 in
`Modules/Platform/Config/config.php` and `Modules/Services/Config/iam.php`), line 28 (`sync_enabled`), from line 106
`RequireStepUpAuthMiddleware.php` (e-mail 2FA skip replaced by the kill-switch check), lines 997 to 1031
(`router/routes/management/management.js` drops `recentAuth`, `router/routes/sickNotes/sickNotes.js` adds it),
`SchoolMetaResource`, frontend auth code comment "Keycloak keeps the step-up level for the IAM lifetime (24h),
max_age makes it ask again after 04:00".

**Confidence.** High for the defaults and behaviour in code. Medium for "asked before within a day". Unknown
whether production overrides the env values (that lives in infra config, not this repo).

## 5. #1684 (merged 2026-11-10, SC-1935) and #1685 (merged 2026-11-11, SC-1936): sync scope

**Answer.** Consumer: the platform Classes & Groups service (`CLASSES_GROUPS_URL`, client
`ClassesGroupsHttpClient`), which receives school years, subjects, groups (classes and courses) and group
enrollments. The repo does not name the team that owns it.

No longer sent: school years that start before 2025-01-01, and their grades, subjects, courses, and teacher and
student enrollments. #1684 applies this to the first migration and school setup; #1685 applies it to live updates
(school-year delete and update, year switch, and the grade, course and enrollment triggers).

PR body quote (#1684): "scopes the platform outbound sync to only sync school years from 2025 and onward. Our older
data can be messy and is not really needed by other teams at this time."

**Evidence.** Config `platform.outbound_sync.floor_school_year_begins_at => '2025-01-01'`,
`OutboundSchoolYearScope::fromFloor`, `ClassesGroupsMigrationService`, `PlatformScopeSchoolRepository` (#1684);
`TimetableController::switchYear`, `SchoolYearChangeService`, enrollment dispatchers (#1685).

**Confidence.** High.

## 6. #1747 and #1748 (merged 2026-11-12, SC-1864): holder endpoints

**Answer.** Two new internal routes, served on the public `/v1` host but usable only by the holder-api service:

- `GET /v1/internal/holder-directory/schools?holder=<id>&ids[]=...` (at most 200 ids, 600 requests per minute).
  #1748 made `holder` required, returns 404 for an unknown holder and 503 when holder-api does not answer.
- `PUT /v1/internal/holder-schools/{schoolId}/name` (body `name`, max 190 characters, 60 requests per minute).

`HolderApiClientMiddleware` accepts only client-credentials tokens of the holder-api client
(`HOLDER_API_CLIENT_ID`); user tokens get 403. So: internal, not for other teams. Core itself calls holder-api
`GET /internal/holders/{id}/schools`.

Public effects: `GET /v1/find-schools` (school search without login) no longer lists holder-type schools; the
school resource gains a `type_key` field; holder admins are sent to the holder portal, and password reset links for
holder schools point there. #1747 adds the migration `2026_11_10_000000_add_holder_school_type.php` and a demo
seeder.

**Evidence.** #1747 and #1748: snapshot entries `get.internal.holder-directory.schools` and
`put.internal.holder-schools.name` (middleware `holder-api.client:holder-directory` at line 878 of `gh pr diff 1747`,
`holder-api.client:holder-rename` at line 568 of `gh pr diff 1748`),
`HolderApiClientMiddleware`, `SchoolResource`, find-schools query.

**Confidence.** High.

## 7. #1647 (merged 2026-11-02, SC-1962): APIs other teams call

**Answer.** No Core route changes (no snapshot change). Two outbound changes: the UMS call
`POST organizations/{orgId}/users/migrate` (and user creation) no longer sends password hash fields when the user
has no local password, and adds `federatedIdentities: [{identityProvider: 'univention', userId: <external id>}]`.
And `POST /v1/auth/login-idm` (Univention login) now syncs a user to IAM on first login when they have no UMS id
yet, with a 10-second timeout; a failure does not block the login. The "endpoint" change in the title is not
visible in the final diff.

**Evidence.** #1647 diff: UMS client payload, login-idm controller, no snapshot file.

**Confidence.** High for "no Core API change". Medium for what UMS owners need to know (the payload shape changes
for passwordless users).

## 8. #1781 (merged 2026-11-17, PE-530): action for other teams

**Answer.** None. `TmsTenantHttpClient::listIdentityProviderAliases` now accepts both `{"identityProviders": [...]}`
and a bare array from TMS v2 `GET organizations/{organizationId}/identity-providers`. Its only caller is the artisan
command `app:create-univention-identity-provider`. It prepares for domain-engineering-platform#588: the TMS owners
can now ship the bare list without breaking Core.

**Evidence.** #1781 diff (one client method and its test).

**Confidence.** High.

## 9. #1823, #1836 tags and the #1811 workflow: can other teams use them

**Answer.** Mostly no; they are team tools.

- #1811 (merged 2026-11-20, SC-2082) adds `.github/workflows/sdui-app-playwright.yml` ("sdui-app Playwright E2E").
  It runs by hand (`workflow_dispatch`) with inputs `test_env` (`main`, `preprod` or a feature env like `sc-1234`),
  `projects` (chromium, android-mobile, ios-mobile, webkit), `workers` (default 3) and `vpn` (default true). It
  runs `npx playwright test --grep-invert @quarantine`. It is not a required check. It joins Netbird (VPN) through
  the new `.github/actions/netbird-connect` action, because `*.sdux.de` answers 403 to GitHub runners outside the
  VPN. Only people with write access to the repo can start it.
- #1823 (merged 2026-11-25, SC-2109) removes the `@regression` tag ("after a merge to main every test runs") and
  adds `@quarantine`: a test that is red for a reason outside the test, linked to a Jira ticket, which must not
  block a run. The realtime chat spec is quarantined (SC-2108).
- #1836 (merged 2026-11-25, SC-2113) defines the `@smoke` set: login, chat attachments (image with alt text),
  sending and deleting a message, a parent starting a new chat, voice messages and opening a push notification.
  Locally: `npm run test:pw:smoke` in `apps/sdui-app` (`npx playwright test --project=chromium --grep @smoke`).

Other teams can read or copy the pattern (tags in `apps/sdui-app/tests/playwright/config/tags.ts`, domain by
folder), but cannot run the workflow without write access and the VPN.

**Evidence.** `main`: `.github/workflows/sdui-app-playwright.yml` (lines 10 to 29 inputs, line 171
`--grep-invert @quarantine`), `apps/sdui-app/tests/playwright/config/tags.ts`; #1823 diff of `tags.ts`,
`tests/playwright/CLAUDE.md`, `ARCHITECTURE.md`; #1836 diff (`tag: [Tag.SMOKE]` on the specs); #1745 and #1756
`apps/sdui-app/package.json` scripts.

**Confidence.** High.

## 10. Contribution rule changes, PRs merged 2026-11-01 to 2026-11-27

Method: all 138 merged PRs in `reports/2026-11/sdui/raw/sdui-monorepo.prs.json` (`jq`), file lists from
`gh api repos/.../pulls/<n>/files`, filtered for `.github/`, `.nvmrc`, `package.json`, README, CLAUDE.md, lint
configs and Dockerfiles. Branch rules read with `gh api repos/.../rulesets` and `rules/branches/main`.

**No change** to: the PR template, required status checks (main has none; `pipeline / gate` of the delivery
workflow is explicitly "not a required check"), root lint or format config, `engines`, the root `.nvmrc`, and the
branch naming rule (`{LETTERS}-{NUMBER}[-description]`, enforced only by a Husky pre-push hook; #1833 on 2026-11-24
only reformats that section of the root CLAUDE.md).

Branch rules: ruleset `default-four-eye-principle` (one approving review, extra approval for unattributed changes)
was last updated 2026-11-01 22:23 UTC. That is a settings change, not a PR; what changed is not visible through the
API. Confidence low on whether it changed anything a contributor notices.

**Changes contributors may notice:**

| PR | Merged | What changes for a contributor | Confidence |
| --- | --- | --- | --- |
| #1745 (SC-2027) | 2026-11-12 | Playwright npm scripts replaced (`test:pw`, `test:pw:headed`, `test:pw:ui`, `test:pw:debug`, `test:pw:smoke`, `test:pw:all-devices`, `test:pw:report`); the old `test:pw:local:*` scripts are gone. New ESLint rules for `tests/playwright/**` (no `waitForTimeout`, no raw locators, specs import `test`/`expect` only from the fixture). | High |
| #1756 (SC-2034) | 2026-11-12 | `@playwright/test` raised to ^1.65.0; `test:pw:all-devices` runs every project. | High |
| #1711 (SC-1999) | 2026-11-09 | `npx nx audit frontend` moved to its own CI job "sdui-app: Package Audit", so an audit finding no longer skips the build and unit tests. | High |
| #1773, #1786, #1788 | 2026-11-18 | Delivery workflow (shadow mode, not required) pinned to newer delivery-templates commits; its PR checks now run on the self-hosted ARC runners (`arc-slim`). #1668, #1670, #1737 were earlier template pin bumps. | High |
| #1785 (SC-2043) | 2026-11-20 | Sdui Meet moved in as `apps/sduiapp-meet`: own workspace and lockfile, own `.nvmrc` (24) and ESLint 8 config. Subtree PRs must be merged with a merge commit, never squash or rebase (root CLAUDE.md). | High |
| #1811 (SC-2082) | 2026-11-20 | New manual E2E workflow and Netbird action (see item 9); advisory. | High |
| #1653 (INFRA-1895) | 2026-11-02 | vault-proxy moved into the monorepo, with its own CI path filter and deploy workflows. | High |
| #1803 (SC-2062) | 2026-11-19 | PHP base image raised to 8.4.28 (local Docker rebuild needed). | High |
| #1876 (SC-2079) | 2026-11-27 | Timetable CI tests now wait for this branch's core and timetable images. | High |

Not contribution rules, left out of the table: #1857 (one-off ops check workflow, manual), #1751 (preprod
echo-server image override), #1661 and #1708 (iOS build workflow), #1683 (dependency override bump), #1418
(new frontend dependency), and the bot docs PRs #1706, #1840, #1873.
