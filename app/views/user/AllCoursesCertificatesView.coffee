require('app/styles/user/certificates-view.sass')
RootView = require 'views/core/RootView'
User = require 'models/User'
Classroom = require 'models/Classroom'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
Campaign = require 'models/Campaign'
LevelSessions = require 'collections/LevelSessions'
Levels = require 'collections/Levels'
ThangTypeConstants = require 'lib/ThangTypeConstants'
ThangType = require 'models/ThangType'
utils = require 'core/utils'
fetchJson = require 'core/api/fetch-json'
locale = require 'locale/locale'
CourseInstances = require 'collections/CourseInstances'


module.exports = class AllCoursesCertificatesView extends RootView
  id: 'certificates-view'
  template: require 'app/templates/user/certificates-view'

  events:
    'click .print-btn': 'onClickPrintButton'
    'click .toggle-btn': 'onClickToggleButton'

  getTitle: ->
    return 'Certificate' if @user.broadName() is 'Anonymous'
    "Certificate: #{@user.broadName()}"

  hashString: (str) ->
    (str.charCodeAt i for i in [0...str.length]).reduce(((hash, char) -> ((hash << 5) + hash) + char), 5381)  # hash * 33 + c

  initialize: (options, @userID) ->
    @multipleCoursesStats = {}
    @utils = utils
    if @userID is me.id
      @user = me
      if utils.isCodeCombat
        @setHero()
    else
      @user = new User _id: @userID
      @user.fetch()
      @supermodel.trackModel @user
      if utils.isCodeCombat
        @listenToOnce @user, 'sync', => @setHero?()
      @user.fetchNameForClassmate success: (data) =>
        @studentName = User.broadName(data)
        @render?()

    if classroomID = utils.getQueryVariable 'class'
      @classroom = new Classroom _id: classroomID
      @classroom.fetch()
      @supermodel.trackModel @classroom
      @listenToOnce @classroom, 'sync', @onClassroomLoaded


      @courseInstances = new CourseInstances()
      @supermodel.trackRequest @courseInstances.fetchForClassroom(@classroom.get('_id'))      
      @listenToOnce @courseInstances, 'sync', @loadStats




    tenbillion = 10000000
    nintybillion = 90000000
    if features?.chinaUx
      @certificateNumber =   # keep only 8 digits
        ((@hashString(@user.id + @courseInstanceID) % nintybillion) + nintybillion) % nintybillion + tenbillion   # 10000000 ~ 99999999

    @currentLang = me.get('preferredLanguage', true)
    @needLanguageToggle = @currentLang.split('-')[0] != 'en'


  setHero: (heroOriginal=null) ->
    heroOriginal ||= utils.getQueryVariable('hero') or @user.get('heroConfig')?.thangType or ThangTypeConstants.heroes.captain
    @thangType = new ThangType()
    @supermodel.trackRequest @thangType.fetchLatestVersion(heroOriginal, {data: {project:'slug,version,original,extendedName,heroClass'}})
    @thangType.once 'sync', (thangType) =>
      if @thangType.get('heroClass') isnt 'Warrior'
        # We only have basic warrior poses and signatures for now
        @setHero ThangTypeConstants.heroes.captain

  onClassroomLoaded: ->
    @loadStats()
    if me.id is @classroom.get('ownerID')
      @teacherName = me.broadName()
    else
      teacherUser = new User _id: @classroom.get('ownerID')
      teacherUser.fetchNameForClassmate success: (data) =>
        @teacherName = User.broadName(data)
        @render?()

  loadStats: ->
    return unless @courseInstances.loaded and @classroom.loaded

    courses = @classroom.get('courses')
    uncompletedCourses = courses.map((i) => i._id)

    @courseInstances.models.forEach((courseInstance) =>
      courseID = courseInstance.get('courseID')
      uncompletedCourses = uncompletedCourses.filter((i) => i != courseID)
    )    
    
    if uncompletedCourses.length # not all courses are completed
      @multipleCoursesStats = null
      return

    @courseInstances.models.forEach((courseInstance) =>
      courseID = courseInstance.get('courseID')
      sessions = new LevelSessions()
      courseLevels = new Levels()
      course = new Course _id: courseID
      
      calculateStats = =>
        return unless sessions.loaded and courseLevels.loaded and course.loaded and @multipleCoursesStats
        @multipleCoursesStats[courseInstance.get('_id')] = @classroom.statsForSessions sessions, courseInstance.get('courseID'), courseLevels
        @multipleCoursesStats[courseInstance.get('_id')].sessions = sessions
        @multipleCoursesStats[courseInstance.get('_id')].course = course
        @mergeStats()

      sessions.fetchForCourseInstance courseInstance.get('_id'), userID: @userID, data: { project: 'state.complete,level.original,playtime,changed,code,codeLanguage,team' }
      @listenToOnce sessions, 'sync', calculateStats

      courseLevels.fetchForClassroomAndCourse @classroom.get('_id'), courseInstance.get('courseID'), data: { project: 'concepts,practice,assessment,primerLanguage,type,slug,name,original,description,shareable,i18n,thangs.id,thangs.components.config.programmableMethods' }
      @listenToOnce courseLevels, 'sync', calculateStats

      course.fetch()
      @listenToOnce course, 'sync', calculateStats
    )

  getCodeLanguageName: ->
    return 'Code' unless @classroom
    if @course and /web-dev-1/.test @course.get('slug')
      return 'HTML/CSS'
    if @course and /web-dev/.test @course.get('slug')
      return 'HTML/CSS/JS'
    return @classroom.capitalizeLanguageName()

  mergeStats: ->
    @projectLinks = []
    @courseStats = {
      levels: {
        numDone: 0
      },
      linesOfCode: 0
    }

    @concepts = []

    for stat in Object.values @multipleCoursesStats
      if not stat.courseComplete
        @multipleCoursesStats = null
        continue

      @courseStats.levels.numDone += stat.levels.numDone
      @courseStats.linesOfCode += stat.linesOfCode

      @concepts = _.uniq @concepts.concat(stat.course.get('concepts').slice().reverse().slice(0, 10))

      if stat.levels.project
        projectSession = stat.sessions.find (session) => session.get('level').original is stat.levels.project.get('original')
        if projectSession
          do =>
            projectLink = "#{window.location.origin}/play/#{stat.levels.project.get('type')}-level/#{projectSession.id}"
            projectLinkData = { link: projectLink }
            @projectLinks.push(projectLinkData)
            fetchJson('/db/level.session/short-link', method: 'POST', json: {url: projectLink}).then (response) =>
              projectLinkData.shortLink = response.shortLink
              @render()    

  onClickPrintButton: ->
    window.print()

  onClickToggleButton: ->
    newLang = 'en'
    if @currentLang.split('-')[0] == 'en'
      newLang = me.get('preferredLanguage', true)
    @currentLang = newLang
    $.i18n.changeLanguage newLang, =>
      locale.load(newLang).then =>
        @render()


  afterRender: ->
    @autoSizeText '.student-name'

  autoSizeText: (selector) ->
    @$(selector).each (index, el) ->
      while el.scrollWidth > el.offsetWidth or el.scrollHeight > el.offsetHeight
        newFontSize = (parseFloat($(el).css('font-size').slice(0, -2)) * 0.95) + 'px'
        $(el).css('font-size', newFontSize)
