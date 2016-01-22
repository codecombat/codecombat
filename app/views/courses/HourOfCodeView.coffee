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
    'click #continue-playing-btn': 'onClickContinuePlayingButton'
    'click #start-new-game-btn': 'onClickStartNewGameButton'
    'click #log-in-btn': 'onClickLogInButton'
    'click #log-out-link': 'onClickLogOutLink'

  initialize: ->
    @setUpHourOfCode()
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @courseInstances.comparator = (ci) -> return ci.get('classroomID') + ci.get('courseID')
    @supermodel.loadCollection(@courseInstances, 'course_instances', { cache: false })

  onCourseInstancesLoaded: ->
    @hourOfCodeCourseInstance = @courseInstances.findWhere({hourOfCode: true})
    if @hourOfCodeCourseInstance
      @sessions = new CocoCollection([], {
        url: "/db/course_instance/#{@hourOfCodeCourseInstance.id}/level_sessions"
        model: LevelSession
      })
      @sessions.comparator = 'created'
      @listenTo @sessions, 'sync', @onSessionsLoaded
      @supermodel.loadCollection(@sessions, 'sessions', { cache: false })

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
      window.tracker?.trackEvent 'Hour of Code Begin'

  onClickContinuePlayingButton: ->
    url = @continuePlayingLink()
    window.tracker?.trackEvent 'HoC continue playing ', category: 'HoC', label: url
    app.router.navigate(url, { trigger: true })

  afterRender: ->
    super()
    @onClickStartNewGameButton() if @getQueryVariable('go') and not @lastLevel

  onClickStartNewGameButton: ->
    # User without hour of code course instance, creates one, starts playing
    modal = new ChooseLanguageModal({
      logoutFirst: @hourOfCodeCourseInstance?
    })
    @openModalView(modal)
    @listenToOnce modal, 'set-language', @startHourOfCodePlay
    window.tracker?.trackEvent 'Start New Game', category: 'HoC', label: 'HoC Start New Game'

  continuePlayingLink: ->
    ci = @hourOfCodeCourseInstance
    "/play/level/#{@lastLevel.get('slug')}?course=#{ci.get('courseID')}&course-instance=#{ci.id}"

  startHourOfCodePlay: ->
    @$('#main-content').hide()
    @$('#begin-hoc-area').removeClass('hide')
    hocCourseInstance = new CourseInstance()
    hocCourseInstance.upsertForHOC({cache: false})
    @listenToOnce hocCourseInstance, 'sync', ->
      url = hocCourseInstance.firstLevelURL()
      document.location.href = url

  onClickLogInButton: ->
    modal = new StudentLogInModal()
    @openModalView(modal)
    modal.on 'want-to-create-account', @onWantToCreateAccount, @
    window.tracker?.trackEvent 'Started Login', category: 'HoC', label: 'HoC Login'

  onWantToCreateAccount: ->
    modal = new StudentSignUpModal()
    @openModalView(modal)
    window.tracker?.trackEvent 'Started Signup', category: 'HoC', label: 'HoC Sign Up'

  onClickLogOutLink: ->
    window.tracker?.trackEvent 'Log Out', category: 'HoC', label: 'HoC Log Out'
    auth.logoutUser()
