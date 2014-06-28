CocoModel = require('./CocoModel')

module.exports = class LevelSession extends CocoModel
  @className: "LevelSession"
  @schema: require 'schemas/models/level_session'
  urlRoot: "/db/level.session"

  initialize: ->
    super()
    @on 'sync', (e) =>
      state = @get('state') or {}
      state.scripts ?= {}
      @set('state', state)

  updatePermissions: ->
    permissions = @get 'permissions'
    permissions = (p for p in permissions when p.target isnt 'public')
    if @get('multiplayer')
      permissions.push {target:'public', access:'write'}
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
    thangSpellArr = (s.split("/") for s in @get('teamSpells')[team])
    for item in thangSpellArr
      thang = item[0]
      spell = item[1]
      return true if c1[thang][spell] isnt c2[thang]?[spell]
    false
