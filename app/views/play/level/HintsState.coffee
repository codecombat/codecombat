module.exports = class HintsState extends Backbone.Model

  initialize: (attributes, options) ->
    { @level, @session } = options
    @listenTo(@level, 'change:documentation', @update)
    @update()

  getHint: (index) ->
    @get('hints')?[index]

  update: ->
    hints = switch me.getHintsGroup()
      when 'hints' then _.cloneDeep(@level.get('documentation')?.hints or [])
      when 'hintsB' then _.cloneDeep(@level.get('documentation')?.hintsB or [])
      else []
    haveIntro = false
    haveOverview = false
    for article in @level.get('documentation')?.specificArticles ? []
      if not haveIntro and article.name is 'Intro'
        hints.unshift(article)
        haveIntro = true
      if not haveOverview and article.name is 'Overview'
        hints.push(article)
        haveOverview = true
      break if haveIntro and haveOverview
    total = _.size(hints)
    @set({
      hints
      total
    })
