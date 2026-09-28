/**
 * dsh-notification — browser half (hand-written bundle, no build step).
 *
 * WHAT IT DOES
 *   OS-level notifications through the browser Notification API when the agent
 *   needs the user (approval / question / plan review) or has actually finished
 *   a turn. Works on every platform the browser runs on: no osascript, no
 *   PowerShell, no notify-send, no subprocess, no network egress.
 *
 * DESIGN RULES THAT MATTER
 *   1. `running: true -> false` is not an ending. A session yields its turn when
 *      it hands work to background subagents/workflows. Those yields are held
 *      until the delegated work drains (settings.waitForBackground).
 *   2. Only delegated *sessions* count as background work. Background shell jobs
 *      (a dev server you left running) are not sessions, so they can never
 *      swallow a notification.
 *   3. After a stop edge the decision is re-read once after DONE_GRACE_MS: if
 *      the session resumed in the meantime, that yield was not an ending.
 *   4. A pending interaction owns the moment: no "finished" notice is emitted
 *      while something is waiting on the user.
 *
 * SIGNALS (public client contracts on dsh 0.1.7-rc.2)
 *   ctx.get('sessions').list           ObservableSnapshot<SessionListState>
 *                                      -> byId rows {id, displayTitle, title,
 *                                         cwd, parentId, origin, running}
 *   ctx.get('uiSession').sessionStatus HostObservable<Map<SessionId, SessionStatus>>
 *                                      -> {running, pendingInteraction{key,kind},
 *                                         completionUnread}
 *   ctx.slots.inject('settings.section') + ctx.slots.register(...) for the page
 *
 * SERVICE ACCESS RULE (learned by breaking the page twice)
 *   The client runner hands `apply` a whitelisting façade:
 *     - `ctx.<service>` is legal ONLY for services listed in this module's
 *       `inject`; anything else throws, the fiber goes FAILED, and the web boot
 *       aborts with "web boot: 1 entry did not activate".
 *     - `ctx.get(name)` is the ungated optional lookup — used here for
 *       `sessions`, `uiSession` and `uiWorkspace`.
 *     - `slots` cannot be reached via ctx.get at all, so it IS declared in
 *       `inject` and read as a direct property.
 *   Allowed ctx verbs: effect, on, once, provide, timers.
 *
 * KNOWN LIMITS (see README)
 *   - No error-specific notice yet: the global client stores expose stop and
 *     pending facts but no per-session agent error; an errored turn still
 *     produces the ordinary finished notice.
 *   - The page must stay open; there is no service worker.
 */
