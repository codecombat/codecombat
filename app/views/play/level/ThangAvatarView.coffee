CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/thang_avatar'
ThangType = require 'models/ThangType'

module.exports = class ThangAvatarView extends CocoView
  className: 'thang-avatar-view'
  template: template

  subscriptions:
    'tome:problems-updated': 'onProblemsUpdated'
    'god:new-world-created': 'onNewWorld'

  constructor: (options) ->
    super options
    @thang = options.thang
    @includeName = options.includeName
    @thangType = @getSpriteThangType()
    if not @thangType
      console.error 'Thang avatar view expected a thang type to be provided.'
      return

    unless @thangType.isFullyLoaded() or @thangType.loading
      @thangType.fetch()

    # couldn't get the level view to load properly through the supermodel
    # so just doing it manually this time.
    @listenTo @thangType, 'sync', @render
    @listenTo @thangType, 'build-complete', @render

  getSpriteThangType: ->
    thangs = @supermodel.getModels(ThangType)
    thangs = (t for t in thangs when t.get('name') is @thang.spriteName)
    loadedThangs = (t for t in thangs when t.isFullyLoaded())
    return loadedThangs[0] or thangs[0] # try to return one with all the goods, otherwise a projection

  getRenderData: (context={}) ->
    context = super context
    context.thang = @thang
    options = @thang?.getLankOptions() or {}
    #options.async = true  # sync builds fail during async builds, and we build HUD version sync
    context.avatarURL = @thangType.getPortraitSource(options) unless @thangType.loading
    context.includeName = @includeName
    context

  setProblems: (problemCount, level) ->
    badge = @$el.find('.badge.problems').text(if problemCount then 'x' else '')
    badge.removeClass('error warning info')
    badge.addClass level if level

  setSharedThangs: (sharedThangCount) ->
    badge = @$el.find('.badge.shared-thangs').text(if sharedThangCount > 1 then sharedThangCount else '')
    # TODO: change the alert color based on whether any of those things that aren't us have problems
    #badge.removeClass('error warning info')
    #badge.addClass level if level

  setSelected: (selected) ->
    @$el.toggleClass 'selected', Boolean(selected)

  onProblemsUpdated: (e) ->
    return unless @thang?.id of e.spell.thangs
    myProblems = []
    for thangID, spellThang of e.spell.thangs when thangID is @thang.id
      #aether = if e.isCast and spellThang.castAether then spellThang.castAether else spellThang.aether
      aether = spellThang.castAether  # try only paying attention to the actually cast ones
      myProblems = myProblems.concat aether.getAllProblems() if aether
    worstLevel = null
    for level in ['error', 'warning', 'info'] when _.some myProblems, {level: level}
      worstLevel = level
      break
    @setProblems myProblems.length, worstLevel

  onNewWorld: (e) ->
    @options.thang = @thang = e.world.thangMap[@thang.id] if @thang and e.world.thangMap[@thang.id]

  destroy: ->
    super()
