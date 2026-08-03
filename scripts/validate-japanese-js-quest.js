#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')
const vm = require('vm')

const questPath = '../app/assets/japanese-js-quest/'
const baseEngine = require(path.join(__dirname, questPath, 'engine.js'))
const curriculumEngine = require(path.join(__dirname, questPath, 'curriculum-engine.js'))
const engine = curriculumEngine.apply(baseEngine)
const introMission = require(path.join(__dirname, questPath, 'intro-mission.js'))
const legacyMissions = require(path.join(__dirname, questPath, 'missions.js'))
const curriculum = require(path.join(__dirname, questPath, 'curriculum-v3.js'))
const progression = require(path.join(__dirname, questPath, 'progression.js'))

function read (relativePath) {
  return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8')
}

function mission (missions, id) {
  return missions.find(item => item.id === id)
}

function assertSpokenFailure (result, code, text) {
  assert.strictEqual(result.ok, false)
  assert.strictEqual(result.error.spoken, true)
  assert.strictEqual(result.error.code, code)
  assert(result.trace.some(frame => frame.type === 'say' && frame.speech.includes(text)))
}

vm.runInNewContext(
  read('app/assets/japanese-js-quest/branch-prompts.js'),
  { window: { JSQuestMissions: legacyMissions }, Object },
)
curriculum.apply(legacyMissions)
const missions = progression.apply([introMission, ...legacyMissions], engine)

assert.strictEqual(missions.length, 23)
assert.deepStrictEqual(missions.map(item => item.id), Array.from({ length: 23 }, (_, index) => index))
assert.strictEqual(mission(missions, 0).wizardLevel, 0)
assert.strictEqual(mission(missions, 1).wizardLevel, 0)
for (const id of [2, 3, 4, 5]) assert.strictEqual(mission(missions, id).wizardLevel, 1)
assert.deepStrictEqual([1, 2, 3].map(progression.thresholdForLevel), [1, 5, 12])
assert.strictEqual(introMission.starterCode, 'hero.say(\'Hello Yuzu\');')

for (const item of missions) {
  assert(item.title && item.starterCode && item.solution)
  assert(Array.isArray(item.variants) && item.variants.length > 0)
  if (item.id > 0) {
    assert(item.requirements.state.minGems >= 1)
    assert(item.variants.every(variant => variant.map.some(row => row.includes('*'))))
  }
  if (item.infiniteLoopDemo) continue

  item.variants.forEach((variant, variantIndex) => {
    const result = engine.simulate(item.solution, item, variantIndex)
    const evaluation = engine.evaluate(item, result, item.solution)
    assert(result.ok, `Mission ${item.id}, field ${variantIndex + 1}: ${result.error?.message}`)
    assert(
      evaluation.passed,
      `Mission ${item.id}, field ${variantIndex + 1}: ${evaluation.messages.join(' | ')}`,
    )
  })
}

const booleanMission = mission(missions, 3)
assert.strictEqual(booleanMission.title, 'true と false')
assert(booleanMission.requirements.booleanDemo)
for (const source of [
  'const alwaysTrue = true;',
  'hero.isTrue(alwaysTrue);',
  'const alwaysFalse = false;',
  'hero.isTrue(alwaysFalse);',
]) assert(booleanMission.starterCode.includes(source))

const booleanResult = engine.simulate(booleanMission.solution, booleanMission, 0)
assert(engine.evaluate(booleanMission, booleanResult, booleanMission.solution).passed)
assert(booleanResult.state.says.includes(curriculumEngine.TRUE_MESSAGE))
assert(booleanResult.state.says.includes(curriculumEngine.FALSE_MESSAGE))
assert(engine.simulate('hero.isTrue(true);', booleanMission, 0).state.says.includes('正しいです。'))
assert(engine.simulate('hero.isTrue(false);', booleanMission, 0).state.says.includes('違いますよ。'))
assertSpokenFailure(engine.simulate('hero.isTrue("true");', booleanMission, 0), 'invalid-boolean', 'true か false')
assertSpokenFailure(engine.simulate('hero.isTrue();', booleanMission, 0), 'invalid-boolean', 'true か false')
assertSpokenFailure(engine.simulate('hero.isTrue(true, false);', booleanMission, 0), 'invalid-boolean', 'true か false')

assert.strictEqual(mission(missions, 4).legacyId, 3)
assert(mission(missions, 4).starterCode.includes('看板が「right」の場合には、どうすればいい？'))
assert(mission(missions, 5).starterCode.includes('その他なら、どうすればいい？'))

const infiniteMission = mission(missions, 14)
assert(infiniteMission.infiniteLoopDemo)
assert(infiniteMission.starterCode.startsWith('hero.move("right");'))
assert(infiniteMission.starterCode.includes('while (true)'))
assert(infiniteMission.starterCode.includes('hero.say('))
assert(infiniteMission.instructions.some(text => text.includes('Ctrl+F5')))
assert(infiniteMission.instructions.some(text => text.includes('丸い矢印')))
assert.strictEqual(mission(missions, 15).legacyId, 13)
assert(mission(missions, 15).starterCode.includes('while (!hero.isAtGoal())'))

assert.deepStrictEqual(
  [2, 3, 12, 13, 20].map(curriculum.finalIdForLegacyId),
  [2, 4, 13, 15, 22],
)
assert.deepStrictEqual(
  [2, 3, 4, 13, 14, 15, 22].map(curriculum.legacyIdForFinalId),
  [2, 2, 3, 12, 12, 13, 20],
)

