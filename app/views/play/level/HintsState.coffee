module.exports = class HintsState extends Backbone.Model
  
  initialize: (attributes, options) ->
    { @level, @session } = options
    @listenTo(@level, 'change:documentation', @update)
    @update()

  update: ->
    hints = @level.get('documentation')?.hints or []
    total = _.size(hints)
    @set({ 
      available: total
      total
    })

    
