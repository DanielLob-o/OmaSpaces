const test = require('node:test');
const assert = require('node:assert/strict');
const { load, Util } = require('../helpers/qml-functions.cjs');

function widget(settings = {}) {
  const root = { home: '/home/me', setting: (key, fallback) => (key in settings ? settings[key] : fallback) };
  return load('BarWidget.qml', ['boolSetting', 'objectSetting', 'expandPath', 'workspaceName', 'numberLabel'],
    { root, Util });
}

test('boolSetting reads strings that `omarchy bar set` writes without --json', () => {
  const root = widget({ a: 'false', b: ' Yes ', c: '0', d: 'on', e: false, f: 'maybe' });
  assert.equal(root.boolSetting('a', true), false);
  assert.equal(root.boolSetting('b', false), true);
  assert.equal(root.boolSetting('c', true), false);
  assert.equal(root.boolSetting('d', false), true);
  assert.equal(root.boolSetting('e', true), false);
  assert.equal(root.boolSetting('f', true), true, 'an unknown word falls back');
  assert.equal(root.boolSetting('missing', false), false);
});

test('objectSetting accepts an object or JSON text, and nothing else', () => {
  const root = widget({ obj: { 1: 'dev' }, text: '{"3":"chat"}', list: [1], bad: '{nope', num: 4 });
  assert.deepEqual(root.objectSetting('obj'), { 1: 'dev' });
  assert.deepEqual(root.objectSetting('text'), { 3: 'chat' });
  assert.deepEqual(root.objectSetting('list'), {});
  assert.deepEqual(root.objectSetting('bad'), {});
  assert.deepEqual(root.objectSetting('num'), {});
  assert.deepEqual(root.objectSetting('missing'), {});
});

test('expandPath expands ~ and $HOME, and keeps relative paths under home', () => {
  const root = widget();
  assert.equal(root.expandPath('~/.config/x.json'), '/home/me/.config/x.json');
  assert.equal(root.expandPath('~'), '/home/me');
  assert.equal(root.expandPath('$HOME/a'), '/home/me/a');
  assert.equal(root.expandPath('notes/a.json'), '/home/me/notes/a.json');
  assert.equal(root.expandPath('/etc/a'), '/etc/a');
  assert.equal(root.expandPath('  '), '');
  assert.equal(root.expandPath(null), '');
});

test('numberLabel shows 0 for workspace 10, adds the name, and never leaves a pill blank', () => {
  const root = widget();
  Object.assign(root, { showNumbers: true, showIcons: true, workspaceNames: { 2: 'web' } });
  assert.equal(root.numberLabel(10, true), '0');
  assert.equal(root.numberLabel(2, true), '2 web');

  root.showNumbers = false;
  assert.equal(root.numberLabel(1, true), '', 'occupied pills show icons only');
  assert.equal(root.numberLabel(1, false), '1', 'empty pills keep their number');
  assert.equal(root.numberLabel(2, true), 'web');

  root.showIcons = false;
  assert.equal(root.numberLabel(1, true), '1', 'with icons off the number is all there is');
});
