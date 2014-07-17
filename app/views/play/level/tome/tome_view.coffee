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

window.SHIM_WORKER_PATH = '/javascripts/workers/catiline_worker_shim.js'

module.exports = class TomeView extends View
  id: 'tome-view'
  template: template
  controlsEnabled: true
  cache: false

  subscriptions:
    'tome:spell-loaded': 'onSpellLoaded'
    'tome:cast-spell': 'onCastSpell'
    'tome:toggle-spell-list': 'onToggleSpellList'
    'tome:change-language': 'updateLanguageForAllSpells'
    'surface:sprite-selected': 'onSpriteSelected'
    'god:new-world-created': 'onNewWorld'
    'tome:comment-my-code': 'onCommentMyCode'

  events:
    'click #spell-view': 'onSpellViewClick'
    'click': 'onClick'

  afterRender: ->
    super()
    @worker = @createWorker()
    programmableThangs = _.filter @options.thangs, 'isProgrammable'
    if programmableThangs.length
      @createSpells programmableThangs, programmableThangs[0].world  # Do before spellList, thangList, and castButton
      @spellList = @insertSubView new SpellListView spells: @spells, supermodel: @supermodel
      @thangList = @insertSubView new ThangListView spells: @spells, thangs: @options.thangs, supermodel: @supermodel
      @castButton = @insertSubView new CastButtonView spells: @spells, levelID: @options.levelID
      @teamSpellMap = @generateTeamSpellMap(@spells)
    else
      @cast()
      console.warn 'Warning: There are no Programmable Thangs in this level, which makes it unplayable.'
    delete @options.thangs

  onNewWorld: (e) ->
    thangs = _.filter e.world.thangs, 'inThangList'
    programmableThangs = _.filter thangs, 'isProgrammable'
    @createSpells programmableThangs, e.world
    @thangList.adjustThangs @spells, thangs
    @spellList.adjustSpells @spells

  onCommentMyCode: (e) ->
    for spellKey, spell of @spells when spell.canWrite()
      console.log 'Commenting out', spellKey
      commentedSource = 'return;  // Commented out to stop infinite loop.\n' + spell.getSource()
      spell.view.updateACEText commentedSource
      spell.view.recompile false
    @cast()

  createWorker: ->
    return new Worker('/javascripts/workers/aether_worker.js')

  generateTeamSpellMap: (spellObject) ->
    teamSpellMap = {}
    for spellName, spell of spellObject
      teamName = spell.team
      teamSpellMap[teamName] ?= []

      spellNameElements = spellName.split '/'
      thangName = spellNameElements[0]
      spellName = spellNameElements[1]

      teamSpellMap[teamName].push thangName if thangName not in teamSpellMap[teamName]

    return teamSpellMap

  createSpells: (programmableThangs, world) ->
    language = @options.session.get('codeLanguage') ? me.get('aceConfig')?.language ? 'javascript'
    pathPrefixComponents = ['play', 'level', @options.levelID, @options.session.id, 'code']
    @spells ?= {}
    @thangSpells ?= {}
    for thang in programmableThangs
      continue if @thangSpells[thang.id]?
      @thangSpells[thang.id] = []
      for methodName, method of thang.programmableMethods
        pathComponents = [thang.id, methodName]
        if method.cloneOf
          pathComponents[0] = method.cloneOf  # referencing another Thang's method
        pathComponents[0] = _.string.slugify pathComponents[0]
        spellKey = pathComponents.join '/'
        @thangSpells[thang.id].push spellKey
        unless method.cloneOf
          skipProtectAPI = @getQueryVariable 'skip_protect_api', (@options.levelID in ['gridmancer'])
          spell = @spells[spellKey] = new Spell
            programmableMethod: method
            spellKey: spellKey
            pathComponents: pathPrefixComponents.concat(pathComponents)
            session: @options.session
            otherSession: @options.otherSession
            supermodel: @supermodel
            skipProtectAPI: skipProtectAPI
            worker: @worker
            language: language
            spectateView: @options.spectateView

    for thangID, spellKeys of @thangSpells
      thang = world.getThangByID thangID
      if thang
        @spells[spellKey].addThang thang for spellKey in spellKeys
      else
        delete @thangSpells[thangID]
        spell.removeThangID thangID for spell in @spells
    null

  onSpellLoaded: (e) ->
    for spellID, spell of @spells
      return unless spell.loaded
    @cast()

  onCastSpell: (e) ->
    # A single spell is cast.
    # Hmm; do we need to make sure other spells are all cast here?
    @cast e?.preload

  cast: (preload=false) ->
    Backbone.Mediator.publish 'tome:cast-spells', spells: @spells, preload: preload

  onToggleSpellList: (e) ->
    @spellList.rerenderEntries()
    @spellList.$el.toggle()

  onSpellViewClick: (e) ->
    @spellList.$el.hide()

  onClick: (e) ->
    Backbone.Mediator.publish 'tome:focus-editor' unless $(e.target).parents('.popover').length

  clearSpellView: ->
    @spellView?.dismiss()
    @spellView?.$el.after('<div id="' + @spellView.id + '"></div>').detach()
    @spellView = null
    @spellTabView?.$el.after('<div id="' + @spellTabView.id + '"></div>').detach()
    @spellTabView = null
    @removeSubView @spellPaletteView if @spellPaletteView
    @spellPaletteView = null
    @castButton?.$el.hide()
    @thangList?.$el.show()

  onSpriteSelected: (e) ->
    thang = e.thang
    spellName = e.spellName
    @spellList?.$el.hide()
    return @clearSpellView() unless thang
    spell = @spellFor thang, spellName
    unless spell?.canRead()
      @clearSpellView()
      @updateSpellPalette thang, spell
      return
    unless spell.view is @spellView
      @clearSpellView()
      @spellView = spell.view
      @spellTabView = spell.tabView
      @$el.find('#' + @spellView.id).after(@spellView.el).remove()
      @$el.find('#' + @spellTabView.id).after(@spellTabView.el).remove()
      @castButton.attachTo @spellView
      @thangList.$el.hide()
      Backbone.Mediator.publish 'tome:spell-shown', thang: thang, spell: spell
    @spellList.setThangAndSpell thang, spell
    @spellView?.setThang thang
    @spellTabView?.setThang thang
    @updateSpellPalette thang, spell

  updateSpellPalette: (thang, spell) ->
    return unless thang and @spellPaletteView?.thang isnt thang and thang.programmableProperties or thang.apiProperties
    @spellPaletteView = @insertSubView new SpellPaletteView thang: thang, supermodel: @supermodel, programmable: spell?.canRead(), language: spell?.language ? @options.session.get('codeLanguage'), session: @options.session
    @spellPaletteView.toggleControls {}, spell.view.controlsEnabled if spell   # TODO: know when palette should have been disabled but didn't exist

  spellFor: (thang, spellName) ->
    return null unless thang?.isProgrammable
    selectedThangSpells = (@spells[spellKey] for spellKey in @thangSpells[thang.id])
    if spellName
      spell = _.find selectedThangSpells, {name: spellName}
    else
      spell = @thangList.topSpellForThang thang
      #spell = selectedThangSpells[0]  # TODO: remember last selected spell for this thang
    spell

  reloadAllCode: ->
    spell.view.reloadCode false for spellKey, spell of @spells when spell.team is me.team or (spell.team in ['common', 'neutral', null])
    Backbone.Mediator.publish 'tome:cast-spells', spells: @spells, preload: false

  updateLanguageForAllSpells: (e) ->
    spell.updateLanguageAether e.language for spellKey, spell of @spells when spell.canWrite()
    @cast()

  destroy: ->
    spell.destroy() for spellKey, spell of @spells
    @worker?.terminate()
    super()
