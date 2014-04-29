# TODO: be useful to add error indicator states to the spellsPopoverTemplate
# TODO: reordering based on errors isn't working yet

View = require 'views/kinds/CocoView'
ThangAvatarView = require 'views/play/level/thang_avatar_view'
template = require 'templates/play/level/tome/thang_list_entry'
spellsPopoverTemplate = require 'templates/play/level/tome/thang_list_entry_spells'
{me} = require 'lib/auth'

module.exports = class ThangListEntryView extends View
  tagName: 'div'  #'li'
  className: 'thang-list-entry-view'
  template: template
  controlsEnabled: true
  reasonsToBeDisabled: {}

  subscriptions:
    'tome:problems-updated': "onProblemsUpdated"
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'surface:frame-changed': "onFrameChanged"
    'level-set-letterbox': 'onSetLetterbox'
    'tome:thang-list-entry-popover-shown': 'onThangListEntryPopoverShown'
    'surface:coordinates-shown': 'onSurfaceCoordinatesShown'

  events:
    'click': 'onClick'
    'mouseenter': 'onMouseEnter'
    'mouseleave': 'onMouseLeave'

  constructor: (options) ->
    super options
    @thang = options.thang
    @spells = options.spells
    @permission = options.permission
    @reasonsToBeDisabled = {}
    @sortSpells()

  getRenderData: (context={}) ->
    context = super context
    context.thang = @thang
    context.spell = @spells
    context

  afterRender: ->
    super()
    @avatar?.destroy()
    @avatar = new ThangAvatarView thang: @thang, includeName: true, supermodel: @supermodel
    @$el.append @avatar.el  # Before rendering, so render can use parent for popover
    @avatar.render()
    @avatar.setSharedThangs @spells.length  # A bit weird to call it sharedThangs; could refactor if we like this
    @$el.toggle Boolean(@thang.exists)
    @$el.popover(
      animation: false
      html: true
      placement: 'bottom'
      trigger: 'manual'
      content: @getSpellListHTML()
      container: @$el.parent().parent().parent()
    )

  sortSpells: ->
    return if @sorted
    # Keep only spells for which we have permissions
    spells = _.filter @spells, (s) => @options.permission and me.team in s.permissions[@options.permission]
    @spells = _.sortBy spells, @sortScoreForSpell
    @sorted = true

  sortScoreForSpell: (s) =>
    # Sort by errored-out spells first, then spells shared with fewest other Thangs
    # Lower comes first
    score = 0
    # My errors are highest priority
    score -= 9001900190019001 * (s.thangs[@thang.id].aether?.getAllProblems().length or 0)
    # Other shared Thangs errors are also high priority
    score -= _.reduce s.thangs, (spellThang, num) -> 900190019001 * (spellThang.aether?.getAllProblems().length or 0)
    # Read-only spells at the bottom
    score += 90019001 unless s.canWrite()
    # The more Thangs sharing a spell, the lower
    score += 9001 * _.size(s.thangs)
    score

  onClick: (e) ->
    return unless @controlsEnabled
    @sortSpells()
    Backbone.Mediator.publish "level-select-sprite", thangID: @thang.id, spellName: @spells[0]?.name

  onMouseEnter: (e) ->
    return unless @controlsEnabled and @spells.length
    @clearTimeouts()
    @showSpellsTimeout = _.delay @showSpells, 100

  onMouseLeave: (e) ->
    return unless @controlsEnabled and @spells.length
    @clearTimeouts()
    @hideSpellsTimeout = _.delay @hideSpells, 100

  clearTimeouts: ->
    clearTimeout @showSpellsTimeout if @showSpellsTimeout
    clearTimeout @hideSpellsTimeout if @hideSpellsTimeout
    @showSpellsTimeout = @hideSpellsTimeout = null

  onThangListEntryPopoverShown: (e) ->
    # I couldn't figure out how to get the mouseenter / mouseleave to always work, so this is a fallback
    # to hide our popover if another Thang's popover gets shown.
    return if e.entry is @
    @hideSpells()

  onSurfaceCoordinatesShown: (e) ->
    # Definitely aren't hovering over this.
    @hideSpells()

  showSpells: =>
    @clearTimeouts()
    @sortSpells()
    @$el.data('bs.popover').options.content = @getSpellListHTML()
    @$el.popover('setContent').popover('show')
    @$el.parent().parent().parent().i18n()
    @popover = @$el.parent().parent().parent().find('.popover')
    @popover.off 'mouseenter mouseleave'
    @popover.mouseenter (e) => @showSpells() if @controlsEnabled
    @popover.mouseleave (e) => @hideSpells()
    thangID = @thang.id
    @popover.find('code').click (e) ->
      Backbone.Mediator.publish "level-select-sprite", thangID: thangID, spellName: $(@).data 'spell-name'
    Backbone.Mediator.publish 'tome:thang-list-entry-popover-shown', entry: @

  hideSpells: =>
    @clearTimeouts()
    @$el.popover('hide')

  getSpellListHTML: ->
    spellsPopoverTemplate {spells: @spells}

  onProblemsUpdated: (e) ->
    return unless e.spell in @spells
    @sorted = false

  onSetLetterbox: (e) ->
    if e.on then @reasonsToBeDisabled.letterbox = true else delete @reasonsToBeDisabled.letterbox
    @updateControls()

  onDisableControls: (e) ->
    return if e.controls and not ('surface' in e.controls)  # disable selection?
    @reasonsToBeDisabled.controls = true
    @updateControls()

  onEnableControls: (e) ->
    delete @reasonsToBeDisabled.controls
    @updateControls()

  updateControls: ->
    enabled = _.keys(@reasonsToBeDisabled).length is 0
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.toggleClass('disabled', not enabled)

  onFrameChanged: (e) ->
    # Optimize
    return unless currentThang = e.world.thangMap[@thang.id]
    exists = Boolean currentThang.exists
    if @thangDidExist isnt exists
      @$el.toggle exists
      @thangDidExist = exists
    dead = exists and currentThang.health <= 0
    if @thangWasDead isnt dead
      @$el.toggleClass 'dead', dead
      @thangWasDead = dead

  destroy: ->
    @avatar?.destroy()
    @popover?.remove()
    @popover?.off 'mouseenter mouseleave'
    @popover?.find('code').off 'click'
    super()
