require('app/styles/artisans/level-guides-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/artisans/level-guides-view'

Campaigns = require 'collections/Campaigns'
Campaign = require 'models/Campaign'

Levels = require 'collections/Levels'
Level = require 'models/Level'

module.exports = class LevelGuidesView extends RootView
  template: template
  id: 'level-guides-view'
  events:
    'click #overview-button': 'onOverviewButtonClicked'
    'click #intro-button': 'onIntroButtonClicked'

  excludedCampaigns = [
    'pico-ctf', 'auditions'
  ]
  includedCampaigns = [
    'intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6',
    'web-dev-1', 'web-dev-2',
    'game-dev-1', 'game-dev-2'
  ]
  levels: []

  onOverviewButtonClicked: (e) ->
    @$('.overview').toggleClass('in')
  onIntroButtonClicked: (e) ->
    @$('.intro').toggleClass('in')

  initialize: () ->

    @campaigns = new Campaigns()

    @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
    @supermodel.trackRequest(@campaigns.fetch(
      data:
        project: 'name,slug,levels'
    ))
  onCampaignsLoaded: (campCollection) ->
    for camp in campCollection.models
      campaignSlug = camp.get 'slug'
      continue if campaignSlug in excludedCampaigns
      continue unless campaignSlug in includedCampaigns
      levels = camp.get 'levels'

      levels = new Levels()
      @listenTo(levels, 'sync', @onLevelsLoaded)
      levels.fetchForCampaign(campaignSlug)
      #for key, level of levels

  onLevelsLoaded: (lvlCollection) ->
    lvlCollection.models.reverse()
    #console.log lvlCollection
    for level in lvlCollection.models
      #console.log level
      levelSlug = level.get 'slug'
      overview = _.find(level.get('documentation').specificArticles, name:'Overview')
      intro = _.find(level.get('documentation').specificArticles, name:'Intro')
      #if intro and overview
      problems = []
      if not overview
        problems.push 'No Overview'
      else
        if not overview.i18n
          problems.push 'Overview doesn\'t have i18n field'
        if not overview.body
          problems.push 'Overview doesn\'t have a body'
        else
          if level.get('campaign')?.indexOf('web') is -1
            jsIndex = overview.body.indexOf('```javascript')
            pyIndex = overview.body.indexOf('```python')
            if jsIndex is -1 and pyIndex isnt -1 or jsIndex isnt -1 and pyIndex is -1
              problems.push 'Overview is missing a language example.'
      if not intro
        problems.push 'No Intro'
      else
        if not intro.i18n
          problems.push 'Intro doesn\'t have i18n field'
        if not intro.body
          problems.push 'Intro doesn\'t have a body'
        else
          if intro.body.indexOf('file/db') is -1
            problems.push 'Intro is missing image'
          if level.get('campaign')?.indexOf('web') is -1
            jsIndex = intro.body.indexOf('```javascript')
            pyIndex = intro.body.indexOf('```python')
            if jsIndex is -1 and pyIndex isnt -1 or jsIndex isnt -1 and pyIndex is -1
              problems.push 'Intro is missing a language example.'
      @levels.push
        level: level
        overview: overview
        intro: intro
        problems: problems
      @levels.sort (a, b) ->
        return b.problems.length - a.problems.length
    @renderSelectors '#level-table'