window.__ModuleLoader__.load({id:"dsh-notification",factory:(require)=>{var module={exports:{}};var exports=module.exports;
'use strict';

/* ────────────────────────────── constants ────────────────────────────── */

var SETTINGS_KEY = 'dsh.notification.settings.v1';
var DONE_GRACE_MS = 2500;
var WIRE_ATTEMPTS = 40;
var WIRE_INTERVAL_MS = 250;
// A dismissed permission prompt leaves `permission` at 'default' forever, so the
// gesture listener keeps asking — but slowly enough not to nag.
var PERMISSION_RETRY_MS = 300000;
var MAX_WALK = 200;
// Chrome keys a page's notifications by TAG. This plugin's needs-input tag was
// stable across page loads (the interaction counter restarts at 1), so a notice
// still sitting in the notification centre could be replaced — silently, with no
// banner — leaving the cue as the only sign. One id per page load keeps every
// notice distinct while intra-page replacement still works.
var RUN_ID = Math.random().toString(36).slice(2, 8);
var testSeq = 0;
var CUES = {
  input: [[880, 0, 0.14], [1174, 0.16, 0.14], [1568, 0.32, 0.20]],
  done: [[784, 0, 0.15], [1046, 0.18, 0.24]]
};
var DEFAULTS = {
  enabled: true,
  input: true,          // the agent needs an answer or an approval
  done: true,           // a turn finished
  sound: true,
  waitForBackground: true,
  system: 'always',     // off | background | always
  // Fixed behaviours, kept as data so the engine stays explicit but no longer
  // worth a settings row: cue volume and the tab-title marker while input is
  // pending. Needs-input notices no longer ask the OS to keep them on screen:
  // that flag was the one difference from the finished notice, which is the one
  // that demonstrably reaches the screen. The in-page card is what persists.
  volume: 0.5,
  titleMarker: true
};

var STRINGS = {
  en: {
    settingsLabel: 'Notifications',
    heading: 'Notifications',
    lead: 'A notification when the agent stops and needs you — or actually finishes.',
    enabled: 'Turn notifications on',
    input: 'When the agent needs an answer or an approval',
    done: 'When a turn finishes',
    waitForBackground: 'Stay quiet while background subagents are still running',
    waitForBackgroundHint: 'A turn that hands work to a subagent has not finished yet.',
    sound: 'Play a sound',
    system: 'Send notifications',
    systemAlways: 'Always',
    systemBackground: 'Only when the page is hidden',
    systemOff: 'Never',
    permission: 'Browser permission',
    granted: 'granted',
    denied: 'denied',
    prompt: 'not granted yet',
    unsupported: 'not supported in this browser',
    request: 'Allow notifications',
    test: 'Send a test',
    inPage: 'Until then, alerts appear in the corner of this page.',
    inPageOff: 'Alerts appear in the corner of this page.',
    testTitle: 'Notifications are on',
    testBody: 'This is what an alert looks like.',
    needsAnswer: 'Needs your answer',
    needsApproval: 'Needs your approval',
    needsReview: 'Plan ready for review',
    finished: 'Finished'
  },
  zh: {
    settingsLabel: '任务通知',
    heading: '任务通知',
    lead: 'agent 停下来需要你操作、或真的跑完时，给你一条通知。',
    enabled: '开启通知',
    input: '需要你回答或批准时',
    done: '一轮任务完成时',
    waitForBackground: '后台子代理还在跑时不打扰',
    waitForBackgroundHint: '把活交给子代理的回合并没有结束。',
    sound: '播放提示音',
    system: '发送通知',
    systemAlways: '始终',
    systemBackground: '仅页面隐藏时',
    systemOff: '从不',
    permission: '浏览器权限',
    granted: '已授权',
    denied: '已拒绝',
    prompt: '尚未授权',
    unsupported: '此浏览器不支持',
    request: '允许通知',
    test: '发一条测试',
    inPage: '在此之前，提醒会显示在页面角上。',
    inPageOff: '提醒会显示在页面角上。',
    testTitle: '通知已开启',
    testBody: '通知长这样。',
    needsAnswer: '需要你回答',
    needsApproval: '需要你批准',
    needsReview: '计划待审阅',
    finished: '已完成'
  }
};

/* ───────────────────────── pure decision core ─────────────────────────
 * Everything below this marker and above `RUNTIME` is pure: no DOM, no cordis,
 * no timers. test/predicate.test.mjs loads this module and exercises exactly
 * these functions.
 */

/**
 * Does this session still own live delegated work?
 *
 * Walks child *sessions* (rows whose parentId points here), recursively through
 * grandchildren. Only sessions count: a background shell job is not a session,
 * so a dev server left running cannot hold a notification forever.
 *
 * @param byId - SessionListState.byId, or null.
 * @param sessionId - parent session identity.
 * @returns true while any descendant session is running.
 */
function hasLiveBackgroundWork(byId, sessionId) {
  if (!byId || typeof sessionId !== 'string') return false;
  var queue = [sessionId];
  var seen = Object.create(null);
  var visited = 0;
  while (queue.length > 0 && visited < MAX_WALK) {
    var id = queue.shift();
    if (seen[id] === true) continue;
    seen[id] = true;
    visited += 1;
    for (var key in byId) {
      if (!Object.prototype.hasOwnProperty.call(byId, key)) continue;
      var row = byId[key];
      if (!row || row.parentId !== id) continue;
      if (row.running === true) return true;
      queue.push(key);
    }
  }
  return false;
}

/**
 * One pure completion decision for one session on one evaluation tick.
 *
 * @param s - {awaiting, held, hasLiveBackgroundWork, hasPendingInteraction,
 *             graceElapsed, nowRunning}
 * @returns 'notify' (fire the finished notice), 'hold' (keep the decision
 *          pending, arm the grace re-read) or 'clear' (drop any pending state).
 */
function decideDone(s) {
  if (s.hasPendingInteraction) return 'clear';   // the needs-input alarm owns this moment
  if (s.nowRunning === true) return 'clear';     // it resumed: whatever we held is moot
  if (s.held === true) return s.hasLiveBackgroundWork ? 'hold' : 'notify';
  if (s.awaiting !== true) return 'clear';
  if (s.hasLiveBackgroundWork) return 'hold';
  return s.graceElapsed === true ? 'notify' : 'hold';
}

/**
 * Merge stored settings over the defaults, dropping anything malformed.
 * @param raw - parsed localStorage value, or anything else.
 * @returns a complete, validated settings object.
 */
function normalizeSettings(raw) {
  var out = {};
  var key;
  for (key in DEFAULTS) out[key] = DEFAULTS[key];
  if (!raw || typeof raw !== 'object') return out;
  for (key in DEFAULTS) {
    if (!Object.prototype.hasOwnProperty.call(raw, key)) continue;
    var value = raw[key];
    if (key === 'volume') {
      var volume = Number(value);
      if (isFinite(volume)) out.volume = Math.min(1, Math.max(0, volume));
    } else if (key === 'system') {
      if (value === 'off' || value === 'background' || value === 'always') out.system = value;
    } else if (typeof value === 'boolean') {
      out[key] = value;
    }
  }
  return out;
}

/* ─────────────────────────────── runtime ─────────────────────────────── */

var React = null;
var reactError = null;
try { React = require('react'); } catch (error) { reactError = String((error && error.message) || error); }

/** Language dictionary following the document/browser language. */
function dictionary() {
  try {
    var lang = (document.documentElement && document.documentElement.lang) || navigator.language || 'en';
    return String(lang).toLowerCase().indexOf('zh') === 0 ? STRINGS.zh : STRINGS.en;
  } catch (error) {
    return STRINGS.en;
  }
}

function t(key) {
  var dict = dictionary();
  return dict[key] || STRINGS.en[key] || key;
}

function basename(path) {
  var parts = String(path || '').split(/[\\/]/).filter(Boolean);
  return parts.length > 0 ? parts[parts.length - 1] : String(path || '');
}

function loadSettings() {
  try {
    var raw = window.localStorage.getItem(SETTINGS_KEY);
    return normalizeSettings(raw ? JSON.parse(raw) : null);
  } catch (error) {
    return normalizeSettings(null);
  }
}

function saveSettings(settings) {
  try { window.localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings)); } catch (error) { /* ignore */ }
}

function notificationCtor() {
  try {
    if (typeof window.Notification === 'function') return window.Notification;
  } catch (error) { /* ignore */ }
  return null;
}

function permissionState() {
  var Ctor = notificationCtor();
  if (!Ctor) return 'unsupported';
  return Ctor.permission || 'default';
}

function requestPermission() {
  var Ctor = notificationCtor();
  if (!Ctor || typeof Ctor.requestPermission !== 'function') return Promise.resolve('unsupported');
  try { return Ctor.requestPermission(); } catch (error) { return Promise.resolve('denied'); }
}

/** WebAudio cues. The context unlocks on the first user gesture (autoplay policy). */
function createAudio(readSettings) {
  var audio = null;

  function unlock() {
    try {
      if (!audio) {
        var Ctor = window.AudioContext || window.webkitAudioContext;
        if (!Ctor) return;
        audio = new Ctor();
      }
      if (audio.state === 'suspended') audio.resume().catch(function () {});
    } catch (error) { /* ignore */ }
  }

  function tone(frequency, delay, duration, volume) {
    if (!audio || audio.state !== 'running') return;
    try {
      var start = audio.currentTime + delay;
      var osc = audio.createOscillator();
      var gain = audio.createGain();
      osc.type = 'sine';
      osc.frequency.value = frequency;
      gain.gain.setValueAtTime(0.0001, start);
      gain.gain.exponentialRampToValueAtTime(Math.max(0.0002, volume), start + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
      osc.connect(gain).connect(audio.destination);
      osc.start(start);
      osc.stop(start + duration + 0.05);
    } catch (error) { /* ignore */ }
  }

  return {
    unlock: unlock,
    play: function (name) {
      var settings = readSettings();
      if (!settings.enabled || !settings.sound) return;
      unlock();
      var sequence = CUES[name] || CUES.done;
      for (var i = 0; i < sequence.length; i += 1) {
        tone(sequence[i][0], sequence[i][1], sequence[i][2], settings.volume * 0.6);
      }
    }
  };
}

/**
 * Tab-title marker with strict ownership: we only ever restore a title we set
 * ourselves, and we re-base if the app rewrites the title while we hold it.
 */
function createTitleMarker() {
  var count = 0;
  var base = null;
  var applied = null;

  function sync() {
    try {
      if (count > 0) {
        if (applied === null || document.title !== applied) base = document.title;
        applied = '\u25CF ' + String(base === null ? '' : base);
        if (document.title !== applied) document.title = applied;
        return;
      }
      if (applied !== null) {
        if (document.title === applied) document.title = base === null ? '' : base;
        applied = null;
        base = null;
      }
    } catch (error) { /* ignore */ }
  }

  return {
    set: function (pending) { count = pending; sync(); },
    clear: function () { count = 0; sync(); }
  };
}

/**
 * In-page alert — the channel that cannot be taken away.
 *
 * Every reason the desktop notice can fail is outside our control: no support,
 * permission never granted, the constructor throwing, the OS swallowing the
 * banner. A cue with nothing visible is the worst thing this plugin can do —
 * the alarm rings and there is nothing to act on — so whenever the notice is
 * not shown, this card carries the same facts instead.
 */
function createBanner() {
  var host = null;
  var cards = Object.create(null);

  function ensureHost() {
    if (host && host.parentNode) return host;
    host = document.createElement('div');
    host.setAttribute('data-dsh-notification-banners', '');
    host.style.cssText = 'position:fixed;right:16px;bottom:16px;z-index:2147483000;'
      + 'display:flex;flex-direction:column;gap:8px;pointer-events:none;';
    document.body.appendChild(host);
    return host;
  }

  function dismiss(key) {
    var card = cards[key];
    if (!card) return;
    delete cards[key];
    try { card.remove(); } catch (error) { /* ignore */ }
  }

  return {
    show: function (options) {
      try {
        dismiss(options.key);
        var card = document.createElement('div');
        card.setAttribute('data-dsh-notification-banner', options.key);
        card.style.cssText = 'pointer-events:auto;cursor:pointer;max-width:320px;'
          + 'background:#1f2328;color:#fff;border-radius:10px;padding:10px 12px;'
          + 'box-shadow:0 6px 20px rgba(0,0,0,.28);display:flex;gap:10px;align-items:flex-start;'
          + 'font:13px/18px system-ui,-apple-system,"Segoe UI",sans-serif;';
        var text = document.createElement('div');
        text.style.cssText = 'flex:1 1 auto;';
        var title = document.createElement('div');
        title.style.cssText = 'font-weight:600;';
        title.textContent = options.title;
        var body = document.createElement('div');
        body.style.cssText = 'opacity:.72;margin-top:2px;';
        body.textContent = options.body || '';
        text.appendChild(title);
        if (options.body) text.appendChild(body);
        var close = document.createElement('button');
        close.type = 'button';
        close.setAttribute('aria-label', 'Dismiss');
        close.style.cssText = 'background:none;border:0;color:#fff;opacity:.55;cursor:pointer;'
          + 'font-size:15px;line-height:15px;padding:0 2px;';
        close.textContent = '\u00D7';
        close.onclick = function (event) {
          event.stopPropagation();
          dismiss(options.key);
        };
        card.onclick = function () {
          dismiss(options.key);
          if (typeof options.onOpen === 'function') options.onOpen();
        };
        card.appendChild(text);
        card.appendChild(close);
        ensureHost().appendChild(card);
        cards[options.key] = card;
        return true;
      } catch (error) {
        return false;
      }
    },
    dismiss: dismiss,
    clearAll: function () {
      for (var key in cards) dismiss(key);
    }
  };
}

/* ──────────────────────────────── engine ─────────────────────────────── */
function createEngine(ctx) {
  var settings = loadSettings();
  var prevById = Object.create(null);
  var awaitingDone = Object.create(null);
  var held = Object.create(null);
  var grace = Object.create(null);        // id -> 'armed' | 'fired'
  var graceTimers = Object.create(null);
  var firedKeys = Object.create(null);
  var settingsListeners = [];
  var disposers = [];
  var currentList = null;
  var currentStatus = null;
  var wireAttempts = 0;
  var audio = createAudio(function () { return settings; });
  var marker = createTitleMarker();
  var banner = createBanner();

  function emitSettings() {
    for (var i = 0; i < settingsListeners.length; i += 1) {
      try { settingsListeners[i](); } catch (error) { /* ignore */ }
    }
  }

  function readList() {
    try {
      var service = ctx.get('sessions');
      if (service && service.list && typeof service.list.getSnapshot === 'function') {
        var snapshot = service.list.getSnapshot();
        if (snapshot && snapshot.byId) return snapshot;
      }
    } catch (error) {
      console.warn('[dsh-notification] session list read failed:', error);
    }
    return null;
  }

  function readStatus() {
    var out = new Map();
    try {
      var ui = ctx.get('uiSession');
      var source = ui && ui.sessionStatus;
      if (source && typeof source.getSnapshot === 'function') {
        var snapshot = source.getSnapshot();
        if (snapshot && typeof snapshot.forEach === 'function') {
          snapshot.forEach(function (value, key) { out.set(key, value || {}); });
          return out;
        }
      }
      var pending = ui && ui.pendingInteractions;
      if (pending && typeof pending.getSnapshot === 'function') {
        var pendingSnapshot = pending.getSnapshot();
        if (pendingSnapshot && typeof pendingSnapshot.forEach === 'function') {
          pendingSnapshot.forEach(function (value, key) {
            out.set(key, { running: undefined, pendingInteraction: value, completionUnread: false });
          });
        }
      }
    } catch (error) {
      console.warn('[dsh-notification] status read failed:', error);
    }
    return out;
  }

  function armGrace(id) {
    if (grace[id] === 'armed' || grace[id] === 'fired') return;
    grace[id] = 'armed';
    graceTimers[id] = window.setTimeout(function () {
      graceTimers[id] = null;
      grace[id] = 'fired';
      evaluate();
    }, DONE_GRACE_MS);
  }

  function clearPending(id) {
    delete awaitingDone[id];
    delete held[id];
    delete grace[id];
    if (graceTimers[id]) {
      window.clearTimeout(graceTimers[id]);
      graceTimers[id] = null;
    }
  }

  function labelOf(id, row, byId) {
    var target = row || (byId ? byId[id] : null);
    if (target && target.displayTitle) return target.displayTitle;
    if (target && target.title) return target.title;
    if (target && target.cwd) return basename(target.cwd);
    return String(id).slice(0, 8);
  }

  /** Ring buffer of the last push attempts, for `__dshNotification.log()`. */
  var attempts = [];
  function recordAttempt(entry) {
    attempts.push(entry);
    if (attempts.length > 25) attempts.shift();
  }

  function systemAllowed() {
    if (!settings.enabled) return false;
    if (settings.system === 'off') return false;
    if (settings.system === 'background') {
      try { return document.hidden === true; } catch (error) { return true; }
    }
    return true;
  }

  function focusAndOpen(id) {
    try { window.focus(); } catch (error) { /* ignore */ }
    try {
      var ui = ctx.get('uiWorkspace');
      if (ui && typeof ui.openSession === 'function') ui.openSession(id);
    } catch (error) {
      console.warn('[dsh-notification] open session failed:', error);
    }
  }

  function push(options) {
    var entry = {
      at: new Date().toISOString().slice(11, 19),
      cue: options.cue,
      title: options.title,
      body: options.body || '',
      delivered: false,
      reason: null
    };
    if (!systemAllowed()) {
      // Silence the user explicitly asked for: no sound either — a cue with no
      // notice is what made this feel broken.
      entry.reason = settings.system === 'background'
        ? 'mode:background (page ' + (document.hidden ? 'hidden' : 'visible') + ')'
        : 'mode:' + settings.system;
      recordAttempt(entry);
      return null;
    }
    var Ctor = notificationCtor();
    if (!Ctor) {
      // Involuntary: the browser cannot show notices at all. Keep the audible
      // cue so the moment is not lost, and put the same facts on screen.
      audio.play(options.cue);
      return fallback(options, entry, 'notifications unsupported in this browser');
    }
    if (Ctor.permission !== 'granted') {
      // Involuntary too: permission is asked on the first page gesture, so this
      // is the "has not clicked anywhere yet" window, and also every push after
      // a prompt the person dismissed or Chrome refused to show.
      audio.play(options.cue);
      return fallback(options, entry, 'permission:' + Ctor.permission);
    }
    audio.play(options.cue);
    try {
      var notice = new Ctor(options.title, {
        body: options.body || '',
        tag: options.tag,
        requireInteraction: options.requireInteraction === true,
        silent: true,                       // our own cue is the sound
        icon: '/favicon.svg'
      });
      notice.onclick = function () {
        focusAndOpen(options.id);
        try { notice.close(); } catch (error) { /* ignore */ }
      };
      entry.delivered = true;
      recordAttempt(entry);
      // A notice the OS accepts can still be swallowed (Focus, quieter
      // messaging, a silent replacement). When the page is not on screen that
      // leaves nothing to find, so leave the card behind as the receipt.
      if (options.backgroundCard === true && document.hidden) showCard(options);
      return notice;
    } catch (error) {
      console.warn('[dsh-notification] notification failed:', error);
      return fallback(options, entry, 'threw: ' + String((error && error.message) || error));
    }
  }

  /**
   * The desktop notice did not happen: log the reason and show the in-page card.
   * A cue never plays without something visible next to it.
   */
  function fallback(options, entry, reason) {
    entry.reason = reason;
    recordAttempt(entry);
    showCard(options);
    return null;
  }

  /** The in-page card, keyed so a second event for the same session replaces it. */
  function showCard(options) {
    banner.show({
      key: options.bannerKey || options.tag || 'dsh-notification-notice',
      title: options.title,
      body: options.body,
      onOpen: function () { focusAndOpen(options.id); }
    });
  }

  /** What the agent is waiting for — used as the notification TITLE. */
  function kindBody(kind) {
    if (kind === 'approval') return t('needsApproval');
    if (kind === 'question') return t('needsAnswer');
    if (kind === 'plan-review' || kind === 'plan') return t('needsReview');
    return t('needsAnswer');
  }

  function evaluate() {
    var list = readList();
    var byId = (list && list.byId) || {};
    var status = readStatus();
    var ids = [];
    var seen = Object.create(null);

    status.forEach(function (_value, id) {
      if (seen[id] !== true) { seen[id] = true; ids.push(id); }
    });
    for (var key in byId) {
      if (Object.prototype.hasOwnProperty.call(byId, key) && seen[key] !== true) {
        seen[key] = true;
        ids.push(key);
      }
    }

    var pendingCount = 0;

    for (var i = 0; i < ids.length; i += 1) {
      var id = ids[i];
      var row = byId[id] || null;
      var state = status.get(id) || null;
      var interaction = state && state.pendingInteraction ? state.pendingInteraction : null;
      var running = state && typeof state.running === 'boolean'
        ? state.running
        : !!(row && row.running === true);
      var current = {
        running: running,
        completionUnread: !!(state && state.completionUnread === true),
        pendingKey: interaction && typeof interaction.key === 'string' ? interaction.key : null
      };
      var previous = Object.prototype.hasOwnProperty.call(prevById, id) ? prevById[id] : null;
      var isSubagent = !!(row && row.origin === 'subagent');

      if (current.pendingKey) pendingCount += 1;

      // 1) a new pending interaction -> the needs-input alarm
      if (current.pendingKey && (!previous || previous.pendingKey !== current.pendingKey) && firedKeys[current.pendingKey] !== true) {
        firedKeys[current.pendingKey] = true;
        if (!isSubagent && settings.input) {
          push({
            id: id,
            cue: 'input',
            tag: 'dsh-notification-input-' + RUN_ID + '-' + current.pendingKey,
            bannerKey: 'input:' + id,
            backgroundCard: true,
            // Status first (that is what a notification is FOR), session second.
            title: kindBody(interaction && interaction.kind),
            body: labelOf(id, row, byId)
          });
        }
      } else if (!current.pendingKey) {
        // Answered, rejected or gone: the in-page card has served its purpose.
        banner.dismiss('input:' + id);
      }
      // Running again means the previous round's business is settled.
      if (current.running === true) banner.dismiss('done:' + id);

      if (isSubagent) {
        prevById[id] = current;
        continue;
      }

      // 2) a stop edge arms a completion decision (a yield is not an ending)
      var stopEdge = !!previous && previous.seeded === true &&
        ((previous.running === true && current.running !== true) ||
         (previous.completionUnread !== true && current.completionUnread === true));
      if (stopEdge) awaitingDone[id] = true;

      var liveWork = settings.waitForBackground && hasLiveBackgroundWork(byId, id);
      var verdict = decideDone({
        awaiting: awaitingDone[id] === true,
        held: held[id] === true,
        hasLiveBackgroundWork: liveWork,
        hasPendingInteraction: !!current.pendingKey,
        graceElapsed: grace[id] === 'fired',
        nowRunning: current.running
      });

      if (verdict === 'clear') {
        clearPending(id);
      } else if (verdict === 'hold') {
        awaitingDone[id] = true;
        if (liveWork) held[id] = true;
        else armGrace(id);
      } else if (verdict === 'notify') {
        clearPending(id);
        if (settings.done) {
          push({
            id: id,
            cue: 'done',
            tag: 'dsh-notification-done-' + RUN_ID + '-' + id,
            bannerKey: 'done:' + id,
            title: t('finished'),
            body: labelOf(id, row, byId),
            requireInteraction: false
          });
        }
      }

      current.seeded = true;
      prevById[id] = current;
    }

    marker.set(settings.titleMarker ? pendingCount : 0);
  }

  function resetBaselines() {
    wire();
    prevById = Object.create(null);
    awaitingDone = Object.create(null);
    held = Object.create(null);
    for (var id in graceTimers) {
      if (graceTimers[id]) window.clearTimeout(graceTimers[id]);
    }
    graceTimers = Object.create(null);
    grace = Object.create(null);
    firedKeys = Object.create(null);
    marker.clear();
    evaluate();
  }

  /**
   * Attach to the stores, retrying while they are not there yet.
   *
   * This plugin must never gate its own activation on client service keys: a key
   * that never registers leaves the loader entry inactive, and the web boot audit
   * then reports the plugin as failed — which takes the whole page down with it.
   * Load ORDER is declared by `dsh.client.inject` in package.json; store
   * AVAILABILITY is handled here, at runtime.
   */
  function wire() {
    var attached = false;
    var sessions = ctx.get('sessions');
    var list = sessions && sessions.list;
    if (list && typeof list.subscribe === 'function' && list !== currentList) {
      currentList = list;
      disposers.push(list.subscribe(evaluate));
      attached = true;
    }
    var ui = ctx.get('uiSession');
    var source = (ui && ui.sessionStatus) || (ui && ui.pendingInteractions);
    if (source && typeof source.subscribe === 'function' && source !== currentStatus) {
      currentStatus = source;
      disposers.push(source.subscribe(evaluate));
      attached = true;
    }

    var complete = !!currentList && !!currentStatus;
    if (!complete && wireAttempts < WIRE_ATTEMPTS) {
      wireAttempts += 1;
      var timer = window.setTimeout(wire, WIRE_INTERVAL_MS);
      disposers.push(function () { window.clearTimeout(timer); });
    } else if (!complete) {
      console.warn('[dsh-notification] session stores never appeared; notifications are off');
    }
    if (attached) evaluate();
  }

  function start() {
    wire();

    try {
      if (typeof ctx.on === 'function') ctx.on('connection/reset', resetBaselines);
    } catch (error) { /* ignore */ }

    // Browser permission may only be requested from a user gesture — and a
    // prompt that is dismissed leaves `permission` at 'default' for good, so
    // asking exactly once means every later alarm becomes a cue with no notice.
    // Unlock audio on every gesture; re-ask while the answer is still 'default'.
    var lastAsk = 0;
    var gesture = function () {
      audio.unlock();
      if (permissionState() !== 'default') return;
      var now = Date.now();
      if (now - lastAsk < PERMISSION_RETRY_MS) return;
      lastAsk = now;
      var result = requestPermission();
      if (result && typeof result.then === 'function') result.then(emitSettings, emitSettings);
    };
    window.addEventListener('pointerdown', gesture, true);
    window.addEventListener('keydown', gesture, true);
    disposers.push(function () {
      window.removeEventListener('pointerdown', gesture, true);
      window.removeEventListener('keydown', gesture, true);
    });

    evaluate();
  }

  function destroy() {
    for (var i = 0; i < disposers.length; i += 1) {
      try { disposers[i](); } catch (error) { /* ignore */ }
    }
    disposers = [];
    for (var id in graceTimers) {
      if (graceTimers[id]) window.clearTimeout(graceTimers[id]);
    }
    graceTimers = Object.create(null);
    marker.clear();
    banner.clearAll();
  }

  return {
    start: start,
    destroy: destroy,
    evaluate: evaluate,
    wired: function () { return { list: currentList !== null, status: currentStatus !== null }; },
    log: function () { return attempts.slice(); },
    settings: function () { return settings; },
    setSetting: function (key, value) {
      var patch = {};
      patch[key] = value;
      settings = normalizeSettings(Object.assign({}, settings, patch));
      saveSettings(settings);
      marker.set(settings.titleMarker ? markerCount() : 0);
      emitSettings();
    },
    subscribeSettings: function (listener) {
      settingsListeners.push(listener);
      return function () {
        var index = settingsListeners.indexOf(listener);
        if (index >= 0) settingsListeners.splice(index, 1);
      };
    },
    permission: permissionState,
    requestPermission: function () {
      var result = requestPermission();
      if (result && typeof result.then === 'function') result.then(emitSettings, emitSettings);
      return result;
    },
    test: function (mode) {
      // 'banner' exercises the in-page card on its own — the path taken when the
      // desktop notice cannot be shown (no permission, no support, or a throw).
      if (mode === 'banner') {
        return banner.show({
          key: 'dsh-notification-test',
          title: t('testTitle'),
          body: t('testBody'),
          onOpen: function () { focusAndOpen(null); }
        }) ? 'banner' : 'banner failed';
      }
      var Ctor = notificationCtor();
      if (!Ctor) return 'unsupported';
      if (Ctor.permission !== 'granted') return 'permission:' + Ctor.permission;
      // `mode: true` mirrors the needs-input notice as it was when it asked the OS
      // to keep it on screen; no argument mirrors the finished notice, which is
      // the one that reaches the screen. Running both A/Bs the flag in one page.
      // Every test gets a fresh tag, so nothing is ever a silent replacement.
      testSeq += 1;
      push({
        id: null,
        cue: 'input',
        tag: 'dsh-notification-test-' + RUN_ID + '-' + String(testSeq),
        title: t('testTitle'),
        body: t('testBody'),
        requireInteraction: mode === true
      });
      return mode === true ? 'sent (requireInteraction: true)' : 'sent';
    }
  };

  function markerCount() {
    var count = 0;
    for (var id in prevById) {
      if (prevById[id] && prevById[id].pendingKey) count += 1;
    }
    return count;
  }
}

/* ──────────────────────────── settings page ──────────────────────────── */

function makeSettingsCard(engine) {
  if (!React || typeof React.createElement !== 'function') return null;
  var e = React.createElement;

  var row = { display: 'flex', alignItems: 'center', gap: '8px', padding: '2px 0' };
  var label = { flex: '1 1 auto', fontSize: '13px', lineHeight: '20px', color: 'var(--dsw-alias-label-secondary, #61666b)' };
  var head = { margin: '0 0 4px', fontSize: '14px', lineHeight: '22px', color: 'var(--dsw-alias-label-primary, #1f2328)' };
  var lead = { margin: '0 0 12px', fontSize: '12px', lineHeight: '18px', color: 'var(--dsw-alias-label-tertiary, #8b9096)' };
  var note = { margin: '8px 0 0', fontSize: '12px', lineHeight: '18px', color: 'var(--dsw-alias-label-tertiary, #8b9096)' };
  var hint2 = { margin: '0 0 6px 24px', fontSize: '12px', lineHeight: '17px', color: 'var(--dsw-alias-label-tertiary, #8b9096)' };

  return function SettingsCard() {
    var state = React.useState(0);
    var rerender = state[1];
    React.useEffect(function () {
      return engine.subscribeSettings(function () { rerender(function (n) { return n + 1; }); });
    }, []);

    var settings = engine.settings();
    var permission = engine.permission();

    function check(key, text, hint) {
      return e('div', { key: key },
        e('label', { style: row },
          e('input', {
            type: 'checkbox',
            checked: settings[key] === true,
            onChange: function (event) { engine.setSetting(key, event.target.checked); }
          }),
          e('span', { style: label }, text)
        ),
        hint ? e('p', { style: hint2 }, hint) : null
      );
    }

    var permissionText = permission === 'granted' ? t('granted')
      : permission === 'denied' ? t('denied')
      : permission === 'unsupported' ? t('unsupported')
      : t('prompt');

    return e('div', { style: { padding: '4px 0', maxWidth: '520px' } },
      e('h3', { style: head }, t('heading')),
      e('p', { style: lead }, t('lead')),
      check('enabled', t('enabled')),
      check('input', t('input')),
      check('done', t('done')),
      check('waitForBackground', t('waitForBackground'), t('waitForBackgroundHint')),
      check('sound', t('sound')),
      e('label', { style: row, key: 'system' },
        e('span', { style: label }, t('system')),
        e('select', {
          value: settings.system,
          onChange: function (event) { engine.setSetting('system', event.target.value); }
        },
          e('option', { value: 'always' }, t('systemAlways')),
          e('option', { value: 'background' }, t('systemBackground')),
          e('option', { value: 'off' }, t('systemOff'))
        )
      ),
      e('div', { style: note }, t('permission') + ': ' + permissionText),
      permission === 'granted' ? null
        : e('div', { style: note }, permission === 'unsupported' ? t('inPageOff') : t('inPage')),
      e('div', { style: { display: 'flex', gap: '8px', marginTop: '8px' } },
        e('button', {
          type: 'button',
          onClick: function () { engine.requestPermission(); }
        }, t('request')),
        e('button', {
          type: 'button',
          onClick: function () { engine.test(); }
        }, t('test'))
      )
    );
  };
}

/* ──────────────────────────────── plugin ─────────────────────────────── */

function apply(ctx) {
  var engine = createEngine(ctx);
  engine.start();

  if (typeof ctx.effect === 'function') {
    ctx.effect(function () { return function () { engine.destroy(); }; }, 'dsh-notification: engine');
  }

  var Card = makeSettingsCard(engine);
  // `slots` is declared in this module's `inject`, which is what makes the
  // direct property read legal under the client runner's façade — and it is the
  // only working path: ctx.get('slots') resolves to nothing for a client plugin.
  var slots = ctx.slots;
  var settingsRegistered = false;
  if (Card && slots && typeof slots.inject === 'function' && typeof slots.register === 'function') {
    try {
      var disposeSlot = slots.inject('settings.section', function () {
        return slots.register({
          name: 'settings.section',
          id: 'dsh-notification',
          order: 132,
          label: function () { return t('settingsLabel'); }
        }, Card);
      });
      settingsRegistered = true;
      if (typeof ctx.effect === 'function') {
        ctx.effect(function () { return disposeSlot; }, 'dsh-notification: settings section');
      }
    } catch (error) {
      console.warn('[dsh-notification] settings section registration failed:', error);
    }
  } else {
    console.warn(
      '[dsh-notification] settings page skipped —' +
      (Card ? '' : ' React unavailable (require("react") failed: ' + String(reactError) + ');') +
      (slots ? '' : ' ctx.get("slots") returned nothing;')
    );
  }

  try {
    window.__dshNotification = {
      settings: function () { return Object.assign({}, engine.settings()); },
      permission: engine.permission,
      test: engine.test,
      log: function () { return engine.log(); },
      diagnostics: function () {
        return {
          react: React !== null && React !== undefined,
          reactError: reactError,
          slots: !!slots,
          settingsRegistered: settingsRegistered,
          inject: module.exports.inject,
          wired: engine.wired(),
          permission: engine.permission()
        };
      },
      probe: function (sessionId) {
        var sessions = ctx.get('sessions');
        var list = sessions && sessions.list && typeof sessions.list.getSnapshot === 'function'
          ? sessions.list.getSnapshot()
          : null;
        var byId = (list && list.byId) || {};
        var row = byId[sessionId] || null;
        return {
          label: row ? row.displayTitle : null,
          running: row ? row.running === true : null,
          liveBackgroundWork: hasLiveBackgroundWork(byId, sessionId)
        };
      }
    };
  } catch (error) { /* ignore */ }
}

module.exports = {
  apply: apply,
  // Only services read as DIRECT properties belong here: the client runner hands
  // `apply` a whitelisting façade that rejects an undeclared `ctx.<service>`
  // read — the fiber ends up FAILED and the whole page boot aborts. Everything
  // else is read through ctx.get(name), the ungated optional lookup.
  //
  // `slots` must be declared: it is the one service ctx.get cannot reach from a
  // client plugin (verified in the browser), and reading it as ctx.slots is how
  // the working settings-page plugins do it.
  inject: ['slots'],
  __internal: {
    hasLiveBackgroundWork: hasLiveBackgroundWork,
    decideDone: decideDone,
    normalizeSettings: normalizeSettings,
    DEFAULTS: DEFAULTS,
    DONE_GRACE_MS: DONE_GRACE_MS
  }
};
return module.exports;}});
