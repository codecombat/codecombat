#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')
const vm = require('vm')

const baseEngine = require(path.join(__dirname, '../app/assets/japanese-js-quest/engine.js'))
const curriculumEngine = require(path.join(__dirname, '../app/assets/japanese-js-quest/curriculum-engine.js'))
const engine = curriculumEngine.apply(baseEngine)
const introMission = require(path.join(__dirname, '../app/assets/japanese-js-quest/intro-mission.js'))
const existingMissions = require(path.join(__dirname, '../app/assets/japanese-js-quest/missions.js'))
const curriculum = require(path.join(__dirname, '../app/assets/japanese-js-quest/curriculum-v3.js'))
const progression = require(path.join(__dirname, '../app/assets/japanese-js-quest/progression.js'))

function read (relativePath) {
  return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8')
}

function assertSpokenFailure (result, expectedCode, expectedText) {
  assert.strictEqual(result.ok, false)
  assert.strictEqual(result.error.spoken, true)
  assert.strictEqual(result.error.code, expectedCode)
  assert(result.trace.some(frame => frame.type === 'say' && frame.speech.includes(expectedText)))
}

const branchPromptSource = read('app/assets/japanese-js-quest/branch-prompts.js')
vm.runInNewContext(branchPromptSource, { window: { JSQuestMissions: existingMissions }, Object })
curriculum.apply(existingMissions)
const missions = progression.apply([introMission, ...existingMissions], engine)

assert.strictEqual(missions.length, 23, 'The campaign must contain exactly 23 missions.')
assert.deepStrictEqual(missions.map(mission => mission.id), Array.from({ length: 23 }, (_, index) => index))
assert.strictEqual(missions.find(mission => mission.id === 0).wizardLevel, 0)
assert.strictEqual(missions.find(mission => mission.id === 1).wizardLevel, 0)
for (const id of [2, 3, 4, 5]) assert.strictEqual(missions.find(mission => mission.id === id).wizardLevel, 1)
assert.strictEqual(progression.thresholdForLevel(1), 1)
assert.strictEqual(progression.thresholdForLevel(2), 5)
assert.strictEqual(progression.thresholdForLevel(3), 12)
assert.strictEqual(introMission.starterCode, 'hero.say(\'Hello Yuzu\');')
assert(!introMission.starterCode.includes('//'))
assert.strictEqual(introMission.starterCode.split('\n').length, 1)

const ids = new Set()
for (const mission of missions) {
  assert(!ids.has(mission.id), `Duplicate mission id: ${mission.id}`)
  ids.add(mission.id)
  assert(mission.title && mission.starterCode && mission.solution, `Mission ${mission.id} is incomplete.`)
  assert(Array.isArray(mission.variants) && mission.variants.length > 0, `Mission ${mission.id} has no fields.`)
  if (mission.id > 0) {
    assert(mission.requirements.state.minGems >= 1, `Mission ${mission.id} must require a gem.`)
    assert(mission.variants.every(variant => variant.map.some(row => row.includes('*'))), `Mission ${mission.id} must show a gem.`)
  }

  if (mission.infiniteLoopDemo) continue

  for (let variantIndex = 0; variantIndex < mission.variants.length; variantIndex++) {
    const result = engine.simulate(mission.solution, mission, variantIndex)
    const evaluation = engine.evaluate(mission, result, mission.solution)
    assert(result.ok, `Mission ${mission.id}, field ${variantIndex + 1}: ${result.error && result.error.message}`)
    assert(
      evaluation.passed,
      `Mission ${mission.id}, field ${variantIndex + 1} failed: ${evaluation.messages.join(' | ')}`
    )
  }
}

const booleanMission = missions.find(mission => mission.id === 3)
assert.strictEqual(booleanMission.title, 'true と false')
assert(booleanMission.requirements.booleanDemo)
assert(booleanMission.starterCode.includes('const alwaysTrue = true;'))
assert(booleanMission.starterCode.includes('hero.isTrue(alwaysTrue);'))
assert(booleanMission.starterCode.includes('const alwaysFalse = false;'))
assert(booleanMission.starterCode.includes('hero.isTrue(alwaysFalse);'))
const booleanResult = engine.simulate(booleanMission.solution, booleanMission, 0)
const booleanEvaluation = engine.evaluate(booleanMission, booleanResult, booleanMission.solution)
assert(booleanResult.ok)
assert(booleanEvaluation.passed)
assert(booleanResult.state.says.includes(curriculumEngine.TRUE_MESSAGE))
assert(booleanResult.state.says.includes(curriculumEngine.FALSE_MESSAGE))

