#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')
const vm = require('vm')

const repositoryPath = path.join(__dirname, '..')
const questPath = path.join(repositoryPath, 'app', 'assets', 'japanese-js-quest')
const baseEngine = require(path.join(questPath, 'engine.js'))
const curriculumEngine = require(path.join(questPath, 'curriculum-engine.js'))
const engine = curriculumEngine.apply(baseEngine)
const introMission = require(path.join(questPath, 'intro-mission.js'))
const legacyMissions = require(path.join(questPath, 'missions.js'))
const curriculum = require(path.join(questPath, 'curriculum-v3.js'))
const progression = require(path.join(questPath, 'progression.js'))
const loopRules = require(path.join(questPath, 'loop-rules.js'))

function read (relativePath) {
  return fs.readFileSync(path.join(repositoryPath, relativePath), 'utf8')
}

vm.runInNewContext(
  read('app/assets/japanese-js-quest/branch-prompts.js'),
  { window: { JSQuestMissions: legacyMissions }, Object },
)
curriculum.apply(legacyMissions)
const missions = progression.apply([introMission, ...legacyMissions], engine)
loopRules.apply(missions)

const loopMissionIds = loopRules.loopMissionIds()
assert.deepStrictEqual(loopMissionIds, [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22])

for (const missionId of loopMissionIds) {
  const mission = missions[missionId]
  const requirements = mission.requirements.loopRules
  assert(requirements)
  assert(Number.isInteger(requirements.maxMoves) && requirements.maxMoves > 0)
  assert(requirements.sourceCallLimits && Object.keys(requirements.sourceCallLimits).length > 0)

  if (mission.infiniteLoopDemo) continue

  for (let variantIndex = 0; variantIndex < mission.variants.length; variantIndex++) {
    const result = engine.simulate(mission.solution, mission, variantIndex)
    assert(result.ok, `Mission ${missionId}, field ${variantIndex + 1}: reference code must run`)
    assert(
      engine.evaluate(mission, result, mission.solution).passed,
      `Mission ${missionId}, field ${variantIndex + 1}: reference code must satisfy loop rules`,
    )
  }
}

const firstForMission = missions[11]
const manuallyUnrolled = [
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
const unrolledResult = engine.simulate(manuallyUnrolled, firstForMission, 0)
const unrolledEvaluation = engine.evaluate(firstForMission, unrolledResult, manuallyUnrolled)
assert.strictEqual(unrolledEvaluation.passed, false)
assert(unrolledEvaluation.messages.some(message => message.includes('コードに hero.move(...) を書けるのは最大 1 回です。')))
assert(unrolledEvaluation.messages.some(message => message.includes('今は 6 回あります。')))
assert(unrolledEvaluation.messages.some(message => message.includes('ループの中に命令を書いて繰り返しましょう。')))
assert(unrolledEvaluation.messages.some(message => message.includes('for ループをコードに書きましょう。')))

const commentedMethodCode = [
  'for (let i = 0; i < 6; i++) {',
  '  // hero.move("left");',
  '  hero.move("right");',
  '}',
].join('\n')
const commentedMethodResult = engine.simulate(commentedMethodCode, firstForMission, 0)
assert(engine.evaluate(firstForMission, commentedMethodResult, commentedMethodCode).passed)

const stringMethodCode = [
  'hero.say("hero.move(\\"left\\")");',
  'for (let i = 0; i < 6; i++) {',
  '  hero.move("right");',
  '}',
].join('\n')
const stringMethodResult = engine.simulate(stringMethodCode, firstForMission, 0)
assert(engine.evaluate(firstForMission, stringMethodResult, stringMethodCode).passed)

const runtimeSource = read('app/assets/japanese-js-quest/curriculum-runtime.js')
for (const text of [
  'infinite-loop-preparation-v2',
  'INFINITE_PREPARED_THIS_LOAD',
  'infinite-loop-prepared',
  '↻ 無限ループを準備する',
  '↻ Ctrl+F5 で再読み込み',
  'Ctrl+F5 でページを再読み込みしてね。',
  'persistInfiniteCompletion()',
  "document.body.classList.add('infinite-loop-running')",
  'window.JSQuestLoopRules.describe',
  'window.JSQuestExecutionGate',
]) assert(runtimeSource.includes(text))
assert(runtimeSource.indexOf('persistInfiniteCompletion()') < runtimeSource.indexOf('collectDemonstrationGem()'))
assert(runtimeSource.indexOf('persistInfiniteCompletion()') < runtimeSource.indexOf('startSpeechLoop()'))

const indexSource = read('app/assets/japanese-js-quest/index.html')
assert(indexSource.includes('<kbd>Ctrl+F5</kbd> 再読み込み'))
assert(indexSource.indexOf('loop-rules.js') < indexSource.indexOf('app-v3.js'))

const appSource = read('app/assets/japanese-js-quest/app-v3.js')
for (const text of [
  "id: 'field-mission-heading'",
  'fieldProgress: ensureElement',
  'victoryConditions: ensureElement',
  "'MISSION ' + String(mission.id).padStart(2, '0') + ' - '",
  'loopRules.describe(mission)',
]) assert(appSource.includes(text))

const learningGuideSource = read('app/assets/japanese-js-quest/learning-guide.js')
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
  'same blue scrollbar theme throughout the game',
]) assert(productRules.includes(text))

console.log(`Validated ${loopMissionIds.length} loop missions, source-call limits and staged infinite-loop preparation.`)
