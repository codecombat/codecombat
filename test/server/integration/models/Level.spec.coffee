require '../../common'

describe 'Level', ->

  level = new Level(
    name: "King's Peak"
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

  it 'loads again after being saved', (done) ->
    url = getURL('/db/level/'+level._id)
    request.get url, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      sameLevel = JSON.parse(body)
      expect(sameLevel.name).toEqual(level.get 'name')
      expect(sameLevel.description).toEqual(level.get 'description')
      expect(sameLevel.permissions).toEqual(simplePermissions)
      done()