const missionOne = mission(missions, 1)
const orderedMission = mission(missions, 2)
assert.strictEqual(engine.simulate('hero.transform("frog");', missionOne, 0).state.form, 'hero')
assert.strictEqual(engine.simulate('hero.transform("frog");', orderedMission, 0).state.form, 'frog')
assert.strictEqual(engine.FORM_LEVELS.dragon, 99)
assert(engine.simulate('hero.transform("dragon");', orderedMission, 0).state.says.includes(engine.LOCKED_POWER_MESSAGE))
assert.strictEqual(
  engine.simulate('hero.transform("dragon");', Object.assign({}, orderedMission, { wizardLevel: 99 }), 0).state.form,
  'dragon',
)

assertSpokenFailure(engine.simulate('hero.move("north");', orderedMission, 0), 'invalid-direction', '"right"、"left"、"up"、"down"')
assertSpokenFailure(engine.simulate('hero.move("right", "left");', orderedMission, 0), 'invalid-direction', '"right"、"left"、"up"、"down"')
assertSpokenFailure(engine.simulate('hero.readSign("extra");', orderedMission, 0), 'unexpected-parameter', 'かっこの中の情報はいらない')
assertSpokenFailure(engine.simulate('hero.say(123);', orderedMission, 0), 'invalid-say', '文字列を1つ')
assertSpokenFailure(engine.simulate('hero.transform("cat");', orderedMission, 0), 'invalid-transform', engine.INVALID_TRANSFORM_MESSAGE)
assertSpokenFailure(engine.simulate('hero.moove("right");', orderedMission, 0), 'unknown-method', 'hero.moove')

const orderedResult = engine.simulate([
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
].join('\n'), orderedMission, 0)
assert.deepStrictEqual(
  orderedResult.trace.map(frame => frame.type),
  ['move', 'transform', 'say', 'transform', 'move', 'move', 'move', 'transform', 'say', 'move', 'transform'],
)
const speechFrames = orderedResult.trace.filter(frame => frame.type === 'say')
assert.notDeepStrictEqual(
  [speechFrames[0].x, speechFrames[0].y],
  [speechFrames[1].x, speechFrames[1].y],
)

for (const id of [4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 19, 20, 21, 22]) {
  assert(mission(missions, id).starterCode.includes('hero.say('))
}

const indexSource = read('app/assets/japanese-js-quest/index.html')
assert(indexSource.includes('23のミッション'))
assert(indexSource.includes('0 / 23'))
assert(indexSource.indexOf('branch-prompts.js') < indexSource.indexOf('curriculum-v3.js'))
assert(indexSource.indexOf('curriculum-v3.js') < indexSource.indexOf('intro-mission.js'))
assert(!indexSource.includes('../javascripts/ace/ace.js'))
for (const file of ['curriculum-engine.js', 'curriculum-ui.js', 'curriculum-runtime.js']) {
  assert(indexSource.includes(`<script src="${file}"></script>`))
}

const curriculumUiSource = read('app/assets/japanese-js-quest/curriculum-ui.js')
for (const text of ['hero.isTrue(boolean)', 'Boolean', 'alwaysTrue', 'while (true)', 'Ctrl+F5']) {
  assert(curriculumUiSource.includes(text))
}
assert(!curriculumUiSource.includes('removeMovedConstCards'))
assert(!curriculumUiSource.includes("dispatchEvent(new CustomEvent('jsquest:missionloaded'"))
assert(!curriculumUiSource.includes('missionNumber.textContent ='))

const learningGuideSource = read('app/assets/japanese-js-quest/learning-guide.js')
assert(learningGuideSource.includes("title: '看板の値で最初の if を動かそう'"))
assert(learningGuideSource.includes("['<code>===</code> は比較'"))
assert(!learningGuideSource.includes("['<code>const</code> はプレイヤーの魔法'"))
assert(!learningGuideSource.includes("['<code>=</code> は代入'"))
assert(learningGuideSource.includes('legacyIdForFinalId'))

const referenceSource = read('app/assets/japanese-js-quest/reference-panel.js')
const terminologySource = read('app/assets/japanese-js-quest/technical-terms.js')
assert(referenceSource.includes('legacyIdForFinalId'))
assert(terminologySource.includes('legacyIdForFinalId'))

const runtimeSource = read('app/assets/japanese-js-quest/curriculum-runtime.js')
for (const text of [
  'const MISSION_COUNT = 23',
  'const INFINITE_MISSION_ID = 14',
  "{ from: 7, text: '⚠️ ワナ' }",
  "{ from: 9, text: '🔑 カギ' }",
  "{ from: 15, text: '👹 敵' }",
  "document.body.classList.add('infinite-loop-running')",
]) assert(runtimeSource.includes(text))
assert(runtimeSource.indexOf('persistInfiniteCompletion()') < runtimeSource.indexOf('collectDemonstrationGem()'))

const productRules = read('docs/PRODUCT_RULES.md')
const developmentRules = read('docs/DEVELOPMENT_RULES.md')
for (const text of [
  '23 missions numbered 00 through 22',
  '## Boolean lesson and `hero.isTrue`',
  '## Intentional infinite-loop mission',
  'Trap appears from mission 07',
  'Enemy appears from mission 15',
  '## Standalone loading and stable curriculum rendering',
]) assert(productRules.includes(text))
assert(developmentRules.includes('Read `docs/PRODUCT_RULES.md`'))

const totalFields = missions.reduce((sum, item) => sum + item.variants.length, 0)
assert.strictEqual(totalFields, 37)
console.log(`Validated ${missions.length} missions and ${totalFields} fields with stable mission selection, booleans, intentional infinite-loop recovery and wizard progression.`)
