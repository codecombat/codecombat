require '../common'

describe 'Campaign', ->

  raw =
    name:'Battlefield 1942'
    description:'Vacation all over the world!'
    levels: []
    permissions:[
      target:'not_the_public'
      access:'owner'
    ]
    
  campaign = new Campaign(raw)

  it 'clears things first', (done) ->
    Campaign.remove {}, (err) ->
      expect(err).toBeNull()
      done()

  it 'can be saved', (done) ->
    campaign.save (err) ->
      expect(err).toBeNull()
      done()

  