const booleanTrue = engine.simulate('hero.isTrue(true);', booleanMission, 0)
assert(booleanTrue.ok)
assert(booleanTrue.state.says.includes('正しいです。'))
const booleanFalse = engine.simulate('hero.isTrue(false);', booleanMission, 0)
assert(booleanFalse.ok)
assert(booleanFalse.state.says.includes('違いますよ。'))
assertSpokenFailure(engine.simulate('hero.isTrue("true");', booleanMission, 0), 'invalid-boolean', 'true か false')
assertSpokenFailure(engine.simulate('hero.isTrue();', booleanMission, 0), 'invalid-boolean', 'true か false')
assertSpokenFailure(engine.simulate('hero.isTrue(true, false);', booleanMission, 0), 'invalid-boolean', 'true か false')

const firstIfMission = missions.find(mission => mission.id === 4)
assert.strictEqual(firstIfMission.legacyId, 3)
assert(firstIfMission.title.includes('if'))
assert(firstIfMission.starterCode.includes('看板が「right」の場合には、どうすればいい？'))
assert(missions.find(mission => mission.id === 5).starterCode.includes('その他なら、どうすればいい？'))

const infiniteMission = missions.find(mission => mission.id === 14)
assert(infiniteMission.infiniteLoopDemo)
assert(infiniteMission.starterCode.includes('while (true)'))
assert(infiniteMission.starterCode.includes('hero.say('))
assert(infiniteMission.starterCode.startsWith('hero.move("right");'))
assert(infiniteMission.instructions.some(text => text.includes('Ctrl+F5')))
assert(infiniteMission.instructions.some(text => text.includes('丸い矢印')))
assert.strictEqual(missions.find(mission => mission.id === 15).legacyId, 13)
assert(missions.find(mission => mission.id === 15).starterCode.includes('while (!hero.isAtGoal())'))

assert.strictEqual(curriculum.finalIdForLegacyId(2), 2)
assert.strictEqual(curriculum.finalIdForLegacyId(3), 4)
assert.strictEqual(curriculum.finalIdForLegacyId(12), 13)
assert.strictEqual(curriculum.finalIdForLegacyId(13), 15)
assert.strictEqual(curriculum.finalIdForLegacyId(20), 22)

const missionOne = missions.find(mission => mission.id === 1)
const orderedMission = missions.find(mission => mission.id === 2)
const lockedTransform = engine.simulate('hero.transform("frog");', missionOne, 0)
assert.strictEqual(lockedTransform.state.form, 'hero')
assert(lockedTransform.state.says.includes(engine.LOCKED_POWER_MESSAGE))
const unlockedTransform = engine.simulate('hero.transform("frog");', orderedMission, 0)
assert.strictEqual(unlockedTransform.state.form, 'frog')
assert.strictEqual(engine.FORM_LEVELS.dragon, 99)
assert(engine.ALLOWED_FORMS.includes('dragon'))
const lockedDragon = engine.simulate('hero.transform("dragon");', orderedMission, 0)
assert.strictEqual(lockedDragon.state.form, 'hero')
assert(lockedDragon.state.says.includes(engine.LOCKED_POWER_MESSAGE))
const level99Mission = Object.assign({}, orderedMission, { wizardLevel: 99 })
assert.strictEqual(engine.simulate('hero.transform("dragon");', level99Mission, 0).state.form, 'dragon')

