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
      @set 'state', state

  saveVersion: (previous, source) ->
    @get
    prevCode = previous.generateCode()


    jsondiffpatch.diff(source, )
    #TODO: Save delta to last source in list, set source to current source

  loadVersion: (language, timestamp) ->
    #Load a version by a given timestamp

  mergeVersion: (language, timestamp1, timestamp2) ->
    # Save a new version using the merged source of timestamp11 and timestamp2 if possible, else return false.

  lookupTable:


  deserializeVCS:
    for node in @levelfoo[language]
      lookupTable[node.id] = node






  ###deserializeVCS: (language) ->
    # No need to walk the whole list here, could do it lazily.
    needsLink = {}
    isLink = {}
    for node in @levelfoo[language]
      nextIDs = node.next
      node.next = []
      for nextID in node.nextIDs
        if nextID in isLink
          node.next.push isLink[nextID]
        else
          needsLink[nextID] ?= []
          needsLink[nextID].push node
      isLink[node.id] = node



  serializeVCS: (language) ->
    vcs = huh.language
      prevs = node.prevs
      for
      for prev in node.prevs




###

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
