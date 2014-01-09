# The SpellListView has SpellListEntryViews, which have ThangAvatarViews.
# The SpellListView serves as a dropdown triggered from a SpellListTabEntryView, which actually isn't in a list, just had a lot of similar parts.
# There is only one SpellListView, and it belongs to the TomeView.

# TODO: showTopDivider should change when we reorder

View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_list'
{me} = require 'lib/auth'
SpellListEntryView = require './spell_list_entry_view'

module.exports = class SpellListView extends View
  className: 'spell-list-view'
  id: 'spell-list-view'
  template: template

  subscriptions: {}

  constructor: (options) ->
    super options
    @spells = options.spells
    @sortSpells()

  sortSpells: ->
    # Keep only spells for which we have permissions
    spells = _.filter @spells, (s) -> s.canRead()
    @spells = _.sortBy spells, @sortScoreForSpell
    #console.log "Kept sorted spells", @spells

  sortScoreForSpell: (s) =>
    # Sort by most spells per fewest Thangs
    # Lower comes first
    score = 0
    # Selected spell at the top
    score -= 9001900190019001 if s is @spell
    # Spells for selected thang at the top
    score -= 900190019001 if @thang and @thang.id of s.thangs
    # Read-only spells at the bottom
    score += 90019001 unless s.canWrite()
    # The more Thangs sharing a spell, the lower
    score += 9001 * _.size(s.thangs)
    # The more spells per Thang, the higher
    score -= _.filter(@spells, (s2) -> thangID of s2.thangs).length for thangID of s.thangs
    score

  sortEntries: ->
    # Call sortSpells before this
    @entries = _.sortBy @entries, (entry) => _.indexOf @spells, entry.spell
    @$el.append entry.$el for entry in @entries

  afterRender: ->
    super()
    @addSpellListEntries()

  addSpellListEntries: ->
    @entries = []
    lastThangs = null
    for spell, index in @spells
      theseThangs = _.keys(spell.thangs)
      changedThangs = not lastThangs or not _.isEqual theseThangs, lastThangs
      lastThangs = theseThangs
      @entries.push entry = new SpellListEntryView spell: spell, showTopDivider: changedThangs, supermodel: @supermodel
    for entry in @entries
      @$el.append entry.el
      entry.render()  # Render after appending so that we can access parent container for popover

  setThangAndSpell: (@thang, @spell) ->
    @entries[0]?.setSelected false
    @sortSpells()
    @sortEntries()
    @entries[0].setSelected true, @thang
