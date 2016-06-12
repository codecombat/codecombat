# TODO: This still needs a way to send problem states to its Thang

CocoView = require 'views/core/CocoView'
ThangAvatarView = require 'views/play/level/ThangAvatarView'
SpellListEntryThangsView = require 'views/play/level/tome/SpellListEntryThangsView'
template = require 'templates/play/level/tome/spell_list_entry'

module.exports = class SpellListEntryView extends CocoView
  tagName: 'div'  #'li'
  className: 'spell-list-entry-view'
  template: template
  controlsEnabled: true

  subscriptions:
    'tome:problems-updated': 'onProblemsUpdated'
    'tome:spell-changed-language': 'onSpellChangedLanguage'
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'god:new-world-created': 'onNewWorld'

  events:
    'click': 'onClick'
    'mouseenter .thang-avatar-view': 'onMouseEnterAvatar'
    'mouseleave .thang-avatar-view': 'onMouseLeaveAvatar'

  constructor: (options) ->
    super options
    @spell = options.spell
    @showTopDivider = options.showTopDivider

  getRenderData: (context={}) ->
    context = super context
    context.spell = @spell
    context.thangNames = (thangID for thangID, spellThang of @spell.thangs when spellThang.thang.exists).join(', ')  # + ', Marcus, Robert, Phoebe, Will Smith, Zap Brannigan, You, Gandaaaaalf'
    context.showTopDivider = @showTopDivider
    context

  getPrimarySpellThang: ->
    if @lastSelectedThang
      spellThang = _.find @spell.thangs, (spellThang) => spellThang.thang.id is @lastSelectedThang.id
      return spellThang if spellThang
    for thangID, spellThang of @spell.thangs
      continue unless spellThang.thang.exists
      return spellThang  # Just do the first one else

  afterRender: ->
    super()
    return unless @options.showTopDivider  # Don't repeat Thang avatars when not changed from previous entry
    return @$el.hide() unless spellThang = @getPrimarySpellThang()
    @$el.show()
    @avatar?.destroy()
    @avatar = new ThangAvatarView thang: spellThang.thang, includeName: false, supermodel: @supermodel
    @$el.prepend @avatar.el  # Before rendering, so render can use parent for popover
    @avatar.render()
    @avatar.setSharedThangs _.size @spell.thangs
    @$el.addClass 'shows-top-divider' if @options.showTopDivider

  setSelected: (selected, @lastSelectedThang) ->
    @avatar?.setSelected selected

  onClick: (e) ->
    spellThang = @getPrimarySpellThang()
    Backbone.Mediator.publish 'level:select-sprite', thangID: spellThang.thang.id, spellName: @spell.name

  onMouseEnterAvatar: (e) ->
    return unless @controlsEnabled and _.size(@spell.thangs) > 1
    @showThangs()

  onMouseLeaveAvatar: (e) ->
    return unless @controlsEnabled and _.size(@spell.thangs) > 1
    @hideThangsTimeout = _.delay @hideThangs, 100

  showThangs: ->
    clearTimeout @hideThangsTimeout if @hideThangsTimeout
    return if @thangsView
    spellThang = @getPrimarySpellThang()
    return unless spellThang
    @thangsView = new SpellListEntryThangsView thangs: (spellThang.thang for thangID, spellThang of @spell.thangs), thang: spellThang.thang, spell: @spell, supermodel: @supermodel
    @thangsView.render()
    @$el.append @thangsView.el
    @thangsView.$el.mouseenter (e) => @onMouseEnterAvatar()
    @thangsView.$el.mouseleave (e) => @onMouseLeaveAvatar()

  hideThangs: =>
    return unless @thangsView
    @thangsView.off 'mouseenter mouseleave'
    @thangsView.$el.remove()
    @thangsView.destroy()
    @thangsView = null

  onProblemsUpdated: (e) ->
    return unless e.spell is @spell
    @$el.toggleClass 'user-code-problem', e.problems.length

  onSpellChangedLanguage: (e) ->
    return unless e.spell is @spell
    @render()  # So that we can update parameters if needed

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true
  toggleControls: (e, enabled) ->
    return if e.controls and not ('editor' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    disabled = not enabled
    # Should refactor the disabling list so we can target the spell list separately?
    # Should not call it 'editor' any more?
    @$el.toggleClass('disabled', disabled).find('*').prop('disabled', disabled)

  onNewWorld: (e) ->
    @lastSelectedThang = e.world.thangMap[@lastSelectedThang.id] if @lastSelectedThang

  destroy: ->
    @avatar?.destroy()
    super()
