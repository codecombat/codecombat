CocoModel = require './CocoModel'
schema = require 'schemas/models/classroom.schema'
utils = require '../core/utils'
levelUtils = require '../core/levelUtils'
{ findNextLevelsBySession, getLevelsDataByOriginals } = require 'ozaria/site/common/ozariaUtils'
coursesHelper = require '../lib/coursesHelper'
User = require 'models/User'
Level = require 'models/Level'
api = require 'core/api'
ClassroomLib = require './ClassroomLib'
Users = require 'collections/Users'
classroomUtils = require 'app/lib/classroom-utils'
prepaids = require('core/store/modules/prepaids').default

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
    if code.length == 14 and code.split('-').length == 3
      url = @urlRoot + "/join-by-activation-code"
    else
      url = @urlRoot + '/~/members'
    options = {
      url: url
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

  setStudentPassword: (student, password) ->
    classroomID = @.id
    return new Promise((resolve, reject) =>
      $.ajax {
        url: "/db/classroom/#{classroomID}/members/#{student.id}/reset-password"
        method: 'POST'
        data: { password }
        success: =>
          @trigger 'save-password:success'
          resolve()
        error: (response) =>
          @trigger 'save-password:error', response.responseJSON
          reject(response.responseJSON)
      }
    )

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

  getLevelsByModules: ->
    courseModuleLevelsMap = {}
    for course in @get('courses')
      isCh1 = course._id == utils.courseIDs.CHAPTER_ONE
      courseLevels = @getLevels({courseID: course._id}).models
      courseModuleLevelsMap[course._id] = {
        modules: levelUtils.buildLevelsListByModule(courseLevels, isCh1)
      }
      if capstoneLevel = courseLevels.find((l) => l.isCapstone())
        courseModuleLevelsMap[course._id].capstone = capstoneLevel
    return courseModuleLevelsMap

  fetchIntroContentDataForLevels: (courseModuleLevelsMap) ->
    introLevels = []
    for course in @get('courses')
      for moduleNum, levels of courseModuleLevelsMap[course._id].modules
        introLevels = introLevels.concat(levels.filter((l) => l.get('introContent')))
    api.levels.fetchIntroContent(introLevels)
    .then (introLevelContentMap) =>
      introLevels.forEach((l) =>
        utils.addIntroLevelContent(l, introLevelContentMap)
      )

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
      unless utils.orderedCourseIDs.includes(courseID)
        nextIndex = utils.findNextLevel(levels, currentIndex, needsPractice)
    if utils.orderedCourseIDs.includes(courseID)
      nextLevelOriginal = findNextLevelsBySession(sessions, courseLevels.models)
      nextLevel = new Level(getLevelsDataByOriginals(courseLevels.models, [nextLevelOriginal])[0])
    else
      nextLevel = courseLevels.models[nextIndex]
      nextLevel = arena if levelsLeft is 0
      nextLevel ?= _.find courseLevels.models, (level) -> not levelSessionMap[level.get('original')]?.get('state')?.complete
    if nextLevel
      nextLevelNumber = @getLevelNumber(nextLevel.get('original'), nextIndex + 1)
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
        nextNumber: nextLevelNumber
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

  isStudentOnLockedCourse: (studentID, courseID) ->
    Classroom.isStudentOnLockedCourse(@attributes, studentID, courseID)

  isStudentOnLockedLevel: (studentID, courseID, levelOriginal) ->
    Classroom.isStudentOnLockedLevel(@attributes, studentID, courseID, levelOriginal)

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

  hasReadPermission: (options = { showNoty: false }) ->
    showNoty = options.showNoty or false
    result = classroomUtils.hasPermission('read', {
      ownerId: @get('ownerID'),
      permissions: @get('permissions')
    }) or @hasWritePermission()
    if !result and showNoty
      noty({ text: 'teacher.not_read_permission', type: 'error', timeout: 4000, killer: true })
    result

  hasWritePermission: (options = { showNoty: false }) ->
    showNoty = options.showNoty or false
    result = classroomUtils.hasPermission('write', {
      ownerId: @get('ownerID'),
      permissions: @get('permissions')
    })
    if !result and showNoty
      noty({ text: $.i18n.t('teacher.not_write_permission'), type: 'error', timeout: 4000, killer: true })
    result

  isOwner: ->
    return me.id == @get('ownerID') || me.isAdmin()

  getDisplayPermission: ->
    if @isOwner()
      return
    if @hasWritePermission()
      return classroomUtils.getDisplayPermission('write')
    else if @hasReadPermission()
      return classroomUtils.getDisplayPermission('read')

  revokeStudentLicenses: ->
    students = new Users()
    Promise.all(students.fetchForClassroom(@, {removeDeleted: true, data: {project: 'firstName,lastName,name,email,products,deleted'}}))
      .then =>
        studentsToRevoke = students.models.filter((student) => student.prepaidStatus() is 'enrolled' and student.prepaidType() is 'course')
        if studentsToRevoke.length > 0
          @showRevokeConfirm(studentsToRevoke).then (revokeConfirmed) =>
            return unless revokeConfirmed

            if !@isOwner() and @hasWritePermission()
              sharedClassroomId = @id

            prepaids.actions.revokeLicenses(null, {
              members: students.models,
              sharedClassroomId,
              confirmed: true,
              updateUserProducts: true
            })

  showRevokeConfirm: (studentsToRevoke)->
    new Promise((resolve) ->
      notification = noty
        text: studentsToRevoke.length + $.i18n.t 'teacher.archive_revoke_confirm'
        type: 'info'
        layout: 'top'
        buttons: [
          {
            addClass: 'btn btn-danger'
            text: $.i18n.t 'teacher.archive_without_revoking'
            onClick: ($noty) ->
              $noty.close()
              resolve(false)
          }
          {
            addClass: 'btn btn-primary'
            text: $.i18n.t 'teacher.revoke_and_archive'
            onClick: ($noty) ->
              $noty.close()
              resolve(true)
          }
        ]
      notification.$buttons.addClass('style-flat')
    )

# Make ClassroomLib accessible as static methods.
_.assign(Classroom, ClassroomLib.default)
