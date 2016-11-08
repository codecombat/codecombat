# TODO: use nock for making sure network requests are sent, blackbox whole script
# TODO: improve coverage of various cases; current coverage is poor and incomplete

request = require 'request'
moment = require 'moment'
followupCloseIoLeads = require '../../../scripts/sales/followupCloseIoLeads'
factories = require './closeFactories'

describe '/scripts/sales/followupCloseIoLeads', ->
  beforeEach ->
    spyOn(request, 'getAsync')
    spyOn(request, 'putAsync')
    spyOn(request, 'postAsync')
    spyOn(followupCloseIoLeads, 'log')

  describe 'contactHasEmailAddress', ->
    it 'returns true if the contact has any email addresses', ->
      expect(followupCloseIoLeads.contactHasEmailAddress(factories.makeContact({withEmails: true}))).toBe(true)

    it 'returns false if the contact has no email addresses', ->
      expect(followupCloseIoLeads.contactHasEmailAddress(factories.makeContact())).toBe(false)

  describe 'contactHasPhoneNumbers', ->
    it 'returns true if the contact has any phone numbers', ->
      expect(followupCloseIoLeads.contactHasPhoneNumbers(factories.makeContact({withPhones: true}))).toBe(true)

    it 'returns false if the contact has no phone numbers', ->
      expect(followupCloseIoLeads.contactHasPhoneNumbers(factories.makeContact())).toBe(false)

  describe 'lowercaseEmailsForContact', ->
    it 'returns a list of email addresses all in lower case', ->
      contactEmails = ['Firstname.Lastname@example.com', 'firstname.middle.lastname@example.com']
      lowercaseContactEmails = ['firstname.lastname@example.com', 'firstname.middle.lastname@example.com']
      expect(followupCloseIoLeads.lowercaseEmailsForContact(factories.makeContact({withEmails: contactEmails}))).toEqual(lowercaseContactEmails)

  describe 'general network requests', ->
    describe 'getJsonUrl', ->
      it 'calls request.getAsync with url and json: true', ->
        url = 'http://example.com/model/id'
        followupCloseIoLeads.getJsonUrl(url)
        expect(request.getAsync.calls.argsFor(0)).toEqual([{
          url: url,
          json: true
        }])

    describe 'postJsonUrl', ->

    describe 'putJsonUrl', ->

  describe 'Close.io API requests', ->
    beforeEach ->
      spyOn(followupCloseIoLeads, 'getJsonUrl').and.returnValue(Promise.resolve())
      spyOn(followupCloseIoLeads, 'postJsonUrl').and.returnValue(Promise.resolve())
      spyOn(followupCloseIoLeads, 'putJsonUrl').and.returnValue(Promise.resolve())

    describe 'getSomeLeads', ->

    describe 'getEmailActivityForLead', ->

    describe 'getActivityForLead', ->

    describe 'postEmailActivity', ->

    describe 'postTask', ->

    describe 'sendMail', ->

    describe 'updateLeadStatus', ->

    describe 'theyHaveNotResponded', ->
      beforeEach ->
        @lead = {id: 'lead_1'}
        @contact = factories.makeContact({ withEmails: 2 })

      describe "we haven't even sent them a first email", ->
        beforeEach ->
          spyOn(followupCloseIoLeads, 'getActivityForLead').and.returnValue(Promise.resolve(factories.makeActivityResult()))

        it 'TODO', (done) ->
          followupCloseIoLeads.theyHaveNotResponded(@lead, @contact).then (result) =>
            expect(result).toBe(false)
            done()

      describe "they haven't sent us any email", ->
        beforeEach ->
          spyOn(followupCloseIoLeads, 'getActivityForLead').and.returnValue(Promise.resolve(factories.makeActivityResult({ auto1: {to: [@contact.emails[0].email]}, they_replied: false })))

        it 'TODO', (done) ->
          followupCloseIoLeads.theyHaveNotResponded(@lead, @contact).then (result) =>
            expect(result).toBe(true)
            done()

      describe "they have sent us an email", ->
        beforeEach ->
          spyOn(followupCloseIoLeads, 'getActivityForLead').and.returnValue(Promise.resolve(factories.makeActivityResult({ auto1: {to: [@contact.emails[0].email]}, they_replied: {to: ['sales_1@codecombat.com'], sender: "Some User <#{@contact.emails[0].email}>"} })))
        it 'TODO', (done) ->
          followupCloseIoLeads.theyHaveNotResponded(@lead, @contact).then (result) =>
            expect(result).toBe(false)
            done()

    describe 'createSendFollowupMailFn', ->
      beforeEach ->
        spyOn(followupCloseIoLeads, 'sendMail').and.returnValue(Promise.resolve())
        spyOn(followupCloseIoLeads, 'getTasksForLead').and.returnValue(factories.makeTasksResult(0))
        spyOn(followupCloseIoLeads, 'updateLeadStatus').and.returnValue(Promise.resolve())

      describe 'when we have sent an auto1 email', ->
        beforeEach ->
          spyOn(followupCloseIoLeads, 'isTemplateAuto1').and.returnValue(true)

        describe 'more than 3 days ago', ->
          beforeEach ->
            spyOn(followupCloseIoLeads, 'getActivityForLead').and.returnValue(Promise.resolve(factories.makeActivityResult({ auto1: true })))
            spyOn(followupCloseIoLeads, 'getRandomEmailTemplateAuto2').and.returnValue('template_auto2')

          describe "and they haven't responded to the first auto-email", ->
            it "sends a followup auto-email", (done) ->
              userApiKeyMap = {close_user_1: 'close_io_mail_key_1'}
              lead = factories.makeLead({ auto1: true })
              contactEmails = ['teacher1@example.com', 'teacher1.fullname@example.com']
              followupCloseIoLeads.createSendFollowupMailFn(userApiKeyMap, moment().subtract(3, 'days').toDate(), lead, contactEmails)( =>
                expect(followupCloseIoLeads.sendMail).toHaveBeenCalled()
                expect(followupCloseIoLeads.updateLeadStatus).toHaveBeenCalled()
                done()
              )

        describe 'in the last 3 days', ->
          beforeEach ->
            spyOn(followupCloseIoLeads, 'getActivityForLead').and.returnValue(Promise.resolve(factories.makeActivityResult({ auto1: { date_created: new Date() } })))
            spyOn(followupCloseIoLeads, 'getRandomEmailTemplateAuto2')

          it "doesn't send a followup email or update the lead's status", (done) ->
            userApiKeyMap = {close_user_1: 'close_io_mail_key'}
            lead = factories.makeLead({ auto1: true })
            contactEmails = ['teacher1@example.com', 'teacher1.fullname@example.com']
            followupCloseIoLeads.createSendFollowupMailFn(userApiKeyMap, moment().subtract(3, 'days'), lead, contactEmails)( =>
              expect(followupCloseIoLeads.sendMail).not.toHaveBeenCalled()
              expect(followupCloseIoLeads.updateLeadStatus).not.toHaveBeenCalled()
              done()
            )

    describe 'sendSecondFollowupMails', ->
      beforeEach ->
        apiKeyMap = {
          'close_io_mail_key_1': 'close_user_1'
          'close_io_mail_key_2': 'close_user_2'
        }
        spyOn(followupCloseIoLeads, 'getUserIdByApiKey').and.callFake((key) -> Promise.resolve(apiKeyMap[key]))
        spyOn(followupCloseIoLeads, 'getSomeLeads').and.returnValue(Promise.resolve(factories.makeLeadsResult()))
        spyOn(followupCloseIoLeads, 'theyHaveNotResponded').and.returnValue(Promise.resolve(true))
        spyOn(followupCloseIoLeads, 'createSendFollowupMailFn').and.returnValue((done)->done())
        spyOn(followupCloseIoLeads, 'closeIoMailApiKeys').and.returnValue(['close_io_mail_key_1', 'close_io_mail_key_2'])


      it 'sends emails', (done) ->
        followupCloseIoLeads.sendSecondFollowupMails ->
          expect(followupCloseIoLeads.createSendFollowupMailFn).toHaveBeenCalled()
          done()

    describe 'createAddCallTaskFn', ->
      beforeEach ->
        spyOn(followupCloseIoLeads, 'sendMail')
        spyOn(followupCloseIoLeads, 'getTasksForLead').and.returnValue(Promise.resolve(factories.makeTasksResult(0)))
        spyOn(followupCloseIoLeads, 'getActivityForLead').and.returnValue(Promise.resolve(factories.makeActivityResult({ auto1: true, auto2: true })))
        spyOn(followupCloseIoLeads, 'isTemplateAuto2').and.callFake((template_id) -> template_id is 'template_auto2')
        spyOn(followupCloseIoLeads, 'postTask').and.returnValue(Promise.resolve())

      it 'creates a call task', (done) ->
        userApiKeyMap = {close_user_1: 'close_io_mail_key_1'}
        lead = factories.makeLead({ auto2: true })
        contactEmails = factories.makeContact({ withEmails: ['teacher1@example.com', 'teacher1.fullname@example.com'] })
        followupCloseIoLeads.createAddCallTaskFn(userApiKeyMap, moment().subtract(3, 'days'), lead, contactEmails)( =>
          expect(followupCloseIoLeads.postTask).toHaveBeenCalled()
          done()
        )

    describe 'addCallTasks', ->
      beforeEach ->
        apiKeyMap = {
          'close_io_mail_key_1': 'close_user_1'
          'close_io_mail_key_2': 'close_user_2'
        }
        spyOn(followupCloseIoLeads, 'getUserIdByApiKey').and.callFake((key) -> Promise.resolve(apiKeyMap[key]))
        spyOn(followupCloseIoLeads, 'getSomeLeads').and.returnValue(Promise.resolve(factories.makeLeadsResult()))
        spyOn(followupCloseIoLeads, 'contactHasEmailAddress').and.returnValue(true)
        spyOn(followupCloseIoLeads, 'contactHasPhoneNumbers').and.returnValue(true)
        spyOn(followupCloseIoLeads, 'createAddCallTaskFn').and.returnValue((done)->done())
        spyOn(followupCloseIoLeads, 'closeIoMailApiKeys').and.returnValue(['close_io_mail_key_1', 'close_io_mail_key_2'])

      it 'adds call tasks', (done) ->
        followupCloseIoLeads.addCallTasks ->
          expect(followupCloseIoLeads.createAddCallTaskFn).toHaveBeenCalled()
          done()
