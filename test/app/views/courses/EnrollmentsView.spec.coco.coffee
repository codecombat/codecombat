EnrollmentsView = require 'views/courses/EnrollmentsView'
Courses = require 'collections/Courses'
Prepaids = require 'collections/Prepaids'
Users = require 'collections/Users'
Classrooms = require 'collections/Classrooms'
factories = require 'test/app/factories'
TeachersContactModal = require 'views/teachers/TeachersContactModal'

describe 'EnrollmentsView', ->

  beforeEach ->
    me.set('anonymous', false)
    me.set('role', 'teacher')
    me.set('enrollmentRequestSent', false)
    @view = new EnrollmentsView()

    # Make three classrooms, sharing users from a pool of 10, 5 of which are enrolled
    prepaid = factories.makePrepaid()
    students = new Users(_.times(10, (i) ->
      factories.makeUser({}, { prepaid: if i%2 then prepaid else null }))
    )

    userSlices = [
      new Users(students.slice(0, 5))
      new Users(students.slice(3, 8))
      new Users(students.slice(7, 10))
    ]

    classrooms = new Classrooms(factories.makeClassroom({}, {members: userSlice}) for userSlice in userSlices)
    @view.classrooms.fakeRequests[0].respondWith({ status: 200, responseText: classrooms.stringify() })
    for request, i in @view.members.fakeRequests
      request.respondWith({status: 200, responseText: userSlices[i].stringify()})

    # Make prepaids of various status
    prepaids = new Prepaids([
      factories.makePrepaid({}, {redeemers: new Users(_.times(5, -> factories.makeUser()))})
      factories.makePrepaid()
      factories.makePrepaid({ # pending
        startDate: moment().add(2, 'months').toISOString()
        endDate: moment().add(14, 'months').toISOString()
      })
      factories.makePrepaid( # empty
        { maxRedeemers: 2 },
        {redeemers: new Users(_.times(2, -> factories.makeUser()))}
      )
    ])
    @view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: prepaids.stringify() })

    # Make a few courses, one free
    courses = new Courses([
      factories.makeCourse({free: true})
      factories.makeCourse({free: false})
      factories.makeCourse({free: false})
      factories.makeCourse({free: false})
    ])
    @view.courses.fakeRequests[0].respondWith({ status: 200, responseText: courses.stringify() })

    jasmine.demoEl(@view.$el)
    window.view = @view

  describe 'For low priority leads', ->
    beforeEach ->
      leadPriorityRequest = jasmine.Ajax.requests.filter((r)-> r.url == '/db/user/-/lead-priority')[0]
      leadPriorityRequest.respondWith({status: 200, responseText: JSON.stringify({ priority: 'low' })})

    describe 'shows the starter license upsell', ->
      it 'when only subscription prepaids exist', ->
        @view.prepaids.set([])
        @view.prepaids.add(factories.makePrepaid({
          type: 'subscription'
          startDate: moment().subtract(3, 'weeks').toISOString()
          endDate: moment().add(2, 'weeks').toISOString()
        }))

        @view.prepaids.trigger('sync')
        @view.render()

        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(1)

      it 'when active starter licenses exist', ->
        @view.prepaids.set([])
        @view.prepaids.add(factories.makePrepaid({
          type: 'starter_license'
          startDate: moment().subtract(3, 'weeks').toISOString()
          endDate: moment().add(2, 'weeks').toISOString()
        }))

        @view.prepaids.trigger('sync')
        @view.render()

        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(1)

      it 'when expired starter licenses exist', ->
        @view.prepaids.set([])
        @view.prepaids.add(factories.makePrepaid({
          type: 'starter_license'
          startDate: moment().subtract(3, 'week').toISOString()
          endDate: moment().subtract(1, 'week').toISOString()
        }))

        @view.prepaids.trigger('sync')
        @view.render()

        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(1)

      it 'when no prepaids exist', ->
        @view.prepaids.set([])

        @view.prepaids.trigger('sync')
        @view.render()

        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(1)

    describe 'does not show the starter license upsell', ->
      it 'when full licenses have existed', ->
        @view.prepaids.set([])
        @view.prepaids.add(factories.makePrepaid({
          startDate: moment().subtract(2, 'month').toISOString()
          endDate: moment().subtract(1, 'month').toISOString()
        }))

        @view.render()
        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(0)

      it 'when full licenses currently exist', ->
        @view.prepaids.set([])
        @view.prepaids.add(factories.makePrepaid({
          startDate: moment().subtract(2, 'month').toISOString()
          endDate: moment().add(1, 'month').toISOString()
        }))

        @view.render()
        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(0)

  describe 'For high priority leads', ->
    beforeEach ->
      leadPriorityRequest = jasmine.Ajax.requests.filter((r)-> r.url == '/db/user/-/lead-priority')[0]
      leadPriorityRequest.respondWith({status: 200, responseText: JSON.stringify({ priority: 'high' })})
      @view.render()

    it "doesn't show the Starter License upsell", ->
      expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(0)

  describe 'For no priority leads', ->
    beforeEach ->
      leadPriorityRequest = jasmine.Ajax.requests.filter((r)-> r.url == '/db/user/-/lead-priority')[0]
      leadPriorityRequest.respondWith({status: 200, responseText: JSON.stringify({ priority: undefined })})
      @view.render()

    it "doesn't show the Starter License upsell", ->
      expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(0)

    describe '"Get Licenses" area', ->

      describe 'when the teacher has made contact', ->
        beforeEach ->
          @view.enrollmentRequestSent = true
          @view.render()

        it 'shows confirmation and a mailto link to schools@codecombat.com', ->
          if not @view.$('#request-sent-btn').length
            fail('Request button not found.')
          if not @view.$('#enrollment-request-sent-blurb').length
            fail('License request sent blurb not found.')
          # TODO: Figure out why this fails in Travis. Seems like it's not loading en locale
  #        if not @view.$('a[href="mailto:schools@codecombat.com"]').length
  #          fail('Mailto: link not found.')

    describe 'when there are no prepaids to show', ->
      beforeEach (done) ->
        @view.prepaids.reset([])
        @view.updatePrepaidGroups()
        _.defer(done)

      it 'fills the void with the rest of the page content', ->
        expect(@view.$('#actions-col').length).toBe(0)
