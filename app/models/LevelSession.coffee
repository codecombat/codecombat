CocoModel = require './CocoModel'

module.exports = class LevelSession extends CocoModel
  @className: 'LevelSession'
  @schema: require 'schemas/models/level_session'
  urlRoot: '/db/level.session'

  initialize: ->
    super()
    @on 'sync', (e) =>
      state = @get('state') or {}
      state.scripts ?= {}
      @set('state', state)

  updatePermissions: ->
    permissions = @get 'permissions', true
    permissions = (p for p in permissions when p.target isnt 'public')
    if @get('multiplayer')
      permissions.push {target: 'public', access: 'write'}
    @set 'permissions', permissions

  getSourceFor: (spellKey) ->
    # spellKey ex: 'tharin/plan'
    code = @get('code')
    parts = spellKey.split '/'
    code?[parts[0]]?[parts[1]]

  readyToRank: ->
    return false unless @get('levelID')  # If it hasn't been denormalized, then it's not ready.
    return false unless c1 = @get('code')
    return false unless team = @get('team')
    return true unless c2 = @get('submittedCode')
    thangSpellArr = (s.split('/') for s in @get('teamSpells')[team])
    for item in thangSpellArr
      thang = item[0]
      spell = item[1]
      return true if c1[thang][spell] isnt c2[thang]?[spell]
    false

  isMultiplayer: ->
    @get('team')? # Only multiplayer level sessions have teams defined

  completed: ->
    @get('state')?.complete || false

  shouldAvoidCorruptData: (attrs) ->
    return false unless me.team is 'humans'
    if _.string.startsWith (attrs?.code ? @get('code'))?.anya?.makeBid ? '', 'var __interceptThis'
      noty text: "Not saving session--it's trying to overwrite Anya's code with transpiled output. Please let us know and help us reproduce this bug!", layout: 'topCenter', type: 'error', killer: false, timeout: 120000
      return true
    false

  save: (attrs, options) ->
    return if @shouldAvoidCorruptData attrs
    super attrs, options

  increaseDifficulty: ->
    state = @get('state') ? {}
    state.difficulty = (state.difficulty ? 0) + 1
    delete state.lastUnsuccessfulSubmissionTime
    @set 'state', state
    @save()
    @trigger 'change-difficulty'

  timeUntilResubmit: ->
    state = @get('state') ? {}
    return 0 unless last = state.lastUnsuccessfulSubmissionTime
    last = new Date(last) if _.isString last
    # Wait at least this long before allowing submit button active again.
    (last - new Date()) + 22 * 60 * 60 * 1000
