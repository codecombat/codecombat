CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/level/related-achievements'
RelatedAchievementsCollection = require 'collections/RelatedAchievementsCollection'
Achievement = require 'models/Achievement'
NewAchievementModal = require './modals/NewAchievementModal'
app = require 'application'

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

  getRenderData: ->
    c = super()
    c.achievements = @achievements
    c.relatedID = @relatedID
    c

  onNewAchievementSaved: (achievement) ->
    app.router.navigate('/editor/achievement/' + (achievement.get('slug') or achievement.id), {trigger: true})

  makeNewAchievement: ->
    modal = new NewAchievementModal model: Achievement, modelLabel: 'Achievement', level: @level
    modal.once 'model-created', @onNewAchievementSaved
    @openModalView modal

  onViewSwitched: (e) ->
    # Lazily load.
    return unless e.targetURL is '#related-achievements-view'
    @loadAchievements()
