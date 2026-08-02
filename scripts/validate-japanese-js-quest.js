#!/usr/bin/env node
'use strict'

const assert = require('assert')
const path = require('path')
const engine = require(path.join(__dirname, '../app/assets/japanese-js-quest/engine.js'))
const introMission = require(path.join(__dirname, '../app/assets/japanese-js-quest/intro-mission.js'))
const existingMissions = require(path.join(__dirname, '../app/assets/japanese-js-quest/missions.js'))
const progression = require(path.join(__dirname, '../app/assets/japanese-js-quest/progression.js'))
const missions = progression.apply([introMission, ...existingMissions], engine)

assert.strictEqual(missions.length, 21, 'The campaign must contain exactly 21 missions.')
assert.strictEqual(missions.find(mission => mission.id === 0).wizardLevel, 0)
assert.strictEqual(missions.find(mission => mission.id === 1).wizardLevel, 0)
for (const id of [2, 3, 4, 5]) assert.strictEqual(missions.find(mission => mission.id === id).wizardLevel, 1)
assert.strictEqual(progression.thresholdForLevel(1), 1)
assert.strictEqual(progression.thresholdForLevel(2), 5)
assert.strictEqual(progression.thresholdForLevel(3), 12)

const ids = new Set()
for (const mission of missions) {
  assert(!ids.has(mission.id), `Duplicate mission id: ${mission.id}`)
  ids.add(mission.id)
  assert(mission.title && mission.starterCode && mission.solution, `Mission ${mission.id} is incomplete.`)
  assert(Array.isArray(mission.variants) && mission.variants.length > 0, `Mission ${mission.id} has no variants.`)
  if (mission.id > 0) {
    assert(mission.requirements.state.minGems >= 1, `Mission ${mission.id} must require a gem.`)
    assert(mission.variants.every(variant => variant.map.some(row => row.includes('*'))), `Mission ${mission.id} must show a gem.`)
  }

  for (let variantIndex = 0; variantIndex < mission.variants.length; variantIndex++) {
    const result = engine.simulate(mission.solution, mission, variantIndex)
    const evaluation = engine.evaluate(mission, result, mission.solution)
    assert(result.ok, `Mission ${mission.id}, variant ${variantIndex}: ${result.error && result.error.message}`)
    assert(
      evaluation.passed,
      `Mission ${mission.id}, variant ${variantIndex} failed: ${evaluation.messages.join(' | ')}`
    )
  }
}

const lockedTransform = engine.simulate('hero.transform("frog");', missions.find(mission => mission.id === 1), 0)
assert.strictEqual(lockedTransform.state.form, 'hero')
assert(lockedTransform.state.says.includes(engine.LOCKED_POWER_MESSAGE))

const unlockedTransform = engine.simulate('hero.transform("frog");', missions.find(mission => mission.id === 2), 0)
assert.strictEqual(unlockedTransform.state.form, 'frog')

console.log(`Validated ${missions.length} missions and ${missions.reduce((sum, mission) => sum + mission.variants.length, 0)} variants with wizard progression.`)
