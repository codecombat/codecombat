require('app/styles/courses/student-assessments-view.sass')
RootComponent = require 'views/core/RootComponent'
FlatLayout = require('core/components/FlatLayout.vue').default
api = require 'core/api'
User = require 'models/User'
Level = require 'models/Level'
utils = require 'core/utils'

StudentAssessmentsComponent = Vue.extend
  name: 'student-assessments-component'
  template: require('templates/courses/student-assessments-view')()
  components:
    'flat-layout': FlatLayout
  props:
    classroomID:
      type: String
      default: -> null
  data: ->
    courseInstances: []
    levelSessions: []
    classroom: null
    levels: null
    sessionMap: {}
    playLevelUrlMap: {}
    levelUnlockedMap: {}
  computed:
    backToClassroomUrl: -> "/teachers/classes/#{@classroom?._id}"
  created: ->
    # TODO: Only fetch the ones for this classroom
    Promise.all([
      api.users.getCourseInstances({ userID: me.id }).then((@courseInstances) =>)
      # TODO: Only load the levels we actually need
      api.classrooms.get({ @classroomID }, { data: {memberID: me.id}, cache: false }).then((@classroom) =>
        @allLevels = _.flatten(_.map(@classroom.courses, (course) => course.levels))
        @levels = _.flatten(_.map(@classroom.courses, (course) => _.filter(course.levels, { assessment: true })))
        @courses = @classroom.courses
      ).then(=>
        _.forEach(@levels, (level) =>
          api.levels.getByOriginal(level.original, {
            data: { project: 'slug,name,original,primaryConcepts' }
          }).then (data) =>
            levelToUpdate = _.find(@levels, {original: data.original})
            Vue.set(levelToUpdate, 'primaryConcepts', data.primaryConcepts)
        )
      )
      api.users.getLevelSessions({ userID: me.id }).then((@levelSessions) =>)
    ]).then =>
      @sessionMap = @createSessionMap()
      @playLevelUrlMap = @createPlayLevelUrlMap()
      # These two maps are for determining if a challenge is unlocked yet
      @previousLevelMap = @createPreviousLevelMap()
      @levelUnlockedMap = @createLevelUnlockedMap()
  methods:
    createSessionMap: ->
      # Map level original to levelSession
      _.reduce(@levelSessions, (map, session) ->
        map[session.level.original] = session
        return map
      , {})
    createPlayLevelUrlMap: ->
      # Map level original to URL to play that level as the student
      _.reduce(@levels, (map, level) =>
        course = _.find(@courses, (c) =>
          Boolean(_.find(c.levels, (l) => l.original is level.original))
        )
        courseInstance = _.find(@courseInstances, (ci) => ci.courseID is course._id)
        if _.all([level.slug, courseInstance?._id, course?._id])
          map[level.original] = "/play/level/#{level.slug}?course-instance=#{courseInstance?._id}&course=#{course?._id}"
        return map
      , {})
    createPreviousLevelMap: ->
      # Map assessment original to the level original of the level that unlocks the assessment
      map = {}
      for level, index in @allLevels
        assessmentIndex = utils.findNextAssessmentForLevel(@allLevels, index)
        if assessmentIndex isnt false
          assessmentOriginal = @allLevels[assessmentIndex].original
          map[assessmentOriginal] ?= level.original
      return map
    createLevelUnlockedMap: ->
      # Map assessment original to whether it has been unlocked yet, using session for the previous level
      map = {}
      for level, index in @levels
        map[level.original] = @sessionMap[@previousLevelMap[level.original]]?.state.complete or false
      return map

module.exports = class StudentAssessmentsView extends RootComponent
  id: 'student-assessments-view'
  template: require 'templates/base-flat'
  VueComponent: StudentAssessmentsComponent
  constructor: (options, @classroomID) ->
    @propsData = { @classroomID }
    super options
