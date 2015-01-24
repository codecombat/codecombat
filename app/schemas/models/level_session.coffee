c = require './../schemas'

LevelSessionPlayerSchema = c.object
  id: c.objectId
    links: [
      {
        rel: 'extra'
        href: '/db/user/{($)}'
      }
    ]
  time:
    type: 'Number'
  changes:
    type: 'Number'

LevelSessionLevelSchema = c.object {required: ['original', 'majorVersion'], links: [{rel: 'db', href: '/db/level/{(original)}/version/{(majorVersion)}'}]},
  original: c.objectId({})
  majorVersion:
    type: 'integer'
    minimum: 0

LevelSessionSchema = c.object
  title: 'Session'
  description: 'A single session for a given level.'
  default:
    codeLanguage: 'python'
    submittedCodeLanguage: 'python'
    playtime: 0

_.extend LevelSessionSchema.properties,
  # denormalization
  creatorName:
    type: 'string'
  levelName:
    type: 'string'
  levelID:
    type: 'string'
  multiplayer:
    type: 'boolean'
  creator: c.objectId
    links:
      [
        {
          rel: 'extra'
          href: '/db/user/{($)}'
        }
      ]
  created: c.date
    title: 'Created'
    readOnly: true

  changed: c.date
    title: 'Changed'
    readOnly: true

  team: c.shortString()
  level: LevelSessionLevelSchema

  screenshot:
    type: 'string'

  heroConfig: c.HeroConfigSchema

  state: c.object {},
    complete:
      type: 'boolean'
    scripts: c.object {},
      ended:
        type: 'object'
        additionalProperties:
          type: 'number'
      currentScript:
        type: [
          'null'
          'string'
        ]
      currentScriptOffset:
        type: 'number'

    selected:
      type: [
        'null'
        'string'
      ]
    playing:
      type: 'boolean'  # Not tracked any more
    frame:
      type: 'number'  # Not tracked any more
    thangs:
      type: 'object'
      additionalProperties:
        title: 'Thang'
        type: 'object'
        properties:
          methods:
            type: 'object'
            additionalProperties:
              title: 'Thang Method'
              type: 'object'
              properties:
                metrics:
                  type: 'object'
                source:
                  type: 'string'
    goalStates:
      type: 'object'
      description: 'Maps Goal ID on a goal state object'
      additionalProperties:
        title: 'Goal State'
        type: 'object'
        properties:
          status: enum: ['failure', 'incomplete', 'success']
    submissionCount:
      description: 'How many times the session has been submitted for real-time playback (can affect the random seed).'
      type: 'integer'
      minimum: 0
    difficulty:
      description: 'The highest difficulty level beaten, for use in increasing-difficulty replayable levels.'
      type: 'integer'
      minimum: 0
    lastUnsuccessfulSubmissionTime: c.date
      description: 'The last time that real-time submission was started without resulting in a win.'
    flagHistory:
      description: 'The history of flag events during the last real-time playback submission.'
      type: 'array'
      items: c.object {required: ['player', 'color', 'time', 'active']},
        player: {type: 'string'}
        team: {type: 'string'}
        color: {type: 'string', enum: ['green', 'black', 'violet']}
        time: {type: 'number', minimum: 0}
        active: {type: 'boolean'}
        pos: c.object {required: ['x', 'y']},
          x: {type: 'number'}
          y: {type: 'number'}
        source: {type: 'string', enum: ['click']}  # Do not store 'code' flag events in the session.

  code:
    type: 'object'
    additionalProperties:
      type: 'object'
      additionalProperties:
        type: 'string'
        format: 'code'

  codeLanguage:
    type: 'string'

  playtime:
    type: 'number'
    title: 'Playtime'
    description: 'The total playtime on this session'

  teamSpells:
    type: 'object'
    additionalProperties:
      type: 'array'

  players:
    type: 'object'

  chat:
    type: 'array'

  meanStrength:
    type: 'number'

  standardDeviation:
    type: 'number'
    minimum: 0

  totalScore:
    type: 'number'

  submitted:
    type: 'boolean'

  submitDate: c.date
    title: 'Submitted'

  submittedCode:
    type: 'object'
    additionalProperties:
      type: 'object'
      additionalProperties:
        type: 'string'
        format: 'code'

  submittedCodeLanguage:
    type: 'string'

  transpiledCode:
    type: 'object'
    additionalProperties:
      type: 'object'
      additionalProperties:
        type: 'string'
        format: 'code'

  isRanking:
    type: 'boolean'
    description: 'Whether this session is still in the first ranking chain after being submitted.'

  unsubscribed:
    type: 'boolean'
    description: 'Whether the player has opted out of receiving email updates about ladder rankings for this session.'

  numberOfWinsAndTies:
    type: 'number'

  numberOfLosses:
    type: 'number'

  scoreHistory:
    type: 'array'
    title: 'Score History'
    description: 'A list of objects representing the score history of a session'
    items:
      title: 'Score History Point'
      description: 'An array with the format [unix timestamp, totalScore]'
      type: 'array'
      items:
        type: 'number'

  matches:
    type: 'array'
    title: 'Matches'
    description: 'All of the matches a submitted session has played in its current state.'
    items:
      type: 'object'
      properties:
        date: c.date
          title: 'Date computed'
          description: 'The date a match was computed.'
        playtime:
          title: 'Playtime so far'
          description: 'The total seconds of playtime on this session when the match was computed.'
          type: 'number'
        metrics:
          type: 'object'
          title: 'Metrics'
          description: 'Various information about the outcome of a match.'
          properties:
            rank:
              title: 'Rank'
              description: 'A 0-indexed ranking representing the player\'s standing in the outcome of a match'
              type: 'number'
        opponents:
          type: 'array'
          title: 'Opponents'
          description: 'An array containing information about the opponents\' sessions in a given match.'
          items:
            type: 'object'
            properties:
              sessionID:
                title: 'Opponent Session ID'
                description: 'The session ID of an opponent.'
                type: ['object', 'string', 'null']
              userID:
                title: 'Opponent User ID'
                description: 'The user ID of an opponent'
                type: ['object', 'string', 'null']
              name:
                title: 'Opponent name'
                description: 'The name of the opponent'
                type: ['string', 'null']
              totalScore:
                title: 'Opponent total score'
                description: 'The totalScore of a user when the match was computed'
                type: ['number', 'string', 'null']
              metrics:
                type: 'object'
                properties:
                  rank:
                    title: 'Opponent Rank'
                    description: 'The opponent\'s ranking in a given match'
                    type: 'number'
              codeLanguage:
                type: ['string', 'null']  # 'null' in case an opponent session got corrupted, don't care much here
                description: 'What submittedCodeLanguage the opponent used during the match'

c.extendBasicProperties LevelSessionSchema, 'level.session'
c.extendPermissionsProperties LevelSessionSchema, 'level.session'

module.exports = LevelSessionSchema
