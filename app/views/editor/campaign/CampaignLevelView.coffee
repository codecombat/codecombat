CocoView = require 'views/core/CocoView'
Level = require 'models/Level'

module.exports = class CampaignLevelView extends CocoView
  id: 'campaign-level-view'
  template: require 'templates/editor/campaign/campaign-level-view'

  events:
    'click .close': 'onClickClose'

  constructor: (options, @level) ->
    super(options)
    @fullLevel = new Level _id: @level.id
    @fullLevel.fetch()
    @listenToOnce @fullLevel, 'sync', => @render?()

  getRenderData: ->
    c = super()
    c.level = if @fullLevel.loaded then @fullLevel else @level
    c

  onClickClose: ->
    @$el.addClass('hidden')
    @trigger 'hidden'
