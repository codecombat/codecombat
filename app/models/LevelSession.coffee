CocoModel = require './CocoModel'
deltasLib = require 'lib/deltas'

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
      vcs = @get('vcs') or {}
      vcs.revisions ?= []
      @set 'vcs', vcs

  revisionMap = null
  getVCSRevisionMap: ->
    return revisionMap if revisionMap?
    revisionMap = {}
    vcs = @get('vcs')
    for revision in vcs.revisions
      revisionMap[revision.timestamp] = revision
    revisionMap

  findRevision: (revisionTimestamp) ->
    return @getVCSRevisionMap[revisionTimestamp]

  saveCodeRevision: (code, previous) ->
    if typeof(previous) is Date
      previous = findRevision()
    vcs = @get('vcs')
    current =
      timestamp: new Date() #TODO Works? Needs this: (new Date()).toISOString()?
      code: code
      previous: previous.timestamp
      newBranch: false
      codeLanguage: 'javaScript' #TODO: Where can I get that from? :/

    for revision in vcs.revisions
    #TODO: GetCode

    #TODO: Get previous miseriously?

    if previous:
      current.diff = jsondiffpatch.diff(current.code, previous.getCode()) if previous?
      previous.code = null;

    vcs = @get "vcs"
    vcs.revisions.push current

    @set "vcs", vcs
    current.timestamp

    @getVCSRevisionMap[current.timestamp] = current

    #TODO: Save delta to last source in list, set source to current source

  loadVersion: (language, timestamp) ->
    #Load a version by a given timestamp

  mergeVersion: (language, timestamp1, timestamp2) ->
    # Save a new version using the merged source of timestamp11 and timestamp2 if possible, else return false.


  deserializeVCS: ->
    for node in @levelfoo.get('language')
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
