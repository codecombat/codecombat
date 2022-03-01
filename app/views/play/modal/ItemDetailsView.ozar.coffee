require('app/styles/play/modal/item-details-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/modal/item-details-view'
CocoCollection = require 'collections/CocoCollection'
LevelComponent = require 'models/LevelComponent'

{downTheChain} = require 'lib/world/world_utils'
utils = require 'core/utils'

module.exports = class ItemDetailsView extends CocoView
  id: "item-details-view"
  template: template

  constructor: ->
    super(arguments...)
    @propDocs = {}
    @spellDocs = {}

  setItem: (@item) ->
    if @item
      @spellDocs = {}
      @item.name = utils.i18n @item.attributes, 'name'
      @item.description = utils.i18n @item.attributes, 'description'
      @item.affordable = me.gems() >= @item.get('gems')
      @item.owned = me.ownsItem @item.get('original')
      @item.comingSoon = not @item.getFrontFacingStats().props.length and not _.size @item.getFrontFacingStats().stats  # Temp: while there are placeholder items
      @componentConfigs = (c.config for c in @item.get('components') when c.config)

      stats = @item.getFrontFacingStats()
      props = (p for p in stats.props when not @propDocs[p])
      if props.length > 0 or ('cast' in stats.props)

        docs = new CocoCollection([], {
          url: '/db/level.component?view=prop-doc-lookup'
          model: LevelComponent
          project: [
            'name'
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

  onDocsLoaded: (levelComponents) ->
    for component in levelComponents.models
      for propDoc in component.get('propertyDocumentation')
        if /^cast.+/.test propDoc.name
          @spellDocs[propDoc.name] = propDoc
        else
          @propDocs[propDoc.name] = propDoc
    @render()

  afterRender: ->
    super()
    @$el.find('.nano:visible').nanoScroller({alwaysVisible: true})

  getRenderData: ->
    c = super()
    c.item = @item
    if @item
      stats = @item.getFrontFacingStats()
      c.stats = _.values(stats.stats)
      _.last(c.stats).isLast = true if c.stats.length
      c.props = []
      stats.props = _.union stats.props, _.keys @spellDocs
      codeLanguage = (me.get('aceConfig') ? {}).language or 'python'
      for prop in stats.props
        doc = @propDocs[prop] ? @spellDocs[prop] ? {}
        description = utils.i18n doc, 'description'

        if _.isObject description
          description = description[codeLanguage] or _.values(description)[0]
        if _.isString description
          description = description.replace(/#{spriteName}/g, 'hero')
          if fact = stats.stats.shieldDefenseFactor
            description = description.replace(/#{shieldDefensePercent}%/g, fact.display)
          if prop is 'buildTypes'
            buildsConfig = _.find @componentConfigs, 'buildables'
            description = description.replace '#{buildTypes}', "`[\"#{_.keys(buildsConfig.buildables).join('\", \"')}\"]`"
          # We don't have the full components loaded here, so we can't really get most of these values.
          componentConfigs = @componentConfigs ? []
          description = description.replace /#{([^.]+?)}/g, (match, keyChain) ->
            for componentConfig in componentConfigs
              if value = downTheChain componentConfig, keyChain
                return value
            #console.log 'gotta find', keyChain, 'from', match
            match
          description = description.replace(/#{(.+?)}/g, '`$1`')
          description = $(marked(description)).html()

        c.props.push {
          name: prop
          description: description or '...'
        }
    c
