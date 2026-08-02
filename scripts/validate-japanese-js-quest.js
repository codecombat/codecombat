#!/usr/bin/env node
'use strict'

const assert = require('assert')
const path = require('path')
const engine = require(path.join(__dirname, '../app/assets/japanese-js-quest/engine.js'))
const missions = require(path.join(__dirname, '../app/assets/japanese-js-quest/missions.js'))

assert.strictEqual(missions.length, 20, 'The campaign must contain exactly 20 missions.')

const ids = new Set()
for (const mission of missions) {
  assert(!ids.has(mission.id), `Duplicate mission id: ${mission.id}`)
  ids.add(mission.id)
  assert(mission.title && mission.starterCode && mission.solution, `Mission ${mission.id} is incomplete.`)
  assert(Array.isArray(mission.variants) && mission.variants.length > 0, `Mission ${mission.id} has no variants.`)

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

console.log(`Validated ${missions.length} missions and ${missions.reduce((sum, mission) => sum + mission.variants.length, 0)} variants.`)
