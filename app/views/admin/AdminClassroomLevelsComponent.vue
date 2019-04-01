<template lang="pug">
div.admin-classroom-levels.container
  h3 Classroom Levels
  div(v-if="loading") Loading...
  div(v-else-if="!$store.getters['me/isAdmin']")
    | You must be logged in as an admin to view this page.
  div(v-else)
    table.table.table-striped.table-condensed
      tbody
        tr
          th Levels
          th Course
        tr(v-for="course in filteredCourses")
          td {{courseLevels(course._id).length}}
          td {{course.name}}
        tr
          td {{totalLevels}}
          td All

    div(v-for="course in filteredCourses")
      strong {{course.name}}
      .small {{course.description}}
      .small Levels last updated {{courseCampaign(course._id).levelsUpdated}}
      table.table.table-striped.table-condensed
        tbody
          tr
            th {{courseLevels(course._id).length}}
            th Slug
            th Type
            th Practice
            th Practice Threshold (m)
            th Shareable
            th Primer
            th New Concepts

          tr(v-for="level in courseLevels(course._id)")
            td
              a(:href="'/play/level/'+level.slug")
               | {{levelNumberMapForCourse(course._id)[level.original]}}
            td {{level.slug}}
            td {{level.type}}
            td {{level.practice}}
            td {{level.practiceThresholdMinutes}}
            td {{level.shareable}}
            td {{level.primerLanguage}}
            td
              span(v-for="concept in levelConceptsBySlug[level.slug]")
                | {{concept}}
                =" "
</template>

<script lang="coffee">
co = require('co')
api = require 'core/api'
Campaign = require 'models/Campaign'

module.exports = Vue.extend({
  data: ->
    campaigns: []
    courses: []
    loading: true

  created: co.wrap ->
    return unless @loading
    yield Promise.all([
      api.campaigns.getAll().then((@campaigns) =>)
      api.courses.getAll().then((@courses) =>)
    ]).then =>
      @loading = false

  methods:
    courseLevels: (courseID) ->
      campaign = @courseCampaign(courseID)
      return [] unless campaign
      levels = Campaign.getLevels(campaign)
      return levels

    courseCampaign: (courseID) ->
      course = _.find(@courses, {_id: courseID})
      return unless course
      campaign = _.find(@campaigns, {_id: course.campaignID})
      return campaign

    levelNumberMapForCourse: (courseID) ->
      campaign = @courseCampaign(courseID)
      return {} unless campaign
      return Campaign.getLevelNumberMap(campaign)

  computed:
    levelConceptsBySlug: ->
      levelConcepts = {}
      seenConcepts = {}
      for course in @filteredCourses
        for level in @courseLevels(course._id)
          levelConcepts[level.slug] = []
          for concept in level.concepts or []
            unless seenConcepts[concept]
              levelConcepts[level.slug].push(concept)
            seenConcepts[concept] = true
      return levelConcepts

    filteredCourses: ->
      return _.filter(@courses, (course) =>
        if course.releasePhase isnt 'released'
          return false
        levels = @courseLevels(course.campaignID)
        unless levels
          return false
        return true
      )

    totalLevels: ->
      sum = _.reduce(@filteredCourses, (sum, course) =>
        return @courseLevels(course._id).length + sum
      , 0)
})

</script>

<style lang="sass">
#admin-classroom-levels-view
  table
    td, th
      padding: 2px
      font-size: 11px
</style>
