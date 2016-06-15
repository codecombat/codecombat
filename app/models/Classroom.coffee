CocoModel = require './CocoModel'
schema = require 'schemas/models/classroom.schema'
utils = require 'core/utils'
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
    # options: courseID, withoutLadderLevels
    Levels = require 'collections/Levels'
    courses = @get('courses')
    return new Levels() unless courses
    levelObjects = []
    for course in courses
      if options.courseID and options.courseID isnt course._id
        continue
      levelObjects.push(course.levels)
    levels = new Levels(_.flatten(levelObjects))
    if options.withoutLadderLevels
      levels.remove(levels.filter((level) -> level.isLadder()))
    return levels
    
  getLadderLevel: (courseID) ->
    Levels = require 'collections/Levels'
    courses = @get('courses')
    course = _.findWhere(courses, {_id: courseID})
    return unless course
    levels = new Levels(course.levels)
    return levels.find (l) -> l.isLadder()

  statsForSessions: (sessions, courseID) ->
    return null unless sessions
    stats = {}
    sessions = sessions.models or sessions
    arena = @getLadderLevel(courseID)
    levels = @getLevels({courseID: courseID, withoutLadderLevels: true})
    levelOriginals = levels.pluck('original')
    completeSessionOriginals = (session.get('level').original for session in sessions when session.get('state').complete)
    incompleteSessionOriginals = (session.get('level').original for session in sessions when not session.get('state').complete)
    levelsLeft = _.size(_.difference(levelOriginals, completeSessionOriginals))
    next = _.find levels.models, (level) -> level.get('original') not in completeSessionOriginals
    lastPlayed = _.find levels.models, (level) -> level.get('original') in incompleteSessionOriginals
    stats.levels = {
      size: levels.size()
      left: levelsLeft
      done: levelsLeft is 0
      numDone: levels.size() - levelsLeft
      pctDone: (100 * (levels.size() - levelsLeft) / levels.size()).toFixed(1) + '%'
      lastPlayed: lastPlayed
      next: next
      first: levels.first()
      arena: arena
    }
    sum = (nums) -> _.reduce(nums, (s, num) -> s + num) or 0
    stats.playtime = sum((session.get('playtime') or 0 for session in sessions))
    return stats

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
