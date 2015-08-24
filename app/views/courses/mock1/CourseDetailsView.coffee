app = require 'core/application'
utils = require 'core/utils'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/course-details'
CocoCollection = require 'collections/CocoCollection'
Campaign = require 'models/Campaign'

module.exports = class CourseDetailsView extends RootView
  id: 'course-details-view'
  template: template

  events:
    'change .expand-progress-checkbox': 'onExpandedProgressCheckbox'
    'change .student-mode-checkbox': 'onChangeStudent'
    'click .btn-play-level': 'onClickPlayLevel'
    'click .btn-save-settings': 'onClickSaveSettings'
    'click .member-header': 'onClickMemberHeader'
    'click .progress-header': 'onClickProgressHeader'
    'mouseenter .progress-level-cell': 'onMouseEnterPoint'
    'mouseleave .progress-level-cell': 'onMouseLeavePoint'

  constructor: (options, @courseID=0, @instanceID=0) ->
    super options
    @studentMode = utils.getQueryVariable('student', false) or options.studentMode
    @initData()

  destroy: ->
    @stopListening?()

  getRenderData: ->
    context = super()
    context.conceptsProgression = @conceptsProgression ? []
    context.course = @course ? {}
    context.courseConcepts = @courseConcepts ? []
    context.instance = @instances?[@currentInstanceIndex] ? {}
    context.instances = @instances ? []
    context.levelConceptsMap = @levelConceptsMap ? {}
    context.maxLastStartedIndex = @maxLastStartedIndex ? 0
    context.memberSort = @memberSort
    context.userConceptsMap = @userConceptsMap ? {}
    context.userLevelStateMap = @userLevelStateMap ? {}
    context.showExpandedProgress = @showExpandedProgress
    context.stats = @stats
    context.studentMode = @studentMode ? false

    conceptsCompleted = {}
    for user of context.userConceptsMap
      for concept of context.userConceptsMap[user]
        conceptsCompleted[concept] ?= 0
        conceptsCompleted[concept]++
    context.conceptsCompleted = conceptsCompleted
    context

  initData: ->
    @memberSort = 'nameAsc'
    mockData = require 'views/courses/mock1/CoursesMockData'
    @course = mockData.courses[@courseID]
    @currentInstanceIndex = @instanceID
    @instances = mockData.instances
    @updateLevelMaps()

    @campaigns = new CocoCollection([], { url: "/db/campaign", model: Campaign, comparator:'_id' })
    @listenTo @campaigns, 'sync', @onCampaignSync
    @supermodel.loadModel @campaigns, 'clan', cache: false

  updateLevelMaps: ->
    @levelMap = {}
    @levelMap[level] = true for level in @course.levels
    @userLevelStateMap = {}
    @stats =
      averageLevelPlaytime: _.random(30, 240)
      averageLevelsCompleted: _.random(1, @course.levels.length)
      students: {}
    @maxLastStartedIndex = -1
    for student in @instances?[@currentInstanceIndex].students
      @userLevelStateMap[student] = {}
      lastCompletedIndex = _.random(-1, @course.levels.length)
      for i in [0..lastCompletedIndex]
        @userLevelStateMap[student][@course.levels[i]] = 'complete'
      lastStartedIndex = lastCompletedIndex + 1
      @userLevelStateMap[student][@course.levels[lastStartedIndex]] = 'started'
      @maxLastStartedIndex = lastStartedIndex if lastStartedIndex > @maxLastStartedIndex

      @stats[student] ?= {}
      @stats[student].levelsCompleted = 0
      @stats[student].levelsCompleted++ for level in @course.levels when @userLevelStateMap[student][level] is 'complete'
      @stats[student].secondsPlayed = Math.round(Math.random() * 1000 * (@stats[student].levelsCompleted + 1))
      @stats[student].secondsLastPlayed = Math.round(Math.random() * 100000)
    @sortMembers()
    @stats.totalPlayTime = @instances?[@currentInstanceIndex].students?.length * @stats.averageLevelPlaytime ? 0
    @stats.totalLevelsCompleted = @instances?[@currentInstanceIndex].students?.length * @stats.averageLevelsCompleted ? 0
    @stats.totalPlayTime = @instances?[@currentInstanceIndex].students?.length * @stats.averageLevelPlaytime ? 0
    @stats.lastLevelCompleted = @course.levels[0] ? @course.levels[@course.levels.length - 1]

  sortMembers: ->
    # Progress sort precedence: most completed concepts, most started concepts, most levels, name sort
    instance = @instances?[@currentInstanceIndex] ? {}
    return if _.isEmpty(instance)
    switch @memberSort
      when "nameDesc"
        instance.students.sort (a, b) -> b.localeCompare(a)
      when "progressAsc"
        instance.students.sort (a, b) =>
          for level in @course.levels
            if @userLevelStateMap[a][level] isnt 'complete' and @userLevelStateMap[b][level] is 'complete'
              return -1
            else if @userLevelStateMap[a][level] is 'complete' and @userLevelStateMap[b][level] isnt 'complete'
              return 1
          0
      when "progressDesc"
        instance.students.sort (a, b) =>
          for level in @course.levels
            if @userLevelStateMap[a][level] isnt 'complete' and @userLevelStateMap[b][level] is 'complete'
              return 1
            else if @userLevelStateMap[a][level] is 'complete' and @userLevelStateMap[b][level] isnt 'complete'
              return -1
          0
      else
        instance.students.sort (a, b) -> a.localeCompare(b)

  onCampaignSync: ->
    return unless @campaigns.loaded
    @conceptsProgression = []
    @courseConcepts = []
    @levelConceptsMap = {}
    @levelNameSlugMap = {}
    @userConceptsMap = {}
    # Update course levels if course has a specific campaign
    for campaign in @campaigns.models when campaign.get('slug') is @course.campaign
      @course.levels = []
      for levelID, level of campaign.get('levels')
        if campaign.get('slug') is @course.campaign
          @course.levels.push level.name
      @updateLevelMaps()

    for campaign in @campaigns.models
      continue if campaign.get('slug') is 'auditions'
      for levelID, level of campaign.get('levels')
        @levelNameSlugMap[level.name] = level.slug
        if level.concepts?
          for concept in level.concepts
            @conceptsProgression.push concept unless concept in @conceptsProgression
            continue unless @levelMap[level.name]
            @courseConcepts.push concept unless concept in @courseConcepts
            @levelConceptsMap[level.name] ?= {}
            @levelConceptsMap[level.name][concept] = true
            for student in @instances?[@currentInstanceIndex].students
              @userConceptsMap[student] ?= {}
              if @userLevelStateMap[student][level.name] is 'complete'
                @userConceptsMap[student][concept] = 'complete'
              else if @userLevelStateMap[student][level.name] is 'started'
                @userConceptsMap[student][concept] ?= 'started'
    @courseConcepts.sort (a, b) => if @conceptsProgression.indexOf(a) < @conceptsProgression.indexOf(b) then -1 else 1
    @render?()

  onChangeStudent: (e) ->
    @studentMode = $('.student-mode-checkbox').prop('checked')
    @render?()
    $('.student-mode-checkbox').attr('checked', @studentMode)

  onExpandedProgressCheckbox: (e) ->
    @showExpandedProgress = $('.expand-progress-checkbox').prop('checked')
    # TODO: why does render reset the checkbox to be unchecked?
    @render?()
    $('.expand-progress-checkbox').attr('checked', @showExpandedProgress)

  onClickMemberHeader: (e) ->
    @memberSort = if @memberSort is 'nameAsc' then 'nameDesc' else 'nameAsc'
    @sortMembers()
    @render?()

  onClickProgressHeader: (e) ->
    @memberSort = if @memberSort is 'progressAsc' then 'progressDesc' else 'progressAsc'
    @sortMembers()
    @render?()

  onClickPlayLevel: (e) ->
    levelName = $(e.target).data('level')
    levelSlug = @levelNameSlugMap[levelName]
    Backbone.Mediator.publish 'router:navigate', {
      route: "/play/level/#{levelSlug}"
      viewClass: 'views/play/level/PlayLevelView'
      viewArgs: [{}, levelSlug]
    }

  onClickSaveSettings:  (e) ->
    if name = $('.edit-name-input').val()
      @instances[@currentInstanceIndex].name = name
    description = $('.edit-description-input').val()
    @instances[@currentInstanceIndex].description = description
    $('#editSettingsModal').modal('hide')
    @render?()

  onMouseEnterPoint: (e) ->
    $('.level-popup-container').hide()
    container = $(e.target).find('.level-popup-container').show()
    margin = 20
    offset = $(e.target).offset()
    scrollTop = $('#page-container').scrollTop()
    height = container.outerHeight()
    container.css('left', offset.left + e.offsetX)
    container.css('top', offset.top + scrollTop - height - margin)

  onMouseLeavePoint: (e) ->
    $(e.target).find('.level-popup-container').hide()
