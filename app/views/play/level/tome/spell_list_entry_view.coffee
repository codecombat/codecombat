# TODO: This still needs a way to send problem states to its Thang

View = require 'views/kinds/CocoView'
ThangAvatarView = require 'views/play/level/thang_avatar_view'
SpellListEntryThangsView = require 'views/play/level/tome/spell_list_entry_thangs_view'
template = require 'templates/play/level/tome/spell_list_entry'

module.exports = class SpellListEntryView extends View
  tagName: 'div'  #'li'
  className: 'spell-list-entry-view'
  template: template
  controlsEnabled: true

  subscriptions:
    'tome:problems-updated': "onProblemsUpdated"
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'

  events:
    'click': 'onClick'
    'mouseenter .thang-avatar-view': 'onMouseEnterAvatar'
    'mouseleave .thang-avatar-view': 'onMouseLeaveAvatar'

  constructor: (options) ->
    super options
    @spell = options.spell
    @showTopDivider = options.showTopDivider

  getRenderData: (context={}) =>
    context = super context
    context.spell = @spell
    context.parameters = (@spell.parameters or []).join ', '
    context.thangNames = (thangID for thangID of @spell.thangs).join(', ')  # + ", Marcus, Robert, Phoebe, Will Smith, Zap Brannigan, You, Gandaaaaalf"
    context.showTopDivider = @showTopDivider
    context

  getPrimarySpellThang: ->
    if @lastSelectedThang
      spellThang = _.find @spell.thangs, (spellThang) => spellThang.thang.id is @lastSelectedThang.id
      return spellThang if spellThang
    for thangID, spellThang of @spell.thangs
      return spellThang  # Just do the first one else

  afterRender: ->
    super()
    return unless @options.showTopDivider  # Don't repeat Thang avatars when not changed from previous entry
    return unless spellThang = @getPrimarySpellThang()
    @avatar = new ThangAvatarView thang: spellThang.thang, includeName: false, supermodel: @supermodel
    @$el.prepend @avatar.el  # Before rendering, so render can use parent for popover
    @avatar.render()
    @avatar.setSharedThangs _.size @spell.thangs
    @$el.addClass 'shows-top-divider' if @options.showTopDivider

  setSelected: (selected, @lastSelectedThang) ->
    @avatar?.setSelected selected

  onClick: (e) ->
    spellThang = @getPrimarySpellThang()
    Backbone.Mediator.publish "level-select-sprite", thangID: spellThang.thang.id, spellName: @spell.name

  onMouseEnterAvatar: (e) ->
    return unless @controlsEnabled and _.size(@spell.thangs) > 1
    @showThangs()

  onMouseLeaveAvatar: (e) ->
    return unless @controlsEnabled and _.size(@spell.thangs) > 1
    @hideThangsTimeout = _.delay @hideThangs, 100

  showThangs: =>
    clearTimeout @hideThangsTimeout if @hideThangsTimeout
    return if @thangsView
    @thangsView = new SpellListEntryThangsView thangs: (spellThang.thang for thangID, spellThang of @spell.thangs), thang: @getPrimarySpellThang().thang, spell: @spell, supermodel: @supermodel
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
    @$el.toggleClass "user-code-problem", e.problems.length

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
