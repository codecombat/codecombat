CocoView = require 'views/core/CocoView'

module.exports = class CampaignLevelView extends CocoView
  id: 'campaign-level-view'
  template: require 'templates/editor/campaign/campaign-level-view'
  
  events:
    'click .close': 'onClickClose'
  
  constructor: (options, @level) ->
    super(options)
    
  getRenderData: ->
    c = super()
    c.level = @level
    c

  onClickClose: ->
    @$el.addClass('hidden')