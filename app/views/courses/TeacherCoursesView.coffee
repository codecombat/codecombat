require('app/styles/courses/teacher-courses-view.sass')
CocoCollection = require 'collections/CocoCollection'
CocoModel = require 'models/CocoModel'
Courses = require 'collections/Courses'
Campaigns = require 'collections/Campaigns'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
User = require 'models/User'
CourseInstance = require 'models/CourseInstance'
Prepaids = require 'collections/Prepaids'
RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-courses-view'
HeroSelectModal = require 'views/courses/HeroSelectModal'
utils = require 'core/utils'

module.exports = class TeacherCoursesView extends RootView
  id: 'teacher-courses-view'
  template: template

  events:
    'click .guide-btn': 'onClickGuideButton'
    'click .play-level-button': 'onClickPlayLevel'

  getTitle: -> return $.i18n.t('teacher.courses')

  initialize: (options) ->
    super(options)
    application.setHocCampaign('') # teachers playing levels from here return here
    @utils = require 'core/utils'
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @courses = new Courses()
    @prepaids = new Prepaids()
    @paidTeacher = me.isAdmin() or me.isTeacher() and /@codeninjas.com$/i.test me.get('email')
    if me.isAdmin()
      @supermodel.trackRequest @courses.fetch()
    else
      @supermodel.trackRequest @courses.fetchReleased()
      @supermodel.trackRequest @prepaids.fetchMineAndShared()
    @campaigns = new Campaigns([], { forceCourseNumbering: true })
    @supermodel.trackRequest @campaigns.fetchByType('course', { data: { project: 'levels,levelsUpdated' } })
    @campaignLevelNumberMap = {}
    window.tracker?.trackEvent 'Classes Guides Loaded', category: 'Teachers', ['Mixpanel']

  onLoaded: ->
    @campaigns.models.forEach (campaign) =>
      levels = campaign.getLevels().models.map (level) =>
        key: level.get('original'), practice: level.get('practice') ? false, assessment: level.get('assessment') ? false
      @campaignLevelNumberMap[campaign.id] = utils.createLevelNumberMap(levels)
    @paidTeacher = @paidTeacher or @prepaids.find((p) => p.get('type') in ['course', 'starter_license'] and p.get('maxRedeemers') > 0)?
    @render?()

  onClickGuideButton: (e) ->
    courseID = $(e.currentTarget).data('course-id')
    courseName = $(e.currentTarget).data('course-name')
    eventAction = $(e.currentTarget).data('event-action')
    window.tracker?.trackEvent eventAction, category: 'Teachers', courseID: courseID, courseName: courseName, ['Mixpanel']

  onClickPlayLevel: (e) ->
    form = $(e.currentTarget).closest('.play-level-form')
    levelSlug = form.find('.level-select').val()
    courseID = form.data('course-id')
    language = form.find('.language-select').val() or 'javascript'
    window.tracker?.trackEvent 'Classes Guides Play Level', category: 'Teachers', courseID: courseID, language: language, levelSlug: levelSlug, ['Mixpanel']
    url = "/play/level/#{levelSlug}?course=#{courseID}&codeLanguage=#{language}"
    firstLevelSlug = @campaigns.get(@courses.at(0).get('campaignID')).getLevels().at(0).get('slug')
    if levelSlug is firstLevelSlug
      @listenToOnce @openModalView(new HeroSelectModal()),
        'hidden': ->
          application.router.navigate(url, { trigger: true })
    else
      application.router.navigate(url, { trigger: true })
