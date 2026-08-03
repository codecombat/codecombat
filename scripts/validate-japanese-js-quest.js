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
const conceptCards = require(path.join(__dirname, questPath, 'concept-card-library.js'))
const solutionHelp = require(path.join(__dirname, questPath, 'solution-help.js'))

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

  const partialSolution = solutionHelp.partialForMission(item, engine)
  assert.notStrictEqual(partialSolution, item.solution, `Mission ${item.id} must not expose its final solution`)
  assert(partialSolution.includes('// TODO:'), `Mission ${item.id} partial help must contain a TODO`)
  assert(partialSolution.includes('// ヒント:'), `Mission ${item.id} partial help must contain comments`)

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

  assert(
    item.variants.some((variant, variantIndex) => {
      const result = engine.simulate(partialSolution, item, variantIndex)
      return !engine.evaluate(item, result, partialSolution).passed
    }),
    `Mission ${item.id} partial help must remain incomplete`,
  )
}

const booleanMission = mission(missions, 3)
assert.strictEqual(booleanMission.title, 'true と false')
assert(booleanMission.requirements.booleanDemo)
assert.strictEqual(booleanMission.requirements.state.goal, true)
assert.strictEqual(booleanMission.requirements.state.maxMoves, 2)
for (const source of [
  '// true という値に alwaysTrue という名前をつける',
  'const alwaysTrue = true;',
  'hero.isTrue(alwaysTrue);',
  '// false という値に alwaysFalse という名前をつける',
  'const alwaysFalse = false;',
  'hero.isTrue(alwaysFalse);',
]) assert(booleanMission.starterCode.includes(source))
assert.strictEqual((booleanMission.starterCode.match(/hero\.move\("right"\);/g) || []).length, 2)
assert(booleanMission.originalStarterCode.includes('hero.move("right");'))

const booleanResult = engine.simulate(booleanMission.solution, booleanMission, 0)
assert(engine.evaluate(booleanMission, booleanResult, booleanMission.solution).passed)
assert(booleanResult.state.says.includes(curriculumEngine.TRUE_MESSAGE))
assert(booleanResult.state.says.includes(curriculumEngine.FALSE_MESSAGE))
assert.strictEqual(booleanResult.state.goalReached, true)
assert.strictEqual(booleanResult.state.moves, 2)
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

const storedCards = conceptCards.allCards()
assert.strictEqual(storedCards.length, 35)
assert.strictEqual(new Set(storedCards.map(card => card.id)).size, storedCards.length)
assert(storedCards.every(card => /^concept-card-\d{3}$/.test(card.id)))
assert(storedCards.every(card => Number.isInteger(card.missionId)))
assert(storedCards.every(card => card.titleHtml && card.bodyHtml))
assert.strictEqual(conceptCards.getCard('concept-card-001').titleHtml, '<code>hero</code> はオブジェクト')
assert(conceptCards.getCard('concept-card-007').titleHtml.includes('Boolean'))
assert(conceptCards.getCard('concept-card-010').titleHtml.includes('名前は自分で決められる'))
assert(conceptCards.getCard('concept-card-010').bodyHtml.includes('ローマ字'))
assert(conceptCards.getCard('concept-card-010').bodyHtml.includes('alwaysTrue'))
assert(conceptCards.getCard('concept-card-025').bodyHtml.includes('コンピューターの力を使い続ける危険'))

for (let missionId = 0; missionId < missions.length; missionId++) {
  const guide = conceptCards.getMissionGuide(missionId)
  assert(guide, `Mission ${missionId} must have a concept guide`)
  assert(guide.title)
  assert(guide.cards.length > 0)
  assert.strictEqual(guide.cards.length, guide.cardIds.length)
  guide.cards.forEach((card, index) => {
    assert(card)
    assert.strictEqual(card.id, guide.cardIds[index])
    assert.strictEqual(card.missionId, missionId)
    assert.strictEqual(conceptCards.getCard(card.id), card)
  })
}
assert.deepStrictEqual(
  conceptCards.getMissionGuide(3).cardIds,
  ['concept-card-007', 'concept-card-008', 'concept-card-009', 'concept-card-010', 'concept-card-011'],
)
assert.deepStrictEqual(
  conceptCards.getMissionGuide(4).cardIds,
  ['concept-card-012', 'concept-card-013', 'concept-card-014'],
)

