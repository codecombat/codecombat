CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/related-achievements'
RelatedAchievementsCollection = require 'collections/RelatedAchievementsCollection'
Achievement = require 'models/Achievement'
NewModelModal = require 'views/modal/NewModelModal'
app = require 'application'

module.exports = class RelatedAchievementsView extends CocoView
  id: 'related-achievements-view'
  template: template
  className: 'tab-pane'

  events:
    'click #new-achievement-button': 'makeNewAchievement'

  constructor: (options) ->
    super options
    @relatedID = options.relatedID
    @achievements = new RelatedAchievementsCollection @relatedID
    console.debug @achievements
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

  render: ->
    console.debug 'rendering achievements'
    super()

  onNewAchievementSaved: (achievement) ->
    app.router.navigate('/editor/achievement/' + (achievement.get('slug') or achievement.id), {trigger: true})

  makeNewAchievement: ->
    modal = new NewModelModal model: Achievement, modelLabel: 'Achievement', properties: related: @relatedID
    modal.once 'success', @onNewAchievementSaved
    @openModalView modal
