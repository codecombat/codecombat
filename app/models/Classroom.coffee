CocoModel = require './CocoModel'
schema = require 'schemas/models/classroom.schema'
utils = require '../core/utils'
{ findNextLevelsBySession, getLevelsDataByOriginals } = require 'ozaria/site/common/ozariaUtils'
coursesHelper = require '../lib/coursesHelper'
User = require 'models/User'
Level = require 'models/Level'

module.exports = class Classroom extends CocoModel
  @className: 'Classroom'
  @schema: schema
  urlRoot: '/db/classroom'

  initialize: () ->
    @listenTo @, 'change:aceConfig', @capitalizeLanguageName
    super(arguments...)

  parse: (obj) ->
    if obj._id
      # It's just the classroom object
      return obj
    else
      # It's a compound response with other stuff too
      @owner = new User(obj.owner)
      return obj.data

  capitalizeLanguageName: ->
    language = @get('aceConfig')?.language
    @capitalLanguage = utils.capitalLanguages[language]

  joinWithCode: (code, opts) ->
    options = {
      url: @urlRoot + '/~/members'
      type: 'POST'
      data: { code: code }
      success: => @trigger 'join:success'
      error: => @trigger 'join:error'
    }
    _.extend options, opts
    @fetch(options)

  fetchByCode: (code, opts) ->
    options = {
      url: _.result(@, 'url')
      data: { code: code, "with-owner": true }
    }
    _.extend options, opts
    @fetch(options)

  getLevelNumber: (levelID, defaultNumber) ->
    unless @levelNumberMap
      @levelNumberMap = {}
      language = @get('aceConfig')?.language
      for course in @get('courses') ? []
        levels = []
        for level in course.levels when level.original
          continue if language? and level.primerLanguage is language
          levels.push({key: level.original, practice: level.practice ? false, assessment: level.assessment ? false})
        _.assign(@levelNumberMap, utils.createLevelNumberMap(levels))
    @levelNumberMap[levelID] ? defaultNumber

  removeMember: (userID, opts) ->
    options = {
      url: _.result(@, 'url') + "/members/#{userID}"
      type: 'DELETE'
    }
    _.extend options, opts
    @fetch(options)

  setStudentPassword: (student, password, options) ->
    classroomID = @.id
    $.ajax {
      url: "/db/classroom/#{classroomID}/members/#{student.id}/reset-password"
      method: 'POST'
      data: { password }
      success: => @trigger 'save-password:success'
      error: (response) => @trigger 'save-password:error', response.responseJSON
    }

  getLevels: (options={}) ->
    # options: courseID, withoutLadderLevels, projectLevels, assessmentLevels, levelsCollection
    # TODO: find a way to get the i18n in here so that level names can be translated (Courses don't include in their denormalized copy of levels)
    Levels = require 'collections/Levels'
    courses = @get('courses')
    return new Levels() unless courses
    levelObjects = []
    for course in courses
      if options.courseID and options.courseID isnt course._id
        continue
      if options.levelsCollection
        for level in course.levels
          matchedLevel = options.levelsCollection.findWhere original: level.original
          levelObjects.push matchedLevel?.attributes or matchedLevel
      else
        levelObjects.push(course.levels)
    levels = new Levels(_.flatten(levelObjects))
    language = @get('aceConfig')?.language
    levels.remove(levels.filter((level) => level.get('primerLanguage') is language)) if language
    if options.withoutLadderLevels
      levels.remove(levels.filter((level) -> level.isLadder()))
    if options.projectLevels
      levels.remove(levels.filter((level) -> level.get('shareable') isnt 'project'))
    if options.assessmentLevels
      levels.remove(levels.filter((level) -> not level.get('assessment')))
    return levels

  getLadderLevel: (courseID) ->
    Levels = require 'collections/Levels'
    courses = @get('courses')
    course = _.findWhere(courses, {_id: courseID})
    return unless course
    levels = new Levels(course.levels)
    return levels.find (l) -> l.isLadder()

  getProjectLevel: (courseID) ->
    Levels = require 'collections/Levels'
    courses = @get('courses')
    course = _.findWhere(courses, {_id: courseID})
    return unless course
    levels = new Levels(course.levels)
    return levels.find (l) -> l.isProject()

  statsForSessions: (sessions, courseID, levelsCollection=undefined) ->
    return null unless sessions
    sessions = sessions.models or sessions
    arena = @getLadderLevel(courseID)
    project = @getProjectLevel(courseID)
    courseLevels = @getLevels({courseID: courseID, withoutLadderLevels: true, levelsCollection: levelsCollection})
    levelSessionMap = {}
    levelSessionMap[session.get('level').original] = session for session in sessions
    currentIndex = -1
    lastStarted = null
    levelsTotal = 0
    levelsLeft = 0
    lastPlayed = null
    lastPlayedNumber = null
    playtime = 0
    levels = []
    linesOfCode = 0
    userLevels = {}
    levelsInCourse = new Set()
    for level, index in courseLevels.models
      levelsTotal++ unless level.get('practice') or level.get('assessment')
      complete = false
      if session = levelSessionMap[level.get('original')]
        complete = session.get('state').complete ? false
        playtime += session.get('playtime') ? 0
        linesOfCode += session.countOriginalLinesOfCode level
        lastPlayed = level
        lastPlayedNumber = @getLevelNumber(level.get('original'), index + 1)
        if complete
          currentIndex = index
        else
          lastStarted = level
          levelsLeft++ unless level.get('practice') or level.get('assessment')
      else if not (level.get('practice') or level.get('assessment'))
        levelsLeft++
      levels.push
        assessment: level.get('assessment') ? false
        practice: level.get('practice') ? false
        complete: complete
      levelsInCourse.add(level.get('original')) unless level.get('practice') or level.get('assessment')
      userLevels[level.get('original')] = complete
    lastPlayed = lastStarted ? lastPlayed
    lastPlayedNumber = '' if lastPlayed?.get('assessment')
    needsPractice = false
    nextIndex = 0
    if currentIndex >= 0
      currentLevel = courseLevels.models[currentIndex]
      currentPlaytime = levelSessionMap[currentLevel.get('original')]?.get('playtime') ? 0
      needsPractice = utils.needsPractice(currentPlaytime, currentLevel.get('practiceThresholdMinutes')) and not currentLevel.get('assessment')
      unless utils.ozariaCourseIDs.includes(courseID)
        nextIndex = utils.findNextLevel(levels, currentIndex, needsPractice)
    if utils.ozariaCourseIDs.includes(courseID)
      nextLevelOriginal = findNextLevelsBySession(sessions, courseLevels.models)
      nextLevel = new Level(getLevelsDataByOriginals(courseLevels.models, [nextLevelOriginal])[0])
    else
      nextLevel = courseLevels.models[nextIndex]
      nextLevel = arena if levelsLeft is 0
      nextLevel ?= _.find courseLevels.models, (level) -> not levelSessionMap[level.get('original')]?.get('state')?.complete
    [_userStarted, courseComplete, _totalComplete] = coursesHelper.hasUserCompletedCourse(userLevels, levelsInCourse)

    stats =
      levels:
        size: levelsTotal
        left: levelsLeft
        done: levelsLeft is 0
        numDone: levelsTotal - levelsLeft
        pctDone: (100 * (levelsTotal - levelsLeft) / levelsTotal).toFixed(1) + '%'
        lastPlayed: lastPlayed
        lastPlayedNumber: lastPlayedNumber
        next: nextLevel
        first: courseLevels.first()
        arena: arena
        project: project
      playtime: playtime
      linesOfCode: linesOfCode
      courseComplete: courseComplete
    stats

  fetchForCourseInstance: (courseInstanceID, options={}) ->
    return unless courseInstanceID
    CourseInstance = require 'models/CourseInstance'
    courseInstance = if _.isString(courseInstanceID) then new CourseInstance({_id:courseInstanceID}) else courseInstanceID
    options = _.extend(options, {
      url: _.result(courseInstance, 'url') + '/classroom'
    })
    @fetch(options)

  inviteMembers: (emails, recaptchaResponseToken, options={}) ->
    options.data ?= {}
    options.data.emails = emails
    options.data.recaptchaResponseToken = recaptchaResponseToken
    options.url = @url() + '/invite-members'
    options.type = 'POST'
    @fetch(options)

  getSortedCourses: ->
    utils.sortCourses(@get('courses') ? [])

  updateCourses: (options={}) ->
    options.url = @url() + '/update-courses'
    options.type = 'POST'
    @fetch(options)

  getSetting: (name) =>
    settings = @get('settings') or {}
    propInfo = Classroom.schema.properties.settings.properties
    return settings[name] if name in Object.keys(settings)
    if name in Object.keys(propInfo)
      return propInfo[name].default

    return false

  hasAssessments: (options={}) ->
    if options.courseId
      course = _.find(@get('courses'), (c) => c._id is options.courseId)
      return false unless course
      return _.any(course.levels, { assessment: true })
    _.any(@get('courses'), (course) -> _.any(course.levels, { assessment: true }))

  isGoogleClassroom: -> @get('googleClassroomId')?.length > 0
