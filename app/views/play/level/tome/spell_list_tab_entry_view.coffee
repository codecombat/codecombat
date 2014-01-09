SpellListEntryView = require './spell_list_entry_view'
ThangAvatarView = require 'views/play/level/thang_avatar_view'
template = require 'templates/play/level/tome/spell_list_tab_entry'
Docs = require 'lib/world/docs'

module.exports = class SpellListTabEntryView extends SpellListEntryView
  template: template
  id: 'spell-list-tab-entry-view'

  subscriptions:
    'tome:spell-loaded': "onSpellLoaded"
    'tome:spell-changed': "onSpellChanged"

  events:
    'click .spell-list-button': 'onDropdownClick'
    'click .reload-code': 'onCodeReload'

  constructor: (options) ->
    super options

  getRenderData: (context={}) =>
    context = super context
    context

  afterRender: ->
    super()
    @$el.addClass 'spell-tab'

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
    doc = Docs.getDocsFor(@thang, [@spell.name])[0]
    @$el.find('code').attr('title', doc.title()).popover(
      animation: true
      html: true
      placement: 'bottom'
      trigger: 'hover'
      content: doc.html()
      container: @$el.parent()
    )
    @docsBuilt = true

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
