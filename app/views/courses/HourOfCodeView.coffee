app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/hour-of-code-view'
utils = require 'core/utils'


module.exports = class HourOfCodeView extends RootView
  id: 'hour-of-code-view'
  template: template
  
  events:
    'click #student-btn': 'onClickStudentButton'

  constructor: (options) ->
    super(options)
    @setUpHourOfCode()

  setUpHourOfCode: ->
    # If we are coming in at /hoc, then we show the landing page.
    # If we have ?hoc=true (for the step after the landing page), then we show any HoC-specific instructions.
    # If we haven't tracked this player as an hourOfCode player yet, and it's a new account, we do that now.
    @hocLandingPage = true
    @hocMode = true
    elapsed = new Date() - new Date(me.get('dateCreated'))
    if not me.get('hourOfCode') and (@hocLandingPage or @hocMode) and elapsed < 5 * 60 * 1000
      me.set('hourOfCode', true)
      me.patch()
      $('body').append($('<img src="https://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
      application.tracker?.trackEvent 'Hour of Code Begin'

  onClickStudentButton: ->
    @state = 'enrolling'
    @stateMessage = undefined
    @render?()

    $.ajax({
      method: 'POST'
      url: '/db/course_instance/-/create-for-hoc'
      context: @
      success: (data) ->
        app.router.navigate("/courses/#{data.courseID}/#{data._id}", {
          trigger: true
        })
    })

#    jqxhr = $.post()
#    jqxhr.done (data, textStatus, jqXHR) =>
#      application.tracker?.trackEvent 'Finished HoC student course creation', {courseID: courseID}
#      # TODO: handle fetch errors
#      me.fetch(cache: false).always =>
#        courseID = courseID
#        route = "/courses/#{courseID}"
#        viewArgs = [{}, courseID]
#        if data?.length > 0
#          courseInstanceID = data[0]._id
#          route += "/#{courseInstanceID}"
#          viewArgs[0].courseInstanceID = courseInstanceID
#        Backbone.Mediator.publish 'router:navigate',
#          route: route
#          viewClass: 'views/courses/CourseDetailsView'
#          viewArgs: viewArgs
#    jqxhr.fail (xhr, textStatus, errorThrown) =>
#      console.error 'Got an error purchasing a course:', textStatus, errorThrown
#      application.tracker?.trackEvent 'Failed HoC student course creation', status: textStatus
#      if xhr.status is 402
#        @state = 'declined'
#        @stateMessage = arguments[2]
#      else
#        @state = 'unknown_error'
#        @stateMessage = "#{xhr.status}: #{xhr.responseText}"
#      @render?()