const indexSource = read('app/assets/japanese-js-quest/index.html')
assert(indexSource.includes('23のミッション'))
assert(indexSource.includes('0 / 23'))
assert(indexSource.indexOf('branch-prompts.js') < indexSource.indexOf('curriculum-v3.js'))
assert(indexSource.indexOf('curriculum-v3.js') < indexSource.indexOf('intro-mission.js'))
assert(indexSource.indexOf('concept-card-library.js') < indexSource.indexOf('learning-guide.js'))
assert(indexSource.indexOf('solution-help.js') < indexSource.indexOf('app-v3.js'))
assert(indexSource.includes('id="show-solution"'))
assert(indexSource.includes('disabled hidden>ヘルプ</button>'))
assert(!indexSource.includes('../javascripts/ace/ace.js'))
for (const file of ['curriculum-engine.js', 'curriculum-ui.js', 'curriculum-runtime.js', 'concept-card-library.js', 'solution-help.js']) {
  assert(indexSource.includes(`<script src="${file}"></script>`))
}

const curriculumUiSource = read('app/assets/japanese-js-quest/curriculum-ui.js')
for (const text of ['hero.isTrue(boolean)', 'alwaysTrue', 'while (true)']) {
  assert(curriculumUiSource.includes(text))
}
assert(!curriculumUiSource.includes('renderBooleanGuide'))
assert(!curriculumUiSource.includes('renderInfiniteGuide'))
assert(!curriculumUiSource.includes('guideShell'))
assert(!curriculumUiSource.includes('removeMovedConstCards'))
assert(!curriculumUiSource.includes("dispatchEvent(new CustomEvent('jsquest:missionloaded'"))
assert(!curriculumUiSource.includes('missionNumber.textContent ='))

const learningGuideSource = read('app/assets/japanese-js-quest/learning-guide.js')
assert(learningGuideSource.includes('window.JSQuestConceptCards'))
assert(learningGuideSource.includes('data-concept-card-id'))
assert(learningGuideSource.includes('card.titleHtml'))
assert(learningGuideSource.includes('card.bodyHtml'))
assert(!learningGuideSource.includes('const guides ='))

const appSource = read('app/assets/japanese-js-quest/app-v3.js')
for (const text of [
  'const solutionHelp = window.JSQuestSolutionHelp',
  'let failedAttempts = {}',
  'function recordFailedAttempt (mission)',
  "els.solution.textContent = '答えを見る'",
  "'ほぼ完成コードを見る'",
  'solutionHelp.partialForMission(mission, engine)',
  '管理者用の正解コードを表示しました。保存はしていません。',
]) assert(appSource.includes(text))
assert(!appSource.includes('attempts[mission.id]'))
assert(!appSource.includes('progress.unlocked = missions.length'))
assert(!appSource.includes('localStorage.setItem(codeKeyPrefix + mission.id, mission.solution)'))

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
  'if (corrected !== current) feedback.textContent = corrected',
]) assert(runtimeSource.includes(text))
assert(!runtimeSource.includes('new MutationObserver(correctFinalMessage)'))
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
  '## Concept card reference base',
  'stable, unique ID',
  '`data-concept-card-id`',
  'Future flashcards, quizzes and review activities must reuse the same reference records',
  '## Final answers and learner partial help',
  'only in admin mode',
  'three failed executions',
  'must remain incomplete',
]) assert(productRules.includes(text))
assert(developmentRules.includes('Read `docs/PRODUCT_RULES.md`'))

const totalFields = missions.reduce((sum, item) => sum + item.variants.length, 0)
assert.strictEqual(totalFields, 37)
console.log(`Validated ${missions.length} missions, ${totalFields} fields, ${storedCards.length} canonical concept cards and incomplete learner help.`)