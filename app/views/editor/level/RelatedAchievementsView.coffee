require('app/styles/editor/related-achievements.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/related-achievements'
RelatedAchievementsCollection = require 'collections/RelatedAchievementsCollection'
Achievement = require 'models/Achievement'
NewAchievementModal = require './modals/NewAchievementModal'

module.exports = class RelatedAchievementsView extends CocoView
  id: 'related-achievements-view'
  template: template
  className: 'tab-pane'

  events:
    'click #new-achievement-button': 'makeNewAchievement'

  subscriptions:
    'editor:view-switched': 'onViewSwitched'

  constructor: (options) ->
    super options
    @level = options.level
    @relatedID = @level.get('original')
    @achievements = new RelatedAchievementsCollection @relatedID

  loadAchievements: ->
    return if @loadingAchievements
    @supermodel.loadCollection @achievements, 'achievements'
    @loadingAchievements = true
    @render()

  onNewAchievementSaved: (achievement) ->
    # We actually open the new tab in NewAchievementModal, so we don't replace this window.
    #url = '/editor/achievement/' + (achievement.get('slug') or achievement.id)
    #application.router.navigate(, {trigger: true})  # Let's open a new tab instead.

  makeNewAchievement: ->
    modal = new NewAchievementModal model: Achievement, modelLabel: 'Achievement', level: @level
    modal.once 'model-created', @onNewAchievementSaved
    @openModalView modal

  onViewSwitched: (e) ->
    # Lazily load.
    return unless e.targetURL is '#related-achievements-view'
    @loadAchievements()
