CocoModel = require './CocoModel'
schema = require 'schemas/models/classroom.schema'
utils = require 'core/utils'

module.exports = class Classroom extends CocoModel
  @className: 'Classroom'
  @schema: schema
  urlRoot: '/db/classroom'
  
  initialize: () ->
    @listenTo @, 'change:aceConfig', @capitalizeLanguageName
    super(arguments...)
    
  capitalizeLanguageName: ->
    language = @get('aceConfig')?.language
    @capitalLanguage = utils.capitalLanguages[language]

  joinWithCode: (code, opts) ->
    options = {
      url: _.result(@, 'url') + '/~/members'
      type: 'POST'
      data: { code: code }
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
    sessions = _.sortBy sessions, (s) -> s.get('changed')
    arena = @getLadderLevel(courseID)
    levels = @getLevels({courseID: courseID, withoutLadderLevels: true})
    levelOriginals = levels.pluck('original')
    sessionOriginals = (session.get('level').original for session in sessions when session.get('state').complete)
    levelsLeft = _.size(_.difference(levelOriginals, sessionOriginals))
    lastSession = _.last(sessions)
    stats.levels = {
      size: levels.size()
      left: levelsLeft
      done: levelsLeft is 0
      numDone: levels.size() - levelsLeft
      pctDone: (100 * (levels.size() - levelsLeft) / levels.size()).toFixed(1) + '%'
      lastPlayed: if lastSession then levels.findWhere({ original: lastSession.get('level').original }) else null
      first: levels.first()
      arena: arena
    }
    sum = (nums) -> _.reduce(nums, (s, num) -> s + num) or 0
    stats.playtime = sum((session.get('playtime') or 0 for session in sessions))
    return stats

  fetchForCourseInstance: (courseInstanceID, options={}) ->
    CourseInstance = require 'models/CourseInstance'
    courseInstance = if _.isString(courseInstanceID) then new CourseInstance({_id:courseInstanceID}) else courseInstanceID
    options = _.extend(options, {
      url: _.result(courseInstance, 'url') + '/classroom'
    })
    @fetch(options)