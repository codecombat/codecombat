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
  browser:
    type: 'object'
  creatorName:
    type: 'string'
  levelName:
    type: 'string'
  levelID:
    type: 'string'
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

  dateFirstCompleted: {} # c.stringDate
#    title: 'Completed'
#    readOnly: true

  team: c.shortString()
  level: LevelSessionLevelSchema

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

    selected:  # Not tracked any more, delete with old level types
      type: [
        'null'
        'string'
      ]
    playing:
      type: 'boolean'  # Not tracked any more, delete with old level types
    frame:
      type: 'number'  # Not tracked any more, delete with old level types
    thangs:   # ... what is this? Is this used?
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
    topScores: c.array {},
      c.object {},
        type: c.scoreType
        date: c.date
          description: 'When the submission achieving this score happened.'
        score: {type: 'number'}  # Store 'time', 'damage-taken', etc. as negative numbers so the index works.
    capstoneStage:
      type: 'number'
      title: 'Capstone Stage'
      description: 'Current capstone stage of the level. If, say, stage 7 is yet incomplete, capstoneStage will be 7. If stage 7 is complete, capstoneStage will be 8. When a capstone level is complete, capstoneStage will be 1 higher than the final stage number.'

  code:
    type: 'object'
    additionalProperties:
      type: 'object'
      additionalProperties:
        type: 'string'
        format: 'code'
        maxLength: 1024*128

  codeLogs:
    type: 'array'

  codeLanguage:
    type: 'string'
    
  codeConcepts:
    type: 'array'
    items:
      type: 'string'    

  playtime:
    type: 'number'
    title: 'Playtime'
    description: 'The total playtime on this session in seconds'
    
  hintTime:
    type: 'number'
    title: 'Hint Time'
    description: 'The total time hints viewed in seconds'
    
  timesCodeRun:
    type: 'number'
    title: 'Times Code Run'
    description: 'The total times the code has been run'
    
  timesAutocompleteUsed:
    type: 'number'
    title: 'Times Autocomplete Used'
    description: 'The total times autocomplete was used'

  teamSpells:
    type: 'object'
    additionalProperties:
      type: 'array'

  players:
    type: 'object'

  chat:
    type: 'array'

  ladderAchievementDifficulty:
    type: 'integer'
    minimum: 0
    description: 'What ogre AI difficulty, 0-4, this human session has beaten in a multiplayer arena.'

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

  isRanking:
    type: 'boolean'
    description: 'Whether this session is still in the first ranking chain after being submitted.'

  randomSimulationIndex:
    type: 'number'
    description: 'A random updated every time the game is randomly simulated for a uniform random distribution of simulations (see #2448).'
    minimum: 0
    maximum: 1

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
          description: 'The total seconds of playtime on this session when the match was computed. Not currently tracked.'
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
        simulator: {type: 'object', description: 'Holds info on who simulated the match, and with what tools.'}
        randomSeed: {description: 'Stores the random seed that was used during this match.'}

  leagues:
    c.array {description: 'Multiplayer data for the league corresponding to Clans and CourseInstances the player is a part of.'},
      c.object {},
        leagueID: {type: 'string', description: 'The _id of a Clan or CourseInstance the user belongs to.'}
        stats: c.object {description: 'Multiplayer match statistics corresponding to this entry in the league.'}
        lastOpponentSubmitDate: c.date {description: 'The submitDate of the last league session we selected to play against (for playing through league opponents in order).'}

  isForClassroom:
    type: 'boolean'
    title: 'Is For Classroom'
    description: 'The level session was created for a user inside a course'

  published:
    type: 'boolean'
    title: 'Published to Project Gallery'
    description: 'Project was published to the Project Gallery for peer students to see'

  keyValueDb:
    type: 'object'
    title: 'Key Value DB'
    description: 'Simplified key-value database for game-dev levels'

LevelSessionSchema.properties.leagues.items.properties.stats.properties = _.pick LevelSessionSchema.properties, 'meanStrength', 'standardDeviation', 'totalScore', 'numberOfWinsAndTies', 'numberOfLosses', 'scoreHistory', 'matches'

c.extendBasicProperties LevelSessionSchema, 'level.session'
c.extendPermissionsProperties LevelSessionSchema, 'level.session'

module.exports = LevelSessionSchema
