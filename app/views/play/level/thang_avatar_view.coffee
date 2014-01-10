View = require 'views/kinds/CocoView'
template = require 'templates/play/level/thang_avatar'
ThangType = require 'models/ThangType'

module.exports = class ThangAvatarView extends View
  className: 'thang-avatar-view'
  template: template

  subscriptions:
    'tome:problems-updated': "onProblemsUpdated"

  constructor: (options) ->
    super options
    @thang = options.thang
    @includeName = options.includeName

  getRenderData: (context={}) =>
    context = super context
    context.thang = @thang
    thangs = @supermodel.getModels(ThangType)
    thangs = (t for t in thangs when t.get('name') is @thang.spriteName)
    thang = thangs[0]
    context.avatarURL = thang.getPortraitSource()
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
    return unless @thang.id of e.spell.thangs
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
