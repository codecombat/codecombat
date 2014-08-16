CocoModel = require './CocoModel'

module.exports = class LevelSession extends CocoModel
  @className: 'LevelSession'
  @schema: require 'schemas/models/level_session'
  urlRoot: '/db/level.session'

  maxRevCount: 100

  initialize: ->
    super()
    @on 'sync', (e) =>
      state = @get('state') or {}
      state.scripts ?= {}
      @set 'state', state
      @vcs = new VCS @maxRevCount, @get('vcs')
    @vcs = new VCS @maxRevCount

  set: (key, value, options) ->
    if key is 'code'
      @vcs.save value
      @set 'vcs', @vcs.serialize()
    super(arguments...)

  getRevisionHeads: ->
    @vcs.heads

  getRevisions: ->
    @vcs.revs

  loadRevision: (revision) ->
    @vcs.load revision
    @set 'vcs', @vcs.serialize()

  updatePermissions: ->
    permissions = @get 'permissions'
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
