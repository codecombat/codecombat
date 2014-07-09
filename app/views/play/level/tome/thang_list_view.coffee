# The ThangListView lives in the code area behind the SpellView, so that when you don't have a spell, you can select any Thang.
# It just ha a bunch of ThangListEntryViews (which are mostly ThangAvatarViews) in a few sections.

View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/thang_list'
{me} = require 'lib/auth'
ThangListEntryView = require './thang_list_entry_view'

module.exports = class ThangListView extends View
  className: 'thang-list-view'
  id: 'thang-list-view'
  template: template

  subscriptions: {}

  constructor: (options) ->
    super options
    @spells = options.spells
    @thangs = _.filter options.thangs, 'isSelectable'
    @sortThangs()

  sortThangs: ->
    @readwriteThangs = _.sortBy _.filter(@thangs, (thang) =>
      return true for spellKey, spell of @spells when thang.id of spell.thangs and spell.canWrite()
      false
    ), @sortScoreForThang
    @readThangs = _.sortBy _.filter(@thangs, (thang) =>
      return true for spellKey, spell of @spells when thang.id of spell.thangs and spell.canRead() and not spell.canWrite()
      false
    ), @sortScoreForThang
    @muggleThangs = _.sortBy _.without(@thangs, @readwriteThangs..., @readThangs...), @sortScoreForThang

  sortScoreForThang: (t) =>
    # Sort by my team, then most spells and fewest shared Thangs per spell,
    # then by thang.spriteName alpha, then by thang.id alpha.
    # Lower comes first
    score = 0
    # Thangs on my team are highest priority
    score -= 9001900190019001 if t.team is me.team
    # The more spells per Thang, the lower
    score -= 900190019001 for spellKey, spell of @spells when t.id of spell.thangs and spell.canRead()
    # The more Thangs per spell, the higher
    score += 90019001 for t2 of spell.thangs for spellKey, spell of @spells when t.id of spell.thangs
    alpha = (s) -> _.reduce [0 ... s.length], ((acc, i) -> acc + s.charCodeAt(i) / Math.pow(100, i)), 0
    # Alpha by spriteName
    score += 9001 * alpha t.spriteName
    # Alpha by id
    score += alpha t.id
    score

  afterRender: ->
    super()
    @addThangListEntries()

  addThangListEntries: ->
    @entries = []
    for [thangs, section, permission] in [
      [@readwriteThangs, '#readwrite-thangs', 'readwrite']  # Your Minions
      [@readThangs, '#read-thangs', 'read']  # Read-Only
      [@muggleThangs, '#muggle-thangs', null]  # Non-Castable
    ]
      section = @$el.find(section).toggle thangs.length > 0
      for thang in thangs
        spells = _.filter @spells, (s) -> thang.id of s.thangs
        entry = new ThangListEntryView thang: thang, spells: spells, permission: permission, supermodel: @supermodel
        section.find('.thang-list').append entry.el  # Render after appending so that we can access parent container for popover
        entry.render()
        @entries.push entry

  topSpellForThang: (thang) ->
    for entry in @entries when entry.thang.id is thang.id
      return entry.spells[0]
    null

  adjustThangs: (spells, thangs) ->
    @spells = @options.spells = spells
    for entry in @entries
      entry.$el.remove()
      entry.destroy()
    @thangs = @options.thangs = thangs
    @sortThangs()
    @addThangListEntries()

  destroy: ->
    entry.destroy() for entry in @entries
    super()
