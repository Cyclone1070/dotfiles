# dsh-notification

Browser task notifications for DeepSeek Harness Web. It tells you when the agent
needs you, or has actually finished — and it never fires while delegated
background work is still running.

Everything happens in the browser: OS notifications through the Web Notifications
API, optional WebAudio cues, and a tab-title marker. No native helper
(`osascript`, PowerShell, `notify-send`), no subprocess, no webhook, no network
egress. It works wherever the DSH web UI runs, on macOS, Linux and Windows alike.

## Behaviours

| Event | Behaviour |
|---|---|
| Agent needs you (approval, question, plan review) | OS notification plus an in-page card that stays until you handle it. Click either → focus the page and open that session. |
| Turn finished | OS notification with the session label (and workspace prefix if enabled). |
| Session yielded to background work | **No notification.** This is the point of the plugin. |
| A delegated subagent finishes | No notification (subagent sessions are not notification subjects). |

Three attention channels, independently switchable: the system notification, a
short sound cue (distinct sequences for needs-input vs finished), and a `●` tab
title marker held while input is pending.

## The completion rule

`running: true → false` is not an ending. A session yields its turn when it hands
work to background subagents or a workflow. Three gates stand between a stop edge
and a notification:

1. **Live background work holds it.** If the session still has running child
   sessions (recursively, grandchildren included), the notice is held until they
   drain.
2. **Shell jobs cannot swallow it.** Only delegated *sessions* count as
   background work. A dev server you left running in a background job is not a
   session, so it can never hold a notification forever.
3. **Grace re-read.** After `DONE_GRACE_MS` (2.5 s) the decision is re-evaluated
   against fresh state. If the session resumed in the meantime, that yield was
   not an ending and nothing is sent.

A pending interaction always wins: no "finished" notice is emitted while
something is waiting on you.

## Settings

One page in the official settings panel (Settings → Notifications). Everything
fits on one screen, and each row says what it does:

| Row | Meaning |
|---|---|
| Turn notifications on | Master switch |
| When the agent needs an answer or an approval | Approval, question or plan review |
| When a turn finishes | A turn really ended |
| Stay quiet while background subagents are still running | A turn that handed work to a subagent has not finished |
| Play a sound | Cue alongside the notice |
| Send notifications | Always / only when the page is hidden / never |

Plus the browser permission state, an **Allow notifications** button and a
**Send a test** button. Settings live in `localStorage` under
`dsh.notification.settings.v1`.

Fixed behaviours with no row of their own: the cue volume, the `●` tab-title
marker while input is pending, and needs-input notices that stay on screen until
handled.

### Notification shape

Status first, session second — no workspace prefix, no filler text:

```
Needs your answer
DSH mermaid diagram…
```

```
Finished
DSH mermaid diagram…
```

### When a notice does not appear

`window.__dshNotification.log()` returns the last 25 delivery attempts, each with
`title`, `body`, `delivered` and a `reason` when it was not:

```js
__dshNotification.log()
// [{ cue: 'input', title: 'Needs your answer', delivered: false,
//    reason: 'permission:default' }, …]
```

A cue still plays when the browser *cannot* deliver (no permission yet, or no
support at all) so the moment is not lost; nothing plays when you asked for
silence through the send mode.

Whatever the reason, the notice's title and session are also shown as a card in
the bottom-right corner of the page, which stays until you click it (it opens the
session) or the interaction is answered. That card is the fallback channel: it
cannot be blocked by the browser, so a cue never plays with nothing on screen.

A notice the OS *accepts* can still be swallowed — Focus mode, Chrome's quieter
messaging, or a same-tag replacement. So a needs-input alert also leaves the card
behind whenever the page is not on screen (`document.hidden`), which is exactly
when a missed alert would otherwise go unnoticed. While you are looking at the
page, the notice is enough and no card appears.

## Permission

