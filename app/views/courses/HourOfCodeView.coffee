app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/hour-of-code-view'
utils = require 'core/utils'
LevelSession = require 'models/LevelSession'
Level = require 'models/Level'
ChooseLanguageModal = require 'views/courses/ChooseLanguageModal'
StudentLogInModal = require 'views/courses/StudentLogInModal'
StudentSignUpModal = require 'views/courses/StudentSignUpModal'
auth = require 'core/auth'

module.exports = class HourOfCodeView extends RootView
  id: 'hour-of-code-view'
  template: template

  events:
    'click #student-btn': 'onClickStudentButton'
    'click #start-new-game-btn': 'onClickStartNewGameButton'
    'click #log-in-btn': 'onClickLogInButton'
    'click #log-out-link': 'onClickLogOutLink'

  initialize: ->
    @setUpHourOfCode()
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @courseInstances.comparator = (ci) -> return ci.get('classroomID') + ci.get('courseID')
    @supermodel.loadCollection(@courseInstances, 'course_instances')

  onCourseInstancesLoaded: ->
    @hourOfCodeCourseInstance = @courseInstances.findWhere({hourOfCode: true})
    if @hourOfCodeCourseInstance
      @sessions = new CocoCollection([], {
        url: "/db/course_instance/#{@hourOfCodeCourseInstance.id}/level_sessions"
        model: LevelSession
      })
      @sessions.comparator = 'created'
      @listenTo @sessions, 'sync', @onSessionsLoaded
      @supermodel.loadCollection(@sessions, 'sessions')

  onSessionsLoaded: ->
    @lastSession = @sessions.last()
    if @lastSession
      @lastLevel = new Level()
      levelData = @lastSession.get('level')
      @supermodel.loadModel(@lastLevel, 'level', {
        url: "/db/level/#{levelData.original}/version/#{levelData.majorVersion}"
        data: {
          project: 'name,slug'
        }
      })
    
  setUpHourOfCode: ->
    # If we haven't tracked this player as an hourOfCode player yet, and it's a new account, we do that now.
    elapsed = new Date() - new Date(me.get('dateCreated'))
    if not me.get('hourOfCode') and (elapsed < 5 * 60 * 1000 or me.get('anonymous'))
      me.set('hourOfCode', true)
      me.patch()
      $('body').append($('<img src="https://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
      application.tracker?.trackEvent 'Hour of Code Begin'

  onClickStartNewGameButton: ->
    # user without hour of code course instance, creates one, starts playing
    modal = new ChooseLanguageModal({
      logoutFirst: @hourOfCodeCourseInstance?
    })
    @openModalView(modal)
    @listenToOnce modal, 'set-language', @startHourOfCodePlay
    
  continuePlayingLink: ->
    ci = @hourOfCodeCourseInstance
    "/play/level/#{@lastLevel.get('slug')}?course=#{ci.get('courseID')}&course-instance=#{ci.id}"

  startHourOfCodePlay: ->
    @$('#main-content').hide()
    @$('#begin-hoc-area').removeClass('hide')
    $.ajax({
      method: 'POST'
      url: '/db/course_instance/-/create-for-hoc'
      context: @
      success: (data) ->
        application.tracker?.trackEvent 'Finished HoC student course creation', {courseID: data.courseID}
        url = "/play/level/course-dungeons-of-kithgard?course=#{data.courseID}&course-instance=#{data._id}"
        app.router.navigate(url, { trigger: true })
    })

  onClickLogInButton: ->
    modal = new StudentLogInModal()
    @openModalView(modal)
    modal.on 'want-to-create-account', @onWantToCreateAccount, @

  onWantToCreateAccount: ->
    modal = new StudentSignUpModal()
    @openModalView(modal)

  onClickLogOutLink: ->
    auth.logoutUser() 
   
