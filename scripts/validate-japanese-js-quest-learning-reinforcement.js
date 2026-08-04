#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')

const questPath = path.join(__dirname, '..', 'app', 'assets', 'japanese-js-quest')
const cards = require(path.join(questPath, 'concept-card-library.js'))
const quizzes = require(path.join(questPath, 'concept-card-quizzes.js'))
const highlighting = require(path.join(questPath, 'editor-concept-highlighting.js'))

function read (file) {
  return fs.readFileSync(path.join(questPath, file), 'utf8')
}

const allCards = cards.allCards()
const allQuizzes = quizzes.allQuizzes()

assert.strictEqual(allCards.length, 35)
assert.deepStrictEqual(Object.keys(allQuizzes).sort(), allCards.map(card => card.id).sort())

for (const card of allCards) {
  const quiz = quizzes.getQuiz(card.id)
  assert(Array.isArray(quiz), `${card.id} must have quiz data`)
  assert(quiz.length >= 1 && quiz.length <= 3, `${card.id} must have one to three questions`)

  for (const item of quiz) {
    assert(item.prompt && item.answer)
    assert(Array.isArray(item.choices))
    assert(item.choices.length >= 3 && item.choices.length <= 4)
    assert(item.choices.includes(item.answer))
    assert.strictEqual(new Set(item.choices).size, item.choices.length)
  }
}

const sample = [
  'const alwaysTrue = true;',
  'hero.isTrue(alwaysTrue);',
  'const direction = "right";',
  '// 読むためのコメント',
].join('\n')
const rendered = highlighting.highlight(sample)

assert(rendered.includes('const <span class="syntax-object">alwaysTrue</span> = <span class="syntax-literal">true</span>;'))
assert(rendered.includes('<span class="syntax-object">hero</span>.<span class="syntax-method">isTrue</span>(<span class="syntax-object">alwaysTrue</span>);'))
assert(rendered.includes('const <span class="syntax-object">direction</span> = &quot;<span class="syntax-literal">right</span>&quot;;'))
assert(rendered.includes('<span class="syntax-comment">// 読むためのコメント</span>'))
assert(!rendered.includes('<span class="syntax-object">const</span>'))
assert(!rendered.includes('<span class="syntax-literal">&quot;</span>'))

const indexSource = read('index.html')
for (const file of [
  'concept-card-memory.css',
  'editor-concept-highlighting.css',
  'concept-card-quizzes.js',
  'concept-card-memory.js',
  'editor-concept-highlighting.js',
]) assert(indexSource.includes(file))
assert(indexSource.indexOf('concept-card-memory.js') < indexSource.indexOf('app-v3.js'))
assert(indexSource.indexOf('app-v3.js') < indexSource.indexOf('editor-concept-highlighting.js'))

const memorySource = read('concept-card-memory.js')
for (const text of [
  'japanese-js-quest-concept-memory-v1',
  'validatedCardIds',
  'previewCardId',
  'isMissionReady',
  'どこかにまちがいがあります',
  '先に「新しい考え方」のカードを全部めくって',
]) assert(memorySource.includes(text))
assert(memorySource.includes("run?.addEventListener('click'"))
assert(memorySource.includes("document.addEventListener('keydown'"))

const highlightingCss = read('editor-concept-highlighting.css')
for (const variable of [
  '--syntax-object-color',
  '--syntax-method-color',
  '--syntax-literal-color',
  '--syntax-comment-color',
  '--syntax-default-color',
]) assert(highlightingCss.includes(variable))

const memoryCss = read('concept-card-memory.css')
for (const className of [
  '.concept-memory-card.is-covered',
  '.concept-memory-card.is-preview',
  '.concept-memory-card.is-validated',
  '.concept-card-quiz-modal',
]) assert(memoryCss.includes(className))

console.log(`Validated ${allCards.length} concept-card quizzes and simplified pedagogical syntax coloring.`)