assertSpokenFailure(engine.simulate('hero.move("north");', orderedMission, 0), 'invalid-direction', '"right"、"left"、"up"、"down"')
assertSpokenFailure(engine.simulate('hero.move("right", "left");', orderedMission, 0), 'invalid-direction', '"right"、"left"、"up"、"down"')
assertSpokenFailure(engine.simulate('hero.readSign("extra");', orderedMission, 0), 'unexpected-parameter', 'かっこの中の情報はいらない')
assertSpokenFailure(engine.simulate('hero.say(123);', orderedMission, 0), 'invalid-say', '文字列を1つ')
assertSpokenFailure(engine.simulate('hero.transform("cat");', orderedMission, 0), 'invalid-transform', engine.INVALID_TRANSFORM_MESSAGE)
assertSpokenFailure(engine.simulate('hero.moove("right");', orderedMission, 0), 'unknown-method', 'hero.moove')

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
  'hero.transform("frog")'
].join('\n')
const orderedResult = engine.simulate(orderedScript, orderedMission, 0)
assert(orderedResult.ok)
assert.deepStrictEqual(
  orderedResult.trace.map(frame => frame.type),
  ['move', 'transform', 'say', 'transform', 'move', 'move', 'move', 'transform', 'say', 'move', 'transform']
)
const speechFrames = orderedResult.trace.filter(frame => frame.type === 'say')
assert.strictEqual(speechFrames.length, 2)
assert.notDeepStrictEqual([speechFrames[0].x, speechFrames[0].y], [speechFrames[1].x, speechFrames[1].y])

for (const id of [4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 19, 20, 21, 22]) {
  assert(missions.find(item => item.id === id).starterCode.includes('hero.say('), `Mission ${id} must contain a branch thinking prompt.`)
}

const indexSource = read('app/assets/japanese-js-quest/index.html')
assert(indexSource.includes('23のミッション'))
assert(indexSource.includes('0 / 23'))
assert(indexSource.indexOf('branch-prompts.js') < indexSource.indexOf('curriculum-v3.js'))
assert(indexSource.indexOf('curriculum-v3.js') < indexSource.indexOf('intro-mission.js'))
assert(indexSource.includes('<script src="curriculum-engine.js"></script>'))
assert(indexSource.includes('<script src="curriculum-ui.js"></script>'))
assert(indexSource.includes('<script src="curriculum-runtime.js"></script>'))

const curriculumUiSource = read('app/assets/japanese-js-quest/curriculum-ui.js')
assert(curriculumUiSource.includes('hero.isTrue(boolean)'))
assert(curriculumUiSource.includes('Boolean'))
assert(curriculumUiSource.includes('alwaysTrue'))
assert(curriculumUiSource.includes('while (true)'))
assert(curriculumUiSource.includes('Ctrl+F5'))
assert(curriculumUiSource.includes('removeMovedConstCards'))

const runtimeSource = read('app/assets/japanese-js-quest/curriculum-runtime.js')
assert(runtimeSource.includes('const MISSION_COUNT = 23'))
assert(runtimeSource.includes('const INFINITE_MISSION_ID = 14'))
assert(runtimeSource.indexOf('persistInfiniteCompletion()') < runtimeSource.indexOf('collectDemonstrationGem()'))
assert(runtimeSource.includes('while (true)'))
assert(runtimeSource.includes("{ from: 7, text: '⚠️ ワナ' }"))
assert(runtimeSource.includes("{ from: 9, text: '🔑 カギ' }"))
assert(runtimeSource.includes("{ from: 15, text: '👹 敵' }"))
assert(runtimeSource.includes("document.body.classList.add('infinite-loop-running')"))

const productRules = read('docs/PRODUCT_RULES.md')
const developmentRules = read('docs/DEVELOPMENT_RULES.md')
assert(productRules.includes('23 missions numbered 00 through 22'))
assert(productRules.includes('## Boolean lesson and `hero.isTrue`'))
assert(productRules.includes('## Intentional infinite-loop mission'))
assert(productRules.includes('Trap appears from mission 07'))
assert(productRules.includes('Enemy appears from mission 15'))
assert(developmentRules.includes('# Development Rules'))
assert(developmentRules.includes('Read `docs/PRODUCT_RULES.md`'))

const totalFields = missions.reduce((sum, mission) => sum + mission.variants.length, 0)
assert.strictEqual(totalFields, 37)
console.log(`Validated ${missions.length} missions and ${totalFields} fields with booleans, intentional infinite-loop recovery, spoken errors and wizard progression.`)
