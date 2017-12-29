<template lang="jade">
flat-layout#student-assessments-view
  .container.m-t-3
    p
      a(href="/students", data-i18n="courses.back_courses")
    div.text-center.m-t-2
      h2
        | {{ $t('courses.assessments') }}
      h1(v-if="classroom")
        | {{ classroom.name }}
      ul.assessments-list.m-t-3
        li
          .row
            .col-xs-5.col-xs-offset-1
              span.table-header.pull-left
                | {{ $t('courses.challenge_level') }}
            .status-column.col-xs-3
              span.table-header.pull-left
                | {{ $t('courses.status') }}
        li(v-for="level in levels")
          .row
            .col-xs-5.col-xs-offset-1
              span.level-name.pull-left
                span(v-if="level.primaryConcepts")
                  | {{ $t('concepts.' + (level.primaryConcepts && level.primaryConcepts[0])) }} ({{ level.name }})
                span(v-else)
                  | ({{ level.name }})
            .col-xs-3
              div.level-status.pull-left
                span(v-if="sessionMap[level.original] && sessionMap[level.original].state.complete")
                  span.glyphicon.glyphicon-ok-sign.success-symbol.text-forest
                  | {{ $t('teacher.success') }}
                span(v-else-if="sessionMap[level.original]")
                  span.glyphicon.glyphicon-question-sign.in-progress-symbol.text-gold
                  | {{ $t('teacher.in_progress') }}
                span(v-else)
                  span.glyphicon.glyphicon-question-sign.not-started-symbol.text-gray
                  | {{ $t('teacher.not_started') }}
            .col-xs-2
              div(v-if="levelUnlockedMap[level.original] && playLevelUrlMap[level.original]")
                a.play-level-btn.btn.btn-lg.btn-gray(v-if="sessionMap[level.original] && sessionMap[level.original].state.complete", :href="playLevelUrlMap[level.original]")
                  | {{ $t('courses.play_again') }}
                a.play-level-btn.btn.btn-lg.btn-forest(v-else-if="sessionMap[level.original]", :href="playLevelUrlMap[level.original]")
                  | {{ $t('courses.keep_trying') }}
                a.play-level-btn.btn.btn-lg.btn-navy(v-else, :href="playLevelUrlMap[level.original]")
                  | {{ $t('courses.start_challenge') }}
              div(v-else)
                a.btn.btn-lg.btn-gray-alt(disabled)
                  | {{ $t('courses.locked') }}
</template>

<script lang="coffee">

require('app/styles/courses/student-assessments-view.sass')
RootComponent = require 'views/core/RootComponent'
FlatLayout = require('core/components/FlatLayout.vue').default
api = require 'core/api'
User = require 'models/User'
Level = require 'models/Level'
utils = require 'core/utils'

module.exports = Vue.extend
  name: 'student-assessments-component'
  template: require('templates/courses/student-assessments-view')()
  components:
    'flat-layout': FlatLayout
  props:
    params:
      type: Array
      default: -> []
  data: ->
    classroomID: ''
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
    @classroomID = @params[0]
    console.log('classroom id', @classroomID)
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

</script>

<style lang="sass">
#student-assessments-view
  .assessments-list
    list-style: none

  .play-level-btn
    min-width: 140px

  .table-header
    font-weight: bold
</style>
