require '../../common'
LevelSystem = require '../../../../server/models/LevelSystem'

describe 'LevelSystem', ->

  raw =
    name: 'Bashing'
    description: 'Performs Thang bashing updates for Bashes Thangs.'
    code: """class Bashing extends System
      constructor: (world) ->
        super world
    """
    codeLanguage: 'coffeescript'
    official: true
    permissions: simplePermissions

  comp = new LevelSystem(raw)

  it 'clears things first', (done) ->
    LevelSystem.remove {}, (err) ->
      expect(err).toBeNull()
      done()

  it 'can be saved', (done) ->
    comp.save (err) ->
      expect(err).toBeNull()
      done()
