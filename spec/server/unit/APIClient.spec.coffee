User = require '../../../server/models/User'
APIClient = require '../../../server/models/APIClient'

utils = require '../utils'
mongoose = require 'mongoose'

describe 'APIClient', ->
  
  describe 'methods.hasControlOfUser', ->
    it 'gives the woo client control over users created on cp.codecombat.com', ->
      codePlayUser = new User({createdOnHost: 'cp.codecombat.com'})
      otherUser = new User()
      wooClient = new APIClient({_id: mongoose.Types.ObjectId('582a4105053eea2400e0c7e8')})
      otherClient = new APIClient()
      
      expect(wooClient.hasControlOfUser(codePlayUser)).toBe(true)
      expect(wooClient.hasControlOfUser(otherUser)).toBe(false)
      expect(otherClient.hasControlOfUser(codePlayUser)).toBe(false)
      expect(otherClient.hasControlOfUser(otherUser)).toBe(false)
