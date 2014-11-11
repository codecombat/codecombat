CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/modal/item-details-view'
CocoCollection = require 'collections/CocoCollection'
LevelComponent = require 'models/LevelComponent'

utils = require 'lib/utils'

module.exports = class ItemDetailsView extends CocoView
  id: "item-details-view"
  template: template

  constructor: ->
    super(arguments...)
    @propDocs = {}

  setItem: (@item) ->
    if @item
      @item.name = utils.i18n @item.attributes, 'name'
      @item.affordable = me.gems() >= @item.get('gems')
      @item.owned = me.ownsItem @item.get('original')
      @item.comingSoon = not @item.getFrontFacingStats().props.length and not _.size @item.getFrontFacingStats().stats  # Temp: while there are placeholder items
      
      stats = @item.getFrontFacingStats()
      props = (p for p in stats.props when not @propDocs[p])
      if props.length > 0

        docs = new CocoCollection([], {
          url: '/db/level.component?view=prop-doc-lookup'
          model: LevelComponent
          project: [
            'propertyDocumentation.name'
            'propertyDocumentation.description'
            'propertyDocumentation.i18n'
          ]
        })
  
        docs.fetch({ data: {
          componentOriginals: [c.original for c in @item.get('components')].join(',')
          propertyNames: props.join(',')
        }})
        @listenToOnce docs, 'sync', @onDocsLoaded
    
    @render()
    @$el.find('.nano:visible').nanoScroller()

  onDocsLoaded: (levelComponents) ->
    for component in levelComponents.models
      for propDoc in component.get('propertyDocumentation')
        @propDocs[propDoc.name] = propDoc
    @render()

  getRenderData: ->
    c = super()
    c.item = @item
    if @item
      stats = @item.getFrontFacingStats()
      c.stats = _.values(stats.stats)
      _.last(c.stats).isLast = true if c.stats.length
      c.props = []
      progLang = (me.get('aceConfig') ? {}).language or 'python'
      for prop in stats.props
        description = utils.i18n @propDocs[prop] ? {}, 'description'

        if _.isObject description
          description = description[progLang] or _.values(description)[0]
        if _.isString description
          description = description.replace(/#{spriteName}/g, 'hero')
          if fact = stats.stats.shieldDefenseFactor
            description = description.replace(/#{shieldDefensePercent}%/g, fact.display)
          description = $(marked(description)).html()

        c.props.push {
          name: prop
          description: description or '...'
        }
    c 