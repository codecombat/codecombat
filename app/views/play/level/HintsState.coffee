module.exports = class HintsState extends Backbone.Model
  
  initialize: (attributes, options) ->
    { @level, @session } = options
    @listenTo(@level, 'change:documentation', @update)
    @update()

  getHint: (index) ->
    @get('hints')?[index]

  update: ->
    hints = @level.get('documentation')?.hints or []
    for article in @level.get('documentation')?.specificArticles ? []
      hints.unshift(article) if article.name is 'Intro'
      hints.push(article) if article.name is 'Overview'
    total = _.size(hints)
    @set({ 
      hints: hints
      total
    })

    
