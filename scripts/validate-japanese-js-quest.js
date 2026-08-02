#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')
const vm = require('vm')
const engine = require(path.join(__dirname, '../app/assets/japanese-js-quest/engine.js'))
const introMission = require(path.join(__dirname, '../app/assets/japanese-js-quest/intro-mission.js'))
const existingMissions = require(path.join(__dirname, '../app/assets/japanese-js-quest/missions.js'))
const progression = require(path.join(__dirname, '../app/assets/japanese-js-quest/progression.js'))
const missions = progression.apply([introMission, ...existingMissions], engine)

assert.strictEqual(missions.length, 21, 'The campaign must contain exactly 21 missions.')
assert.strictEqual(missions.find(mission => mission.id === 0).wizardLevel, 0)
assert.strictEqual(missions.find(mission => mission.id === 1).wizardLevel, 0)
for (const id of [2, 3, 4, 5]) assert.strictEqual(missions.find(mission => mission.id === id).wizardLevel, 1)
assert.strictEqual(progression.thresholdForLevel(1), 1)
assert.strictEqual(progression.thresholdForLevel(2), 5)
assert.strictEqual(progression.thresholdForLevel(3), 12)
assert.strictEqual(introMission.starterCode, 'hero.say(\'Hello Yuzu\');')
assert(!introMission.starterCode.includes('//'), 'Mission 00 must contain only the executable line.')
assert.strictEqual(introMission.starterCode.split('\n').length, 1)

const ids = new Set()
for (const mission of missions) {
  assert(!ids.has(mission.id), `Duplicate mission id: ${mission.id}`)
  ids.add(mission.id)
  assert(mission.title && mission.starterCode && mission.solution, `Mission ${mission.id} is incomplete.`)
  assert(Array.isArray(mission.variants) && mission.variants.length > 0, `Mission ${mission.id} has no variants.`)
  if (mission.id > 0) {
    assert(mission.requirements.state.minGems >= 1, `Mission ${mission.id} must require a gem.`)
    assert(mission.variants.every(variant => variant.map.some(row => row.includes('*'))), `Mission ${mission.id} must show a gem.`)
  }

  for (let variantIndex = 0; variantIndex < mission.variants.length; variantIndex++) {
    const result = engine.simulate(mission.solution, mission, variantIndex)
    const evaluation = engine.evaluate(mission, result, mission.solution)
    assert(result.ok, `Mission ${mission.id}, variant ${variantIndex}: ${result.error && result.error.message}`)
    assert(
      evaluation.passed,
      `Mission ${mission.id}, variant ${variantIndex} failed: ${evaluation.messages.join(' | ')}`,
    )
  }
}

const lockedTransform = engine.simulate('hero.transform("frog");', missions.find(mission => mission.id === 1), 0)
assert.strictEqual(lockedTransform.state.form, 'hero')
assert(lockedTransform.state.says.includes(engine.LOCKED_POWER_MESSAGE))

const unlockedTransform = engine.simulate('hero.transform("frog");', missions.find(mission => mission.id === 2), 0)
assert.strictEqual(unlockedTransform.state.form, 'frog')

const orderedMission = missions.find(mission => mission.id === 2)
const orderedScript = [
  'hero.move("up")',
  'hero.transform("frog")',
  'hero.say("frog")',
  'hero.transform("hero")',
  'hero.move("right")',
  'hero.move("right")',
  'hero.move("right")',
  'hero.transform("frog")',
  'hero.say("frog")',
  'hero.move("up")',
  'hero.transform("frog")',
].join('\n')
const orderedResult = engine.simulate(orderedScript, orderedMission, 0)
assert(orderedResult.ok)
assert.deepStrictEqual(
  orderedResult.trace.map(frame => frame.type),
  ['move', 'transform', 'say', 'transform', 'move', 'move', 'move', 'transform', 'say', 'move', 'transform'],
)
const speechFrames = orderedResult.trace.filter(frame => frame.type === 'say')
assert.strictEqual(speechFrames.length, 2)
assert.notDeepStrictEqual(
  [speechFrames[0].x, speechFrames[0].y],
  [speechFrames[1].x, speechFrames[1].y],
  'Speech bubbles must remain attached to their exact execution positions.',
)
assert.strictEqual(speechFrames[0].form, 'frog')
assert.strictEqual(speechFrames[1].form, 'frog')

const promptSource = fs.readFileSync(path.join(__dirname, '../app/assets/japanese-js-quest/branch-prompts.js'), 'utf8')
vm.runInNewContext(promptSource, { window: { JSQuestMissions: missions }, Object })
for (const id of [3, 4, 5, 6, 7, 8, 9, 13, 14, 15, 17, 18, 19, 20]) {
  const mission = missions.find(item => item.id === id)
  assert(mission.starterCode.includes('hero.say('), `Mission ${id} must contain a branch thinking prompt.`)
}
assert(missions.find(mission => mission.id === 3).starterCode.includes('看板が「right」の場合には、どうすればいい？'))
assert(missions.find(mission => mission.id === 4).starterCode.includes('その他なら、どうすればいい？'))

const terminologySource = fs.readFileSync(path.join(__dirname, '../app/assets/japanese-js-quest/technical-terms.js'), 'utf8')
assert(terminologySource.includes("english: 'String', katakana: 'ストリング'"))
assert(terminologySource.includes("preferredText: 'これは文字列という値です。'"))
assert(terminologySource.includes("english: 'Comment', katakana: 'コメント'"))
assert(terminologySource.includes('comment-concept-card'))

const speechUiSource = fs.readFileSync(path.join(__dirname, '../app/assets/japanese-js-quest/speech-ui.js'), 'utf8')
const speechCssSource = fs.readFileSync(path.join(__dirname, '../app/assets/japanese-js-quest/speech-ui.css'), 'utf8')
assert(speechUiSource.includes('document.body.appendChild(bubble)'))
assert(speechUiSource.includes("bubble.classList.add('speech-clamped-top')"))
assert(speechCssSource.includes('position: fixed'))
assert(speechCssSource.includes('z-index: 2147483000'))

console.log(`Validated ${missions.length} missions and ${missions.reduce((sum, mission) => sum + mission.variants.length, 0)} variants with ordered actions, bilingual terminology and wizard progression.`)
