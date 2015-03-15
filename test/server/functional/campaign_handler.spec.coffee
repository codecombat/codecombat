require '../common'

levels = [
  {
    name: 'Level 1'
    description: 'This is the first level.'
    disableSpaces: true
    icon: 'somestringyoudontneed.png'
  }
  {
    name: 'Level 2'
    description: 'This is the second level.'
    requiresSubscription: true
    backspaceThrottle: true
  }
]

achievement = {
  name: 'Level 1 Complete'
}

campaign = {
  name: 'Campaign'
  levels: {}
}

levelURL = getURL('/db/level')
achievementURL = getURL('/db/achievement')
campaignURL = getURL('/db/campaign')
campaignSchema = require '../../../app/schemas/models/campaign.schema'
campaignLevelProperties = _.keys(campaignSchema.properties.levels.additionalProperties.properties)

describe '/db/campaign', ->
  it 'prepares the db first', (done) ->
    clearModels [Achievement, Campaign, Level, User], (err) ->
      expect(err).toBeNull()
      loginAdmin (admin) ->
        levels[0].permissions = levels[1].permissions = [{target: admin._id, access: 'owner'}]
        request.post {uri: levelURL, json: levels[0]}, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          levels[0] = body
          request.post {uri: levelURL, json: levels[1]}, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            levels[1] = body
            achievement.related = levels[0].original
            achievement.rewards = { levels: [levels[1].original] }
            request.post {uri: achievementURL, json: achievement}, (err, res, body) ->
              achievement = body
              done()

  it 'can create campaigns', (done) ->
    for level in levels.reverse()
      campaign.levels[level.original] = _.pick level, campaignLevelProperties
    request.post {uri: campaignURL, json: campaign}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      campaign = body
      done()

describe '/db/campaign/.../levels', ->
  it 'fetches the levels in a campaign', (done) ->
    url = getURL("/db/campaign/#{campaign._id}/levels")
    request.get {uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.length).toBe(2)
      expect(_.difference(['level-1', 'level-2'],(level.slug for level in body)).length).toBe(0)
      done()

describe '/db/campaign/.../achievements', ->
  it 'fetches the achievements in the levels in a campaign', (done) ->
    url = getURL("/db/campaign/#{campaign._id}/achievements")
    request.get {uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.length).toBe(1)
      done()
