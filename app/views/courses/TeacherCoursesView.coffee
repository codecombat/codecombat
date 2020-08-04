require('app/styles/courses/teacher-courses-view.sass')
CocoCollection = require 'collections/CocoCollection'
CocoModel = require 'models/CocoModel'
Courses = require 'collections/Courses'
Campaigns = require 'collections/Campaigns'
Campaign = require 'models/Campaign'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
User = require 'models/User'
CourseInstance = require 'models/CourseInstance'
Prepaids = require 'collections/Prepaids'
RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-courses-view'
HeroSelectModal = require 'views/courses/HeroSelectModal'
utils = require 'core/utils'
api = require 'core/api'
ozariaUtils = require 'ozaria/site/common/ozariaUtils'

module.exports = class TeacherCoursesView extends RootView
  id: 'teacher-courses-view'
  template: template

  events:
    'click .guide-btn': 'onClickGuideButton'
    'click .play-level-button': 'onClickPlayLevel'
    'click .show-change-log': 'onClickShowChange'

  getMeta: -> { title: "#{$.i18n.t('teacher.courses')} | #{$.i18n.t('common.ozaria')}" }

  initialize: (options) ->
    super(options)
    application.setHocCampaign('') # teachers playing levels from here return here
    @utils = require 'core/utils'
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @courses = new Courses()
    @prepaids = new Prepaids()
    @paidTeacher = me.isAdmin() or me.isPaidTeacher()
    if me.isAdmin()
      @supermodel.trackRequest @courses.fetch()
    else
      @supermodel.trackRequest @courses.fetchReleased()
      @supermodel.trackRequest @prepaids.fetchMineAndShared()
    @campaigns = new Campaigns([], { forceCourseNumbering: true })
    @supermodel.trackRequest @campaigns.fetchByType('course', { data: { project: 'levels,levelsUpdated' } })
    @campaignLevelNumberMap = {}
    @courseChangeLog = {}
    @campaignLevelsModuleMap = {}
    @moduleNameMap = utils.courseModules
    @listenTo @campaigns, 'sync', ->
      @campaigns.models.map((campaign) => Object.assign(@campaignLevelsModuleMap, campaign.getLevelsByModules()))
      # since intro content data is only needed for display names in the dropdown
      # do not add it to supermodel.trackRequest which would increase the load time of the page  
      Campaign.fetchIntroContentDataForLevels(@campaignLevelsModuleMap).then () => @render?()
    window.tracker?.trackEvent 'Classes Guides Loaded', category: 'Teachers', ['Mixpanel']
    @getLevelDisplayNameWithLabel = (level) -> ozariaUtils.getLevelDisplayNameWithLabel(level)
    @getIntroContentNameWithLabel = (content) -> ozariaUtils.getIntroContentNameWithLabel(content)

  onLoaded: ->
    @campaigns.models.forEach (campaign) =>
      levels = campaign.getLevels().models.map (level) =>
        key: level.get('original'), practice: level.get('practice') ? false, assessment: level.get('assessment') ? false
      @campaignLevelNumberMap[campaign.id] = utils.createLevelNumberMap(levels)
    @paidTeacher = @paidTeacher or @prepaids.find((p) => p.get('type') in ['course', 'starter_license'] and p.get('maxRedeemers') > 0)?
    @fetchChangeLog()
    me.getClientCreatorPermissions()?.then(() => @render?())
    @render?()

  fetchChangeLog: ->
    api.courses.fetchChangeLog().then((changeLogInfo) =>
      @courses.models.forEach (course) =>
        changeLog = _.filter(changeLogInfo, { 'id' : course.get('_id') })
        changeLog = _.sortBy(changeLog, 'date')
        @courseChangeLog[course.id] = _.mapValues(_.groupBy(changeLog, 'date'))
      @render?()  
    )
    .catch((e) =>
      console.error(e)
    )

  onClickGuideButton: (e) ->
    courseID = $(e.currentTarget).data('course-id')
    courseName = $(e.currentTarget).data('course-name')
    eventAction = $(e.currentTarget).data('event-action')
    window.tracker?.trackEvent eventAction, category: 'Teachers', courseID: courseID, courseName: courseName, ['Mixpanel']

  onClickPlayLevel: (e) ->
    form = $(e.currentTarget).closest('.play-level-form')
    levelSlug = form.find('.selectpicker').val()
    introIndex = (form.find('.intro-content:selected').data() || {}).index
    courseID = form.data('course-id')
    language = form.find('.language-select').val() or 'javascript'
    window.tracker?.trackEvent 'Classes Guides Play Level', category: 'Teachers', courseID: courseID, language: language, levelSlug: levelSlug, ['Mixpanel']

    # Because we don't know what classroom to match this with, this may have outdated campaign caching:
    campaignLevels = @campaigns.get(@courses.get(courseID).get('campaignID')).getLevels() || []
    if campaignLevels.find((l) => l.get('slug') == levelSlug)?.get('type') == 'intro'
      url = "/play/intro/#{levelSlug}?course=#{courseID}&codeLanguage=#{language}&intro-content=#{introIndex}"
    else
      url = "/play/level/#{levelSlug}?course=#{courseID}&codeLanguage=#{language}"
    application.router.navigate(url, { trigger: true })

  onClickShowChange: (e) ->
    showChangeLog = $(e.currentTarget)
    changeLogDiv = showChangeLog.closest('.course-change-log')
    changeLogText = changeLogDiv.find('.change-log')
    if changeLogText.hasClass('hidden')
      changeLogText.removeClass('hidden')
      showChangeLog.text($.i18n.t('courses.hide_change_log'))
    else
      changeLogText.addClass('hidden')
      showChangeLog.text($.i18n.t('courses.show_change_log'))
