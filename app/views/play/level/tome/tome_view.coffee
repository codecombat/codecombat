# There's one TomeView per Level. It has:
# - a CastButtonView, which has
#   - a cast button
#   - an autocast settings options button
# - for each spell (programmableMethod):
#   - a Spell, which has
#     - a list of Thangs that share that Spell, with one aether per Thang per Spell
#     - a SpellView, which has
#       - tons of stuff; the meat
# - a SpellListView, which has
#   - for each spell:
#     - a SpellListEntryView, which has
#       - icons for each Thang
#       - the spell name
#       - a reload button
#       - documentation for that method (in a popover)
# - a SpellPaletteView, which has
#   - for each programmableProperty:
#     - a SpellPaletteEntryView
#
# The CastButtonView and SpellListView always show.
# The SpellPaletteView shows the entries for the currently selected Programmable Thang.
# The SpellView shows the code and runtime state for the currently selected Spell and, specifically, Thang.
# The SpellView obscures most of the SpellListView when present. We might mess with this.
# You can switch a SpellView to showing the runtime state of another Thang sharing that Spell.
# SpellPaletteViews are destroyed and recreated whenever you switch Thangs.
# The SpellListView shows spells to which your team has read or readwrite access.
# It doubles as a Thang selector, since it's there when nothing is selected.

View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/tome'
{me} = require 'lib/auth'
Spell = require './spell'
SpellListView = require './spell_list_view'
ThangListView = require './thang_list_view'
SpellPaletteView = require './spell_palette_view'
CastButtonView = require './cast_button_view'

module.exports = class TomeView extends View
  id: 'tome-view'
  template: template
  controlsEnabled: true
  cache: false

  subscriptions:
    'tome:spell-loaded': "onSpellLoaded"
    'tome:cast-spell': "onCastSpell"
    'tome:toggle-spell-list': 'onToggleSpellList'
    'surface:sprite-selected': 'onSpriteSelected'

  events:
    'click #spell-view': 'onSpellViewClick'
    'click': -> Backbone.Mediator.publish 'focus-editor'

  afterRender: ->
    super()
    programmableThangs = _.filter @options.thangs, 'isProgrammable'
    @createSpells programmableThangs  # Do before spellList, thangList, and castButton
    @spellList = @insertSubView new SpellListView spells: @spells, supermodel: @supermodel
    @thangList = @insertSubView new ThangListView spells: @spells, thangs: @options.thangs, supermodel: @supermodel
    @castButton = @insertSubView new CastButtonView spells: @spells

  createSpells: (programmableThangs) ->
    # If needed, we could make this able to update when programmableThangs changes.
    # We haven't done that yet, so call it just once on init.
    pathPrefixComponents = ['play', 'level', @options.levelID, @options.session.id, 'code']
    @spells = {}
    @thangSpells = {}
    for thang in programmableThangs
      world = thang.world
      @thangSpells[thang.id] = []
      for methodName, method of thang.programmableMethods
        pathComponents = [thang.id, methodName]
        if method.cloneOf
          pathComponents[0] = method.cloneOf  # referencing another Thang's method
        pathComponents[0] = _.string.slugify pathComponents[0]
        spellKey = pathComponents.join '/'
        @thangSpells[thang.id].push spellKey
        unless method.cloneOf
          spell = @spells[spellKey] = new Spell method, spellKey, pathPrefixComponents.concat(pathComponents), @options.session, @supermodel
    for thangID, spellKeys of @thangSpells
      thang = world.getThangByID(thangID)
      @spells[spellKey].addThang thang for spellKey in spellKeys
    null

  onSpellLoaded: (e) ->
    for spellID, spell of @spells
      return unless spell.loaded
    @cast()

  onCastSpell: (e) ->
    # A single spell is cast.
    # Hmm; do we need to make sure other spells are all cast here?
    @cast()

  cast: ->
    Backbone.Mediator.publish 'tome:cast-spells', spells: @spells

  onToggleSpellList: (e) ->
    @spellList.$el.toggle()

  onSpellViewClick: (e) ->
    @spellList.$el.hide()

  clearSpellView: ->
    @spellView?.dismiss()
    @spellView?.$el.after('<div id="' + @spellView.id + '"></div>').detach()
    @spellView = null
    @spellTabView?.$el.after('<div id="' + @spellTabView.id + '"></div>').detach()
    @spellTabView = null
    @removeSubView @spellPaletteView if @spellPaletteView
    @thangList.$el.show()

  onSpriteSelected: (e) ->
    thang = e.thang
    spellName = e.spellName
    @spellList.$el.hide()
    return @clearSpellView() unless thang?.isProgrammable
    selectedThangSpells = (@spells[spellKey] for spellKey in @thangSpells[thang.id])
    if spellName
      spell = _.find selectedThangSpells, {name: spellName}
    else
      spell = @thangList.topSpellForThang thang
      #spell = selectedThangSpells[0]  # TODO: remember last selected spell for this thang
    return @clearSpellView() unless spell?.canRead()
    @spellList.setThangAndSpell thang, spell
    return if spell.view is @spellView
    @clearSpellView()
    @spellView = spell.view
    @spellTabView = spell.tabView
    @$el.find('#' + @spellView.id).after(@spellView.el).remove()
    @$el.find('#' + @spellTabView.id).after(@spellTabView.el).remove()
    @spellView.setThang thang
    @spellTabView.setThang thang
    @thangList.$el.hide()
    @spellPaletteView = @insertSubView new SpellPaletteView thang: thang
    @spellPaletteView.toggleControls {}, @spellView.controlsEnabled   # TODO: know when palette should have been disabled but didn't exist
    # New, good event
    Backbone.Mediator.publish 'tome:spell-shown', thang: thang, spell: spell
    # Bad, old one for old scripts (TODO)
    Backbone.Mediator.publish 'editor:tab-shown', thang: thang, methodName: spell.name

  reloadAllCode: ->
    spell.view.reloadCode false for spellKey, spell of @spells
    Backbone.Mediator.publish 'tome:cast-spells', spells: @spells

  destroy: ->
    super()
    for spellKey, spell of @spells
      spell.view.destroy()