Chrome only grants notifications from a user gesture, and a prompt that gets
dismissed leaves the answer at `default` — which used to mean every later alert
was a cue with no notice. The plugin therefore asks again on a later gesture, at
most once every five minutes, and stops once the answer is `granted` or `denied`.
If the answer is `denied`, allow notifications for the DSH origin in
`chrome://settings/content/notifications`; the in-page card works either way.

## Install

Installed into a profile by absolute path, because the npm name
`dsh-notification` belongs to an unrelated package:

```sh
# from the profile, pointing at this checkout
dsh plugin --profile web add link:/path/to/dotfiles/dsh/plugins/dsh-notification
```

The profile records it as a local link; reload the page afterwards.

## Signals used

All public client contracts (`dsh 0.1.7-rc.2`):

- `ctx.sessions.list` — `ObservableSnapshot<SessionListState>`: `byId` rows with
  `displayTitle`, `title`, `cwd`, `parentId`, `origin`, `running`.
- `ctx.uiSession.sessionStatus` — `HostObservable<Map<SessionId, SessionStatus>>`:
  `running`, `pendingInteraction {key, kind}`, `completionUnread`.
- `ctx.slots.inject('settings.section')` + `ctx.slots.register(...)` for the page.

If `sessionStatus` is unavailable the engine falls back to
`uiSession.pendingInteractions` (needs-input only) and logs a warning rather than
failing the fiber.

## Activation contract (do not regress)

The client runner hands `apply` a whitelisting façade, and this plugin broke the
entire page boot twice before the rules were pinned down:

| Rule | Why it matters here |
|---|---|
| `ctx.<service>` is legal **only** for services listed in this module's `inject` | An undeclared read throws → fiber `FAILED` → `web boot: 1 entry did not activate — dsh-notification: failed`, and the page shows nothing |
| `ctx.get(name)` is the ungated optional lookup | Used for `sessions`, `uiSession`, `uiWorkspace` |
| `slots` **must** be declared and read as `ctx.slots` | It is the one service `ctx.get` cannot reach from a client plugin (verified in the browser: `ctx.get('slots')` is `undefined`, `ctx.slots` works) |
| Declaring a service you never read directly is a risk | A declared-but-unresolvable service parks the fiber — also a boot failure |
| Callable verbs are `effect`, `on`, `once`, `provide`, timers | Timer verbs additionally require `inject: ['timer']` |

Store **availability** is a runtime concern: the engine retries wiring every
250 ms (up to 40 attempts), re-wires on `connection/reset`, and re-attaches when a
store object is replaced. `window.__dshNotification.diagnostics()` reports
`react`, `slots`, `settingsRegistered` and the wiring state of both stores.

`test/activation.test.mjs` drives the real bundle through a harness that enforces
the façade rules above, including the "`slots` hidden from `ctx.get`" case.

If a future change ever breaks the page boot again, the escape hatch is:

```sh
dsh plugin --profile web remove dsh-notification   # then reload
```

## Known limits

- **No error-specific notice yet.** The global client stores expose stop and
  pending facts but no per-session agent error (`lastAgentError` lives on a
  retained per-session snapshot). A turn that errors still produces the ordinary
  finished notice instead of a distinct "failed" one.
- **The page must stay open.** There is no service worker, so nothing is
  delivered once the tab is closed.
- **iOS/Android WebViews cannot show these notifications** (local
  `new Notification()` needs a service-worker push there). The settings page
  reports the permission state, and the in-page card still appears.
- **The first sound after a page load may be silent** until you interact with the
  page once — browser autoplay policy unlocks the audio context on the first
  gesture.

## Development

```sh
node test/predicate.test.mjs   # pure decision core: gating, grace, settings
node --check lib/client.js     # no build step: lib/ IS the shipped artifact
```

`lib/client.js` is hand-written and loaded directly by `dsh-client-modules`; there
is no bundler in this repo and nothing to compile.

## License

MIT. The completion-gating approach was informed by `dsh-notify-xc` (MIT) and the
WebAudio cue approach by `dsh-notify-me` (MIT); the implementation here is ours.
