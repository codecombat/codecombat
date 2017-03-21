SuperModel = require 'models/SuperModel'
Level = require 'models/Level'
ThangType = require 'models/ThangType'

describe 'Level', ->
  describe 'denormalize', ->
    level = new Level({
      thangs: [
        {
          "thangType": "A"
          "id": "Tharin"
          "components": [
            {"original": "a", "majorVersion": 0}
            {"original": "b", "majorVersion": 0, "config": {i: 2}}
            {"original": "c", "majorVersion": 0, "config": {i: 1, ii: 2, nest: {iii: 3}}}
            # should add one more
          ]
        }
      ]
      type: 'hero'
    })

    thangType = new ThangType({
      original: 'A'
      version: {major: 0, minor: 0}
      components: [
        {"original": "a", "majorVersion": 0, "config": {i: 1}}
        {"original": "c", "majorVersion": 0, "config": {i: 3, nest: {iv: 4}}}
        {"original": "d", "majorVersion": 0, "config": {i: 1}}
      ]
    })

    supermodel = new SuperModel()
    supermodel.registerModel(thangType)

    result = level.denormalize(supermodel)
    tharinThangComponents = result.thangs[0].components

    it 'adds default configs to thangs without any config', ->
      aComp = _.find tharinThangComponents, {original:'a'}
      expect(_.isEqual(aComp.config, {i:1})).toBeTruthy()

    it 'leaves alone configs for components the level thang has but the thang type does not', ->
      bComp = _.find tharinThangComponents, {original:'b'}
      expect(_.isEqual(bComp.config, {i:2})).toBeTruthy()

    it 'merges configs where both the level thang and thang type have one, giving priority to the level thang', ->
      cComp = _.find tharinThangComponents, {original:'c'}
      expect(_.isEqual(cComp.config, {i: 1, ii: 2, nest: {iii: 3, iv: 4}})).toBeTruthy()

    it 'adds components from the thang type that do not exist in the level thang', ->
      dComp = _.find tharinThangComponents, {original:'d'}
      expect(dComp).toBeTruthy()
      expect(_.isEqual(dComp?.config, {i: 1})).toBeTruthy()
