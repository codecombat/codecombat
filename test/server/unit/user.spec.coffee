GLOBAL._ = require 'lodash'

User = require '../../../server/users/User'

describe 'user', ->

  it 'is Admin if it has admin permission', (done) ->
    adminUser = new User()
    adminUser.set('permissions', ['whatever', 'admin', 'user'])
    expect(adminUser.isAdmin()).toBeTruthy()
    done()

  it 'isn\'t Admin if it has no permission', (done) ->
    myUser = new User()
    myUser.set('permissions', [])
    expect(myUser.isAdmin()).toBeFalsy()
    done()

  it 'isn\'t Admin if it has only user permission', (done) ->
    classicUser = new User()
    classicUser.set('permissions', ['user'])
    expect(classicUser.isAdmin()).toBeFalsy()
    done()
