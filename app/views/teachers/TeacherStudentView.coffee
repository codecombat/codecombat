require('app/styles/teachers/teacher-student-view.sass')
RootView = require 'views/core/RootView'
Campaigns = require 'collections/Campaigns'
Classroom = require 'models/Classroom'
State = require 'models/State'
Courses = require 'collections/Courses'
Levels = require 'collections/Levels'
LevelSession = require 'models/LevelSession'
LevelSessions = require 'collections/LevelSessions'
User = require 'models/User'
Users = require 'collections/Users'
CourseInstances = require 'collections/CourseInstances'
require 'd3/d3.js'
utils = require 'core/utils'
aceUtils = require 'core/aceUtils'
fullPageTemplate = require 'templates/teachers/teacher-student-view-full'
viewTemplate = require 'templates/teachers/teacher-student-view'

module.exports = class TeacherStudentView extends RootView
  id: 'teacher-student-view'

  events:
    'change #course-dropdown': 'onChangeCourseChart'
    'change .course-select': 'onChangeCourseSelect'
    'click .progress-dot a': 'onClickProgressDot'
    'click .level-progress-dot': 'onClickStudentProgressDot'
    'click .nav-link': 'onClickSolutionTab'

  getTitle: -> return @user?.broadName()
  
  onClickSolutionTab: (e) ->
    link = $(e.target).closest('a')
    levelSlug = link.data('level-slug')
    solutionIndex = link.data('solution-index')
    tracker.trackEvent('Click Teacher Student Solution Tab', {levelSlug, solutionIndex})

  initialize: (options, classroomID, @studentID) ->
    @state = new State({
      'renderOnlyContent': options.renderOnlyContent
    })

    if (options.renderOnlyContent)
      @template = viewTemplate
    else
      @template = fullPageTemplate

    @classroom = new Classroom({_id: classroomID})
    @listenToOnce @classroom, 'sync', @onClassroomSync
    @supermodel.trackRequest(@classroom.fetch())

    if @studentID
      @user = new User({ _id: @studentID })
      @supermodel.trackRequest(@user.fetch())

    @courses = new Courses()
    @supermodel.trackRequest(@courses.fetch({data: { project: 'name,i18n,slug' }}))

    @courseInstances = new CourseInstances()
    @supermodel.trackRequest @courseInstances.fetchForClassroom(classroomID)

    # TODO: fetch only necessary thang data (i.e. levels with student progress, via separate API instead of complicated data.project values)
    @levels = new Levels()
    @supermodel.trackRequest(@levels.fetchForClassroom(classroomID, {data: {project: 'name,original,i18n,primerLanguage,thangs.id,thangs.components.config.programmableMethods.plan.solutions,thangs.components.config.programmableMethods.plan.context'}}))
    @urls = require('core/urls')

    # wrap templates so they translate when called
    translateTemplateText = (template, context) => $('<div />').html(template(context)).i18n().html()
    @singleStudentLevelProgressDotTemplate = _.wrap(require('templates/teachers/hovers/progress-dot-single-student-level'), translateTemplateText)
    @levelProgressMap = {}
    me.getClientCreatorPermissions()?.then(() => @render?())
    super(options)

  onLoaded: ->
    @selectedCourseId = @courses.first().id if @courses.loaded and @courses.length > 0 and not @selectedCourseId
    if @students.loaded and not @destroyed
      @user = _.find(@students.models, (s)=> s.id is @studentID)
      @updateLastPlayedInfo()
      @updateLevelProgressMap()
      @updateLevelDataMap()
      @calculateStandardDev()
      @updateSolutions()
      @render()

    super()
    # Navigate to anchor after loading complete, update selectedCourseId for progress dropdown
    if window.location.hash
      levelSlug = window.location.hash.substring(1)
      @updateSelectedCourseProgress(levelSlug)
      window.location.href = window.location.href 

  afterRender: ->
    super(arguments...)
    @$('.progress-dot, .btn-view-project-level').each (i, el) ->
      dot = $(el)
      dot.tooltip({
        html: true
        container: dot
      }).delegate '.tooltip', 'mousemove', ->
        dot.tooltip('hide')

    @$('.glyphicon-question-sign').each (i, el) ->
      dot = $(el)
      dot.tooltip({
        html: true
        container: dot
      }).delegate '.tooltip', 'mousemove', ->
        dot.tooltip('hide')

    @drawBarGraph()
    @onChangeCourseChart()

    oldEditor.destroy() for oldEditor in @aceEditors ? []
    @aceEditors = []
    aceEditors = @aceEditors
    classLang = @classroom.get('aceConfig')?.language or 'python'
    @$el.find('pre:has(code[class*="lang-"])').each ->
      codeElem = $(@).first().children().first()
      lang = mode for mode of aceUtils.aceEditModes when codeElem?.hasClass('lang-' + mode)
      aceEditor = aceUtils.initializeACE(@, lang or classLang)
      aceEditors.push aceEditor

  updateSolutions: ->
    return unless @classroom?.loaded and @sessions?.loaded and @levels?.loaded
    @levelSolutionsMap = @levels.getSolutionsMap([@classroom.get('aceConfig')?.language, 'html'])
    @levelStudentCodeMap = {}
    for session in @sessions.models when session.get('creator') is @studentID
      # Normal level
      @levelStudentCodeMap[session.get('level').original] = session.get('code')?['hero-placeholder']?['plan']
      # Arena level
      @levelStudentCodeMap[session.get('level').original] ?= session.get('code')?['hero-placeholder-1']?['plan']

  updateSelectedCourseProgress: (levelSlug) ->
    return unless levelSlug
    @selectedCourseId = @classroom.get('courses').find((c) => c.levels.find((l) => l.slug is levelSlug))?._id
    return unless @selectedCourseId
    @render?()

  onClickProgressDot: (e) ->
    @updateSelectedCourseProgress(@$(e.currentTarget).data('level-slug'))

  onChangeCourseChart: (e)->
    if (e)
      selected = ('#visualisation-'+((e.currentTarget).value))
      $("[id|='visualisation']").hide()
      $(selected).show()

  onChangeCourseSelect: (e) ->
    @selectedCourseId = $(e.currentTarget).val()
    @render?()
    window.tracker?.trackEvent 'Change Teacher Student Code Review Course', {category: 'Teachers', classroomId: @classroom.id, studentId: @studentID, @selectedCourseId}

  onClickStudentProgressDot: (e) ->
    levelSlug = $(e.currentTarget).data('level-slug')
    levelProgress = $(e.currentTarget).data('level-progress')
    window.tracker?.trackEvent 'Click Teacher Student Code Review Progress Dot', {category: 'Teachers', classroomId: @classroom.id, courseId: @selectedCourseId, studentId: @studentID, levelSlug, levelProgress}

  questionMarkHtml: (i18nBlurb) ->
    "<div style='text-align: left; width: 400px; font-family:Open Sans, sans-serif;'>" + $.i18n.t(i18nBlurb) + "</div>"

  calculateStandardDev: ->
    return unless @courses.loaded and @levels.loaded and @sessions?.loaded and @levelData

    levelSessionsByStudentByLevel = {}
    for session in @sessions.models
      userSessions = levelSessionsByStudentByLevel[session.get('creator')] or {}
      userSessionsForLevel = userSessions[session.get('level').original] or []
      userSessionsForLevel.push session
      userSessions[session.get('level').original] = userSessionsForLevel
      levelSessionsByStudentByLevel[session.get('creator')] = userSessions
    levelDataByLevel = {}
    for levelDatum in @levelData
      levelDataByLevel[levelDatum.levelID] = levelDatum
    @courseComparisonMap = []
    for versionedCourse in @classroom.getSortedCourses() or []
      course = @courses.get(versionedCourse._id)
      numbers = []
      studentCourseTotal = 0
      members = 0 #this is the COUNT for our standard deviation, number of members who have played all of the levels this student has played.
      for member in @classroom.get('members')
        number = 0
        memberPlayed = 0 # number of levels a member has played that this student has also played
        for versionedLevel in versionedCourse.levels
          sessions = (levelSessionsByStudentByLevel[member] ? {})[versionedLevel.original] ? []
          for session in sessions
            playedLevel = levelDataByLevel[session.get('level').original]
            if playedLevel.levelProgress is 'complete' or playedLevel.levelProgress is 'started'
              number += session.get('playtime') or 0
              memberPlayed += 1
            if session.get('creator') is @studentID
              studentCourseTotal += session.get('playtime') or 0
        if memberPlayed > 0 then members += 1
        numbers.push number

      # add all numbers[]
      sum = numbers.reduce (a,b) -> a + b

      # divide by members to get MEAN, remember MEAN is only an average of the members' performance on levels THIS student has done.
      mean = sum/members

      # # for each number in numbers[], subtract MEAN then SQUARE, add all, then divide by COUNT to get VARIANCE
      diffSum = numbers.map((num) -> (num-mean)**2).reduce (a,b) -> a+b
      variance = (diffSum / members)

      # square root of VARIANCE is standardDev
      StandardDev = Math.sqrt(variance)

      perf = -(studentCourseTotal - mean) / StandardDev
      perf = if perf > 0 then Math.ceil(perf) else Math.floor(perf)

      @courseComparisonMap.push {
        courseModel: course
        courseID: course.get('_id')
        studentCourseTotal: studentCourseTotal
        standardDev: StandardDev
        mean: mean
        performance: perf
      }

    # console.log (@courseComparisonMap)

  drawBarGraph: ->
    return unless @courses.loaded and @levels.loaded and @sessions?.loaded and @levelData and @courseComparisonMap

    WIDTH = 1142
    HEIGHT = 600
    MARGINS = {
      top: 50
      right: 20
      bottom: 50
      left: 70
    }


    for versionedCourse in @classroom.getSortedCourses() or []
      # this does all of the courses, logic for whether student was assigned is in corresponding jade file
      vis = d3.select('#visualisation-'+versionedCourse._id)
      # TODO: continue if selector isn't found.
      courseLevelData = []
      for level in @levelData when level.courseID is versionedCourse._id
        if level.assessment
          continue
        courseLevelData.push level

      course = @courses.get(versionedCourse._id)
      levels = @classroom.getLevels({courseID: course.id}).models


      xRange = d3.scale.ordinal().rangeRoundBands([MARGINS.left, WIDTH - MARGINS.right], 0.1).domain(courseLevelData.map( (d) -> d.levelIndex))
      yRange = d3.scale.linear().range([HEIGHT - (MARGINS.top), MARGINS.bottom]).domain([0, d3.max(courseLevelData, (d) -> if d.classAvg > d.studentTime then d.classAvg else d.studentTime)])
      xAxis = d3.svg.axis().scale(xRange).tickSize(1).tickSubdivide(true)
      yAxis = d3.svg.axis().scale(yRange).tickSize(1).orient('left').tickSubdivide(true)

      vis.append('svg:g').attr('class', 'x axis').attr('transform', 'translate(0,' + (HEIGHT - (MARGINS.bottom)) + ')').call xAxis
      vis.append('svg:g').attr('class', 'y axis').attr('transform', 'translate(' + MARGINS.left + ',0)').call yAxis

      chart = vis.selectAll('rect')
        .data(courseLevelData)
        .enter()
      # draw classroom average bars
      chart.append('rect')
        .attr('class', 'classroom-bar')
        .attr('x', ((d) -> xRange(d.levelIndex) + (xRange.rangeBand())/2))
        .attr('y', (d) -> yRange(d.classAvg))
        .attr('width', (xRange.rangeBand())/2)
        .attr('height', (d) -> HEIGHT - (MARGINS.bottom) - yRange(d.classAvg))
        .attr('fill', '#5CB4D0')
      # add classroom average values
      chart.append('text')
        .attr('x', ((d) -> xRange(d.levelIndex) + (xRange.rangeBand())/2))
        .attr('y', ((d) -> yRange(d.classAvg) - 3 ))
        .text((d)-> if d.classAvg isnt 0 and d.classAvg isnt d.studentTime then d.classAvg)
        .attr('class', 'label')
      # draw student playtime bars
      chart.append('rect')
        .attr('class', 'student-bar')
        .attr('x', ((d) -> xRange(d.levelIndex)))
        .attr('y', (d) -> yRange(d.studentTime))
        .attr('width', (xRange.rangeBand())/2)
        .attr('height', (d) -> HEIGHT - (MARGINS.bottom) - yRange(d.studentTime))
        .attr('fill', (d) -> if d.levelProgress is 'complete' then '#20572B' else '#F2BE19')
      # add student playtime value
      chart.append('text')
        .attr('x', ((d) -> xRange(d.levelIndex)) )
        .attr('y', ((d) -> yRange(d.studentTime) - 3 ))
        .text((d)-> if d.studentTime isnt 0 then d.studentTime)
        .attr('class', 'label')

      labels = vis.append("g").attr("class", "labels")
      # add Playtime axis label
      labels.append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 20)
        .attr("x", - HEIGHT/2)
        .attr("dy", ".71em")
        .style("text-anchor", "middle")
        .text($.i18n.t("teacher.playtime_axis"))
      # add levels axis label
      labels.append("text")
        .attr("x", WIDTH/2)
        .attr("y", HEIGHT - 10)
        .text($.i18n.t("teacher.levels_axis") + " " + course.getTranslatedName())
        .style("text-anchor", "middle")


  onClassroomSync: ->
    # Now that we have the classroom from db, can request all level sessions for this classroom
    @sessions = new LevelSessions()
    @sessions.comparator = 'changed' # Sort level sessions by changed field, ascending
    @listenTo @sessions, 'sync', @onSessionsSync
    @supermodel.trackRequests(@sessions.fetchForAllClassroomMembers(@classroom))

    @students = new Users()
    jqxhrs = @students.fetchForClassroom(@classroom, removeDeleted: true)
    # @listenTo @students, ->
    @supermodel.trackRequests jqxhrs

  onSessionsSync: ->
    # Now we have some level sessions, and enough data to calculate last played string
    # This may be called multiple times due to paged server API calls via fetchForAllClassroomMembers
    return if @destroyed # Don't do anything if page was destroyed after db request
    @updateLastPlayedInfo()
    @updateLevelProgressMap()
    @updateLevelDataMap()
    @updateSolutions()

  updateLastPlayedInfo: ->
    # Make sure all our data is loaded, @sessions may not even be intialized yet
    return unless @courses.loaded and @levels.loaded and @sessions?.loaded and @user?.loaded

    # Use lodash to find the last session for our user, @sessions already sorted by changed date
    session = _.findLast @sessions.models, (s) => s.get('creator') is @user.id

    return unless session

    # Find course for this level session, for it's name
    # Level.original is the original id, used for level versioning, and connects levels to level sessions
    for versionedCourse in @classroom.getSortedCourses() or []
      for level in versionedCourse.levels
        if level.original is session.get('level').original
          # Found the level for our level session in the classroom versioned courses
          # Find the full course so we can get it's name
          course = @courses.get(versionedCourse._id)
          break

    # Find level for this level session, for it's name
    level = @levels.findWhere({original: session.get('level').original})

    # extra vars for display
    @lastPlayedCourse = course
    @lastPlayedLevel = level
    @lastPlayedSession = session

  lastPlayedString: ->
    # Update last played string based on what we found
    lastPlayedString = ""
    lastPlayedString += @lastPlayedCourse.getTranslatedName() if @lastPlayedCourse
    lastPlayedString += ": " if @lastPlayedCourse and @lastPlayedLevel
    lastPlayedString += @lastPlayedLevel.getTranslatedName() if @lastPlayedLevel
    if @lastPlayedCourse or @lastPlayedLevel
      if me.get('preferredLanguage', true) is 'en-US'
        lastPlayedString += ", on "
      else
        lastPlayedString += ", "
    lastPlayedString += moment(@lastPlayedSession.get('changed')).format("LLLL") if @lastPlayedSession
    lastPlayedString

  updateLevelProgressMap: ->
    return unless @courses.loaded and @levels.loaded and @sessions?.loaded and @user?.loaded

    # Map levels to sessions once, so we don't have to search entire session list multiple times below
    @levelSessionMap = {}
    for session in @sessions.models when session.get('creator') is @studentID
      @levelSessionMap[session.get('level').original] = session

    # Create mapping of level to student progress
    @levelProgressMap = {}
    for versionedCourse in @classroom.getSortedCourses() or []
      for versionedLevel in versionedCourse.levels
        session = @levelSessionMap[versionedLevel.original]
        if session?.get('creator') is @studentID
          if session.get('state')?.complete
            @levelProgressMap[versionedLevel.original] = 'complete'
          else
            @levelProgressMap[versionedLevel.original] = 'started'
        else
          @levelProgressMap[versionedLevel.original] = 'not started'

  updateLevelDataMap: ->
    return unless @courses.loaded and @levels.loaded and @sessions?.loaded

    @levelData = []
    for versionedCourse in @classroom.getSortedCourses() or []
      course = @courses.get(versionedCourse._id)
      for versionedLevel in versionedCourse.levels
        playTime = 0 # TODO: this and timesPlayed should probably only count when the levels are completed
        timesPlayed = 0
        studentTime = 0
        levelProgress = 'not started'
        for session in @sessions.models
          if session.get('level').original is versionedLevel.original
            # if @levelProgressMap[versionedLevel.original] == 'complete' # ideally, don't log sessions that aren't completed in the class
            playTime += session.get('playtime') or 0
            timesPlayed += 1
            if session.get('creator') is @studentID
              studentTime = session.get('playtime') or 0
              if @levelProgressMap[versionedLevel.original] is 'complete'
                levelProgress = 'complete'
              else if @levelProgressMap[versionedLevel.original] is 'started'
                levelProgress = 'started'
        classAvg = if timesPlayed > 0 then Math.round(playTime / timesPlayed) else 0 # only when someone other than the user has played
        # console.log (timesPlayed)
        @levelData.push {
          assessment: versionedLevel.assessment
          levelID: versionedLevel.original
          levelIndex: @classroom.getLevelNumber(versionedLevel.original)
          levelName: versionedLevel.name
          courseModel: course
          courseID: course.get('_id')
          classAvg: classAvg
          studentTime: if studentTime then studentTime else 0
          levelProgress: levelProgress
          # required:
        }

  studentStatusString: () ->
    status = @user.prepaidStatus()
    return "" unless @user.get('coursePrepaid')
    expires = @user.get('coursePrepaid')?.endDate
    date = if expires? then moment(expires).utc().format('l') else ''
    utils.formatStudentLicenseStatusDate(status, date)

  canViewStudentProfile: () -> @classroom && (@classroom.get('ownerID') == me.id || me.isAdmin())

  # TODO: Hookup enroll/assign functionality

  # onClickEnrollStudentButton: (e) ->
  #   userID = $(e.currentTarget).data('user-id')
  #   user = @user.get(userID)
  #   selectedUsers = new Users([user])
  #   @enrollStudents(selectedUsers)
  #   window.tracker?.trackEvent $(e.currentTarget).data('event-action'), category: 'Teachers', classroomID: @classroom.id, userID: userID, ['Mixpanel']
  #
  # enrollStudents: (selectedUsers) ->
  #   modal = new ActivateLicensesModal { @classroom, selectedUsers, users: @user }
  #   @openModalView(modal)
  #   modal.once 'redeem-users', (enrolledUsers) =>
  #     enrolledUsers.each (newUser) =>
  #       user = @user.get(newUser.id)
  #       if user
  #         user.set(newUser.attributes)
  #     null


  # levelPopoverContent: (level, session, i) ->
  #   return null unless level
  #   context = {
  #     moment: moment
  #     level: level
  #     session: session
  #     i: i
  #     canViewSolution: @teacherMode
  #   }
  #   return popoverTemplate(context)
  #
  # getLevelURL: (level, course, courseInstance, session) ->
  #   return null unless @teacherMode and _.all(arguments)
  #   "/play/level/#{level.get('slug')}?course=#{course.id}&course-instance=#{courseInstance.id}&session=#{session.id}&observing=true"
