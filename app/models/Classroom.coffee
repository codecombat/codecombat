CocoModel = require './CocoModel'
schema = require 'schemas/models/classroom.schema'
utils = require '../core/utils'
User = require 'models/User'

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
          levels.push({key: level.original, practice: level.practice ? false})
        _.assign(@levelNumberMap, utils.createLevelNumberMap(levels))
    @levelNumberMap[levelID] ? defaultNumber

  removeMember: (userID, opts) ->
    options = {
      url: _.result(@, 'url') + '/members'
      type: 'DELETE'
      data: { userID: userID }
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
    # options: courseID, withoutLadderLevels, projectLevels
    # TODO: find a way to get the i18n in here so that level names can be translated (Courses don't include in their denormalized copy of levels)
    Levels = require 'collections/Levels'
    courses = @get('courses')
    return new Levels() unless courses
    levelObjects = []
    for course in courses
      if options.courseID and options.courseID isnt course._id
        continue
      levelObjects.push(course.levels)
    levels = new Levels(_.flatten(levelObjects))
    language = @get('aceConfig')?.language
    levels.remove(levels.filter((level) => level.get('primerLanguage') is language)) if language
    if options.withoutLadderLevels
      levels.remove(levels.filter((level) -> level.isLadder()))
    if options.projectLevels
      levels.remove(levels.filter((level) -> level.get('shareable') isnt 'project'))
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

  statsForSessions: (sessions, courseID) ->
    return null unless sessions
    sessions = sessions.models or sessions
    arena = @getLadderLevel(courseID)
    project = @getProjectLevel(courseID)
    courseLevels = @getLevels({courseID: courseID, withoutLadderLevels: true})
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
    for level, index in courseLevels.models
      levelsTotal++ unless level.get('practice')
      complete = false
      if session = levelSessionMap[level.get('original')]
        complete = session.get('state').complete ? false
        playtime += session.get('playtime') ? 0
        lastPlayed = level
        lastPlayedNumber = @getLevelNumber(level.get('original'), index + 1)
        if complete
          currentIndex = index
        else
          lastStarted = level
          levelsLeft++ unless level.get('practice')
      else if not level.get('practice')
        levelsLeft++
      levels.push
        practice: level.get('practice') ? false
        complete: complete
    lastPlayed = lastStarted ? lastPlayed
    needsPractice = false
    nextIndex = 0
    if currentIndex >= 0
      currentLevel = courseLevels.models[currentIndex]
      currentPlaytime = levelSessionMap[currentLevel.get('original')]?.get('playtime') ? 0
      needsPractice = utils.needsPractice(currentPlaytime, currentLevel.get('practiceThresholdMinutes'))
      nextIndex = utils.findNextLevel(levels, currentIndex, needsPractice)
    nextLevel = courseLevels.models[nextIndex]
    nextLevel = arena if levelsLeft is 0
    nextLevel ?= _.find courseLevels.models, (level) -> not levelSessionMap[level.get('original')]?.get('state')?.complete

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
    stats

  fetchForCourseInstance: (courseInstanceID, options={}) ->
    return unless courseInstanceID
    CourseInstance = require 'models/CourseInstance'
    courseInstance = if _.isString(courseInstanceID) then new CourseInstance({_id:courseInstanceID}) else courseInstanceID
    options = _.extend(options, {
      url: _.result(courseInstance, 'url') + '/classroom'
    })
    @fetch(options)

  inviteMembers: (emails, options={}) ->
    options.data ?= {}
    options.data.emails = emails
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
