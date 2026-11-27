const test = require('node:test');
const assert = require('node:assert/strict');
const { load, strings, I18n, Util } = require('../helpers/qml-functions.cjs');

const NAMES = ['tr', 'trn', 'normalizeProfiles', 'uniqueProfileName', 'parseWebApp', 'toplevelClass', 'applyProfile',
  'placePendingWindow', 'profileStatusText'];

function widget(state = {}) {
  const runs = [];
  const moves = [];
  const root = {
    strings: strings(),
    profiles: [],
    pendingPlacements: [],
    profileStatus: null,
    bar: { run: command => runs.push(command) },
    moveWindowToWorkspace: (address, workspace) => moves.push([address, workspace]),
    ...state,
  };
  load('BarWidget.qml', NAMES, { root, Util, I18n });
  return { root, runs, moves };
}

function window(cls, workspace) {
  return { workspace: { id: workspace }, lastIpcObject: { class: cls } };
}

test('normalizeProfiles drops broken entries and clamps workspaces', () => {
  const { root } = widget();
  const profiles = root.normalizeProfiles([
    { name: 'Work', apps: [{ class: 'firefox', workspace: 12, command: 'firefox' }, { workspace: 1 }, null] },
    { apps: [{ class: 'foot', workspace: 'x' }] },
    'junk',
    { name: 'Empty' },
  ]);
  assert.deepEqual(profiles, [
    { name: 'Work', apps: [{ class: 'firefox', workspace: 10, command: 'firefox' }] },
    { name: 'Profile 2', apps: [{ class: 'foot', workspace: 1, command: '' }] },
    { name: 'Empty', apps: [] },
  ]);
  assert.deepEqual(root.normalizeProfiles({}), []);
});

test('uniqueProfileName skips names that are taken', () => {
  const { root } = widget({ profiles: [{ name: 'Layout 2' }] });
  assert.equal(root.uniqueProfileName('profiles.defaultLayoutName'), 'Layout 3');
});

test('parseWebApp reads Chromium web app classes', () => {
  const { root } = widget();
  assert.deepEqual(root.parseWebApp('brave-web.whatsapp.com__-Default'),
    { host: 'web.whatsapp.com', path: '', url: 'https://web.whatsapp.com/' });
  assert.deepEqual(root.parseWebApp('chromium-app.example.com__mail_inbox-Profile_1'),
    { host: 'app.example.com', path: 'mail/inbox', url: 'https://app.example.com/mail/inbox' });
  assert.equal(root.parseWebApp('firefox'), null);
});

test('applyProfile keeps open apps, launches missing ones, and remembers where they go', () => {
  const { root, runs } = widget({
    profiles: [{
      name: 'Work',
      apps: [
        { class: 'Firefox', workspace: 1, command: 'launch-firefox' },
        { class: 'foot', workspace: 2, command: 'launch-foot' },
        { class: 'foot', workspace: 3, command: 'launch-foot' },
        { class: 'slack', workspace: 4, command: '' },
      ],
    }],
    allToplevels: () => [window('firefox', 5), window('foot', 3)],
  });
  root.applyProfile(0);
  assert.deepEqual(runs, ['launch-foot'], 'firefox is open anywhere, one foot is open on its own workspace');
  assert.deepEqual(root.pendingPlacements.map(p => [p.cls, p.workspace]), [['foot', 2]]);
  assert.deepEqual(root.profileStatus, { kind: 'ready', name: 'Work', launched: 1, skipped: 1 });
  assert.equal(root.profileStatusText(), 'Work ready · 1 opened · 1 without a launch command');
});

test('applyProfile prefers a window on the right workspace', () => {
  const { root, runs } = widget({
    profiles: [{ name: 'P', apps: [{ class: 'foot', workspace: 1, command: 'a' }, { class: 'foot', workspace: 2, command: 'b' }] }],
    allToplevels: () => [window('foot', 2)],
  });
  root.applyProfile(0);
  assert.deepEqual(runs, ['a'], 'the foot on workspace 2 satisfies the second entry, not the first');
});

test('placePendingWindow moves the first matching new window once', () => {
  const later = Date.now() + 60000;
  const { root, moves } = widget({
    pendingPlacements: [
      { cls: 'foot', workspace: 2, expires: later },
      { cls: 'foot', workspace: 3, expires: later },
      { cls: 'old', workspace: 4, expires: Date.now() - 1 },
    ],
  });
  root.placePendingWindow('abc123,1,Foot,title, with a comma');
  assert.deepEqual(moves, [['0xabc123', 2]]);
  assert.deepEqual(root.pendingPlacements.map(p => p.workspace), [3], 'expired entries are dropped');

  root.placePendingWindow('0xdef,3,foot,t');
  assert.deepEqual(moves.length, 1, 'a window already on its workspace is not moved');
  assert.deepEqual(root.pendingPlacements, []);
});

test('profileStatusText builds whole sentences from the catalog', () => {
  const { root } = widget();
  assert.equal(root.profileStatusText(), '');
  root.profileStatus = { kind: 'captured', count: 1, name: 'Layout 1' };
  assert.equal(root.profileStatusText(), 'Captured 1 app into Layout 1');
  root.profileStatus = { kind: 'recaptured', count: 3, name: 'Home' };
  assert.equal(root.profileStatusText(), 'Recaptured Home · 3 apps');
  root.profileStatus = { kind: 'ready', name: 'Home', launched: 0, skipped: 0 };
  assert.equal(root.profileStatusText(), 'Home ready · everything already open');
  root.profileStatus = { kind: 'captured', count: 2, name: 'Has %1 in it' };
  assert.equal(root.profileStatusText(), 'Captured 2 apps into Has %1 in it', 'a name is not a placeholder');
});
