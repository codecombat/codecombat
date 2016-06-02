HINT_FREQUENCY = 2 * 60

module.exports = class HintsState extends Backbone.Model
  
  initialize: (attributes, options) ->
    { @level, @session } = options
    @listenTo(@session, 'change:playtime', @update)
    @listenTo(@level, 'change:documentation', @update)
    @update()

  update: ->
    hints = @level.get('documentation')?.hints or []
    total = _.size(hints)
    maximum = Math.floor(@session.get('playtime') / HINT_FREQUENCY)
    @set({ 
      available: Math.min(total, maximum)
      total
    })

    
