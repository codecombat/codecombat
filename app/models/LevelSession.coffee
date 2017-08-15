CocoModel = require './CocoModel'
api = require('core/api')

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
    @get('submittedCodeLanguage')? and @get('team')?

  completed: ->
    @get('state')?.complete || @get('submitted') || false

  shouldAvoidCorruptData: (attrs) ->
    return false unless me.team is 'humans'
    if _.string.startsWith (attrs?.code ? @get('code'))?.anya?.makeBid ? '', 'var __interceptThis'
      noty text: "Not saving session--it's trying to overwrite Anya's code with transpiled output. Please let us know and help us reproduce this bug!", layout: 'topCenter', type: 'error', killer: false, timeout: 120000
      return true
    false

  save: (attrs, options) ->
    return if @shouldAvoidCorruptData attrs
    super attrs, options

  increaseDifficulty: (callback) ->
    state = @get('state') ? {}
    state.difficulty = (state.difficulty ? 0) + 1
    delete state.lastUnsuccessfulSubmissionTime
    @set 'state', state
    @trigger 'change-difficulty'
    @save null, success: callback

  timeUntilResubmit: ->
    state = @get('state') ? {}
    return 0 unless last = state.lastUnsuccessfulSubmissionTime
    last = new Date(last) if _.isString last
    # Wait at least this long before allowing submit button active again.
    wait = (last - new Date()) + 22 * 60 * 60 * 1000
    if wait > 24 * 60 * 60 * 1000
      # System clock must've gotten busted; max out at one day's wait.
      wait = 24 * 60 * 60 * 1000
      state.lastUnsuccessfulSubmissionTime = new Date()
      @set 'state', state
    wait

  recordScores: (scores, level) ->
    return unless scores
    state = @get 'state'
    oldTopScores = state.topScores ? []
    newTopScores = []
    now = new Date()
    for scoreType in level.get('scoreTypes') ? []
      oldTopScore = _.find oldTopScores, type: scoreType
      newScore = scores[scoreType]
      unless newScore?
        newTopScores.push oldTopScore
        continue
      newScore *= -1 if scoreType in ['time', 'damage-taken']  # Make it so that higher is better
      if not oldTopScore? or newScore > oldTopScore.score
        newTopScores.push type: scoreType, date: now, score: newScore
      else
        newTopScores.push oldTopScore
    state.topScores = newTopScores
    @set 'state', state

  generateSpellsObject: (options={}) ->
    {level} = options
    {createAetherOptions} = require 'lib/aether_utils'
    aetherOptions = createAetherOptions functionName: 'plan', codeLanguage: @get('codeLanguage'), skipProtectAPI: options.level?.isType('game-dev')
    spellThang = thang: {id: 'Hero Placeholder'}, aether: new Aether aetherOptions
    spells = "hero-placeholder/plan": thang: spellThang, name: 'plan'
    source = @get('code')?['hero-placeholder']?.plan ? ''
    try
      spellThang.aether.transpile source
    catch e
      console.log "Couldn't transpile!\n#{source}\n", e
      spellThang.aether.transpile ''
    spells

  isFake: -> @id is 'A Fake Session ID'

  inLeague: (leagueId) ->
    return false unless @get('leagues')
    for league in @get('leagues')
      return true if league.leagueID is leagueId
    return false

  updateKeyValueDb: (keyValueDb) ->
    oldDb = @get('keyValueDb') ? {}
    @originalKeyValueDb ?= oldDb
    @set('keyValueDb', keyValueDb) if _.size keyValueDb

  saveKeyValueDb: ->
    keyValueDb = @get('keyValueDb') ? {}
    return unless @originalKeyValueDb
    return if @isFake()
    for key, value of keyValueDb
      oldValue = @originalKeyValueDb[key]
      if not oldValue or typeof(oldValue) is 'string' or typeof(value) is 'string'
        api.levelSessions.setKeyValue({ sessionID: @id, key, value})
      else if typeof(oldValue) is 'number' and typeof(value) is 'number'
        increment = value - oldValue
        api.levelSessions.incrementKeyValue({ sessionID: @id, key, value: increment})

    @set('keyValueDb', keyValueDb) if _.size keyValueDb
    delete @originalKeyValueDb



