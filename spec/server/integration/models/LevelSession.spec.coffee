require '../../common'
LevelSession = require '../../../../server/models/LevelSession'

describe 'LevelSession', ->

  session = new LevelSession(
    permissions: simplePermissions
  )

  it 'clears things first', (done) ->
    clearModels [LevelSession], (err) ->
      expect(err).toBeNull()
      done()

  it 'saves', (done) ->
    session.save (err) ->
      throw err if err
      done()
