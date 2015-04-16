config = require '../../../server_config'
require '../common'
utils = require '../../../app/core/utils' # Must come after require /common
mongoose = require 'mongoose'

describe 'Clans', ->
  stripe = require('stripe')(config.stripe.secretKey)
  clanURL = getURL('/db/clan')

  clanCount = 0
  createClanName = (name) -> name + clanCount++

  createClan = (user, type, description, done) ->
    name = createClanName 'myclan'
    requestBody =
      type: type
      name: name
    requestBody.description = description if description?
    request.post {uri: clanURL, json: requestBody }, (err, res, body) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe(200)
      expect(body.type).toEqual(type)
      expect(body.name).toEqual(name)
      expect(body.description).toEqual(description) if description?
      expect(body.members?.length).toEqual(1)
      expect(body.members?[0]).toEqual(user.id)
      Clan.findById body._id, (err, clan) ->
        expect(clan.get('type')).toEqual(type)
        expect(clan.get('name')).toEqual(name)
        expect(clan.get('description')).toEqual(description) if description?
        expect(clan.get('members')?.length).toEqual(1)
        expect(clan.get('members')?[0]).toEqual(user._id)
        User.findById user.id, (err, user) ->
          expect(err).toBeNull()
          expect(user.get('clans')?.length).toBeGreaterThan(0)
          expect(_.find user.get('clans'), (clanID) -> clan._id.equals clanID).toBeDefined()
          done(clan)

  it 'Clear database users and clans', (done) ->
    clearModels [User, Clan], (err) ->
      throw err if err
      done()

  it 'Create clan', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', 'test description', (clan) ->
        done()

  it 'Anonymous create clan 401', (done) ->
    logoutUser ->
      requestBody =
        type: 'public'
        name: createClanName 'myclan'
      request.post {uri: clanURL, json: requestBody }, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(401)
        done()

  it 'Create clan missing type 422', (done) ->
    loginNewUser (user1) ->
      requestBody =
        name: createClanName 'myclan'
      request.post {uri: clanURL, json: requestBody }, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(422)
        done()

  it 'Create clan missing name 422', (done) ->
    loginNewUser (user1) ->
      requestBody =
        type: 'public'
      request.post {uri: clanURL, json: requestBody }, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(422)
        done()

  it 'Get public clans', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        createClan user1, 'public', 'the second clan', (clan2) ->
          request.get {uri: "#{clanURL}/-/public" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            expect(body.length).toBeGreaterThan(1)
            done()

  it 'Get public clans anonymous', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        createClan user1, 'public', null, (clan2) ->
          logoutUser ->
            request.get {uri: "#{clanURL}/-/public" }, (err, res, body) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              expect(body.length).toBeGreaterThan(1)
              done()

  it 'Join clan', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        loginNewUser (user2) ->
          request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            Clan.findById clan1.id, (err, clan1) ->
              expect(err).toBeNull()
              expect(clan1.get('members')?.length).toEqual(2)
              expect(_.find clan1.get('members'), (memberID) -> user2._id.equals memberID).toBeDefined()
              User.findById user2.id, (err, user2) ->
                expect(err).toBeNull()
                expect(user2.get('clans')?.length).toBeGreaterThan(0)
                expect(_.find user2.get('clans'), (clanID) -> clan1._id.equals clanID).toBeDefined()
                done()

  it 'Join invalid clan 404', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        loginNewUser (user2) ->
          request.put {uri: "#{clanURL}/1234/join" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(404)
            done()

  it 'Join clan anonymous 401', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        logoutUser ->
          request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(401)
            done()

  it 'Join clan twice 200', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        loginNewUser (user2) ->
          request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            Clan.findById clan1.id, (err, clan1) ->
              expect(err).toBeNull()
              expect(_.find clan1.get('members'), (memberID) -> memberID.equals user2.id).toBeDefined()
              request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                done()

  it 'Leave clan', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', 'do not stay too long', (clan1) ->
        loginNewUser (user2) ->
          request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            request.put {uri: "#{clanURL}/#{clan1.id}/leave" }, (err, res, body) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              Clan.findById clan1.id, (err, clan1) ->
                expect(err).toBeNull()
                expect(_.find clan1.get('members'), (memberID) -> memberID.equals user2.id).toBeUndefined()
                User.findById user2.id, (err, user2) ->
                  expect(err).toBeNull()
                  expect(user2.get('clans').length).toEqual(0)
                  done()

  it 'Leave clan not member 200', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        loginNewUser (user2) ->
          request.put {uri: "#{clanURL}/#{clan1.id}/leave" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            Clan.findById clan1.id, (err, clan1) ->
              expect(err).toBeNull()
              expect(_.find clan1.get('members'), (memberID) -> memberID.equals user2.id).toBeUndefined()
              done()

  it 'Leave owned clan 403', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        request.put {uri: "#{clanURL}/#{clan1.id}/leave" }, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Remove member', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        loginNewUser (user2) ->
          request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            loginUser user1, (user1) ->
              request.put {uri: "#{clanURL}/#{clan1.id}/remove/#{user2.id}" }, (err, res, body) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                Clan.findById clan1.id, (err, clan1) ->
                  expect(err).toBeNull()
                  expect(clan1.get('members').length).toEqual(1)
                  expect(clan1.get('members')[0]).toEqual(user1.get('_id'))
                  User.findById user2.id, (err, user2) ->
                    expect(err).toBeNull()
                    expect(user2.get('clans').length).toEqual(0)
                    done()

  it 'Remove non-member 200', (done) ->
    loginNewUser (user2) ->
      loginNewUser (user1) ->
        createClan user1, 'public', null, (clan1) ->
          request.put {uri: "#{clanURL}/#{clan1.id}/remove/#{user2.id}" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            Clan.findById clan1.id, (err, clan1) ->
              expect(err).toBeNull()
              expect(clan1.get('members').length).toEqual(1)
              expect(clan1.get('members')[0]).toEqual(user1.get('_id'))
              done()

  it 'Remove invalid memberID 404', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        request.put {uri: "#{clanURL}/#{clan1.id}/remove/123" }, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(404)
          done()

  it 'Remove member, not in clan 403', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        loginNewUser (user2) ->
          request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            loginNewUser (user3) ->
              request.put {uri: "#{clanURL}/#{clan1.id}/remove/#{user2.id}" }, (err, res, body) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(403)
                done()

  it 'Remove member, not the owner 403', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        loginNewUser (user2) ->
          request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            loginNewUser (user3) ->
              request.put {uri: "#{clanURL}/#{clan1.id}/join" }, (err, res, body) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                request.put {uri: "#{clanURL}/#{clan1.id}/remove/#{user2.id}" }, (err, res, body) ->
                  expect(err).toBeNull()
                  expect(res.statusCode).toBe(403)
                  done()

  it 'Remove member from owned clan 403', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan1) ->
        request.put {uri: "#{clanURL}/#{clan1.id}/remove/#{user1.id}" }, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Delete clan', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan) ->
        request.del {uri: "#{clanURL}/#{clan.id}" }, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(204)
          User.findById user1.id, (err, user1) ->
            expect(err).toBeNull()
            expect(user1.get('clans').length).toEqual(0)
            done()

  it 'Delete clan anonymous 401', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan) ->
        logoutUser ->
          request.del {uri: "#{clanURL}/#{clan.id}" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(401)
            done()

  it 'Delete clan not owner 403', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan) ->
        loginNewUser (user2) ->
          request.del {uri: "#{clanURL}/#{clan.id}" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(403)
            done()

  it 'Delete clan no longer exists 404', (done) ->
    loginNewUser (user1) ->
      createClan user1, 'public', null, (clan) ->
        request.del {uri: "#{clanURL}/#{clan.id}" }, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(204)
          request.del {uri: "#{clanURL}/#{clan.id}" }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(404)
            done()

  it 'Delete clan invalid ID 404', (done) ->
    loginNewUser (user1) ->
      request.del {uri: "#{clanURL}/1234" }, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(404)
        done()
