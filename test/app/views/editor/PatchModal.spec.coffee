LevelComponent = require 'models/LevelComponent'
Patch = require 'models/Patch'

PatchModal = require 'views/editor/PatchModal'

describe 'PatchModal', ->
  describe 'acceptPatch', ->
    it 'triggers LevelComponents and Systems to recompile their code', ->
      levelComponent = new LevelComponent({ code: 'newList = (item.prop for item in list)', id: 'id' })
      levelComponent.markToRevert()
      levelComponent.set('code', 'func = -> console.log()')
      patch = new Patch({delta: levelComponent.getDelta(), target: 'id'})

      levelComponent = new LevelComponent({ code: 'newList = (item.prop for item in list)', id: 'id' })
      levelComponent.markToRevert()
      patchModal = new PatchModal(patch, levelComponent)
      patchModal.render()
      patchModal.acceptPatch()
      expect(levelComponent.get('js').indexOf('function()')).toBeGreaterThan(-1)
