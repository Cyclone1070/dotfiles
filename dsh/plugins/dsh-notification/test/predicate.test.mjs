/**
 * Predicate tests for dsh-notification.
 *
 * The client half is a single browser bundle that talks to the module loader, so
 * these tests load the REAL file with a stubbed loader and exercise the pure
 * decision core it exports. No build step, no bundler, no jsdom.
 *
 *   node test/predicate.test.mjs
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const source = readFileSync(new URL('../lib/client.js', import.meta.url), 'utf8');

let captured = null;
const windowStub = {
  __ModuleLoader__: {
    load(definition) {
      captured = definition;
    }
  }
};
const documentStub = { documentElement: { lang: 'en' }, hidden: false, title: '' };
const navigatorStub = { language: 'en-US' };
const requireStub = () => {
  throw new Error('react is not available in tests');
};

new Function('window', 'document', 'navigator', 'require', source)(
  windowStub,
  documentStub,
  navigatorStub,
  requireStub
);

assert.ok(captured, 'the bundle must register itself with the module loader');
assert.equal(captured.id, 'dsh-notification');

const exported = captured.factory(requireStub);
const { hasLiveBackgroundWork, decideDone, normalizeSettings, DEFAULTS } = exported.__internal;

assert.deepEqual(exported.inject, ['slots'], 'only ctx.slots is read as a direct property');
assert.equal(typeof exported.apply, 'function');

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

/* ── hasLiveBackgroundWork: only delegated SESSIONS hold a notice ───────── */

console.log('hasLiveBackgroundWork');

test('a running child session holds the notice', () => {
  const byId = {
    parent: { id: 'parent' },
    child: { id: 'child', parentId: 'parent', running: true }
  };
  assert.equal(hasLiveBackgroundWork(byId, 'parent'), true);
});

test('a running grandchild holds the notice', () => {
  const byId = {
    parent: { id: 'parent' },
    child: { id: 'child', parentId: 'parent', running: false },
    grandchild: { id: 'grandchild', parentId: 'child', running: true }
  };
  assert.equal(hasLiveBackgroundWork(byId, 'parent'), true);
});

test('a stopped child does not hold the notice', () => {
  const byId = {
    parent: { id: 'parent' },
    child: { id: 'child', parentId: 'parent', running: false }
  };
  assert.equal(hasLiveBackgroundWork(byId, 'parent'), false);
});

test('the parent running itself is not background work', () => {
  const byId = { parent: { id: 'parent', running: true } };
  assert.equal(hasLiveBackgroundWork(byId, 'parent'), false);
});

test('an unrelated running session does not hold the notice', () => {
  const byId = {
    parent: { id: 'parent' },
    other: { id: 'other', parentId: 'somebody-else', running: true }
  };
  assert.equal(hasLiveBackgroundWork(byId, 'parent'), false);
});

test('a parent cycle terminates (a -> b -> a)', () => {
  const byId = {
    a: { id: 'a', parentId: 'b', running: false },
    b: { id: 'b', parentId: 'a', running: false }
  };
  assert.equal(hasLiveBackgroundWork(byId, 'a'), false);
});

test('missing snapshots are safe', () => {
  assert.equal(hasLiveBackgroundWork(null, 'parent'), false);
  assert.equal(hasLiveBackgroundWork({}, null), false);
});

/* ── decideDone: a yield is not an ending ───────────────────────────────── */

console.log('decideDone');

test('stop with live background work holds', () => {
  assert.equal(decideDone({ awaiting: true, hasLiveBackgroundWork: true }), 'hold');
});

test('held session with work still running keeps holding', () => {
  assert.equal(decideDone({ awaiting: true, held: true, hasLiveBackgroundWork: true }), 'hold');
});

test('held session notifies the moment the work drains', () => {
  assert.equal(decideDone({ awaiting: true, held: true, hasLiveBackgroundWork: false }), 'notify');
});

test('stop with no background work waits for the grace re-read', () => {
  assert.equal(decideDone({ awaiting: true, hasLiveBackgroundWork: false, graceElapsed: false }), 'hold');
});

test('grace re-read that survives notifies', () => {
  assert.equal(decideDone({ awaiting: true, hasLiveBackgroundWork: false, graceElapsed: true }), 'notify');
});

test('a pending interaction owns the moment', () => {
  assert.equal(decideDone({ awaiting: true, held: true, hasPendingInteraction: true }), 'clear');
});

test('a session that resumed is cleared, not notified', () => {
  assert.equal(decideDone({ awaiting: true, graceElapsed: true, nowRunning: true }), 'clear');
});

test('no stop edge means silence', () => {
  assert.equal(decideDone({ awaiting: false, graceElapsed: true }), 'clear');
});

/* ── normalizeSettings: stored garbage never reaches the engine ─────────── */

console.log('normalizeSettings');

test('defaults survive a null payload', () => {
  assert.deepEqual(normalizeSettings(null), DEFAULTS);
});

test('volume is clamped and non-numeric volume is ignored', () => {
  assert.equal(normalizeSettings({ volume: 9 }).volume, 1);
  assert.equal(normalizeSettings({ volume: -3 }).volume, 0);
  assert.equal(normalizeSettings({ volume: 'loud' }).volume, DEFAULTS.volume);
});

test('an unknown system mode falls back to the default', () => {
  assert.equal(normalizeSettings({ system: 'sometimes' }).system, DEFAULTS.system);
  assert.equal(normalizeSettings({ system: 'off' }).system, 'off');
});

test('non-boolean switches are ignored', () => {
  assert.equal(normalizeSettings({ done: 'yes' }).done, DEFAULTS.done);
  assert.equal(normalizeSettings({ done: false }).done, false);
});

console.log('\n' + passed + ' checks passed' + (process.exitCode ? ' (with failures)' : ''));
