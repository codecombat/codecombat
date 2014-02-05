require '../common'

describe '/db/campaign_draft', ->
  
  draft = {
    level: {}
    user: 'yoyoyo'
  }
  
  request = require 'request'
  it 'clears the db first', (done) ->
    clearModels [LevelDraft], (err) ->
      throw err if err
      done()

  url = getURL('/db/level_draft')

  it 'can make a LevelDraft, and ignores the user property given.', (done) ->
    loginJoe (joe) ->
      request.post {uri:url, json:draft}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.user).toBe(joe._id.toString())
        done()