#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')

const repositoryPath = path.join(__dirname, '..')
const questPath = path.join(repositoryPath, 'app', 'assets', 'japanese-js-quest')
const cards = require(path.join(questPath, 'concept-card-library.js'))
const quizzes = require(path.join(questPath, 'concept-card-quizzes.js'))
const highlighting = require(path.join(questPath, 'editor-concept-highlighting.js'))

function read (file) {
  return fs.readFileSync(path.join(questPath, file), 'utf8')
}

function readRepositoryFile (file) {
  return fs.readFileSync(path.join(repositoryPath, file), 'utf8')
}

const allCards = cards.allCards()
const allQuizzes = quizzes.allQuizzes()

assert.strictEqual(allCards.length, 36)
assert.deepStrictEqual(Object.keys(allQuizzes).sort(), allCards.map(card => card.id).sort())

const guidedCardIds = []
for (const [missionId, guideData] of Object.entries(cards.missionGuides)) {
  for (const cardId of guideData.cardIds) {
    const card = cards.getCard(cardId)
    assert(card, `${cardId} must resolve from the canonical card database`)
    assert.strictEqual(card.missionId, Number(missionId))
    guidedCardIds.push(cardId)
  }
}
assert.deepStrictEqual(guidedCardIds.slice().sort(), allCards.map(card => card.id).sort())
assert.strictEqual(new Set(guidedCardIds).size, guidedCardIds.length)
assert.deepStrictEqual(cards.getMissionGuide(1).cardIds, ['concept-card-036', 'concept-card-005'])
assert(cards.getCard('concept-card-036').titleHtml.includes('<code>//</code>'))
assert(cards.getCard('concept-card-036').titleHtml.includes('Comment'))
assert(cards.getCard('concept-card-036').bodyHtml.includes('命令として実行しません'))

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
assert.strictEqual(quizzes.getQuiz('concept-card-036').length, 2)

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

const technicalTermsSource = read('technical-terms.js')
assert(!technicalTermsSource.includes('addCommentExplanation'))
assert(!technicalTermsSource.includes('comment-concept-card'))
assert(!technicalTermsSource.includes('grid.appendChild(article)'))
assert(technicalTermsSource.includes("section.dataset.technicalTermsEnhanced = 'true'"))

const memorySource = read('concept-card-memory.js')
for (const text of [
  'japanese-js-quest-concept-memory-v1',
  'validatedCardIds',
  'previewCardId',
  'isMissionReady',
  'どこかにまちがいがあります',
  '先に「新しい考え方」のカードを全部めくって',
  'jsquest:conceptcardschanged',
  "new URLSearchParams(root.location.search).get('admin') === '1'",
  'ADMIN：正解を選ぶ',
  '正しい選択肢を選びました',
  'inputs.find(input => input.value === item.answer)',
]) assert(memorySource.includes(text))
assert(memorySource.includes("run?.addEventListener('click'"))
assert(memorySource.includes("document.addEventListener('keydown'"))

const learningGuideSource = read('learning-guide.js')
for (const text of [
  'window.JSQuestReadingHelp',
  'scheduleQuizAnnotations',
  "event.target.closest('.concept-card-quiz-button')",
  "document.getElementById('concept-card-quiz-modal')",
  "document.addEventListener('click', scheduleQuizAnnotations, true)",
  'annotateText',
]) assert(learningGuideSource.includes(text))
for (const word of [
  '主人公', '文字列', '命令', '実行', '条件', '比較', '分岐', '繰り返し', '無限',
  '選択肢', '再起動', '危険', '引用符', '優先順位', '総復習',
]) assert(learningGuideSource.includes(word + ':'))

const highlightingSource = read('editor-concept-highlighting.js')
for (const text of [
  'window.JSQuestExecutionGate.canRun()',
  'window.JSQuestExecutionGate?.explainBlockedExecution()',
  'jsquest:conceptcardschanged',
  'caretOffsetFromPoint',
  'document.caretPositionFromPoint',
  'document.caretRangeFromPoint',
  'range.toString().length',
  'fallback.setSelectionRange(clamped, clamped)',
  'ace.session.doc.indexToPosition(clamped, 0)',
  'showEditor(caretOffset)',
]) assert(highlightingSource.includes(text))

const globalStyles = read('styles.css')
for (const variable of [
  '--scrollbar-track',
  '--scrollbar-thumb',
  '--scrollbar-thumb-hover',
  '--scrollbar-size',
]) assert(globalStyles.includes(variable))
assert(globalStyles.includes('*::-webkit-scrollbar'))
assert(globalStyles.includes('scrollbar-color: var(--scrollbar-thumb) var(--scrollbar-track)'))
assert(globalStyles.includes('.code-panel .panel-heading p { font-size: 0.78rem;'))

const highlightingCss = read('editor-concept-highlighting.css')
for (const variable of [
  '--syntax-object-color',
  '--syntax-method-color',
  '--syntax-literal-color',
  '--syntax-comment-color',
  '--syntax-default-color',
]) assert(highlightingCss.includes(variable))
assert(highlightingCss.includes('var(--scrollbar-thumb)'))
assert(highlightingCss.includes('var(--scrollbar-track)'))

const memoryCss = read('concept-card-memory.css')
for (const className of [
  '#mission-learning-guide [data-concept-card-id]:not([data-mastery-prepared])',
  '.concept-memory-card.is-covered',
  '.concept-memory-card.is-preview',
  '.concept-memory-card.is-validated',
  '.concept-card-quiz-modal',
  '.concept-card-quiz-admin-fill',
]) assert(memoryCss.includes(className))
assert(memoryCss.includes('scrollbar-color: var(--scrollbar-thumb) var(--scrollbar-track)'))

const productRules = readRepositoryFile('docs/PRODUCT_RULES.md')
for (const text of [
  '## Concept-card validation and memory',
  'between one and three very simple multiple-choice questions',
  'dedicated concept-memory storage key',
  'Only one unvalidated card may remain previewed at a time',
  '## Simplified pedagogical syntax preview',
  'CSS custom properties',
  'String quote characters remain in the default syntax color',
  'cannot open the editable code view or execute the mission',
  'Whenever a mission or concept card is added or changed',
  'Admin mode provides a quiz-review control',
  'cursor placed at the corresponding source-code offset',
  'Difficult kanji and advanced words in mission explanations, concept cards and mini-quizzes',
  'same blue scrollbar theme throughout the game',
]) assert(productRules.includes(text))

const readme = read('README.md')
for (const text of [
  'Les 36 cartes',
  '// はコメント（Comment）',
  'ADMIN：正解を選ぶ',
  "le curseur est placé à l'endroit correspondant",
  'mêmes infobulles de lecture',
  'même thème bleu que l\'éditeur',
]) assert(readme.includes(text))
assert(!fs.existsSync(path.join(repositoryPath, 'docs', 'LEARNING_REINFORCEMENT_PLAN.md')))

console.log(`Validated ${allCards.length} concept-card quizzes, canonical comment cards, reading help and global scrollbar styling.`)
