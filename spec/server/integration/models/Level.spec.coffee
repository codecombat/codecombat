require '../../common'
Level = require '../../../../server/models/Level'

describe 'Level', ->

  level = new Level(
    name: 'King\'s Peak'
    description: 'Climb a mountain!!!'
    permissions: simplePermissions
    original: new ObjectId()
  )

  it 'clears things first', (done) ->
    clearModels [Level], (err) ->
      expect(err).toBeNull()
      done()

  it 'saves', (done) ->
    level.save (err) ->
      throw err if err
      done()
