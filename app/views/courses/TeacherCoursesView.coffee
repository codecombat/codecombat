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
api = require 'core/api'

module.exports = class TeacherCoursesView extends RootView
  id: 'teacher-courses-view'
  template: template

  events:
    'click .guide-btn': 'onClickGuideButton'
    'click .play-level-button': 'onClickPlayLevel'
    'click .show-change-log': 'onClickShowChange'
    'click .video-thumbnail': 'onClickVideoThumbnail'

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
    @videoLevels = utils.videoLevels || {}
    window.tracker?.trackEvent 'Classes Guides Loaded', category: 'Teachers', ['Mixpanel']

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

  onClickVideoThumbnail: (e) ->
    @$('#video-modal').modal('show')
    image_src = e.target.src.slice(e.target.src.search('/images'))
    video = (Object.values(@videoLevels || {}).find((l) => l.thumbnail_unlocked == image_src) || {})
    @$('.video-player')[0].src = if me.showChinaVideo() then video.cn_url else video.url

    if !me.showChinaVideo()
      require.ensure(['@vimeo/player'], (require) =>
        VideoPlayer = require('@vimeo/player').default
        @videoPlayer = new VideoPlayer(@$('.video-player')[0])
        @videoPlayer.play().catch((err) => console.error("Error while playing the video:", err))
      , (e) =>
        console.error e
      , 'vimeo')
    @$('#video-modal').on ('hide.bs.modal'), (e)=>
      if me.showChinaVideo()
        @$('.video-player').attr('src', '');
      else
        @videoPlayer?.pause()

  destroy: ->
    @$('#video-modal').modal('hide')
    super()
