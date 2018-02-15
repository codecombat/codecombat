<template lang="pug">
  flat-layout
    .container.m-t-3
      p
        a(href="/students", data-i18n="courses.back_courses")
      div.m-t-2
        h2.text-center
          | {{ $t('courses.challenges') }}
        h1(v-if="classroom").text-center
          | {{ classroom.name }}
        div.assessments-list.m-t-3(v-for="chunk in levelsByCourse" v-if="chunk.assessmentLevels.length && inCourses[chunk.course._id]")
          .row
            .col-xs-5
              span.table-header
                | {{ $dbt(chunk.course, 'name') }}
            .status-column.col-xs-5
              span.table-header
                | {{ $t('courses.status') }}
          student-assessment-row(
            v-for="level in chunk.assessmentLevels",
            :assessment="level.assessment",
            :assessmentPlacement="level.assessmentPlacement",
            :primaryConcept="level.primaryConcept",
            :name="$dbt(level, 'name')",
            :score="sessionMap[level.original] && sessionMap[level.original].topScore",
            :thresholdAchieved="sessionMap[level.original] && sessionMap[level.original].thresholdAchieved",
            :scoreType="level.scoreType",
            :complete="!!(sessionMap[level.original] && sessionMap[level.original].state.complete)",
            :started="!!sessionMap[level.original]",
            :codeConcepts="(sessionMap[level.original] && sessionMap[level.original].codeConcepts) || []",
            :playUrl="playLevelUrlMap[level.original]",
          )

</template>

<script lang="coffee">

FlatLayout = require('core/components/FlatLayout').default
api = require 'core/api'
User = require 'models/User'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
utils = require 'core/utils'
StudentAssessmentRow = require('./StudentAssessmentRow').default
  
module.exports = Vue.extend
  name: 'student-assessments-component'
  components:
    'flat-layout': FlatLayout,
    'student-assessment-row': StudentAssessmentRow
  props:
    classroomID:
      type: String
      default: -> null
  data: ->
    courseInstances: []
    levelSessions: []
    classroom: null
    levels: null
    levelsByCourse: null
    sessionMap: {}
    playLevelUrlMap: {}
    levelUnlockedMap: {}
    inCourses: {}
  computed:
    backToClassroomUrl: -> "/teachers/classes/#{@classroom?._id}"
  created: ->
    # TODO: Only fetch the ones for this classroom
    Promise.all([
      # TODO: Only load the levels we actually need
      Promise.all([
        api.users.getCourseInstances({ userID: me.id }).then((@courseInstances) =>),
        api.courses.getAll().then((@courses) =>),
        api.classrooms.get({ @classroomID }, { data: {memberID: me.id}, cache: false }).then((@classroom) =>)
      ]).then(=>
        @allLevels = _.flatten(_.map(@classroom.courses, (course) => course.levels))
        @levels = _.flatten(_.map(@classroom.courses, (course) => _.filter(course.levels, 'assessment')))
        @inCourses = {}
        for courseInstance in @courseInstances
          if courseInstance.classroomID is @classroomID and me.id in courseInstance.members
            @inCourses[courseInstance.courseID] = true
        @levelsByCourse = _.map(@classroom.courses, (course) => {
          course: _.find(@courses, ({_id: course._id})),
          assessmentLevels: _.filter(course.levels, 'assessment')
        })
        @courses = @classroom.courses
        return Promise.all(_.map(@levels, (level) =>
          api.levels.getByOriginal(level.original, {
            data: { project: 'slug,name,original,primaryConcepts,i18n,scoreTypes' }
          }).then (data) =>
            levelToUpdate = _.find(@levels, {original: data.original})
            Vue.set(levelToUpdate, 'primaryConcept', _.first(data.primaryConcepts))
            Vue.set(levelToUpdate, 'i18n', data.i18n)
            if data.scoreTypes
              Vue.set(levelToUpdate, 'scoreTypes', data.scoreTypes)
              # pick the first score, not currently showing multiple
              scoreType = _.first(data.scoreTypes)
              if _.isObject(scoreType)
                Vue.set(levelToUpdate, 'scoreType', scoreType.type)
        ))
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
      _.reduce(@levelSessions, (map, session) =>
        # Take the raw top score data and chosen score type and
        # pull the pertinent data out.
        level = _.find(@levels, {original: session.level.original})
        topScores = LevelSession.getTopScores({level, session})
        if level
          score = _.find(topScores, {type: level.scoreType})
          session.topScore = score?.score
          session.thresholdAchieved = score?.thresholdAchieved
        map[session.level.original] = session
        return map
      , {})
    createPlayLevelUrlMap: ->
      # Map level original to URL to play that level as the student
      _.reduce(@levels, (map, level) =>
        course = _.find(@courses, (c) =>
          Boolean(_.find(c.levels, (l) => l.original is level.original))
        )
        courseInstance = _.find(@courseInstances, (ci) => ci.courseID is course._id and ci.classroomID is @classroomID)
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
</script>

<style lang="sass">
#student-assessments-view .style-flat
  .table-header
    font-weight: bold

  font-size: 16px
  line-height: 27px
</style>
