FacebookHandler = require 'lib/FacebookHandler'

mockAuthEvent = 
  response:
    authResponse:
      accessToken: "aksdhjflkqjrj245234b52k345q344le4j4k5l45j45s4dkljvdaskl"
      userID: "4301938"
      expiresIn: 5138
      signedRequest: "akjsdhfjkhea.3423nkfkdsejnfkd"
    status: "connected"

# Whatev, it's all public info anyway
mockMe =
  id: "4301938"
  email: "scott@codecombat.com"
  first_name: "Scott"
  gender: "male"
  last_name: "Erickson"
  link: "https://www.facebook.com/scott.erickson.779"
  locale: "en_US"
  name: "Scott Erickson"
  timezone: -7
  updated_time: "2014-05-21T04:58:06+0000"
  username: "scott.erickson.779"
  verified: true
  work: [
    {
      employer:
        id: "167559910060759"
        name: "CodeCombat"

      location:
        id: "114952118516947"
        name: "San Francisco, California"

      start_date: "2013-02-28"
    }
    {
      end_date: "2013-01-31"
      employer:
        id: "39198748555"
        name: "Skritter"

      location:
        id: "106109576086811"
        name: "Oberlin, Ohio"

      start_date: "2008-06-01"
    }
  ]
  
window.FB ?= { 
  api: ->
}
  
describe 'lib/FacebookHandler.coffee', ->
  it 'on facebook-logged-in, gets data from FB and sends a patch to the server', ->
    me.clear({silent:true})
    me.markToRevert()
    me.set({_id: '12345'})
    
    spyOn FB, 'api'
    
    new FacebookHandler()
    Backbone.Mediator.publish 'facebook-logged-in', mockAuthEvent
    
    expect(FB.api).toHaveBeenCalled()
    apiArgs = FB.api.calls.argsFor(0)
    expect(apiArgs[0]).toBe('/me')
    apiArgs[1](mockMe) # sending the 'response'
    request = jasmine.Ajax.requests.mostRecent()
    expect(request).toBeDefined()
    params = JSON.parse request.params
    expect(params.firstName).toBe(mockMe.first_name)
    expect(params.lastName).toBe(mockMe.last_name)
    expect(params.gender).toBe(mockMe.gender)
    expect(params.email).toBe(mockMe.email)
    expect(params.facebookID).toBe(mockMe.id)
    expect(request.method).toBe('PATCH')
    expect(_.string.startsWith(request.url, '/db/user/12345')).toBeTruthy()
