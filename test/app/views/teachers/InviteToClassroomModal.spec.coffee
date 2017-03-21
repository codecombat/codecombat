InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
User = require 'models/User'
factories = require 'test/app/factories'

describe 'InviteToClassroomModal', ->

  modal = null

  beforeEach (done) ->
    window.me = @teacher = factories.makeUser()
    @classroom = factories.makeClassroom({ code: "wordsouphere", codeCamel: "WordSoupHere", ownerID: @teacher.id })
    modal = new InviteToClassroomModal({ @classroom })
    jasmine.demoModal(modal)
    modal.render()
    _.defer done

  describe 'Invite by email', ->
    beforeEach (done) ->
      @emails = ['test@example.com', 'test2@example.com']
      modal.$('#invite-emails-textarea').val(@emails.join('\n'))
      modal.$('#send-invites-btn').click()
      _.defer done

    it 'sends the request', (done) ->
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe("/db/classroom/#{@classroom.id}/invite-members")
      expect(request.method).toBe("POST")
      expect(request.data()['emails[]']).toEqual(@emails)
      _.defer done
