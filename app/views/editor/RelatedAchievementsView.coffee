CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/related-achievements'
RelatedAchievementsCollection = require 'collections/RelatedAchievementsCollection'
Achievement = require 'models/Achievement'

module.exports = class RelatedAchievementsView extends CocoView
  id: 'related-achievements-view'
  template: template
  className: 'tab-pane'

  constructor: (options) ->
    super options
    @relatedID = options.id
    @achievements = new RelatedAchievementsCollection @relatedID
    console.debug @achievements
    @supermodel.loadCollection @achievements, 'achievements'

  onLoaded: ->
    console.debug 'related achievements loaded'
    super()

  getRenderData: ->
    c = super()
    c.achievements = @achievements
    c.relatedID = @relatedID
    c
