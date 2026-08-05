#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')

const repositoryPath = path.join(__dirname, '..')
const questPath = path.join(repositoryPath, 'app', 'assets', 'japanese-js-quest')
const cards = require(path.join(questPath, 'concept-card-library-extension.js'))
const quizzes = require(path.join(questPath, 'concept-card-quizzes-extension.js'))
const missions = require(path.join(questPath, 'missions.js'))
const introMission = require(path.join(questPath, 'intro-mission.js'))
const applyMissionContentPolish = require(path.join(questPath, 'mission-content-polish.js'))

function read (file) {
  return fs.readFileSync(path.join(questPath, file), 'utf8')
}

const allCards = cards.allCards()
const allQuizzes = quizzes.allQuizzes()
const missionOne = cards.getMissionGuide(1)

assert.strictEqual(allCards.length, 38)
assert.strictEqual(new Set(allCards.map(card => card.id)).size, 38)
assert.deepStrictEqual(missionOne.cardIds, [
  'concept-card-037',
  'concept-card-038',
  'concept-card-036',
  'concept-card-005',
])
assert.strictEqual(missionOne.cards.length, 4)

for (const cardId of ['concept-card-037', 'concept-card-038']) {
  const card = cards.getCard(cardId)
  const quiz = quizzes.getQuiz(cardId)
  assert(card)
  assert.strictEqual(card.missionId, 1)
  assert(Array.isArray(quiz))
  assert(quiz.length >= 1 && quiz.length <= 3)
  assert(Object.prototype.hasOwnProperty.call(allQuizzes, cardId))
  for (const item of quiz) {
    assert(item.prompt)
    assert(item.answer)
    assert(item.choices.includes(item.answer))
    assert(item.choices.length >= 3 && item.choices.length <= 4)
  }
}

assert(cards.getCard('concept-card-037').titleHtml.includes('JavaScript'))
assert(cards.getCard('concept-card-037').bodyHtml.includes('プログラミング言語'))
assert(cards.getCard('concept-card-038').titleHtml.includes('Editor'))
assert(cards.getCard('concept-card-038').bodyHtml.includes('コードを読んだり、書いたり、直したり'))
assert(cards.getCard('concept-card-005').bodyHtml.includes('1マスだけ進みます'))
assert(cards.getCard('concept-card-005').bodyHtml.includes('進む回数だけこのメソッドを呼びます'))
assert(quizzes.getQuiz('concept-card-005').some(item => item.answer === '1マス'))

const runtimeRoot = { JSQuestMissions: [introMission, ...missions] }
applyMissionContentPolish(runtimeRoot)
const runtimeMissionOne = runtimeRoot.JSQuestMissions.find(mission => mission.id === 1)
assert(runtimeMissionOne.instructions.includes('ヒーローを光るゴールのマスまで進めるとクリアです。'))
assert.strictEqual(introMission.starterCode, 'hero.say("Hello Yuzu");')
assert.strictEqual(introMission.solution, 'hero.say("Hello Yuzu");')

const singleQuotedLiteral = /(^|[^\w])'(?:\\.|[^'\\])*'/m
for (const mission of runtimeRoot.JSQuestMissions) {
  for (const field of ['starterCode', 'solution']) {
    assert(!singleQuotedLiteral.test(mission[field]), 'Mission ' + mission.id + ' ' + field + ' must use double-quoted string literals')
  }
}

const index = read('index.html')
const headerCss = read('editor-header-v2.css')
const celebration = read('concept-complete-celebration.js')
const celebrationCss = read('concept-complete-celebration.css')
const tooltipLayer = read('global-tooltip-layer.js')
const tooltipCss = read('global-tooltip-layer.css')
const technicalTerms = read('technical-terms.js')
const productRules = fs.readFileSync(path.join(repositoryPath, 'docs', 'PRODUCT_RULES.md'), 'utf8')

assert(index.includes('<h3>JavaScript editor</h3>'))
assert(!index.includes('<h3>JavaScript</h3><p>Ctrl / ⌘ + Enter で実行</p>'))
assert(index.includes('<div class="panel-heading editor-heading">'))
assert(index.includes('<div class="shortcut-list editor-shortcut-row">'))
for (const shortcut of [
  '<kbd>Ctrl / ⌘ + Enter</kbd> で実行',
  '<kbd>Ctrl+C</kbd> コピー',
  '<kbd>Ctrl+V</kbd> はりつけ',
  '<kbd>Ctrl+Z</kbd> もどす',
  '<kbd>Ctrl+F5</kbd> 再読み込み',
]) assert(index.includes(shortcut))

assert(index.indexOf('concept-card-library.js') < index.indexOf('concept-card-library-extension.js'))
assert(index.indexOf('concept-card-library-extension.js') < index.indexOf('learning-guide.js'))
assert(index.indexOf('concept-card-quizzes.js') < index.indexOf('concept-card-quizzes-extension.js'))
assert(index.indexOf('concept-card-quizzes-extension.js') < index.indexOf('concept-card-memory.js'))
assert(index.indexOf('intro-mission.js') < index.indexOf('mission-content-polish.js'))
assert(index.indexOf('concept-card-memory.js') < index.indexOf('concept-complete-celebration.js'))
assert(index.indexOf('editor-concept-highlighting.js') < index.indexOf('global-tooltip-layer.js'))
assert(index.indexOf('global-tooltip-layer.css') > index.indexOf('reference-panel.css'))
assert(index.indexOf('editor-concept-highlighting.css') < index.indexOf('editor-header-v2.css'))

for (const text of [
  'grid-template-columns: minmax(0, 1fr)',
  'justify-content: center',
  'flex-wrap: nowrap',
  'width: 100%',
  'font-size: 0.82rem',
]) assert(headerCss.includes(text))

for (const text of [
  'おめでとう！',
  'ミッションがひらいたよ。',
  '説明を最後まで読んで、下へスクロールしよう。',
  'jsquest:conceptcardschanged',
  'isMissionReady()',
]) assert(celebration.includes(text))
assert(celebrationCss.includes('.concept-complete-icon'))
assert(celebrationCss.includes('var(--success)'))

for (const text of [
  'document.body.appendChild(tooltip)',
  'event.target.closest(\'[data-tooltip]\')',
  'getBoundingClientRect()',
  'querySelectorAll(\'[aria-modal="true"]\')',
  'window.addEventListener(\'scroll\', positionTooltip, true)',
]) assert(tooltipLayer.includes(text))
assert(tooltipCss.includes('z-index: 2147483200'))
assert(tooltipCss.includes('pointer-events: none'))
assert(tooltipCss.includes('.glossary-token::before'))
assert(tooltipCss.includes('display: none !important'))

assert(technicalTerms.includes('canonicalMissionZeroCode = \'hero.say("Hello Yuzu");\''))
assert(technicalTerms.includes('\'hero.say(\\\'Hello Yuzu\\\');\''))

for (const rule of [
  'all concept cards assigned to a mission become validated',
  'double-quoted string literals',
  'one tile in the requested direction',
  'global tooltip layer mounted directly under `body`',
]) assert(productRules.includes(rule))

console.log('Validated the final editor, concept-card, mission-copy, celebration, quote and tooltip UX rules.')
