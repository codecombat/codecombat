EnrollmentsView = require 'views/courses/EnrollmentsView'
Courses = require 'collections/Courses'
Prepaids = require 'collections/Prepaids'
Users = require 'collections/Users'
Classrooms = require 'collections/Classrooms'
factories = require 'test/app/factories'
TeachersContactModal = require 'views/teachers/TeachersContactModal'

describe 'EnrollmentsView', ->
  
  beforeEach (done) ->
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
    @view.supermodel.once 'loaded-all', done

    
  it 'shows how many courses there are which enrolled students will have access to', ->
    expect(_.contains(@view.$('#enrollments-blurb').text(), '2–4')).toBe(true)
    if @view.$('#actions-col').length isnt 1
      fail('There should be an #action-col, other tests depend on it.')

  describe '"Get Licenses" area', ->

    describe 'when the teacher has made contact', ->
      beforeEach ->
        me.set('enrollmentRequestSent', true)
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
      
