#GLOBAL._ = require 'lodash'
#
#require '../common'
#AnalyticsUsersActive = require '../../../server/models/AnalyticsUsersActive'
#LevelSession = require '../../../server/models/LevelSession'
#User = require '../../../server/models/User'
#mongoose = require 'mongoose'
#
## TODO: these tests have some rerun/cleanup issues
## TODO: add tests for purchase, payment, subscribe, unsubscribe, and earned achievements
#
## TODO: AnalyticsUsersActive collection isn't currently used.
## TODO: Will remove these tests if we end up ripping out the disabled saveActiveUser calls.
#
#describe 'Analytics', ->
#
#  xit 'registered user', (done) ->
#    clearModels [AnalyticsUsersActive], (err) ->
#      expect(err).toBeNull()
#      user = new User
#        permissions: []
#        name: "Fred" + Math.floor(Math.random() * 10000)
#      user.save (err) ->
#        expect(err).toBeNull()
#        userID = mongoose.Types.ObjectId(user.get('_id'))
#        AnalyticsUsersActive.find {creator : userID}, (err, activeUsers) ->
#          expect(activeUsers.length).toEqual(0)
#          user.register ->
#            AnalyticsUsersActive.find {creator : userID}, (err, activeUsers) ->
#              expect(err).toBeNull()
#              expect(activeUsers.length).toEqual(1)
#              expect(activeUsers[0]?.get('event')).toEqual('register')
#              done()
#
#  xit 'level completed', (done) ->
#    clearModels [AnalyticsUsersActive], (err) ->
#      expect(err).toBeNull()
#      unittest.getNormalJoe (joe) ->
#        userID = mongoose.Types.ObjectId(joe.get('_id'))
#        session = new LevelSession
#          name: 'Beat Gandalf'
#          levelID: 'lotr'
#          permissions: simplePermissions
#          state: complete: false
#          creator: userID
#        session.save (err) ->
#          expect(err).toBeNull()
#          AnalyticsUsersActive.find {creator : userID}, (err, activeUsers) ->
#            expect(activeUsers.length).toEqual(0)
#            session.set 'state', complete: true
#            session.save (err) ->
#              expect(err).toBeNull()
#              AnalyticsUsersActive.find {creator : userID}, (err, activeUsers) ->
#                expect(err).toBeNull()
#                expect(activeUsers.length).toEqual(1)
#                expect(activeUsers[0]?.get('event')).toEqual('level-completed/lotr')
#                done()
#
#  xit 'level playtime', (done) ->
#    clearModels [AnalyticsUsersActive], (err) ->
#      expect(err).toBeNull()
#      unittest.getNormalJoe (joe) ->
#        userID = mongoose.Types.ObjectId(joe.get('_id'))
#        session = new LevelSession
#          name: 'Beat Gandalf'
#          levelID: 'lotr'
#          permissions: simplePermissions
#          playtime: 60
#          creator: userID
#        session.save (err) ->
#          expect(err).toBeNull()
#          AnalyticsUsersActive.find {creator : userID}, (err, activeUsers) ->
#            expect(err).toBeNull()
#            expect(activeUsers.length).toEqual(1)
#            expect(activeUsers[0]?.get('event')).toEqual('level-playtime/lotr')
#            done()
#
