#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')

const repositoryPath = path.join(__dirname, '..')
const questPath = path.join(repositoryPath, 'app', 'assets', 'japanese-js-quest')
const cards = require(path.join(questPath, 'concept-card-library-extension.js'))
const quizzes = require(path.join(questPath, 'concept-card-quizzes-extension.js'))

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
  'concept-card-005'
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

const index = read('index.html')
const headerCss = read('editor-header-v2.css')

assert(index.includes('<h3>JavaScript editor</h3>'))
assert(!index.includes('<h3>JavaScript</h3><p>Ctrl / ⌘ + Enter で実行</p>'))
assert(index.includes('<div class="panel-heading editor-heading">'))
assert(index.includes('<div class="shortcut-list editor-shortcut-row">'))
for (const shortcut of [
  '<kbd>Ctrl / ⌘ + Enter</kbd> で実行',
  '<kbd>Ctrl+C</kbd> コピー',
  '<kbd>Ctrl+V</kbd> はりつけ',
  '<kbd>Ctrl+Z</kbd> もどす',
  '<kbd>Ctrl+F5</kbd> 再読み込み'
]) assert(index.includes(shortcut))

assert(index.indexOf('concept-card-library.js') < index.indexOf('concept-card-library-extension.js'))
assert(index.indexOf('concept-card-library-extension.js') < index.indexOf('learning-guide.js'))
assert(index.indexOf('concept-card-quizzes.js') < index.indexOf('concept-card-quizzes-extension.js'))
assert(index.indexOf('concept-card-quizzes-extension.js') < index.indexOf('concept-card-memory.js'))
assert(index.indexOf('editor-concept-highlighting.css') < index.indexOf('editor-header-v2.css'))

for (const text of [
  'grid-template-columns: minmax(0, 1fr)',
  'justify-content: center',
  'flex-wrap: nowrap',
  'width: 100%',
  'font-size: 0.82rem'
]) assert(headerCss.includes(text))

console.log('Validated the two-row JavaScript editor header and 38 canonical concept cards with quizzes.')
