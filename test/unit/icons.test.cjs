const test = require('node:test');
const assert = require('node:assert/strict');
const { library, load } = require('../helpers/qml-functions.cjs');

const IconRules = library('IconRules.js');

test('class rules match common apps', () => {
  assert.equal(IconRules.iconForClass('com.mitchellh.ghostty'), '');
  assert.equal(IconRules.iconForClass('foot'), '');
  assert.equal(IconRules.iconForClass('footclient'), '');
  assert.equal(IconRules.iconForClass('firefox'), '󰈹');
  assert.equal(IconRules.iconForClass('libreoffice-calc'), '󰧷', 'the specific rule wins over libreoffice');
  assert.equal(IconRules.iconForClass('libreoffice-impress'), '󰈙');
  assert.equal(IconRules.iconForClass('unknown-app'), '');
  assert.equal(IconRules.iconForClass(''), '');
});

test('title rules apply to browsers only', () => {
  assert.equal(IconRules.iconForTitle('my video - youtube', 'brave-browser'), '󰗃');
  assert.equal(IconRules.iconForTitle('repo · github', 'firefox'), '󰊤');
  assert.equal(IconRules.iconForTitle('github', 'com.mitchellh.ghostty'), '', 'a terminal keeps its own icon');
  assert.equal(IconRules.iconForTitle('', 'firefox'), '');
});

function widget(entries) {
  const root = { iconCache: {} };
  load('BarWidget.qml', ['parseIconOverrideEntries', 'applyIconOverrideEntries', 'customIconFor', 'iconForClass'],
    { root, IconRules, console: { warn() {} } });
  root.applyIconOverrideEntries(root.parseIconOverrideEntries(entries));
  return root;
}

test('the rules file keeps valid entries and accepts "pattern" for "match"', () => {
  const root = widget([
    { match: 'claude', icon: 'A' },
    { pattern: 'zed', icon: 'B' },
    { match: 'no-icon' },
    null,
    'text',
    { match: '(', icon: 'C' },
  ]);
  assert.deepEqual(root.iconOverrideEntries.map(e => e.match), ['claude', 'zed', '(']);
  assert.equal(root.customIconRules.length, 2, 'an invalid regex is skipped, not fatal');
  assert.deepEqual(root.parseIconOverrideEntries({ match: 'x' }), [], 'only an array is a rules file');
});

test('custom rules win over built-in rules, and the first match wins', () => {
  const root = widget([{ match: 'ghostty', icon: 'G' }, { match: 'ghost', icon: 'H' }]);
  assert.equal(root.iconForClass('com.mitchellh.ghostty', ''), 'G');
  assert.equal(root.iconForClass('firefox', ''), '󰈹');
  assert.equal(root.iconForClass('nothing-known', ''), IconRules.DEFAULT_ICON);
});

test('custom rules are case-insensitive and also match the title', () => {
  const root = widget([{ match: 'Claude', icon: 'C' }]);
  assert.equal(root.iconForClass('com.mitchellh.ghostty', 'claude code'), 'C');
});
