#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')

const root = path.join(__dirname, '..')
const questRoot = path.join(root, 'app/assets/japanese-js-quest')
const baseEngine = require(path.join(questRoot, 'engine.js'))
const curriculumEngine = require(path.join(questRoot, 'curriculum-engine.js'))
const engine = curriculumEngine.apply(baseEngine)
const introMission = require(path.join(questRoot, 'intro-mission.js'))
const legacyMissions = require(path.join(questRoot, 'missions.js'))
const curriculum = require(path.join(questRoot, 'curriculum-v3.js'))
const progression = require(path.join(questRoot, 'progression.js'))
const loopRules = require(path.join(questRoot, 'loop-rules.js'))

function read (relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8')
}

curriculum.apply(legacyMissions)
const missions = progression.apply([introMission, ...legacyMissions], engine)
loopRules.apply(missions)

const loopMissionIds = Object.keys(loopRules.LOOP_RULES).map(Number)
assert.deepStrictEqual(loopMissionIds, [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22])

for (const missionId of loopMissionIds) {
  const mission = missions.find(item => item.id === missionId)
  assert(mission, `Missing loop mission ${missionId}`)
  assert(Array.isArray(mission.requirements.sourceCallLimits))
  assert(mission.requirements.sourceCallLimits.length > 0)
  assert(Array.isArray(mission.victoryConditions))
  assert(mission.victoryConditions.some(item => item.label.includes('最大')))

  if (mission.infiniteLoopDemo) continue
  mission.variants.forEach((variant, variantIndex) => {
    const result = engine.simulate(mission.solution, mission, variantIndex)
    const evaluation = engine.evaluate(mission, result, mission.solution)
    assert(result.ok, `Mission ${missionId}, field ${variantIndex + 1} solution must execute`)
    assert(evaluation.passed, `Mission ${missionId}, field ${variantIndex + 1}: ${evaluation.messages.join(' | ')}`)
  })
}

const firstLoopMission = missions.find(item => item.id === 11)
const commentedLoopCheat = [
  '// for (let i = 0; i < 6; i++) {',
  '//   hero.move("right");',
  '// }',
  '',
  'hero.move("right");',
  'hero.move("right");',
  'hero.move("right");',
  'hero.move("right");',
  'hero.move("right");',
  'hero.move("right");',
].join('\n')
const commentedResult = engine.simulate(commentedLoopCheat, firstLoopMission, 0)
const commentedEvaluation = engine.evaluate(firstLoopMission, commentedResult, commentedLoopCheat)
assert(commentedResult.state.goalReached)
assert.strictEqual(commentedEvaluation.passed, false)
assert(commentedEvaluation.messages.some(message => message.includes('for ループを使いましょう')))
assert(commentedEvaluation.messages.some(message => message.includes('hero.move(...) を書けるのは最大 1 回')))

const dummyLoopCheat = [
  'for (let i = 0; i < 0; i++) {',
  '  hero.move("right");',
  '}',
  'hero.move("right");',
  'hero.move("right");',
  'hero.move("right");',
  'hero.move("right");',
  'hero.move("right");',
  'hero.move("right");',
].join('\n')
const dummyResult = engine.simulate(dummyLoopCheat, firstLoopMission, 0)
const dummyEvaluation = engine.evaluate(firstLoopMission, dummyResult, dummyLoopCheat)
assert.strictEqual(dummyEvaluation.passed, false)
assert(dummyEvaluation.messages.some(message => message.includes('今は 7 回あります')))

assert.strictEqual(engine.countMethodCalls('// hero.move("right");\nhero.move("right");', 'move'), 1)
assert(!engine.stripComments('// for (;;) {}').includes('for'))

const indexSource = read('app/assets/japanese-js-quest/index.html')
assert(indexSource.includes('<kbd>Ctrl+F5</kbd> 再読み込み'))
assert(indexSource.includes('<script src="loop-rules.js"></script>'))
assert(indexSource.indexOf('loop-rules.js') < indexSource.indexOf('app-v3.js'))

const runtimeSource = read('app/assets/japanese-js-quest/curriculum-runtime.js')
for (const text of [
  'INFINITE_PREPARE_KEY',
  'preparedOnEarlierPageLoad',
  'markInfinitePreparation',
  '無限ループを準備する',
  'Ctrl+F5 でページを再読み込みしてね',
  'field-mission-heading',
  'victory-conditions',
]) assert(runtimeSource.includes(text))
assert(runtimeSource.indexOf('clearInfinitePreparation()') < runtimeSource.indexOf('persistInfiniteCompletion()'))

const learningGuideSource = read('app/assets/japanese-js-quest/learning-guide.js')
assert(learningGuideSource.includes("無限: 'むげん'"))
assert(learningGuideSource.includes("document.getElementById('field-mission-heading')"))

const styleSource = read('app/assets/japanese-js-quest/adventure-ui.css')
for (const text of [
  '.field-mission-heading',
  '.victory-condition',
  '.button.infinite-prepare',
  '.code-panel.infinite-preparation',
  '#editor-fallback::-webkit-scrollbar',
]) assert(styleSource.includes(text))

const productRules = read('docs/PRODUCT_RULES.md')
for (const text of [
  'two-step reload preparation',
  'source-code call limit',
  'commented-out loop keywords do not satisfy',
  '`MISSION XX - mission title`',
  'same detailed blue scrollbar theme throughout the game',
]) assert(productRules.includes(text))

console.log(`Validated ${loopMissionIds.length} loop missions, source-call limits and staged infinite-loop preparation.`)
