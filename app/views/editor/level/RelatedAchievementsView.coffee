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

  constructor: (options) ->
    super options
    @level = options.level
    @relatedID = @level.get('original')
    @achievements = new RelatedAchievementsCollection @relatedID
    @supermodel.loadCollection @achievements, 'achievements'

  onLoaded: ->
    console.debug 'related achievements loaded'
    @achievements.loading = false
    super()

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
