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
        select(v-model="selectedCourse")
          option(v-for="chunk in levelsByCourse", :value="chunk.course._id") {{ $dbt(chunk.course, 'name') }}
        div.assessments-list.m-t-3(v-for="chunk in levelsByCourse" v-if="chunk.course._id === selectedCourse")
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
            :complete="!!(sessionMap[level.original] && sessionMap[level.original].state.complete)",
            :started="!!sessionMap[level.original]",
            :playUrl="playLevelUrlMap[level.original]",
            :goals="level.goals",
            :goalStates="sessionMap[level.original] ? sessionMap[level.original].state.goalStates : []"
          )

</template>

<script lang="coffee">

FlatLayout = require 'core/components/FlatLayout'
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
    levelMap: {}
    playLevelUrlMap: {}
    levelUnlockedMap: {}
    inCourses: {}
    courses: []
    selectedCourse: ''
  computed:
    backToClassroomUrl: -> "/teachers/classes/#{@classroom?._id}"
  created: ->
    # TODO: Only fetch the ones for this classroom
    Promise.all([
      # TODO: Only load the levels we actually need
      Promise.all([
        api.users.getCourseInstances({ userID: me.id }).then((@courseInstances) =>),
        @$store.dispatch('courses/fetch').then(=> @courses = @$store.getters['courses/sorted'])
        api.classrooms.get({ @classroomID }, { data: {memberID: me.id} }).then((@classroom) =>)
      ]).then(=>
        @allLevels = _.flatten(_.map(@classroom.courses, (course) => course.levels))
        for level in @allLevels
          @levelMap[level.original] = level
        @levels = _.flatten(_.map(@classroom.courses, (course) => _.filter(course.levels, 'assessment')))
        @inCourses = {}
        for courseInstance in @courseInstances
          if courseInstance.classroomID is @classroomID and me.id in courseInstance.members
            @inCourses[courseInstance.courseID] = true
        @levelsByCourse = _.map(@classroom.courses, (course) => {
          course: @$store.state.courses.byId[course._id]
          assessmentLevels: _.filter(course.levels, 'assessment')
        }).filter((chunk) => chunk.assessmentLevels.length and @inCourses[chunk.course._id])
        @selectedCourse = document.location.hash.replace('#','') or _.first(@levelsByCourse)?.course._id

        @courses = @classroom.courses
        return Promise.all(_.map(@levels, (level) =>
          api.levels.getByOriginal(level.original, {
            data: { project: 'slug,name,original,primaryConcepts,i18n,goals' }
          }).then (data) =>
            levelToUpdate = _.find(@levels, {original: data.original})
            Vue.set(levelToUpdate, 'primaryConcept', _.first(data.primaryConcepts))
            Vue.set(levelToUpdate, 'i18n', data.i18n)
            Vue.set(levelToUpdate, 'goals', data.goals)
        ))
      )
      api.users.getLevelSessions({ userID: me.id }).then((@levelSessions) =>)
    ]).then =>
      @sessionMap = @createSessionMap()
      # These two maps are for determining if a challenge is unlocked yet
      @previousLevelMap = @createPreviousLevelMap()
      @levelUnlockedMap = @createLevelUnlockedMap()
      @playLevelUrlMap = @createPlayLevelUrlMap()
  methods:
    createSessionMap: ->
      # Map level original to levelSession
      _.reduce(@levelSessions, (map, session) =>
        level = @levelMap[session.level.original]
        return map if not level # we fetch all user sessions; handle when user has a session not in their courses
        defaultLanguage = level.primerLanguage or @classroom.aceConfig.language
        if session.codeLanguage isnt defaultLanguage
          return map
        map[session.level.original] = session
        level.complete = session.state?.complete # needed for utils.findNextAssessmentForLevel to work
        return map
      , {})
    createPlayLevelUrlMap: ->
      # Map level original to URL to play that level as the student
      _.reduce(@levels, (map, level) =>
        unless (@levelUnlockedMap[level.original] or @sessionMap[level.original])
          return map
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

        # TODO: move this needsPractice logic to utils, copied from https://github.com/codecombat/codecombat/blob/2beb7c4/server/middleware/course-instances.coffee#L178
        needsPractice = if level.type in ['course-ladder', 'ladder'] then false
        else if level.assessment then false
        else utils.needsPractice(@sessionMap[level.original]?.playtime || 0, level.practiceThresholdMinutes)

        assessmentIndex = utils.findNextAssessmentForLevel(@allLevels, index, needsPractice)
        if assessmentIndex >= 0
          if level.practice and not needsPractice
            continue # do not overwrite current mapping if user does not need practice
          assessmentOriginal = @allLevels[assessmentIndex].original
          map[assessmentOriginal] ?= level.original
          
          # also map any assessments that immediately follow, esp. combo levels
          findAssessmentIndex = assessmentIndex
          while true
            findAssessmentIndex += 1
            nextLevel = @allLevels[findAssessmentIndex]
            unless nextLevel and nextLevel.assessment
              break
            map[nextLevel.original] = level.original
            
      return map
    createLevelUnlockedMap: ->
      # Map assessment original to whether it has been unlocked yet, using session for the previous level
      map = {}
      for level, index in @levels
        map[level.original] = @sessionMap[@previousLevelMap[level.original]]?.state.complete or false
      return map
  watch: {
    selectedCourse: (newValue) ->
      document.location.hash = newValue
  }
</script>

<style lang="sass">
#student-assessments-view .style-flat
  .table-header
    font-weight: bold

  font-size: 16px
  line-height: 27px
</style>
