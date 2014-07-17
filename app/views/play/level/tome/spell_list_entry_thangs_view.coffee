View = require 'views/kinds/CocoView'
ThangAvatarView = require 'views/play/level/thang_avatar_view'
template = require 'templates/play/level/tome/spell_list_entry_thangs'

module.exports = class SpellListEntryThangsView extends View
  className: 'spell-list-entry-thangs-view'
  template: template

  constructor: (options) ->
    super options
    @thangs = options.thangs
    @thang = options.thang
    @spell = options.spell
    @avatars = []

  getRenderData: (context={}) ->
    context = super context
    context.thangs = @thangs
    context.spell = @spell
    context

  afterRender: ->
    super()
    avatar.destroy() for avatar in @avatars if @avatars
    @avatars = []
    spellName = @spell.name
    for thang in @thangs
      avatar = new ThangAvatarView thang: thang, includeName: true, supermodel: @supermodel, creator: @
      @$el.append avatar.el
      avatar.render()
      avatar.setSelected thang is @thang
      avatar.$el.data('thang-id', thang.id).click (e) ->
        Backbone.Mediator.publish 'level-select-sprite', thangID: $(@).data('thang-id'), spellName: spellName
      avatar.onProblemsUpdated spell: @spell
      @avatars.push avatar

  destroy: ->
    avatar.destroy() for avatar in @avatars
    super()
