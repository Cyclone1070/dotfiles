/**
 * Activation tests for dsh-notification's browser half.
 *
 * These exist because the plugin broke the whole page boot twice. The client
 * runner hands `apply` a whitelisting façade whose real rules are:
 *
 *   1. Reading a service as a property (`ctx.slots`) is legal ONLY when the
 *      module's own `inject` declares it; otherwise it throws, the fiber ends up
 *      FAILED, and the boot aborts with
 *      "web boot: 1 entry did not activate — dsh-notification: failed".
 *   2. `ctx.get(name)` is the ungated optional lookup — and for `slots` it
 *      resolves to nothing, which is why `slots` is declared and read directly.
 *   3. Only a fixed verb set (effect, on, once, provide, timers) is callable.
 *
 * The harness below enforces exactly those rules, so a regression fails here
 * instead of in the user's browser.
 *
 *   node test/activation.test.mjs
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const source = readFileSync(new URL('../lib/client.js', import.meta.url), 'utf8');

/* ── the guard harness (mirrors dsh-cordis-client-runner's façade) ───────── */

const CTX_VERBS = new Set([
  'effect', 'on', 'once', 'provide',
  'timeout', 'interval', 'setTimeout', 'setInterval', 'throttle', 'debounce'
]);

function guardedCtx(services, options = {}) {
  const declared = new Set(options.declared ?? []);
  const hiddenFromGet = new Set(options.hiddenFromGet ?? []);
  const base = {
    effect: (fn) => {
      const dispose = fn();
      return typeof dispose === 'function' ? dispose : () => {};
    },
    on: () => () => {},
    once: () => () => {},
    provide: () => () => {}
  };
  return new Proxy(base, {
    get(target, prop) {
      if (prop === 'get') {
        return (name) => (hiddenFromGet.has(name) ? undefined : services[name]);
      }
      if (typeof prop !== 'string') return undefined;
      if (CTX_VERBS.has(prop)) return (...args) => Reflect.apply(target[prop], target, args);
      if (!declared.has(prop)) {
        throw new Error(
          `service "${prop}" is not declared by your plugin. Declare it on the plugin you return: ` +
          `{ inject: ['${prop}', ...], apply(ctx) { ... } }`
        );
      }
      return services[prop];
    }
  });
}

/* ── load the bundle with a stubbed module loader ───────────────────────── */

let captured = null;
const timers = [];
const windowStub = {
  __ModuleLoader__: { load: (definition) => { captured = definition; } },
  localStorage: { getItem: () => null, setItem: () => {} },
  addEventListener: () => {},
  removeEventListener: () => {},
  setTimeout: (fn) => { timers.push(fn); return timers.length; },
  clearTimeout: () => {},
  focus: () => {},
  Notification: Object.assign(function Notification() {}, {
    permission: 'default',
    requestPermission: () => Promise.resolve('granted')
  })
};
const documentStub = { documentElement: { lang: 'en' }, hidden: false, title: 'DSH' };
const navigatorStub = { language: 'en-US' };
const requireStub = (id) => {
  if (id === 'react') {
    return {
      createElement: () => null,
      useState: (initial) => [initial, () => {}],
      useEffect: () => {}
    };
  }
  throw new Error('module not available in tests: ' + String(id));
};

new Function('window', 'document', 'navigator', 'require', source)(
  windowStub, documentStub, navigatorStub, requireStub
);

const exported = captured.factory(requireStub);
const counters = { list: 0, status: 0, settings: 0 };

function makeStores() {
  return {
    sessions: {
      list: {
        subscribe: () => { counters.list += 1; return () => {}; },
        getSnapshot: () => ({ ids: [], byId: {} })
      }
    },
    uiSession: {
      sessionStatus: {
        subscribe: () => { counters.status += 1; return () => {}; },
        getSnapshot: () => new Map()
      }
    },
    slots: {
      inject: (_key, callback) => { callback(); return () => {}; },
      register: () => { counters.settings += 1; return () => {}; }
    }
  };
}

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed += 1;
    console.log('  ok  ' + name);
  } catch (error) {
    console.error('FAIL  ' + name);
    console.error('      ' + (error && error.message));
    process.exitCode = 1;
  }
}

console.log('activation');

test('inject declares exactly the directly-read service', () => {
  assert.deepEqual(exported.inject, ['slots'], 'only ctx.slots is read as a property');
  assert.equal(typeof exported.apply, 'function');
});

test('the guard harness itself rejects an undeclared service read', () => {
  const ctx = guardedCtx({ sessions: {} });
  assert.notEqual(ctx.get('sessions'), undefined, 'ctx.get must stay ungated');
  assert.throws(() => ctx.sessions, /is not declared by your plugin/, 'the harness must be strict');
});

test('apply() survives the guard with NO services at all', () => {
  const ctx = guardedCtx({}, { declared: exported.inject });
  exported.apply(ctx);
  assert.equal(counters.list, 0);
  assert.ok(timers.length >= 1, 'a retry must be scheduled while stores are missing');
});

test('apply() wires both stores through ctx.get when they are present', () => {
  const ctx = guardedCtx(makeStores(), { declared: exported.inject });
  const before = { list: counters.list, status: counters.status };
  exported.apply(ctx);
  assert.equal(counters.list, before.list + 1, 'the session list must be wired');
  assert.equal(counters.status, before.status + 1, 'the status store must be wired');
});

test('the settings page registers with slots declared and hidden from ctx.get', () => {
  // This is the real browser shape: ctx.get('slots') is undefined, ctx.slots works.
  const ctx = guardedCtx(makeStores(), { declared: exported.inject, hiddenFromGet: ['slots'] });
  const before = counters.settings;
  exported.apply(ctx);
  assert.equal(counters.settings, before + 1, 'slots.register must be called once');
});

test('stores that appear later are picked up by the retry', () => {
  const services = {};
  const ctx = guardedCtx(services, { declared: exported.inject });
  exported.apply(ctx);
  const before = { list: counters.list, status: counters.status };
  Object.assign(services, makeStores());
  timers[timers.length - 1]();
  assert.equal(counters.list, before.list + 1, 'the retry must attach the list');
  assert.equal(counters.status, before.status + 1, 'the retry must attach the status store');
});

test('the pending-interaction store alone is enough to wire', () => {
  const before = counters.status;
  const ctx = guardedCtx({
    uiSession: {
      pendingInteractions: {
        subscribe: () => { counters.status += 1; return () => {}; },
        getSnapshot: () => new Map()
      }
    }
  }, { declared: exported.inject });
  exported.apply(ctx);
  assert.equal(counters.status, before + 1, 'the fallback store must be accepted');
});

console.log('\n' + passed + ' checks passed' + (process.exitCode ? ' (with failures)' : ''));
