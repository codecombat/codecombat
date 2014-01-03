require '../common'

describe 'CampaignStatus', ->

  user = new User(name:'sup')
  campaign = new Campaign(name:'Project Vengeance.', permissions: simplePermissions)
  stat = new CampaignStatus(user: user._id, campaign: campaign._id)

  it 'clears things first', (done) ->
    clearModels [User, Campaign, CampaignStatus], (err) ->
      expect(err).toBeNull()
      done()

  it 'can be saved', (done) ->
    saveModels [user, campaign, stat], (err) ->
      expect(err).toBeNull()
      done()

  it 'can populate', (done) ->
    CampaignStatus
      .findOne({_id:stat._id})
      .populate('user')
      .populate('campaign')
      .exec (err, c) ->
        expect(err).toBe(null)
        expect(c.user.get('name')).not.toBeUndefined()
        expect(c.campaign.get('name')).not.toBeUndefined()
        done()

  it 'rejects duplicates', (done) ->
    stat2 = new CampaignStatus(user: user._id, campaign: campaign._id)
    stat2.save (err) ->
      expect(err).not.toBe(null)
      done()
