require '../../common'
LevelComponent = require '../../../../server/models/LevelComponent'

describe 'LevelComponent', ->

  raw =
    name: 'Bashes Everything'
    description: 'Makes the unit uncontrollably bash anything bashable, using the bash system.'
    code: 'bash();'
    codeLanguage: 'javascript'
    official: true
    permissions: simplePermissions

  comp = new LevelComponent(raw)

  it 'clears things first', (done) ->
    LevelComponent.remove {}, (err) ->
      expect(err).toBeNull()
      done()

  it 'can be saved', (done) ->
    comp.save (err) ->
      expect(err).toBeNull()
      done()
