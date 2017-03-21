require '../../common'
LevelThangType = require '../../../../server/models/LevelThangType'

describe 'LevelThangType', ->

  thang_type = new LevelThangType(
    permissions: simplePermissions
  )

  it 'clears things first', (done) ->
    clearModels [LevelThangType], (err) ->
      expect(err).toBeNull()
      done()

  it 'saves', (done) ->
    thang_type.save (err) ->
      throw err if err
      done()
