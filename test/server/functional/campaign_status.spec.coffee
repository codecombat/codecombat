require '../common'

describe '/db/campaign_status', ->
  request = require 'request'
  it 'clears the db first', (done) ->
    clearModels [Campaign, CampaignStatus], (err) ->
      throw err if err
      done()

  user = new User(name:'sup')
  campaign = new Campaign(name:'Project Vengeance.', permissions: simplePermissions)
  stat = {campaign: campaign._id, user: user._id}
  url = getURL('/db/campaign_status')

  it 'can make a CampaignStatus, and ignores the user property given.', (done) ->
    loginJoe (joe) ->
      request.post {uri:url, json:stat}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.user).toBe(joe._id.toString())
        expect(body.user).not.toBe(user._id.toString())
        done()
