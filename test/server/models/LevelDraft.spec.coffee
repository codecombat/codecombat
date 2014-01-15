require '../common'

describe 'LevelDraft', ->

  level = new Level(
    name: "King's Peak Redux"
    description: 'Climb a mountain.'
    permissions: simplePermissions
    original: new ObjectId()
  )

  it 'clears things first', (done) ->
    clearModels [Level, LevelDraft], (err) ->
      expect(err).toBeNull()
      done()

  it 'saves', (done) ->
    level.save (err) ->
      throw err if err

      draft = new LevelDraft(
        user: new ObjectId()
        level: level
      )

      draft.save (err) ->
        throw err if err

        LevelDraft.findOne {_id:draft._id}, (err, fetched) ->
          expect(fetched.level.original).toBeDefined()
          done()
