SpellListEntryView = require './spell_list_entry_view'
ThangAvatarView = require 'views/play/level/thang_avatar_view'
template = require 'templates/play/level/tome/spell_list_tab_entry'
popoverTemplate = require 'templates/play/level/tome/spell_palette_entry_popover'
LevelComponent = require 'models/LevelComponent'
{downTheChain} = require 'lib/world/world_utils'

module.exports = class SpellListTabEntryView extends SpellListEntryView
  template: template
  id: 'spell-list-tab-entry-view'

  subscriptions:
    'tome:spell-loaded': "onSpellLoaded"
    'tome:spell-changed': "onSpellChanged"
    'god:new-world-created': 'onNewWorld'

  events:
    'click .spell-list-button': 'onDropdownClick'
    'click .reload-code': 'onCodeReload'

  constructor: (options) ->
    super options

  getRenderData: (context={}) ->
    context = super context
    context

  afterRender: ->
    super()
    @$el.addClass 'spell-tab'

  onNewWorld: (e) ->
    @thang = e.world.thangMap[@thang.id] if @thang

  setThang: (thang) ->
    return if thang.id is @thang?.id
    @thang = thang
    @spellThang = @spell.thangs[@thang.id]
    @buildAvatar()
    @buildDocs() unless @docsBuilt

  buildAvatar: ->
    avatar = new ThangAvatarView thang: @thang, includeName: false, supermodel: @supermodel
    if @avatar
      @avatar.$el.replaceWith avatar.$el
      @avatar.destroy()
    else
      @$el.find('.thang-avatar-placeholder').replaceWith avatar.$el
    @avatar = avatar
    @avatar.render()

  buildDocs: ->
    @docsBuilt = true
    lcs = @supermodel.getModels LevelComponent
    found = false
    for lc in lcs when not found
      for doc in lc.get('propertyDocumentation') ? []
        if doc.name is @spell.name
          found = true
          break
    return unless found
    doc.owner = 'this'
    doc.shortName = doc.shorterName = doc.title = "this.#{doc.name}();"
    @$el.find('code').popover(
      animation: true
      html: true
      placement: 'bottom'
      trigger: 'hover'
      content: @formatPopover doc
      container: @$el.parent()
    )

  formatPopover: (doc) ->
    content = popoverTemplate doc: doc, marked: marked, argumentExamples: (arg.example or arg.default or arg.name for arg in doc.args ? [])
    owner = @thang
    content = content.replace /#{spriteName}/g, @thang.spriteName  # No quotes like we'd get with @formatValue
    content.replace /\#\{(.*?)\}/g, (s, properties) => @formatValue downTheChain(owner, properties.split('.'))

  formatValue: (v) ->
    # TODO: refactor and move spell_palette_entry_view version of this somewhere else
    # maybe think about making it common with what Aether does and the SpellDebugView, too
    if _.isNumber v
      if v == Math.round v
        return v
      return v.toFixed 2
    if _.isString v
      return "\"#{v}\""
    if v?.id
      return v.id
    if v?.name
      return v.name
    if _.isArray v
      return '[' + (@formatValue v2 for v2 in v).join(', ') + ']'
    if _.isPlainObject v
      return safeJSONStringify v, 2
    v

  onMouseEnterAvatar: (e) ->  # Don't call super
  onMouseLeaveAvatar: (e) ->  # Don't call super
  onClick: (e) ->  # Don't call super

  onDropdownClick: (e) ->
    Backbone.Mediator.publish 'tome:toggle-spell-list'

  onCodeReload: ->
    Backbone.Mediator.publish "tome:reload-code", spell: @spell

  updateReloadButton: ->
    changed = @spell.hasChanged null, @spell.getSource()
    @$el.find('.reload-code').css('display', if changed then 'inline-block' else 'none')

  onSpellLoaded: (e) ->
    return unless e.spell is @spell
    @updateReloadButton()

  onSpellChanged: (e) ->
    return unless e.spell is @spell
    @updateReloadButton()

  toggleControls: (e, enabled) ->
    # Don't call super; do it differently
    return if e.controls and not ('editor' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.toggleClass 'read-only', not enabled

  destroy: ->
    @avatar?.destroy()
    @$el.find('code').popover 'destroy'
    super()
