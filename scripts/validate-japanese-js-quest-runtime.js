#!/usr/bin/env node
'use strict'

const assert = require('assert')
const fs = require('fs')
const path = require('path')
const vm = require('vm')

const root = path.join(__dirname, '..')
const questRoot = path.join(root, 'app/assets/japanese-js-quest')

function readQuest (name) {
  return fs.readFileSync(path.join(questRoot, name), 'utf8')
}

const postedMessages = []
const context = vm.createContext({
  console,
  self: {
    postMessage: message => postedMessages.push(message),
  },
})

context.importScripts = function (...names) {
  for (const name of names) {
    vm.runInContext(readQuest(name), context, { filename: name })
  }
}

vm.runInContext(readQuest('quest-worker.js'), context, { filename: 'quest-worker.js' })

const introMission = require(path.join(questRoot, 'intro-mission.js'))
context.self.onmessage({
  data: {
    code: introMission.solution,
    mission: introMission,
    variantIndex: 0,
  },
})

assert.strictEqual(postedMessages.length, 1)
assert(!postedMessages[0].workerError)
assert(postedMessages[0].result.ok)
assert(postedMessages[0].evaluation.passed)
assert(postedMessages[0].result.state.says.includes('Hello Yuzu'))

const workerSource = readQuest('quest-worker.js')
assert(workerSource.includes("importScripts('engine.js', 'curriculum-engine.js')"))
assert(workerSource.includes('workerError'))

const appSource = readQuest('app-v3.js')
for (const text of [
  'let adminUnlockedAll = false',
  'function isUnlocked (index)',
  'const unlocked = isUnlocked(index)',
  'if (!isUnlocked(index) || running) return',
  'adminUnlockedAll = true',
  "new URL('quest-worker.js', window.location.href)",
  '}, 5000)',
]) assert(appSource.includes(text))
assert(!appSource.includes('URL.createObjectURL'))
assert(!appSource.includes('new Blob('))

const curriculumEngineSource = readQuest('curriculum-engine.js')
assert(!curriculumEngineSource.includes('installWorkerAdapter(window'))
assert(!curriculumEngineSource.includes('rootObject.Worker ='))

const learningGuideSource = readQuest('learning-guide.js')
assert(learningGuideSource.includes('scheduleAnnotations'))
assert(!learningGuideSource.includes('new MutationObserver'))

const productRules = fs.readFileSync(path.join(root, 'docs/PRODUCT_RULES.md'), 'utf8')
for (const text of [
  'static `quest-worker.js` worker',
  'must not globally replace or monkey-patch',
  'same admin-unlocked state',
  'bounded number of times',
]) assert(productRules.includes(text))

console.log('Validated mission 00 worker execution, admin unlocking and bounded concept rendering.')
