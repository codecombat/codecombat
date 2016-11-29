request = require 'request'
moment = require 'moment'
updateCloseIoLeads = require '../../../scripts/sales/updateCloseIoLeads'
factories = require './closeFactories'

MongoClient = require('mongodb').MongoClient;
ZenProspect = require('../../../scripts/sales/lib/ZenProspect');
utils = require('../../server/utils')

_ = require('lodash')

describe '/scripts/sales/updateCloseIoLeads', ->
  describe 'findCocoContacts', ->
    beforeEach ->
      spyOn(MongoClient, 'connect').and.callFake (url, callback) ->
        db =
          close: _.noop
          collection: (collectionName) ->
            find: ->
              toArray: (callback) ->
                switch collectionName
                  when 'trial.requests'
                    callback(null, [
                      {
                        properties:
                          email: "email@example.com"
                          firstName: "First"
                          lastName: "Last"
                      }
                    ])
                  when 'users'
                    callback(null, [
                      {
                        _id: "userID"
                        emailLower: "email@example.com"
                        email: "email@example.com"
                      }
                    ])
                  when 'classrooms'
                    callback(null, [
                      {
                        ownerID: "userID"
                      }
                    ])
        callback(null, db)

    describe 'when the contact doesn\'t exist on ZP yet', ->
      beforeEach ->
        DO_NOT_CONTACT = '57290b9c7ff0bb3b3ef2bebb'
        spyOn(ZenProspect.Contacts, 'searchAsync').and.returnValue(Promise.resolve([]))
        spyOn(ZenProspect.Contact.prototype, 'save').and.callFake (attrs = {}) ->
          @set(attrs)
          @set { id: 'zpContactID' }
          expect(@get('contact_stage_id')).toEqual(DO_NOT_CONTACT)
          Promise.resolve({})

      it 'creates a new ZP contact', (done) ->
        updateCloseIoLeads.findCocoContacts (err, contacts) ->
          expect(contacts['email@example.com']).toBeDefined()
          expect(ZenProspect.Contact.prototype.save).toHaveBeenCalled()
          done()

    describe 'when the contact already exists on ZP', ->
      beforeEach ->
        DO_NOT_CONTACT = '57290b9c7ff0bb3b3ef2bebb'
        spyOn(ZenProspect.Contacts, 'searchAsync').and.returnValue(Promise.resolve([
          new ZenProspect.Contact { id: 'zpContactID', email: 'email@example.com' }
        ]))
        spyOn(ZenProspect.Contact.prototype, 'update').and.callFake (attrs = {}) ->
          @set(attrs)
          expect(@get('contact_stage_id')).toEqual(DO_NOT_CONTACT)
          Promise.resolve({})
        
      it 'updates the ZP contact', (done) ->
        updateCloseIoLeads.findCocoContacts (err, contacts) ->
          expect(contacts['email@example.com']).toBeDefined()
          expect(ZenProspect.Contact.prototype.update).toHaveBeenCalled()
          done()
